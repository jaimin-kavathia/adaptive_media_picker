import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../core/models.dart'
    show CropAspectRatioOption, CropShape, PickerLabels;
import 'builtin_cropper.dart';

/// Web image cropper.
///
/// Uses the package's pure-Flutter crop editor instead of `image_cropper`'s
/// web backend: that backend pulls `dart:io` into the import graph (breaking
/// WASM) and requires host apps to add cropperjs to `index.html`.
class PlatformImageCropper {
  /// Crops [sourcePath] (a blob URL) and returns a blob URL for the result,
  /// or null if the user cancels, cropping fails, or [context] is missing.
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
    if (context == null) {
      debugPrint('BuildContext is required for web cropping.');
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
    final String ext = encodedImageExtension(cropped);
    return XFile.fromData(
      cropped,
      mimeType: ext == 'jpg' ? 'image/jpeg' : 'image/png',
      name: 'cropped.$ext',
    ).path;
  }
}
