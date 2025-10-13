import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    // Validate inputs
    if (sourcePath.isEmpty) {
      debugPrint('Web image cropping failed: sourcePath is empty');
      return null;
    }

    if (compressQuality < 0 || compressQuality > 100) {
      debugPrint(
          'Web image cropping failed: compressQuality must be between 0 and 100, got $compressQuality');
      return null;
    }

    try {
      final ImageCompressFormat format = compressFormat == 'png'
          ? ImageCompressFormat.png
          : ImageCompressFormat.jpg;

      debugPrint(
          'Starting web image crop: sourcePath=$sourcePath, format=$compressFormat, quality=$compressQuality');

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

      if (cropped == null) {
        debugPrint('Web image cropping: user canceled or no file returned');
        return null;
      }

      debugPrint('Web image cropping successful: ${cropped.path}');
      return cropped.path;
    } catch (e, stackTrace) {
      debugPrint('Web image cropping failed: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
      return null;
    }
  }
}
