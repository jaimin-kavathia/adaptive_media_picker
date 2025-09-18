import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart' as pm;

import 'models.dart';

/// Handles runtime permissions for camera and media library.
///
/// Platform notes:
/// - Android: On API 33+, first prompt via `permission_handler`. If status is
///   ambiguous, inspect `photo_manager` assets to infer limited access.
/// - iOS: Uses `photo_manager` for read/write with limited mode handling.
/// - Desktop (macOS/Windows/Linux): No runtime permission; relies on file
///   dialogs and app entitlements where applicable.
/// Handles platform-specific permission flows for camera and media library.
class PermissionManager {
  const PermissionManager();

  /// Ensures the required permissions are granted for the requested [source].
  ///
  /// Returns a [PermissionResolution] indicating whether access is granted,
  /// limited, or denied (possibly permanently).
  Future<PermissionResolution> ensureMediaPermission({
    required ImageSource source,
    required MediaType mediaType,
  }) async {
    if (kIsWeb) {
      return PermissionResolution.grantedFull();
    }

    // Desktop platforms: no runtime permission flow; rely on file selectors.
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return PermissionResolution.grantedFull();
    }

    // Camera permissions
    if (source == ImageSource.camera) {
      final cam = await Permission.camera.request();
      PermissionStatus? mic;
      if (mediaType == MediaType.video) {
        mic = await Permission.microphone.request();
      }
      final permanentlyDenied =
          cam.isPermanentlyDenied || (mic?.isPermanentlyDenied ?? false);
      if (cam.isGranted && (mic == null || mic.isGranted))
        return PermissionResolution.grantedFull();
      if (permanentlyDenied)
        return PermissionResolution.denied(permanentlyDenied: true);
      return PermissionResolution.denied();
    }

    // Gallery / library permissions
    if (Platform.isAndroid) {
      final int sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt >= 33) {
        // Request granular media permissions via permission_handler
        final PermissionStatus photosStatus = await Permission.photos.request();
        PermissionStatus? videosStatus;
        if (mediaType == MediaType.video) {
          videosStatus = await Permission.videos.request();
        }
        final bool permanentlyDenied =
            photosStatus.isPermanentlyDenied ||
            (videosStatus?.isPermanentlyDenied ?? false);
        if (permanentlyDenied)
          return PermissionResolution.denied(permanentlyDenied: true);

        // If either permission is limited, treat as limited
        final bool isLimited =
            await Permission.photos.isLimited ||
            (mediaType == MediaType.video
                ? (await Permission.videos.isLimited)
                : false);
        if (isLimited) return PermissionResolution.grantedLimited();

        // Otherwise, granted (full)
        if (photosStatus.isGranted &&
            (videosStatus == null || videosStatus.isGranted)) {
          return PermissionResolution.grantedFull();
        }

        return PermissionResolution.denied();
      } else {
        final storage = await Permission.storage.request();
        if (storage.isGranted) return PermissionResolution.grantedFull();
        if (storage.isPermanentlyDenied)
          return PermissionResolution.denied(permanentlyDenied: true);
        return PermissionResolution.denied();
      }
    }

    if (Platform.isIOS) {
      // Use permission_handler to reflect iOS Photos limited/full accurately
      final PermissionStatus status = await Permission.photos.request();
      if (status.isPermanentlyDenied)
        return PermissionResolution.denied(permanentlyDenied: true);
      if (!status.isGranted && !status.isLimited)
        return PermissionResolution.denied();
      final bool isLimited = await Permission.photos.isLimited;
      return isLimited
          ? PermissionResolution.grantedLimited()
          : PermissionResolution.grantedFull();
    }

    if (Platform.isMacOS) {
      return PermissionResolution.grantedFull();
    }

    return PermissionResolution.grantedFull();
  }

  /// Presents the OS-provided limited access selection (iOS only).
  Future<void> presentLimitedIfAvailable() async {
    if (kIsWeb) return;
    if (Platform.isIOS) {
      await pm.PhotoManager.presentLimited(type: pm.RequestType.common);
    }
  }
}
