import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mobile_image_cropper.dart' as mobile_impl;
import 'builtin_cropper.dart';
import '../core/models.dart'
    show CropAspectRatioOption, CropShape, PickerLabels;

/// Image cropper for `dart:io` platforms.
///
/// Android and iOS use the native `image_cropper` UI (uCrop /
/// TOCropViewController). Desktop platforms have no native cropper, so they
/// use the package's built-in Flutter crop editor and write the result to a
/// temporary file.
class PlatformImageCropper {
  /// Crop an image using platform-specific implementations.
  ///
  /// Returns the cropped file path, or null if cropping failed or was
  /// cancelled. Desktop cropping needs a [context] to show the editor.
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
    try {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        return await mobile_impl.BackendImageCropper.cropImage(
          sourcePath: sourcePath,
          context: context,
          compressFormat: compressFormat,
          compressQuality: compressQuality,
          themeBrightness: themeBrightness,
          primaryColor: primaryColor,
          cropAspectRatio: cropAspectRatio,
          lockCropAspectRatio: lockCropAspectRatio,
          cropShape: cropShape,
          labels: labels,
        );
      }
      if (context == null) {
        debugPrint('BuildContext is required for desktop cropping.');
        return null;
      }
      final Uint8List? cropped = await cropWithBuiltInEditor(
        sourcePath: sourcePath,
        context: context,
        themeBrightness: themeBrightness,
        primaryColor: primaryColor,
        cropAspectRatio: cropAspectRatio,
        lockCropAspectRatio: lockCropAspectRatio,
        cropShape: cropShape,
        labels: labels,
      );
      if (cropped == null) return null;
      final File out = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'adaptive_media_picker_${DateTime.now().microsecondsSinceEpoch}'
        '.${encodedImageExtension(cropped)}',
      );
      await out.writeAsBytes(cropped, flush: true);
      return out.path;
    } catch (e) {
      debugPrint('Image cropping failed: $e');
      return null;
    }
  }
}
