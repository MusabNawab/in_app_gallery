import 'package:flutter/material.dart';
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';

/// Aspect ratio preset model for [PhotoEditorScreen].
class EditorAspectRatio {
  final String label;
  final IconData icon;
  final CropAspectRatio? type;
  final double? ratio;
  final double widthRatio;
  final double heightRatio;
  final bool isFree;
  final bool isOriginal;

  const EditorAspectRatio({
    required this.label,
    required this.icon,
    this.type,
    this.ratio,
    this.widthRatio = 1.0,
    this.heightRatio = 1.0,
    this.isFree = false,
    this.isOriginal = false,
  });

  double? get numericRatio {
    if (isFree || isOriginal) return null;
    if (ratio != null) return ratio;
    if (type == CropAspectRatio.square) return 1.0;
    if (widthRatio > 0 && heightRatio > 0) {
      return widthRatio / heightRatio;
    }
    return null;
  }

  /// Default aspect ratio presets available in the editor.
  static const List<EditorAspectRatio> defaultPresets = [
    EditorAspectRatio(
      label: 'Free Crop',
      icon: Icons.crop_free_rounded,
      isFree: true,
    ),
    EditorAspectRatio(
      label: 'Original',
      icon: Icons.crop_original_rounded,
      isOriginal: true,
      type: CropAspectRatio.original,
    ),
    EditorAspectRatio(
      label: '1:1 Square',
      icon: Icons.crop_square_rounded,
      type: CropAspectRatio.square,
      ratio: 1.0,
      widthRatio: 1.0,
      heightRatio: 1.0,
    ),
    EditorAspectRatio(
      label: '4:3',
      icon: Icons.crop_landscape_rounded,
      type: CropAspectRatio.custom,
      ratio: 4.0 / 3.0,
      widthRatio: 4.0,
      heightRatio: 3.0,
    ),
    EditorAspectRatio(
      label: '16:9',
      icon: Icons.crop_16_9_rounded,
      type: CropAspectRatio.custom,
      ratio: 16.0 / 9.0,
      widthRatio: 16.0,
      heightRatio: 9.0,
    ),
    EditorAspectRatio(
      label: '9:16',
      icon: Icons.crop_portrait_rounded,
      type: CropAspectRatio.custom,
      ratio: 9.0 / 16.0,
      widthRatio: 9.0,
      heightRatio: 16.0,
    ),
    EditorAspectRatio(
      label: '3:2',
      icon: Icons.crop_3_2_rounded,
      type: CropAspectRatio.custom,
      ratio: 3.0 / 2.0,
      widthRatio: 3.0,
      heightRatio: 2.0,
    ),
    EditorAspectRatio(
      label: '2:3',
      icon: Icons.crop_portrait_rounded,
      type: CropAspectRatio.custom,
      ratio: 2.0 / 3.0,
      widthRatio: 2.0,
      heightRatio: 3.0,
    ),
  ];
}
