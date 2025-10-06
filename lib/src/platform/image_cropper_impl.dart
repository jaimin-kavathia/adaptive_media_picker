import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mobile_image_cropper.dart'
    if (dart.library.html) 'web_image_cropper.dart'
    as backend_impl;

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
      return await backend_impl.BackendImageCropper.cropImage(
        sourcePath: sourcePath,
        context: context,
        compressFormat: compressFormat,
        compressQuality: compressQuality,
      );
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
