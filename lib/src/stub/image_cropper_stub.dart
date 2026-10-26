import 'package:flutter/widgets.dart';

import '../core/models.dart'
    show CropAspectRatioOption, CropShape, PickerLabels;

/// Stub: platform-wide cropper that does nothing on unsupported platforms
class PlatformImageCropper {
  /// Returns null to indicate cropping not supported on this platform
  static Future<String?> cropImage({
    required String sourcePath,
    BuildContext? context,
    String compressFormat = 'jpg',
    int compressQuality = 100,
    Brightness? themeBrightness,
    Color? primaryColor,
    CropAspectRatioOption? cropAspectRatio,
    bool lockCropAspectRatio = false,
    CropShape cropShape = CropShape.rectangle,
    PickerLabels labels = const PickerLabels(),
  }) async {
    return null;
  }
}
