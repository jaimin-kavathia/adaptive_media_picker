import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../core/models.dart' show CropAspectRatioOption;

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
    CropAspectRatioOption? cropAspectRatio,
    bool lockCropAspectRatio = false,
  }) async {
    try {
      final ImageCompressFormat format = compressFormat == 'png'
          ? ImageCompressFormat.png
          : ImageCompressFormat.jpg;

      final CropAspectRatioPreset initPreset =
          _presetFor(cropAspectRatio ?? CropAspectRatioOption.square);

      // Android's `withAspectRatio`/`lockAspectRatio` and iOS's initial
      // ratio both rely on this top-level, numeric, *locking* aspect ratio.
      // There's no way to hand iOS an initial-but-adjustable ratio, so that
      // combination only takes effect on Android via [initPreset] below.
      CropAspectRatio? lockedRatio;
      if (lockCropAspectRatio && cropAspectRatio != null) {
        final (int, int)? data = _ratioData(cropAspectRatio);
        if (data != null) {
          lockedRatio = CropAspectRatio(
            ratioX: data.$1.toDouble(),
            ratioY: data.$2.toDouble(),
          );
        }
      }

      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: format,
        compressQuality: compressQuality,
        aspectRatio: lockedRatio,
        uiSettings: _getMobileUiSettings(
          themeBrightness: themeBrightness,
          primaryColor: primaryColor,
          initAspectRatio: initPreset,
          lockAspectRatio: lockCropAspectRatio,
        ),
      );

      return cropped?.path;
    } catch (e) {
      debugPrint('Mobile image cropping failed: $e');
      return null;
    }
  }

  static CropAspectRatioPreset _presetFor(CropAspectRatioOption option) {
    switch (option) {
      case CropAspectRatioOption.original:
        return CropAspectRatioPreset.original;
      case CropAspectRatioOption.square:
        return CropAspectRatioPreset.square;
      case CropAspectRatioOption.ratio3x2:
        return CropAspectRatioPreset.ratio3x2;
      case CropAspectRatioOption.ratio4x3:
        return CropAspectRatioPreset.ratio4x3;
      case CropAspectRatioOption.ratio5x4:
        return CropAspectRatioPreset.ratio5x4;
      case CropAspectRatioOption.ratio7x5:
        return CropAspectRatioPreset.ratio7x5;
      case CropAspectRatioOption.ratio16x9:
        return CropAspectRatioPreset.ratio16x9;
    }
  }

  static (int, int)? _ratioData(CropAspectRatioOption option) {
    switch (option) {
      case CropAspectRatioOption.original:
        return null;
      case CropAspectRatioOption.square:
        return (1, 1);
      case CropAspectRatioOption.ratio3x2:
        return (3, 2);
      case CropAspectRatioOption.ratio4x3:
        return (4, 3);
      case CropAspectRatioOption.ratio5x4:
        return (5, 4);
      case CropAspectRatioOption.ratio7x5:
        return (7, 5);
      case CropAspectRatioOption.ratio16x9:
        return (16, 9);
    }
  }

  /// Get mobile-specific UI settings for the image cropper.
  static List<PlatformUiSettings> _getMobileUiSettings({
    Brightness? themeBrightness,
    Color? primaryColor,
    required CropAspectRatioPreset initAspectRatio,
    required bool lockAspectRatio,
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
          initAspectRatio: initAspectRatio,
          lockAspectRatio: lockAspectRatio,
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
