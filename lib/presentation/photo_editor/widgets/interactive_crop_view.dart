import 'dart:typed_data';

import 'package:flutter/material.dart';

enum _CropHandle {
  none,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
  inside,
}

/// An interactive crop view widget featuring:
/// - Freeform custom crop (drag edges and corners freely)
/// - Aspect ratio locked crop (1:1, 16:9, etc.)
/// - Pan crop box across image
/// - Semi-transparent mask, rule-of-thirds grid, and stylish corner/edge handles
class InteractiveCropView extends StatefulWidget {
  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;
  final Rect cropRect; // Normalized 0.0 - 1.0 relative to image
  final ValueChanged<Rect> onCropRectChanged;
  final double? targetAspectRatio; // null = Free / Custom Crop
  final int rotationDegrees;
  final bool flipHorizontal;

  const InteractiveCropView({
    super.key,
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.cropRect,
    required this.onCropRectChanged,
    this.targetAspectRatio,
    this.rotationDegrees = 0,
    this.flipHorizontal = false,
  });

  @override
  State<InteractiveCropView> createState() => _InteractiveCropViewState();
}

class _InteractiveCropViewState extends State<InteractiveCropView> {
  _CropHandle _activeHandle = _CropHandle.none;
  Offset? _lastPanPosition;

  static const double _handleHitRadius = 32.0;
  static const double _minCropSize = 0.05; // 5% minimum normalized size

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth - 24;
        final availH = constraints.maxHeight - 24;

        if (availW <= 0 || availH <= 0) return const SizedBox.shrink();

        // Effective dimensions after rotation
        final bool isRotated =
            widget.rotationDegrees == 90 || widget.rotationDegrees == 270;
        final double imgW =
            (isRotated ? widget.imageHeight : widget.imageWidth).toDouble();
        final double imgH =
            (isRotated ? widget.imageWidth : widget.imageHeight).toDouble();

        final double imgRatio = (imgH > 0 && imgW > 0) ? imgW / imgH : 1.0;

        double renderW = availW;
        double renderH = renderW / imgRatio;
        if (renderH > availH) {
          renderH = availH;
          renderW = renderH * imgRatio;
        }
        renderW = renderW.clamp(1.0, availW);
        renderH = renderH.clamp(1.0, availH);

        return Center(
          child: SizedBox(
            width: renderW,
            height: renderH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Render image with rotation and flip
                ClipRect(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(
                      widget.flipHorizontal ? -1.0 : 1.0,
                      1.0,
                      1.0,
                    ),
                    child: RotatedBox(
                      quarterTurns: (widget.rotationDegrees ~/ 90) % 4,
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),

                // Interactive Crop Mask & Handles Overlay
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    _onPanStart(details.localPosition, renderW, renderH);
                  },
                  onPanUpdate: (details) {
                    _onPanUpdate(
                      details.localPosition,
                      renderW,
                      renderH,
                      imgRatio,
                    );
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _activeHandle = _CropHandle.none;
                      _lastPanPosition = null;
                    });
                  },
                  onPanCancel: () {
                    setState(() {
                      _activeHandle = _CropHandle.none;
                      _lastPanPosition = null;
                    });
                  },
                  child: CustomPaint(
                    size: Size(renderW, renderH),
                    painter: _CropOverlayPainter(
                      cropRect: widget.cropRect,
                      activeHandle: _activeHandle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onPanStart(Offset localPos, double width, double height) {
    _lastPanPosition = localPos;
    final pixelRect = Rect.fromLTRB(
      widget.cropRect.left * width,
      widget.cropRect.top * height,
      widget.cropRect.right * width,
      widget.cropRect.bottom * height,
    );

    // Hit test corners first
    if ((localPos - pixelRect.topLeft).distance <= _handleHitRadius) {
      _activeHandle = _CropHandle.topLeft;
    } else if ((localPos - pixelRect.topRight).distance <= _handleHitRadius) {
      _activeHandle = _CropHandle.topRight;
    } else if ((localPos - pixelRect.bottomLeft).distance <= _handleHitRadius) {
      _activeHandle = _CropHandle.bottomLeft;
    } else if ((localPos - pixelRect.bottomRight).distance <= _handleHitRadius) {
      _activeHandle = _CropHandle.bottomRight;
    }
    // Hit test edges
    else if ((localPos.dy - pixelRect.top).abs() <= _handleHitRadius &&
        localPos.dx >= pixelRect.left - _handleHitRadius &&
        localPos.dx <= pixelRect.right + _handleHitRadius) {
      _activeHandle = _CropHandle.top;
    } else if ((localPos.dy - pixelRect.bottom).abs() <= _handleHitRadius &&
        localPos.dx >= pixelRect.left - _handleHitRadius &&
        localPos.dx <= pixelRect.right + _handleHitRadius) {
      _activeHandle = _CropHandle.bottom;
    } else if ((localPos.dx - pixelRect.left).abs() <= _handleHitRadius &&
        localPos.dy >= pixelRect.top - _handleHitRadius &&
        localPos.dy <= pixelRect.bottom + _handleHitRadius) {
      _activeHandle = _CropHandle.left;
    } else if ((localPos.dx - pixelRect.right).abs() <= _handleHitRadius &&
        localPos.dy >= pixelRect.top - _handleHitRadius &&
        localPos.dy <= pixelRect.bottom + _handleHitRadius) {
      _activeHandle = _CropHandle.right;
    }
    // Inside pan
    else if (pixelRect.contains(localPos)) {
      _activeHandle = _CropHandle.inside;
    } else {
      _activeHandle = _CropHandle.none;
    }

    setState(() {});
  }

  void _onPanUpdate(
    Offset localPos,
    double width,
    double height,
    double imageAspectRatio,
  ) {
    if (_activeHandle == _CropHandle.none || _lastPanPosition == null) return;

    final dx = (localPos.dx - _lastPanPosition!.dx) / width;
    final dy = (localPos.dy - _lastPanPosition!.dy) / height;
    _lastPanPosition = localPos;

    double l = widget.cropRect.left;
    double t = widget.cropRect.top;
    double r = widget.cropRect.right;
    double b = widget.cropRect.bottom;

    if (_activeHandle == _CropHandle.inside) {
      // Pan whole crop box
      final rectW = r - l;
      final rectH = b - t;

      l = (l + dx).clamp(0.0, 1.0 - rectW);
      t = (t + dy).clamp(0.0, 1.0 - rectH);
      r = l + rectW;
      b = t + rectH;
    } else {
      // Resize handles
      switch (_activeHandle) {
        case _CropHandle.topLeft:
          l = (l + dx).clamp(0.0, r - _minCropSize);
          t = (t + dy).clamp(0.0, b - _minCropSize);
          break;
        case _CropHandle.topRight:
          r = (r + dx).clamp(l + _minCropSize, 1.0);
          t = (t + dy).clamp(0.0, b - _minCropSize);
          break;
        case _CropHandle.bottomLeft:
          l = (l + dx).clamp(0.0, r - _minCropSize);
          b = (b + dy).clamp(t + _minCropSize, 1.0);
          break;
        case _CropHandle.bottomRight:
          r = (r + dx).clamp(l + _minCropSize, 1.0);
          b = (b + dy).clamp(t + _minCropSize, 1.0);
          break;
        case _CropHandle.top:
          t = (t + dy).clamp(0.0, b - _minCropSize);
          break;
        case _CropHandle.bottom:
          b = (b + dy).clamp(t + _minCropSize, 1.0);
          break;
        case _CropHandle.left:
          l = (l + dx).clamp(0.0, r - _minCropSize);
          break;
        case _CropHandle.right:
          r = (r + dx).clamp(l + _minCropSize, 1.0);
          break;
        default:
          break;
      }

      // If a fixed aspect ratio is selected, enforce it
      if (widget.targetAspectRatio != null) {
        final targetR = widget.targetAspectRatio!;
        // targetR = (cropWidthPixels) / (cropHeightPixels)
        // cropWidthPixels = (r - l) * width
        // cropHeightPixels = (b - t) * height
        // (r - l) * width / ((b - t) * height) = targetR
        // (r - l) = (b - t) * (height / width) * targetR = (b - t) * (targetR / imageAspectRatio)
        final normalizedTargetRatio = targetR / imageAspectRatio;

        if (_activeHandle == _CropHandle.left ||
            _activeHandle == _CropHandle.right) {
          final newH = (r - l) / normalizedTargetRatio;
          final centerH = (t + b) / 2;
          t = (centerH - newH / 2).clamp(0.0, 1.0);
          b = (t + newH).clamp(0.0, 1.0);
        } else {
          final newW = (b - t) * normalizedTargetRatio;
          final centerW = (l + r) / 2;
          l = (centerW - newW / 2).clamp(0.0, 1.0);
          r = (l + newW).clamp(0.0, 1.0);
        }
      }
    }

    final newRect = Rect.fromLTRB(l, t, r, b);
    widget.onCropRectChanged(newRect);
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final _CropHandle activeHandle;

  _CropOverlayPainter({required this.cropRect, required this.activeHandle});

  @override
  void paint(Canvas canvas, Size size) {
    final pixelRect = Rect.fromLTRB(
      cropRect.left * size.width,
      cropRect.top * size.height,
      cropRect.right * size.width,
      cropRect.bottom * size.height,
    );

    // 1. Semi-transparent outside mask
    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final fullPath = Path()..addRect(Offset.zero & size);
    final cropPath = Path()..addRect(pixelRect);
    final overlayPath = Path.combine(PathOperation.difference, fullPath, cropPath);
    canvas.drawPath(overlayPath, maskPaint);

    // 2. White border around crop area
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(pixelRect, borderPaint);

    // 3. Rule of Thirds 3x3 Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final stepX = pixelRect.width / 3;
    final stepY = pixelRect.height / 3;

    canvas.drawLine(
      Offset(pixelRect.left + stepX, pixelRect.top),
      Offset(pixelRect.left + stepX, pixelRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(pixelRect.left + stepX * 2, pixelRect.top),
      Offset(pixelRect.left + stepX * 2, pixelRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(pixelRect.left, pixelRect.top + stepY),
      Offset(pixelRect.right, pixelRect.top + stepY),
      gridPaint,
    );
    canvas.drawLine(
      Offset(pixelRect.left, pixelRect.top + stepY * 2),
      Offset(pixelRect.right, pixelRect.top + stepY * 2),
      gridPaint,
    );

    // 4. Corner Handles (L-shaped bold brackets)
    final handlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    const cornerLen = 20.0;

    // Top-Left
    canvas.drawLine(
      pixelRect.topLeft,
      pixelRect.topLeft + const Offset(cornerLen, 0),
      handlePaint,
    );
    canvas.drawLine(
      pixelRect.topLeft,
      pixelRect.topLeft + const Offset(0, cornerLen),
      handlePaint,
    );

    // Top-Right
    canvas.drawLine(
      pixelRect.topRight,
      pixelRect.topRight + const Offset(-cornerLen, 0),
      handlePaint,
    );
    canvas.drawLine(
      pixelRect.topRight,
      pixelRect.topRight + const Offset(0, cornerLen),
      handlePaint,
    );

    // Bottom-Left
    canvas.drawLine(
      pixelRect.bottomLeft,
      pixelRect.bottomLeft + const Offset(cornerLen, 0),
      handlePaint,
    );
    canvas.drawLine(
      pixelRect.bottomLeft,
      pixelRect.bottomLeft + const Offset(0, -cornerLen),
      handlePaint,
    );

    // Bottom-Right
    canvas.drawLine(
      pixelRect.bottomRight,
      pixelRect.bottomRight + const Offset(-cornerLen, 0),
      handlePaint,
    );
    canvas.drawLine(
      pixelRect.bottomRight,
      pixelRect.bottomRight + const Offset(0, -cornerLen),
      handlePaint,
    );

    // 5. Edge Midpoint Ticks
    const edgeLen = 14.0;
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top Center
    final topCenter = Offset(pixelRect.center.dx, pixelRect.top);
    canvas.drawLine(
      topCenter - const Offset(edgeLen / 2, 0),
      topCenter + const Offset(edgeLen / 2, 0),
      edgePaint,
    );

    // Bottom Center
    final bottomCenter = Offset(pixelRect.center.dx, pixelRect.bottom);
    canvas.drawLine(
      bottomCenter - const Offset(edgeLen / 2, 0),
      bottomCenter + const Offset(edgeLen / 2, 0),
      edgePaint,
    );

    // Center Left
    final centerLeft = Offset(pixelRect.left, pixelRect.center.dy);
    canvas.drawLine(
      centerLeft - const Offset(0, edgeLen / 2),
      centerLeft + const Offset(0, edgeLen / 2),
      edgePaint,
    );

    // Center Right
    final centerRight = Offset(pixelRect.right, pixelRect.center.dy);
    canvas.drawLine(
      centerRight - const Offset(0, edgeLen / 2),
      centerRight + const Offset(0, edgeLen / 2),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.activeHandle != activeHandle;
  }
}
