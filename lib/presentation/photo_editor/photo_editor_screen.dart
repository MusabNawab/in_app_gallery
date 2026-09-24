import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';

import 'widgets/widgets.dart';

export 'widgets/widgets.dart';

/// A comprehensive, high-performance photo editor screen powered by [BicubicResizer].
///
/// Features include:
/// - Freeform custom crop (drag edges and corners freely)
/// - Preset aspect ratio cropping (1:1, 4:3, 16:9, 9:16, 3:2, 2:3)
/// - Custom aspect ratio dialog (e.g. 5:4, 21:9, etc.)
/// - 90° clockwise rotation and horizontal flip
/// - Resolution presets (Original, FHD 1080p, HD 720p, 512px)
/// - Quality control slider (10-100)
/// - Native C Bicubic filter selector (Catmull-Rom, Mitchell, Cubic B-Spline)
/// - Native C edge handling modes (Clamp, Reflect, Wrap, Zero)
class PhotoEditorScreen extends StatefulWidget {
  final File file;
  final AssetEntity? asset;
  final int? initialQuality;
  final ThemeData? theme;

  const PhotoEditorScreen({
    super.key,
    required this.file,
    this.asset,
    this.initialQuality,
    this.theme,
  });

  /// Convenient static navigation method to open the photo editor.
  static Future<File?> open({
    required BuildContext context,
    required File file,
    AssetEntity? asset,
    int? initialQuality,
    ThemeData? theme,
  }) async {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PhotoEditorScreen(
          file: file,
          asset: asset,
          initialQuality: initialQuality,
          theme: theme,
        ),
      ),
    );
  }

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen>
    with SingleTickerProviderStateMixin {
  // Image metadata
  Uint8List? _imageBytes;
  int _originalWidth = 0;
  int _originalHeight = 0;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _loadingMessage = 'Loading image...';

  // Current editing state
  late TabController _tabController;

  // Aspect ratio presets (Free crop first!)
  final List<EditorAspectRatio> _aspectRatios =
      EditorAspectRatio.defaultPresets;

  late EditorAspectRatio _selectedAspectRatio;
  Rect _cropRect = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0); // Normalized 0-1
  int _rotationDegrees = 0; // 0, 90, 180, 270
  bool _flipHorizontal = false;

  // Custom aspect ratio if user entered one
  EditorAspectRatio? _customUserRatio;

  // Resize target presets (0 = Original, 1920 = FHD, 1080 = HD, 720 = SD, 512 = Thumb)
  int _targetMaxDimension = 0;
  late int _quality;
  BicubicFilter _filter = BicubicFilter.catmullRom;
  EdgeMode _edgeMode = EdgeMode.clamp;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _tabController = TabController(length: 3, vsync: this);
    _selectedAspectRatio = _aspectRatios[0]; // Default to Free Crop
    _quality = widget.initialQuality ?? 90;
    _loadImageData();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadImageData() async {
    try {
      final bytes = await widget.file.readAsBytes();
      final info = BicubicResizer.getImageInfo(bytes);
      final orientedW = info.orientedWidth > 0
          ? info.orientedWidth
          : info.width;
      final orientedH = info.orientedHeight > 0
          ? info.orientedHeight
          : info.height;

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _originalWidth = orientedW;
          _originalHeight = orientedH;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load image: $e')));
      }
    }
  }

  void _resetEdits() {
    setState(() {
      _selectedAspectRatio = _aspectRatios[0]; // Free crop
      _customUserRatio = null;
      _cropRect = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
      _rotationDegrees = 0;
      _flipHorizontal = false;
      _targetMaxDimension = 0;
      _quality = widget.initialQuality ?? 90;
      _filter = BicubicFilter.catmullRom;
      _edgeMode = EdgeMode.clamp;
    });
  }

  void _resetCropRect() {
    setState(() {
      _cropRect = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
    });
  }

  void _onAspectRatioSelected(EditorAspectRatio ratio) {
    setState(() {
      _selectedAspectRatio = ratio;
      _cropRect = _computeInitialCropRect(ratio);
    });
  }

  Rect _computeInitialCropRect(EditorAspectRatio ratio) {
    if (ratio.isFree) {
      // In Free mode, maintain current crop or reset to full
      return _cropRect;
    }

    final bool isRotated = _rotationDegrees == 90 || _rotationDegrees == 270;
    final double imgW = (isRotated ? _originalHeight : _originalWidth)
        .toDouble();
    final double imgH = (isRotated ? _originalWidth : _originalHeight)
        .toDouble();

    if (imgW <= 0 || imgH <= 0) return const Rect.fromLTWH(0, 0, 1, 1);

    final double imgAspect = imgW / imgH;
    final double targetAspect = ratio.isOriginal
        ? imgAspect
        : (ratio.numericRatio ?? imgAspect);

    if (imgAspect > targetAspect) {
      // Image is wider than target aspect ratio
      final double normW = targetAspect / imgAspect;
      final double normL = (1.0 - normW) / 2.0;
      return Rect.fromLTWH(normL, 0.0, normW, 1.0);
    } else {
      // Image is taller than target aspect ratio
      final double normH = imgAspect / targetAspect;
      final double normT = (1.0 - normH) / 2.0;
      return Rect.fromLTWH(0.0, normT, 1.0, normH);
    }
  }

  /// Crops and transforms an image region using hardware-accelerated [ui.Canvas].
  static Future<Uint8List> _cropAndTransformRegion({
    required Uint8List imageBytes,
    required Rect normalizedCropRect,
    int rotationDegrees = 0,
    bool flipHorizontal = false,
  }) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final srcW = image.width.toDouble();
    final srcH = image.height.toDouble();

    final cropX = (normalizedCropRect.left * srcW).clamp(0.0, srcW);
    final cropY = (normalizedCropRect.top * srcH).clamp(0.0, srcH);
    final cropW = (normalizedCropRect.width * srcW).clamp(1.0, srcW - cropX);
    final cropH = (normalizedCropRect.height * srcH).clamp(1.0, srcH - cropY);

    final srcRect = Rect.fromLTWH(cropX, cropY, cropW, cropH);

    final bool isRotated = rotationDegrees == 90 || rotationDegrees == 270;
    final int outW = (isRotated ? cropH : cropW).round();
    final int outH = (isRotated ? cropW : cropH).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.save();
    canvas.translate(outW / 2.0, outH / 2.0);
    if (flipHorizontal) {
      canvas.scale(-1.0, 1.0);
    }
    if (rotationDegrees != 0) {
      canvas.rotate(rotationDegrees * math.pi / 180.0);
    }

    final dstRect = Rect.fromLTWH(-cropW / 2.0, -cropH / 2.0, cropW, cropH);
    canvas.drawImageRect(
      image,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    final picture = recorder.endRecording();
    final croppedUiImage = await picture.toImage(outW, outH);
    final byteData = await croppedUiImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();
    croppedUiImage.dispose();

    return byteData!.buffer.asUint8List();
  }

  Future<void> _applyAndSave() async {
    if (_imageBytes == null) return;

    setState(() {
      _isProcessing = true;
      _loadingMessage = 'Processing...';
    });

    try {
      // Step 1: Crop and transform exact user-selected region
      final Uint8List workingBytes = await _cropAndTransformRegion(
        imageBytes: _imageBytes!,
        normalizedCropRect: _cropRect,
        rotationDegrees: _rotationDegrees,
        flipHorizontal: _flipHorizontal,
      );

      // Step 2: Read oriented dimensions of the cropped region
      final croppedInfo = BicubicResizer.getImageInfo(workingBytes);
      int targetW = croppedInfo.orientedWidth > 0
          ? croppedInfo.orientedWidth
          : croppedInfo.width;
      int targetH = croppedInfo.orientedHeight > 0
          ? croppedInfo.orientedHeight
          : croppedInfo.height;

      // Apply resolution downscale limit if user configured one
      if (_targetMaxDimension > 0 &&
          (targetW > _targetMaxDimension || targetH > _targetMaxDimension)) {
        final dims = BicubicResizer.computeFitDimensions(
          sourceWidth: targetW,
          sourceHeight: targetH,
          maxWidth: _targetMaxDimension,
          maxHeight: _targetMaxDimension,
        );
        targetW = dims.width;
        targetH = dims.height;
      }

      // Step 3: Run native C Bicubic filter & compression

      final processedBytes = await BicubicResizer.resizeAsync(
        bytes: workingBytes,
        outputWidth: targetW,
        outputHeight: targetH,
        quality: _quality,
        filter: _filter,
        edgeMode: _edgeMode,
      );

      // Step 4: Save to clean temporary file
      final dir = await getTemporaryDirectory();
      final ext = widget.file.path.toLowerCase().endsWith('.png')
          ? '.png'
          : '.jpg';
      final outputPath = '${dir.path}/edited_${const Uuid().v4()}$ext';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(processedBytes);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        Navigator.pop(context, outputFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Error editing photo: $e'),
          ),
        );
      }
    }
  }

  void _showCustomRatioDialog() {
    EditorDialogs.showCustomRatioDialog(
      context: context,
      onRatioApplied: (customRatio) {
        setState(() {
          _customUserRatio = customRatio;
        });
        _onAspectRatioSelected(customRatio);
      },
    );
  }

  void _showResolutionPicker() {
    EditorDialogs.showResolutionPicker(
      context: context,
      currentDimension: _targetMaxDimension,
      onDimensionSelected: (dim) {
        setState(() {
          _targetMaxDimension = dim;
        });
      },
    );
  }

  void _showFilterPicker() {
    EditorDialogs.showFilterPicker(
      context: context,
      currentFilter: _filter,
      onFilterSelected: (filter) {
        setState(() {
          _filter = filter;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? Theme.of(context);
    final primaryColor = effectiveTheme.primaryColor;

    return Theme(
      data: effectiveTheme.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Photo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset All',
              onPressed: _resetEdits,
            ),
            IconButton(
              icon: Icon(Icons.check_rounded, color: primaryColor, size: 28),
              tooltip: 'Apply & Save',
              onPressed: _isProcessing || _isLoading ? null : _applyAndSave,
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Live interactive crop preview
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : EditorPreviewArea(
                          imageBytes: _imageBytes,
                          originalWidth: _originalWidth,
                          originalHeight: _originalHeight,
                          cropRect: _cropRect,
                          selectedAspectRatio: _selectedAspectRatio,
                          rotationDegrees: _rotationDegrees,
                          flipHorizontal: _flipHorizontal,
                          filter: _filter,
                          onCropRectChanged: (newRect) {
                            setState(() {
                              _cropRect = newRect;
                            });
                          },
                          onResetCropRect: _resetCropRect,
                        ),
                ),

                // Editor controls bottom sheet
                EditorBottomControls(
                  tabController: _tabController,
                  primaryColor: primaryColor,
                  cropTab: EditorCropTab(
                    aspectRatios: _aspectRatios,
                    customUserRatio: _customUserRatio,
                    selectedAspectRatio: _selectedAspectRatio,
                    onAspectRatioSelected: _onAspectRatioSelected,
                    onCustomRatioPressed: _showCustomRatioDialog,
                    primaryColor: primaryColor,
                  ),
                  rotateTab: EditorRotateTab(
                    primaryColor: primaryColor,
                    flipHorizontal: _flipHorizontal,
                    onRotate90: () {
                      setState(() {
                        _rotationDegrees = (_rotationDegrees + 90) % 360;
                        if (_selectedAspectRatio.isFree) {
                          _cropRect = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
                        } else {
                          _cropRect = _computeInitialCropRect(
                            _selectedAspectRatio,
                          );
                        }
                      });
                    },
                    onFlip: () {
                      setState(() {
                        _flipHorizontal = !_flipHorizontal;
                      });
                    },
                    onResetCrop: _resetCropRect,
                  ),
                  qualityTab: EditorQualityTab(
                    primaryColor: primaryColor,
                    quality: _quality,
                    onQualityChanged: (val) {
                      setState(() {
                        _quality = val;
                      });
                    },
                    targetMaxDimension: _targetMaxDimension,
                    filter: _filter,
                    onResolutionPickerPressed: _showResolutionPicker,
                    onFilterPickerPressed: _showFilterPicker,
                  ),
                ),
              ],
            ),

            // Processing overlay
            if (_isProcessing)
              EditorProcessingOverlay(
                primaryColor: primaryColor,
                message: _loadingMessage,
              ),
          ],
        ),
      ),
    );
  }
}
