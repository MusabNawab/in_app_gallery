import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'in_app_gallery_method_channel.dart';

abstract class InAppGalleryPlatform extends PlatformInterface {
  /// Constructs a InAppGalleryPlatform.
  InAppGalleryPlatform() : super(token: _token);

  static final Object _token = Object();

  static InAppGalleryPlatform _instance = MethodChannelInAppGallery();

  /// The default instance of [InAppGalleryPlatform] to use.
  ///
  /// Defaults to [MethodChannelInAppGallery].
  static InAppGalleryPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [InAppGalleryPlatform] when
  /// they register themselves.
  static set instance(InAppGalleryPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
