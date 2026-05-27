import 'dart:io';

import 'package:flutter/material.dart';

import '../constants/constants.dart';
import '../utils/in_app_gallery_utils.dart';

class PickCameraWidget extends StatelessWidget {
  const PickCameraWidget({
    super.key,
    required this.pickedImage,
    this.imageQuality,
    this.cameraWidget,
  });

  final ValueChanged<File?> pickedImage;
  final int? imageQuality;
  final Widget? cameraWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return InkWell(
      onTap: () async {
        final result = await InAppGalleryUtils.onCameraPicked(
          context: context,
          imageQuality: imageQuality,
        );
        pickedImage(result);
      },
      child:
          cameraWidget ??
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Column(
              spacing: 20,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 48,
                ),
                Text(
                  Constants.camera,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
    );
  }
}
