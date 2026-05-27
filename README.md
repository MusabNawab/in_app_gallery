# In App Gallery

A highly customizable, beautiful Flutter package for selecting images and videos from the device gallery. It provides a polished UI, media compression, and robust media handling using Bloc and photo_manager.

## Features

*   **Media Fetching**: Fetch and display images and videos from the local gallery.
*   **Custom UI**: A highly customizable and sleek user interface for media selection.
*   **Compression**: Built-in image and video compression features.
*   **Permissions**: Handles required permissions out of the box.
*   **Pure Dart Package**: Restructured as a pure Dart package with no native plugin boilerplate, making integration easier and reducing build footprint.

## Showcase

Here are some screenshots of the `in_app_gallery` package in action:

<p align="center">
  <img src="https://raw.githubusercontent.com/MusabNawab/in_app_gallery/main/screenshots/1.png" width="200" alt="Showcase 1"/>
  <img src="https://raw.githubusercontent.com/MusabNawab/in_app_gallery/main/screenshots/2.png" width="200" alt="Showcase 2"/>
  <img src="https://raw.githubusercontent.com/MusabNawab/in_app_gallery/main/screenshots/3.png" width="200" alt="Showcase 3"/>
  <img src="https://raw.githubusercontent.com/MusabNawab/in_app_gallery/main/screenshots/4.jpg" width="200" alt="Showcase 4"/>
</p>

## Dependencies & Architecture

This package is built using several robust packages to provide a seamless experience:
* **[photo_manager](https://pub.dev/packages/photo_manager)**: For fetching and managing gallery assets.
* **[flutter_bloc](https://pub.dev/packages/flutter_bloc)**: For predictable state management.
* **[flutter_image_compress](https://pub.dev/packages/flutter_image_compress)**: For high-quality image compression.
* **[hw_video_compress](https://pub.dev/packages/hw_video_compress)**: For hardware-accelerated, native video compression.
* **[media_kit](https://pub.dev/packages/media_kit)**: For reliable video playback within the selection grid.
* **[permission_handler](https://pub.dev/packages/permission_handler)**: For requesting device permissions.

### Video Compression
Video compression is delegated to the standalone **[hw_video_compress](https://pub.dev/packages/hw_video_compress)** package. It executes hardware-accelerated video compression natively on both iOS and Android to prevent out-of-memory errors and minimize compilation size.

## Getting Started

Add `in_app_gallery` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  in_app_gallery: ^1.0.0
```

## Platform Requirements

### Android
Add the following permissions to your `AndroidManifest.xml` (located in `android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED"/>
```

### iOS
Add the following keys to your `Info.plist` (located in `ios/Runner/Info.plist`):

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app requires access to the photo library to pick images and videos.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app requires access to save photos to the library.</string>
```

## Usage

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_gallery/in_app_gallery.dart';

// Inside your stateful widget:
List<File> _selectedMedia = [];

Future<void> _openGallery() async {
  final result = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const InAppGalleryScreen(
        title: 'Select Media',
        maxSelection: 10,
        allowVideoCompression: true,
      ),
    ),
  );

  if (result != null && result is List) {
    setState(() {
      _selectedMedia = List<File>.from(result);
    });
  }
}
```

## Customizations

`InAppGalleryScreen` offers various customization parameters:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `appBar` | `PreferredSizeWidget Function(int fileCount, VoidCallback onSelectionComplete)?` | `null` | Custom builder to supply a custom App Bar. Receives selection count and completion trigger. |
| `imagesTabText` | `String` | `'Images'` | Custom label text for the images category tab. |
| `videosTabText` | `String` | `'Videos'` | Custom label text for the videos category tab. |
| `maxSelection` | `int?` | `null` | Max number of images/videos user can select. |
| `allowVideoCompression` | `bool` | `false` | Enable/disable compressing videos before returning them. |
| `imageQuality` | `int?` | `null` | Target compression quality (0-100) for picked images. |
| `cameraWidget` | `Widget?` | `null` | Custom builder to override the look of the camera option. |
| `noMediaWidget` | `Widget?` | `null` | Custom widget to show when no media files are found. |
| `permissionDeniedWidget` | `Widget?` | `null` | Custom widget to display when permissions are denied. |
| `compressionDialogWidget` | `Widget Function(BuildContext, Stream<double>)?` | `null` | Custom progress dialog shown during media processing. |


