import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
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

  /// Opens the device camera to take a photo.
  /// Checks for camera permissions first, and shows a settings permission dialog if permanently denied.
  /// Returns the picked [File] or null if the user cancelled or denied permission.
  static Future<File?> onCameraPicked({
    required BuildContext context,
    int? imageQuality,
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
      // Use the built-in imageQuality parameter to save memory and processing time
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      // Handle or log potential platform exceptions
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Processes the selected media items from the gallery.
  /// Applies image and video compression if configured.
  /// Returns a list of processed [File]s ready for upload.
  static Future<List<File>> onSelectionCompleted({
    int? imageQuality,
    required List<AssetEntity> selectedMedia,
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

        final file = await asset.file;
        if (file == null) {
          currentFileIndex++;
          continue;
        }

        // -----------------------
        // HANDLE VIDEOS
        // -----------------------
        if (asset.type == AssetType.video) {
          if (!allowVideoCompression) {
            finalFiles.add(file);
            continue; // Move to the next asset
          }

          final originalBytes = await file.length();
          if (originalBytes > maxVideoSizeBytes) {
            final filename = asset.title ?? 'Unknown Video';

            if (onVideoSizeExceeded != null) {
              onVideoSizeExceeded(filename);
            }
            continue; // Skip compressing and adding this file
          }

          final compressedVideo = await compressVideo(file);
          finalFiles.add(compressedVideo);
          continue;
        }

        // -----------------------
        // HANDLE IMAGES
        // -----------------------
        if (imageQuality == null) {
          finalFiles.add(file);
        } else {
          final compressedImage = await compressImage(
            file,
            quality: imageQuality,
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
  static Future<File> compressImage(File file, {int quality = 50}) async {
    try {
      final dir = await getTemporaryDirectory();
      final ext = file.path.toLowerCase().endsWith('.png') ? '.png' : '.jpg';
      final format = ext == '.png' ? CompressFormat.png : CompressFormat.jpeg;
      final targetPath = '${dir.path}/${const Uuid().v4()}_compressed$ext';

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
