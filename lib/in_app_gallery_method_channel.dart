import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'in_app_gallery_platform_interface.dart';

/// An implementation of [InAppGalleryPlatform] that uses method channels.
class MethodChannelInAppGallery extends InAppGalleryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('in_app_gallery');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
