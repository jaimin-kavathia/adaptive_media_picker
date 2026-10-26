import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../core/models.dart';

/// Runtime permission handling (Web stub).
///
/// Browsers grant access per file through the file chooser, so every request
/// resolves to full access.
class PermissionManager {
  /// Creates a stub [PermissionManager].
  const PermissionManager();

  /// Testing hook kept for API parity with the native implementation.
  static bool bypassPlatformChannelsForTests = false;

  /// Always resolves to [PermissionResolution.grantedFull] on this platform.
  Future<PermissionResolution> ensureMediaPermission({
    required ImageSource source,
    required MediaType mediaType,
    BuildContext? context,
    String? dialogTitle,
    String? dialogMessage,
    String? settingsButtonLabel,
    String? cancelButtonLabel,
  }) async {
    return PermissionResolution.grantedFull();
  }

  /// No-op on this platform.
  Future<void> presentLimitedIfAvailable() async {}

  /// Always true on this platform.
  bool isValidImageExtension(String path) => true;

  /// Always true on this platform.
  bool isValidVideoExtension(String path) => true;
}
