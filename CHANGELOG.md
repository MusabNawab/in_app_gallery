## 1.0.1

* **Pure Dart Package**: Restructured the project from a native plugin to a pure Dart package by removing local native folders and dependencies.
* **Stand-alone Compression**: Migrated local video compression logic to the standalone `hw_video_compress` package.
* **Bug Fixes**: 
  * Solved an infinite app lifecycle permission checking loop/crash.
  * Fixed pop collision race conditions during selection processing.
  * Resolved generic type erasure issues when returning lists from routes.
  * Fixed image picking selection callback from `PickCameraWidget`.
* **Customizations**: Added properties to customize tab bar labels (`imagesTabText`, `videosTabText`) and custom app bar selection trigger callbacks.

## 1.0.0

* Initial release of in_app_gallery plugin. Provides custom gallery UI and media picking capabilities.
