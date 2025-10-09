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
        uiSettings: _getMobileUiSettings(
          themeBrightness: themeBrightness,
          primaryColor: primaryColor,
        ),
      );

      return cropped?.path;
    } catch (e) {
      debugPrint('Mobile image cropping failed: $e');
      return null;
    }
  }

  /// Get mobile-specific UI settings for the image cropper.
  static List<PlatformUiSettings> _getMobileUiSettings({
    Brightness? themeBrightness,
    Color? primaryColor,
  }) {
    final Brightness brightness = themeBrightness ?? Brightness.light;
    final bool isDark = brightness == Brightness.dark;
    // Primary brand color
    final Color primary =
        primaryColor ?? (isDark ? Colors.blueAccent : Colors.blue);
    // Surfaces and text colors
    final Color surface = isDark ? const Color(0xFF121212) : Colors.white;
    final Color onSurface = isDark ? Colors.white : Colors.black;
    // Dim and frame/grid accents
    final Color dimmed = isDark ? Colors.black54 : Colors.black26;
    final Color frameColor = primary.withValues(alpha: 0.9);
    final Color gridColor = isDark ? Colors.white70 : Colors.black45;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: primary,
          toolbarWidgetColor:
              onSurface.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          backgroundColor: surface,
          activeControlsWidgetColor: primary,
          dimmedLayerColor: dimmed,
          cropFrameColor: frameColor,
          cropGridColor: gridColor,
          cropFrameStrokeWidth: 2,
          cropGridRowCount: 3,
          cropGridColumnCount: 3,
          cropGridStrokeWidth: 1,
          showCropGrid: true,
          statusBarLight: !isDark,
          navBarLight: !isDark,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
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
