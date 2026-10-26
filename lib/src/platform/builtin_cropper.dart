import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../core/models.dart'
    show CropAspectRatioOption, CropShape, PickerLabels;
import '../ui/crop_page.dart';

/// Shared (platform-agnostic) half of the built-in cropper used on Web and
/// desktop: loads [sourcePath] and runs [BuiltInCropPage].
///
/// Returns the cropped, encoded bytes, or null if the user cancels or the
/// image can't be read. Free of `dart:io`, so it is safe for Web/WASM.
Future<Uint8List?> cropWithBuiltInEditor({
  required String sourcePath,
  required BuildContext context,
  Brightness? themeBrightness,
  Color? primaryColor,
  CropAspectRatioOption? cropAspectRatio,
  bool lockCropAspectRatio = false,
  CropShape cropShape = CropShape.rectangle,
  PickerLabels labels = const PickerLabels(),
}) async {
  final Uint8List source;
  try {
    source = await XFile(sourcePath).readAsBytes();
  } catch (e) {
    debugPrint('Built-in cropping failed to read $sourcePath: $e');
    return null;
  }
  if (!context.mounted) return null;
  return BuiltInCropPage.show(
    context: context,
    image: source,
    aspectRatio: cropAspectRatio,
    lockAspectRatio: lockCropAspectRatio,
    themeBrightness: themeBrightness,
    primaryColor: primaryColor,
    circle: cropShape == CropShape.circle,
    labels: labels,
  );
}

/// File extension matching the encoding of [bytes] (the built-in cropper
/// keeps JPEG sources as JPEG and writes everything else as PNG).
String encodedImageExtension(Uint8List bytes) =>
    bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8 ? 'jpg' : 'png';
