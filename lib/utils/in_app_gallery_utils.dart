import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hw_video_compress/hw_video_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'permission_access_utils.dart';

/// Utility class for the in_app_gallery package.
/// Provides methods to handle camera picking, media selection processing,
/// and video/image compression.
class InAppGalleryUtils {
  static final HwVideoCompress _hwVideoCompress = HwVideoCompress();

  /// Opens the device camera to take a photo or record a video.
  /// Checks for camera permissions first, and shows a settings permission dialog if permanently denied.
  /// Returns the picked [File] or null if the user cancelled or denied permission.
  static Future<File?> onCameraPicked({
    required BuildContext context,
    int? imageQuality,
    bool isVideo = false,
  }) async {
    try {
      final status = await Permission.camera.status;

      if (status.isPermanentlyDenied) {
        // Check if context is still mounted before using it across an async gap
        if (!context.mounted) return null;
        await PermissionAccessUtils.showPermissionDialog(context, 'Camera');
        return null;
      }

      final picker = ImagePicker();
      final XFile? pickedFile;
      if (isVideo) {
        pickedFile = await picker.pickVideo(source: ImageSource.camera);
      } else {
        pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: imageQuality,
        );
      }

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      // Handle or log potential platform exceptions
      debugPrint('Error picking media from camera: $e');
      return null;
    }
  }

  /// Formats byte size into human readable format (e.g. 1.5 MB).
  static String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Processes the selected media items from the gallery.
  /// Applies image and video compression if configured.
  /// Uses [editedFiles] when available for customized photos.
  /// Returns a list of processed [File]s ready for upload.
  static Future<List<File>> onSelectionCompleted({
    int? imageQuality,
    required List<AssetEntity> selectedMedia,
    Map<String, File>? editedFiles,
    required bool allowVideoCompression,
    void Function(String filename)? onVideoSizeExceeded,
    void Function(int current, int total)? onProgress,
  }) async {
    final List<File> finalFiles = [];
    const int maxVideoSizeBytes = 1500 * 1024 * 1024; // 1.5 GB
    final int totalFiles = selectedMedia.length;
    int currentFileIndex = 1;

    for (final asset in selectedMedia) {
      try {
        if (onProgress != null) {
          onProgress(currentFileIndex, totalFiles);
        }

        final bool hasEditedFile =
            editedFiles != null && editedFiles.containsKey(asset.id);
        final file = hasEditedFile ? editedFiles[asset.id]! : await asset.file;
        if (file == null) {
          currentFileIndex++;
          continue;
        }

        final originalBytes = await file.length();

        // -----------------------
        // HANDLE VIDEOS
        // -----------------------
        if (asset.type == AssetType.video) {
          if (!allowVideoCompression) {
            debugPrint(
              'Video Processed (Uncompressed): ${asset.title ?? file.path} | '
              'Size: ${formatBytes(originalBytes)}',
            );
            finalFiles.add(file);
            currentFileIndex++;
            continue; // Move to the next asset
          }

          if (originalBytes > maxVideoSizeBytes) {
            final filename = asset.title ?? 'Unknown Video';

            if (onVideoSizeExceeded != null) {
              onVideoSizeExceeded(filename);
            }
            currentFileIndex++;
            continue; // Skip compressing and adding this file
          }

          final compressedVideo = await compressVideo(file);
          final compressedBytes = await compressedVideo.length();
          debugPrint(
            'Video Processed (Compressed): ${asset.title ?? file.path} | '
            'Original Size: ${formatBytes(originalBytes)} -> '
            'Compressed Size: ${formatBytes(compressedBytes)}',
          );
          finalFiles.add(compressedVideo);
          currentFileIndex++;
          continue;
        }

        // -----------------------
        // HANDLE IMAGES
        // -----------------------
        if (hasEditedFile) {
          debugPrint(
            'Image Processed (User Edited): ${asset.title ?? file.path} | '
            'Size: ${formatBytes(originalBytes)}',
          );
          finalFiles.add(file);
        } else if (imageQuality == null) {
          debugPrint(
            'Image Processed (Uncompressed): ${asset.title ?? file.path} | '
            'Size: ${formatBytes(originalBytes)}',
          );
          finalFiles.add(file);
        } else {
          final compressedImage = await compressImage(
            file,
            quality: imageQuality,
          );
          final compressedBytes = await compressedImage.length();
          debugPrint(
            'Image Processed (Compressed): ${asset.title ?? file.path} | '
            'Original Size: ${formatBytes(originalBytes)} -> '
            'Compressed Size: ${formatBytes(compressedBytes)}',
          );
          finalFiles.add(compressedImage);
        }
        currentFileIndex++;
      } catch (e) {
        // Catch individual file failures so the whole loop doesn't crash
        debugPrint('Failed to process asset ${asset.title}: $e');
        currentFileIndex++;
      }
    }

    return finalFiles;
  }

  /// Stream of compression progress (0.0 to 1.0)
  static Stream<double> get progressStream {
    return _hwVideoCompress.onProgress;
  }

  /// Compresses an image and returns the compressed file.
  /// Uses native C bicubic compression via [BicubicResizer] when possible,
  /// with automatic fallback to [FlutterImageCompress].
  static Future<File> compressImage(File file, {int quality = 50}) async {
    try {
      final dir = await getTemporaryDirectory();
      final ext = file.path.toLowerCase().endsWith('.png') ? '.png' : '.jpg';
      final targetPath = '${dir.path}/${const Uuid().v4()}_compressed$ext';

      // 1. Attempt high-performance Bicubic native C resize/compression
      try {
        final bytes = await file.readAsBytes();
        final info = BicubicResizer.getImageInfo(bytes);
        final srcW = info.orientedWidth > 0 ? info.orientedWidth : info.width;
        final srcH =
            info.orientedHeight > 0 ? info.orientedHeight : info.height;

        if (srcW > 0 && srcH > 0) {
          final targetDims = BicubicResizer.computeFitDimensions(
            sourceWidth: srcW,
            sourceHeight: srcH,
            maxWidth: 1024,
            maxHeight: 1024,
          );

          final Uint8List compressedBytes;
          if (info.format == ImageFormat.png) {
            compressedBytes = await BicubicResizer.resizePngAsync(
              pngBytes: bytes,
              outputWidth: targetDims.width,
              outputHeight: targetDims.height,
            );
          } else {
            compressedBytes = await BicubicResizer.resizeJpegAsync(
              jpegBytes: bytes,
              outputWidth: targetDims.width,
              outputHeight: targetDims.height,
              quality: quality,
            );
          }

          final compressedFile = File(targetPath);
          await compressedFile.writeAsBytes(compressedBytes);
          return compressedFile;
        }
      } catch (e) {
        log('Bicubic compress fallback: $e');
      }

      // 2. Fallback to FlutterImageCompress
      final format = ext == '.png' ? CompressFormat.png : CompressFormat.jpeg;
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1024,
        minHeight: 1024,
        format: format,
      );

      if (result != null) {
        return File(result.path);
      }
    } catch (e) {
      log('Error compressing image: $e');
    }
    return file;
  }

  /// Resizes and crops an image file using [BicubicResizer] with native C performance.
  static Future<File> resizeAndCompressWithBicubic({
    required File inputFile,
    int? outputWidth,
    int? outputHeight,
    int? maxWidth,
    int? maxHeight,
    int quality = 90,
    int compressionLevel = 6,
    BicubicFilter filter = BicubicFilter.catmullRom,
    EdgeMode edgeMode = EdgeMode.clamp,
    double crop = 1.0,
    CropAnchor cropAnchor = CropAnchor.center,
    CropAspectRatio cropAspectRatio = CropAspectRatio.original,
    double aspectRatioWidth = 1.0,
    double aspectRatioHeight = 1.0,
    bool applyExifOrientation = true,
  }) async {
    final dir = await getTemporaryDirectory();
    final ext = inputFile.path.toLowerCase().endsWith('.png') ? '.png' : '.jpg';
    final targetPath = '${dir.path}/${const Uuid().v4()}_bicubic$ext';

    int targetW = outputWidth ?? 0;
    int targetH = outputHeight ?? 0;

    if (targetW <= 0 || targetH <= 0) {
      final bytes = await inputFile.readAsBytes();
      final info = BicubicResizer.getImageInfo(bytes);
      final srcW = info.orientedWidth > 0 ? info.orientedWidth : info.width;
      final srcH =
          info.orientedHeight > 0 ? info.orientedHeight : info.height;

      if (maxWidth != null || maxHeight != null) {
        final dims = BicubicResizer.computeFitDimensions(
          sourceWidth: srcW,
          sourceHeight: srcH,
          maxWidth: maxWidth ?? srcW,
          maxHeight: maxHeight ?? srcH,
        );
        targetW = dims.width;
        targetH = dims.height;
      } else {
        targetW = srcW;
        targetH = srcH;
      }
    }

    await BicubicResizer.resizeFileToFileAsync(
      inputPath: inputFile.path,
      outputPath: targetPath,
      outputWidth: targetW,
      outputHeight: targetH,
      quality: quality,
      compressionLevel: compressionLevel,
      filter: filter,
      edgeMode: edgeMode,
      crop: crop,
      cropAnchor: cropAnchor,
      cropAspectRatio: cropAspectRatio,
      aspectRatioWidth: aspectRatioWidth,
      aspectRatioHeight: aspectRatioHeight,
      applyExifOrientation: applyExifOrientation,
    );

    return File(targetPath);
  }

  /// Compresses a video using the native platform implementation via MethodChannel.
  static Future<File> compressVideo(File file) async {
    try {
      final originalSize = await file.length();

      // SKIP COMPRESSION IF ALREADY UNDER 100MB
      if (originalSize < 100 * 1024 * 1024) {
        return file;
      }

      final String? compressedPath = await _hwVideoCompress.compressVideo(
        file.path,
      );

      if (compressedPath != null) {
        final compressedFile = File(compressedPath);
        if (await compressedFile.exists()) {
          final compressedSize = await compressedFile.length();
          if (compressedSize >= originalSize) {
            try {
              await compressedFile.delete();
            } catch (_) {}
            return file;
          }
          return compressedFile;
        }
      }
    } catch (e) {
      log('Error compressing video: $e');
    }
    return file;
  }
}
