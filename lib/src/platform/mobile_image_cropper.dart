import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Mobile image cropper implementation for Android and iOS.
class BackendImageCropper {
  /// Crop an image on mobile platforms.
  static Future<String?> cropImage({
    required String sourcePath,
    BuildContext? context,
    String compressFormat = 'jpg',
    int compressQuality = 100,
  }) async {
    try {
      final ImageCompressFormat format = compressFormat == 'png'
          ? ImageCompressFormat.png
          : ImageCompressFormat.jpg;

      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: format,
        compressQuality: compressQuality,
        uiSettings: _getMobileUiSettings(),
      );

      return cropped?.path;
    } catch (e) {
      debugPrint('Mobile image cropping failed: $e');
      return null;
    }
  }

  /// Get mobile-specific UI settings for the image cropper.
  static List<PlatformUiSettings> _getMobileUiSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ];
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return [
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ];
    }

    return const <PlatformUiSettings>[];
  }
}
