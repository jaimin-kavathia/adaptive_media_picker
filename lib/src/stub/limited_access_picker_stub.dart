// LimitedAccessPicker stub
import 'package:flutter/material.dart';

import '../core/models.dart';

class LimitedAccessPicker {
  const LimitedAccessPicker({
    this.allowMultiple = false,
    this.maxImages,
    this.mediaType = MediaType.image,
  });

  final bool allowMultiple;
  final int? maxImages;
  final MediaType mediaType;

  // Returns `List<dynamic>` instead of `List<AssetEntity>`: naming the
  // photo_manager type here would pull `dart:io` into web/WASM builds.
  static Future<List<dynamic>?> show({
    required BuildContext context,
    bool allowMultiple = false,
    int? maxImages,
    MediaType mediaType = MediaType.image,
    Brightness? themeBrightness,
    Color? primaryColor,
  }) async {
    throw UnsupportedError(
      'LimitedAccessPicker is not supported on this platform.',
    );
  }
}
