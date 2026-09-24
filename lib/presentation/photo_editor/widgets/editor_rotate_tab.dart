import 'package:flutter/material.dart';

import 'editor_action_button.dart';

/// Rotate tab widget providing buttons for 90° clockwise rotation, flip, and full image reset.
class EditorRotateTab extends StatelessWidget {
  final Color primaryColor;
  final bool flipHorizontal;
  final VoidCallback onRotate90;
  final VoidCallback onFlip;
  final VoidCallback onResetCrop;

  const EditorRotateTab({
    super.key,
    required this.primaryColor,
    required this.flipHorizontal,
    required this.onRotate90,
    required this.onFlip,
    required this.onResetCrop,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            EditorActionButton(
              icon: Icons.rotate_90_degrees_cw_rounded,
              label: 'Rotate 90°',
              primaryColor: primaryColor,
              onTap: onRotate90,
            ),
            EditorActionButton(
              icon: Icons.flip_rounded,
              label: 'Flip',
              primaryColor: primaryColor,
              isActive: flipHorizontal,
              onTap: onFlip,
            ),
            EditorActionButton(
              icon: Icons.crop_free_rounded,
              label: 'Full Image',
              primaryColor: primaryColor,
              onTap: onResetCrop,
            ),
          ],
        ),
      ),
    );
  }
}
