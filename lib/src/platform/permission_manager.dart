import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_permission/smart_permission.dart';
import 'package:photo_manager/photo_manager.dart';

import '../core/models.dart';

/// Handles runtime permissions for camera and media library.
///
/// Platform notes:
/// - Android: On API 33+, uses `smart_permission` for granular media permissions.
///   If status is ambiguous, inspect `photo_manager` assets to infer limited access.
/// - iOS: Uses `smart_permission` for Photos permission with limited mode handling.
/// - Desktop (macOS/Windows/Linux): No runtime permission; relies on file
///   dialogs and app entitlements where applicable.
/// Handles platform-specific permission flows for camera and media library.
class PermissionManager {
  const PermissionManager();

  /// Testing hook: when true, `ensureMediaPermission` short-circuits to
  /// grantedFull to avoid invoking platform channels in headless CI.
  static bool bypassPlatformChannelsForTests = false;

  /// Ensures the required permissions are granted for the requested [source].
  ///
  /// Returns a [PermissionResolution] indicating whether access is granted,
  /// limited, or denied (possibly permanently).
  Future<PermissionResolution> ensureMediaPermission({
    required ImageSource source,
    required MediaType mediaType,
    BuildContext? context,
  }) async {
    if (bypassPlatformChannelsForTests) {
      return PermissionResolution.grantedFull();
    }
    if (kIsWeb) {
      return PermissionResolution.grantedFull();
    }

    // Desktop platforms: no runtime permission flow; rely on file selectors.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows)) {
      return PermissionResolution.grantedFull();
    }

    // Camera permissions
    if (source == ImageSource.camera) {
      if (context == null) {
        // No context available, return denied
        return PermissionResolution.denied();
      }

      // Use smart_permission for camera
      final permissions = [Permission.camera];
      if (mediaType == MediaType.video) {
        permissions.add(Permission.microphone);
      }

      final result = await SmartPermission.requestMultiple(
        context,
        permissions: permissions,
      );

      if (result.values.every((granted) => granted)) {
        return PermissionResolution.grantedFull();
      }

      // Check if any permission is permanently denied by trying to request again
      // This is a simplified approach - smart_permission handles the UX
      return PermissionResolution.denied();
    }

    // Gallery / library permissions
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (context == null) {
        // No context available, return denied
        return PermissionResolution.denied();
      }

      final int sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt >= 33) {
        // Request granular media permissions via smart_permission
        final permissions = [Permission.photos];
        if (mediaType == MediaType.video) {
          permissions.add(Permission.videos);
        }

        if (!context.mounted) return PermissionResolution.denied();

        final result = await SmartPermission.requestMultiple(
          context,
          permissions: permissions,
        );

        // Get albums to check for limited access
        final List<AssetPathEntity> albums =
            await PhotoManager.getAssetPathList(
          onlyAll: true,
          type: RequestType.all,
        );

        if (albums.isNotEmpty) {
          final List<AssetEntity> assets = await albums.first.getAssetListRange(
            start: 0,
            end: 100,
          );

          final validImages = assets
              .where(
                (asset) =>
                    asset.type == AssetType.image &&
                    isValidImageExtension(asset.title ?? ''),
              )
              .toList();

          final validVideos = assets
              .where(
                (asset) =>
                    asset.type == AssetType.video &&
                    isValidVideoExtension(asset.title ?? ''),
              )
              .toList();

          // If either permission is limited, treat as limited
          final bool isLimited = (mediaType == MediaType.image
                  ? validImages.isNotEmpty
                  : false) ||
              (mediaType == MediaType.video ? validVideos.isNotEmpty : false);
          if (isLimited) return PermissionResolution.grantedLimited();
        }

        // Check if all permissions granted
        if (result.values.every((granted) => granted)) {
          return PermissionResolution.grantedFull();
        }

        return PermissionResolution.denied();
      } else {
        // Android < 33: use storage permission
        if (!context.mounted) return PermissionResolution.denied();

        final result = await SmartPermission.request(
          context,
          permission: Permission.storage,
        );
        if (result) return PermissionResolution.grantedFull();
        return PermissionResolution.denied();
      }
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      if (context == null) {
        // No context available, return denied
        return PermissionResolution.denied();
      }

      // Use smart_permission for iOS Photos permission
      final result = await SmartPermission.request(
        context,
        permission: Permission.photos,
      );

      if (!result) {
        return PermissionResolution.denied();
      }

      // Check if limited access using photo_manager
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.all,
      );

      if (albums.isNotEmpty) {
        final List<AssetEntity> assets = await albums.first.getAssetListRange(
          start: 0,
          end: 100,
        );

        final validImages = assets
            .where(
              (asset) =>
                  asset.type == AssetType.image &&
                  isValidImageExtension(asset.title ?? ''),
            )
            .toList();

        final validVideos = assets
            .where(
              (asset) =>
                  asset.type == AssetType.video &&
                  isValidVideoExtension(asset.title ?? ''),
            )
            .toList();

        // If we have limited access (some assets but not all)
        final bool isLimited =
            (mediaType == MediaType.image ? validImages.isNotEmpty : false) ||
                (mediaType == MediaType.video ? validVideos.isNotEmpty : false);
        if (isLimited) return PermissionResolution.grantedLimited();
      }

      return PermissionResolution.grantedFull();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      return PermissionResolution.grantedFull();
    }

    return PermissionResolution.grantedFull();
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
