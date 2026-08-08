## 1.0.4

* **Camera Option & Layout Improvements**: 
  * Always display camera option tile at index 0 on both Images and Videos tabs, even when gallery is empty.
  * Added video recording support to camera tile on Videos tab.
  * Removed legacy `noMediaWidget` fallback screen.
* **Full Screen Video Preview**: 
  * Migrated from `media_kit` to Flutter's native `video_player` package.
  * Replaced video preview dialog with full-screen video player view featuring interactive playback controls, progress scrubbing, and duration indicators.
* **Single Selection Behavior**: 
  * Automatically unselects previous file when `maxSelection == 1` upon selecting a new media item or capturing via camera.
* **Pagination & Deduplication Fixes**: 
  * Prevented duplicate images/videos during scrolling by adding pagination locks and unique asset ID filtering.
  * Fixed infinite scrolling loop when reaching the end of gallery items.
* **Dependency Updates**: 
  * Updated dependencies to latest releases (`fluttertoast`, `permission_handler`, `video_player`, `flutter_image_compress`, `photo_manager`, `uuid`).

## 1.0.3

* **Build & JVM Compatibility**: 
  * Downgraded the example app configuration to Java 17 / JVM 17 for better compatibility.
  * Aligned both Java and Kotlin compiler targets in the example app to avoid target mismatch errors.
  * Bypassed Kotlin JVM target validation checks for third-party dependencies (like `photo_manager`) to resolve build errors on systems running Java 21.

## 1.0.2

* **Dependency Cleanup**: Removed `device_info_plus` due to compatibility conflicts with the file picker.

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
