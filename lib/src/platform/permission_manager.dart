import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_permission/smart_permission.dart';

import '../core/models.dart';

/// Handles runtime permissions for camera and media library.
///
/// Platform notes:
/// - Android: On API 33+, requests granular media permissions
///   (`READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`); below that, storage.
/// - iOS: Requests the Photos permission with limited-mode detection.
/// - Desktop (macOS/Windows/Linux): No runtime permission; relies on file
///   dialogs and app entitlements where applicable.
///
/// The heavy lifting (rationale dialog, permanently-denied "Open Settings"
/// dialog, waiting for the user to return from Settings and re-checking) is
/// delegated to `smart_permission`. The dialog strings can be customized via
/// the optional parameters of [ensureMediaPermission].
class PermissionManager {
  const PermissionManager();

  /// Testing hook: when true, `ensureMediaPermission` short-circuits to
  /// grantedFull to avoid invoking platform channels in headless CI.
  static bool bypassPlatformChannelsForTests = false;

  /// Ensures the required permissions are granted for the requested [source].
  ///
  /// The optional dialog strings are forwarded to `smart_permission`, which
  /// shows the rationale and "Open Settings" dialogs on your behalf.
  ///
  /// Returns a [PermissionResolution] indicating whether access is granted,
  /// limited, or denied (possibly permanently).
  Future<PermissionResolution> ensureMediaPermission({
    required ImageSource source,
    required MediaType mediaType,
    BuildContext? context,
    String? dialogTitle,
    String? dialogMessage,
    String? settingsButtonLabel,
    String? cancelButtonLabel,
  }) async {
    if (bypassPlatformChannelsForTests) {
      return PermissionResolution.grantedFull();
    }
    if (kIsWeb) {
      return PermissionResolution.grantedFull();
    }

    // Desktop platforms: no runtime permission flow; rely on file selectors.
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      return PermissionResolution.grantedFull();
    }

    if (context == null) {
      // No context available: dialogs cannot be shown, return denied.
      return PermissionResolution.denied();
    }

    // Camera permissions
    if (source == ImageSource.camera) {
      final permissions = [
        Permission.camera,
        if (mediaType == MediaType.video) Permission.microphone,
      ];
      final results = await SmartPermission.requestMultipleResults(
        context: context,
        permissions: permissions,
        title: dialogTitle,
        description: dialogMessage,
        settingsButtonText: settingsButtonLabel,
        denyButtonText: cancelButtonLabel,
      );
      return _toResolution(results.values);
    }

    // Gallery / library permissions
    if (defaultTargetPlatform == TargetPlatform.android) {
      final int sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      // API 33+: granular media permissions; below: legacy storage.
      final Permission permission = sdkInt >= 33
          ? (mediaType == MediaType.video
              ? Permission.videos
              : Permission.photos)
          : Permission.storage;
      if (!context.mounted) return PermissionResolution.denied();
      final result = await SmartPermission.requestResult(
        context: context,
        permission: permission,
        title: dialogTitle,
        description: dialogMessage,
        settingsButtonText: settingsButtonLabel,
        denyButtonText: cancelButtonLabel,
      );
      return _toResolution([result]);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await SmartPermission.requestResult(
        context: context,
        permission: Permission.photos,
        title: dialogTitle,
        description: dialogMessage,
        settingsButtonText: settingsButtonLabel,
        denyButtonText: cancelButtonLabel,
      );
      return _toResolution([result]);
    }

    return PermissionResolution.grantedFull();
  }

  /// Maps `smart_permission` results onto a [PermissionResolution].
  PermissionResolution _toResolution(Iterable<SmartPermissionResult> results) {
    if (results.isNotEmpty && results.every((r) => r.canProceed)) {
      final bool limited =
          results.any((r) => r == SmartPermissionResult.limited);
      return limited
          ? PermissionResolution.grantedLimited()
          : PermissionResolution.grantedFull();
    }
    return PermissionResolution.denied(
      permanentlyDenied: results.any((r) => r.isPermanentlyDenied),
    );
  }

  /// Presents the OS-provided limited access selection (iOS only).
  Future<void> presentLimitedIfAvailable() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await PhotoManager.presentLimited(type: RequestType.common);
    }
  }

  bool isValidImageExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    const validExtensions = [
      'jpg',
      'jpeg',
      'png',
      'bmp',
      'webp',
      'heic',
      'heif',
      'tiff',
      'tif',
    ];
    return validExtensions.contains(ext);
  }

  bool isValidVideoExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    const validExtensions = [
      'mp4',
      'mov',
      'm4v',
      'avi',
      'wmv',
      'flv',
      'mkv',
      'webm',
      '3gp',
    ];
    return validExtensions.contains(ext);
  }
}
