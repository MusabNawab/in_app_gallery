# In App Gallery

A highly customizable, beautiful Flutter plugin for selecting images and videos from the device gallery. It provides a polished UI, media compression, and robust media handling using flutter blocks and photo_manager.

## Features

*   **Media Fetching**: Fetch and display images and videos from the local gallery.
*   **Custom UI**: A highly customizable and sleek user interface for media selection.
*   **Compression**: Built-in image and video compression features.
*   **Permissions**: Handles required permissions out of the box.

## Showcase

Here are some screenshots of the `in_app_gallery` plugin in action:

<p align="center">
  <img src="https://raw.githubusercontent.com/MusabNawab/in_app_gallery/main/screenshots/1.png" width="200" alt="Showcase 1"/>
  <img src="https://raw.githubusercontent.com/MusabNawab/in_app_gallery/main/screenshots/2.png" width="200" alt="Showcase 2"/>
  <img src="https://raw.githubusercontent.com/MusabNawab/in_app_gallery/main/screenshots/3.png" width="200" alt="Showcase 3"/>
  <img src="https://raw.githubusercontent.com/MusabNawab/in_app_gallery/main/screenshots/4.png" width="200" alt="Showcase 4"/>
</p>

*(Note to developer: Create a `screenshots` folder in your repository, place the 4 images you provided as `1.png`, `2.png`, `3.png`, and `4.png`, and update the image URLs to point to your actual repository).*

## Dependencies & Architecture

This plugin is built using several robust packages to provide a seamless experience:
* **[photo_manager](https://pub.dev/packages/photo_manager)**: For fetching and managing gallery assets.
* **[flutter_bloc](https://pub.dev/packages/flutter_bloc)**: For predictable state management.
* **[flutter_image_compress](https://pub.dev/packages/flutter_image_compress)**: For high-quality image compression.
* **[media_kit](https://pub.dev/packages/media_kit)**: For reliable video playback within the selection grid.
* **[permission_handler](https://pub.dev/packages/permission_handler)**: For requesting device permissions.

### Video Compression
Video compression is handled natively to ensure maximum performance and avoid out-of-memory errors:
* **Android**: Uses [Transcoder](https://github.com/natario1/Transcoder) (`com.otaliastudios:transcoder`) for lightning-fast hardware-accelerated video compression directly via Kotlin.
* **iOS**: Leverages native `AVFoundation` (`AVAssetExportSession`) to perform highly optimized, asynchronous video compression.

## Getting Started

Add `in_app_gallery` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  in_app_gallery: ^0.0.1
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

  if (result != null && result is List<File>) {
    setState(() {
      _selectedMedia = result;
    });
  }
}
```

