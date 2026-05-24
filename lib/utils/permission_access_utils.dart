import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/constants.dart';

/// Utility class for handling permissions required by the in_app_gallery package.
class PermissionAccessUtils {
  /// Shows a dialog instructing the user to open app settings to grant permissions.
  static Future<void> showPermissionDialog(
    BuildContext context,
    String permissionName,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(Constants.permissionRequiredTitle(permissionName)),
        content: Text(Constants.permissionRequiredContent(permissionName)),
        actions: [
          TextButton(
            child: const Text(Constants.cancel),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text(Constants.openSettings),
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  /// Processes a list of permission statuses and returns true if all are granted or limited.
  static Future<bool> handlePermissionResult(
    List<PermissionStatus> statuses,
    String name,
  ) async {
    // FIX: Returns true if every permission is EITHER granted OR limited
    final isAllowed = statuses.every(
      (element) => element.isGranted || element.isLimited,
    );

    if (isAllowed) {
      return true;
    }

    // that they need to open settings to grant '$name' permissions.
    return false;
  }

  /// Requests and checks if the camera permission is granted.
  static Future<bool> checkCameraPermissions() async {
    final status = await Permission.camera.request();
    return handlePermissionResult([status], "Camera");
  }

  /// Requests and checks if the photo/video gallery permissions are granted.
  /// Handles platform-specific logic for Android versions >= 33 and iOS.
  static Future<bool> checkGalleryPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        final statuses = await [Permission.photos, Permission.videos].request();

        return handlePermissionResult(statuses.values.toList(), "Gallery");
      } else {
        final status = await Permission.storage.request();
        return handlePermissionResult([status], "Storage");
      }
    }

    // For iOS and others
    final status = await Permission.photos.request();
    return handlePermissionResult([status], "Gallery");
  }
}
