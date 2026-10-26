import 'package:flutter/material.dart';

import '../core/models.dart';

/// Limited-access selection sheet (Web stub).
///
/// Browsers have no limited Photos access mode, so [show] is unsupported
/// here; `AdaptiveMediaPicker` never calls it on Web.
class LimitedAccessPicker {
  /// Creates a stub instance.
  const LimitedAccessPicker({
    this.allowMultiple = false,
    this.maxImages,
    this.mediaType = MediaType.image,
  });

  /// Whether multiple selection is allowed.
  final bool allowMultiple;

  /// Maximum number of selectable items when [allowMultiple] is true.
  final int? maxImages;

  /// The media type displayed in the sheet.
  final MediaType mediaType;

  /// Always throws [UnsupportedError] on this platform.
  // Returns `List<dynamic>` instead of `List<AssetEntity>`: naming the
  // photo_manager type here would pull `dart:io` into web/WASM builds.
  static Future<List<dynamic>?> show({
    required BuildContext context,
    bool allowMultiple = false,
    int? maxImages,
    MediaType mediaType = MediaType.image,
    Brightness? themeBrightness,
    Color? primaryColor,
    PickerLabels labels = const PickerLabels(),
  }) async {
    throw UnsupportedError(
      'LimitedAccessPicker is not supported on this platform.',
    );
  }
}
