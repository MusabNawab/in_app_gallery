import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';

import 'editor_aspect_ratio.dart';
import 'interactive_crop_view.dart';

/// Preview area widget showing the interactive canvas, crop dimensions pill, and reset crop button.
class EditorPreviewArea extends StatelessWidget {
  final Uint8List? imageBytes;
  final int originalWidth;
  final int originalHeight;
  final Rect cropRect;
  final EditorAspectRatio selectedAspectRatio;
  final int rotationDegrees;
  final bool flipHorizontal;
  final BicubicFilter filter;
  final ValueChanged<Rect> onCropRectChanged;
  final VoidCallback onResetCropRect;

  const EditorPreviewArea({
    super.key,
    required this.imageBytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.cropRect,
    required this.selectedAspectRatio,
    required this.rotationDegrees,
    required this.flipHorizontal,
    required this.filter,
    required this.onCropRectChanged,
    required this.onResetCropRect,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytes == null) {
      return const Center(child: Text('No image data'));
    }

    final bool isRotated =
        rotationDegrees == 90 || rotationDegrees == 270;
    final int imgW = isRotated ? originalHeight : originalWidth;
    final int imgH = isRotated ? originalWidth : originalHeight;

    final int cropPixelW = (cropRect.width * imgW).round();
    final int cropPixelH = (cropRect.height * imgH).round();

    final bool hasCropped = (cropRect.left > 0.005 ||
        cropRect.top > 0.005 ||
        cropRect.right < 0.995 ||
        cropRect.bottom < 0.995);

    return Column(
      children: [
        // Interactive Draggable Crop Canvas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: InteractiveCropView(
              imageBytes: imageBytes!,
              imageWidth: originalWidth,
              imageHeight: originalHeight,
              cropRect: cropRect,
              targetAspectRatio: selectedAspectRatio.isOriginal
                  ? (imgW / imgH)
                  : selectedAspectRatio.numericRatio,
              rotationDegrees: rotationDegrees,
              flipHorizontal: flipHorizontal,
              onCropRectChanged: onCropRectChanged,
            ),
          ),
        ),

        // Live crop info pill and reset button
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '${selectedAspectRatio.label} • ${cropPixelW}x$cropPixelH px • ${filter.name}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasCropped) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onResetCropRect,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restart_alt, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Reset Box',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
