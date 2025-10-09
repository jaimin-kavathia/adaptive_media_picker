import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';

/// Web image cropper implementation.
class BackendImageCropper {
  /// Crop an image on web platform.
  static Future<String?> cropImage({
    required String sourcePath,
    required BuildContext context,
    String compressFormat = 'jpg',
    int compressQuality = 100,
    Brightness? themeBrightness,
    Color? primaryColor,
  }) async {
    try {
      final ImageCompressFormat format = compressFormat == 'png'
          ? ImageCompressFormat.png
          : ImageCompressFormat.jpg;

      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: format,
        compressQuality: compressQuality,
        uiSettings: [
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.page,
            size: const CropperSize(width: 520, height: 520),
          ),
        ],
      );

      return cropped?.path;
    } catch (e) {
      debugPrint('Web image cropping failed: $e');
      return null;
    }
  }
}
