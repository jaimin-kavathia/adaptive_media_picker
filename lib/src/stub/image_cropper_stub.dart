import 'package:flutter/widgets.dart';

/// Stub: platform-wide cropper that does nothing on unsupported platforms
class PlatformImageCropper {
  /// Returns null to indicate cropping not supported on this platform
  static Future<String?> cropImage({
    required String sourcePath,
    BuildContext? context,
    String compressFormat = 'jpg',
    int compressQuality = 100,
    dynamic themeBrightness,
    dynamic primaryColor,
  }) async {
    return null;
  }
}
