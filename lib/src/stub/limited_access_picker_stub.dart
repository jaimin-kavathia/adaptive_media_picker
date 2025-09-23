// LimitedAccessPicker stub
import 'package:adaptive_media_picker/adaptive_media_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class LimitedAccessPicker {
  const LimitedAccessPicker({
    this.allowMultiple = false,
    this.maxImages,
    this.mediaType = MediaType.image,
  });

  final bool allowMultiple;
  final int? maxImages;
  final MediaType mediaType;

  static Future<List<AssetEntity>?> show({
    required BuildContext context,
    bool allowMultiple = false,
    int? maxImages,
    MediaType mediaType = MediaType.image,
  }) async {
    throw UnsupportedError(
      'LimitedAccessPicker is not supported on this platform.',
    );
  }
}
