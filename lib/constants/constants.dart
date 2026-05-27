import 'package:flutter/widgets.dart';

class Constants {
  // Colors
  static final Color primaryColor = Color(0xFF1E88E5);
  static final Color secondaryColor = Color(0xFF00ACC1);

  // Compression dialog
  static const String processingMedia = "Processing media...";

  // Permission Dialog
  static String permissionRequiredTitle(String name) =>
      "$name Permission Required";
  static String permissionRequiredContent(String name) =>
      "Please grant $name permission in app settings to use this feature.";
  static const String cancel = "Cancel";
  static const String openSettings = "Open Settings";

  // Permissions Denied Widget
  static const String galleryAccessRequired = "Gallery Access Required";
  static const String galleryAccessRequiredSubtitle =
      "To select and upload photos, please allow access to your device's gallery in the app settings.";

  // No Media Widget
  static const String noMediaFound = "No Media Found";
  static const String noMediaFoundSubtitle =
      "You haven't captured any media yet.";

  // Pick Camera Widget
  static const String camera = "Camera";

  // Compression Dialog
  static const String compressingVideo = "Compressing video...";

  // Toasts / Errors
  static String videoSizeExceeded(String filename) =>
      "Skipped $filename: size > 1.5 GB";
}
