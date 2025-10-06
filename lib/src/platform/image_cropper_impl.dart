import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mobile_image_cropper.dart' as mobile_impl;
import 'web_image_cropper.dart' as web_impl;
import '../stub/image_cropper_stub.dart' as stub_impl;

/// Platform-specific image cropper implementation.
///
/// This file provides image cropping functionality for supported platforms
/// (Android, iOS, Web) and no-op behavior for unsupported platforms.
class PlatformImageCropper {
  /// Crop an image using platform-specific implementations.
  ///
  /// Returns the cropped file path, or null if cropping failed, was cancelled,
  /// or is not supported on the current platform.
  static Future<String?> cropImage({
    required String sourcePath,
    BuildContext? context,
    String compressFormat = 'jpg',
    int compressQuality = 100,
  }) async {
    // Check if cropping is supported on this platform
    if (!_isCroppingSupported()) {
      debugPrint('Image cropping is not supported on this platform');
      return null;
    }

    try {
      if (kIsWeb) {
        if (context == null) {
          debugPrint('BuildContext is required for web cropping.');
          return null;
        }
        return web_impl.BackendImageCropper.cropImage(
          sourcePath: sourcePath,
          context: context,
          compressFormat: compressFormat,
          compressQuality: compressQuality,
        );
      } else if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        return mobile_impl.BackendImageCropper.cropImage(
          sourcePath: sourcePath,
          context: context,
          compressFormat: compressFormat,
          compressQuality: compressQuality,
        );
      } else {
        return stub_impl.PlatformImageCropper.cropImage(
          sourcePath: sourcePath,
          context: context,
          compressFormat: compressFormat,
          compressQuality: compressQuality,
        );
      }
    } catch (e) {
      debugPrint('Image cropping failed: $e');
      return null;
    }
  }

  /// Check if image cropping is supported on the current platform.
  static bool _isCroppingSupported() {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
