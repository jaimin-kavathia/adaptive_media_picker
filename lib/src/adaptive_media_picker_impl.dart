import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'limited_access_picker.dart';
import 'models.dart';
import 'permission_manager.dart';

/// High-level orchestrator for adaptive media picking across platforms.
///
/// Responsibilities:
/// - Requests and evaluates runtime permissions per platform and API level
/// - Detects and handles "limited access" modes with a built-in grid UI
/// - Delegates to `image_picker` when full access is available
/// - Applies platform caveats (e.g., camera→gallery fallback on web/desktop)
class AdaptiveMediaPicker {
  AdaptiveMediaPicker({PermissionManager? permissionManager}) : _permissionManager = permissionManager ?? const PermissionManager();

  final PermissionManager _permissionManager;
  final ImagePicker _picker = ImagePicker();

  /// Picks images or a single video depending on [options].
  ///
  /// Flow overview:
  /// - Requests appropriate permissions based on platform and [options]
  /// - If limited access is active (iOS / Android 14+), presents a bottom sheet
  ///   letting users pick from the allowed set
  /// - If full access is available, calls `image_picker` directly
  /// - On web/desktop, camera requests fall back to gallery
  ///
  /// Returns a [PickResult] containing selected items and final permission state.
  Future<PickResult> pickImage({
    required BuildContext context,
    PickOptions options = const PickOptions(),
  }) async {
    // On web and desktop platforms, camera capture is not supported.
    // If the caller requests camera, transparently fall back to gallery.
    final bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
    final ImageSource effectiveSource = (kIsWeb || isDesktop) && options.source == ImageSource.camera
        ? ImageSource.gallery
        : options.source;
    // Web: use image_picker for web directly and avoid any Platform checks.
    if (kIsWeb) {
      final bool wantsVideo = options.mediaType == MediaType.video;
      if (wantsVideo) {
        final XFile? video = await _picker.pickVideo(source: effectiveSource);
        final items = video == null ? <PickedMedia>[] : [PickedMedia(path: video.path, mimeType: null)];
        return PickResult(items: items, permissionResolution: PermissionResolution.grantedFull());
      }
      if (options.allowMultiple && effectiveSource == ImageSource.gallery) {
        final images = await _picker.pickMultiImage(imageQuality: options.imageQuality, limit: options.maxImages);
        final items = images.map((x) => PickedMedia(path: x.path, mimeType: null)).toList();
        return PickResult(items: items, permissionResolution: PermissionResolution.grantedFull());
      }
      final XFile? image = await _picker.pickImage(
        source: effectiveSource,
        imageQuality: options.imageQuality,
        maxWidth: options.maxWidth?.toDouble(),
        maxHeight: options.maxHeight?.toDouble(),
      );
      final items = image == null ? <PickedMedia>[] : [PickedMedia(path: image.path, mimeType: null)];
      return PickResult(items: items, permissionResolution: PermissionResolution.grantedFull());
    }

    final bool wantsVideo = options.mediaType == MediaType.video;
    final PermissionResolution permission = await _permissionManager.ensureMediaPermission(
      source: effectiveSource,
      mediaType: options.mediaType,
    );

    if (!permission.granted) {
      if (permission.permanentlyDenied && options.showOpenSettingsDialog) {
        if (!context.mounted) {
          return PickResult(items: const [], permissionResolution: permission);
        }
        final bool open = await _showOpenSettingsDialog(context, options);
        if (open) {
          await openAppSettings();
        }
      }
      return PickResult(items: const [], permissionResolution: permission);
    }

    // If OS reported limited, go through limited flow.
    if (permission.limited) {
      if (!context.mounted) {
        return PickResult(items: const [], permissionResolution: permission);
      }
      final List<AssetEntity>? selected = await LimitedAccessPicker.show(
        context: context,
        allowMultiple: options.allowMultiple,
        maxImages: options.maxImages,
        mediaType: wantsVideo ? MediaType.video : MediaType.image,
      );
      if (selected == null || selected.isEmpty) {
        return PickResult(items: const [], permissionResolution: permission);
      }
      final items = await Future.wait(selected.map((e) async {
        final file = await e.file;
        return file == null
            ? null
            : PickedMedia(
                path: file.path,
                mimeType: e.mimeType,
                width: e.width,
                height: e.height,
              );
      }));
      return PickResult(
        items: items.whereType<PickedMedia>().toList(),
        permissionResolution: permission,
      );
    }

    // Android 13+ edge case: user selected limited for images but not videos (or vice versa).
    // Even if permission looks "full", if the requested media type list is empty, force limited UI.
    if (Platform.isAndroid && effectiveSource == ImageSource.gallery) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt >= 33) {
        final RequestType type = wantsVideo ? RequestType.video : RequestType.image;
        final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true, type: type);
        final bool hasAny = albums.isNotEmpty
            ? (await albums.first.getAssetListRange(start: 0, end: 1)).isNotEmpty
            : false;
        if (!hasAny) {
          if (!context.mounted) {
            return PickResult(items: const [], permissionResolution: PermissionResolution.grantedLimited());
          }
          final List<AssetEntity>? selected = await LimitedAccessPicker.show(
            context: context,
            allowMultiple: options.allowMultiple,
            maxImages: options.maxImages,
            mediaType: wantsVideo ? MediaType.video : MediaType.image,
          );
          if (selected == null || selected.isEmpty) {
            return PickResult(items: const [], permissionResolution: PermissionResolution.grantedLimited());
          }
          final items = await Future.wait(selected.map((e) async {
            final file = await e.file;
            return file == null
                ? null
                : PickedMedia(
                    path: file.path,
                    mimeType: e.mimeType,
                    width: e.width,
                    height: e.height,
                  );
          }));
          return PickResult(
            items: items.whereType<PickedMedia>().toList(),
            permissionResolution: PermissionResolution.grantedLimited(),
          );
        }
      }
    }

    // Full access flows
    if (wantsVideo) {
      if (effectiveSource == ImageSource.camera) {
        final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
        if (video == null) return PickResult(items: const [], permissionResolution: permission);
        return PickResult(items: [PickedMedia(path: video.path, mimeType: null)], permissionResolution: permission);
      } else {
        final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
        if (video == null) return PickResult(items: const [], permissionResolution: permission);
        return PickResult(items: [PickedMedia(path: video.path, mimeType: null)], permissionResolution: permission);
      }
    }

    if (options.allowMultiple && effectiveSource == ImageSource.gallery) {
      try {
        final images = await _picker.pickMultiImage(
          imageQuality: options.imageQuality,
          limit: options.maxImages,
        );
        List<PickedMedia> items = images
            .map((x) => PickedMedia(
                  path: x.path,
                  mimeType: null,
                ))
            .toList();
        if (options.maxImages != null && items.length > options.maxImages!) {
          items = items.take(options.maxImages!).toList();
        }
        return PickResult(items: items, permissionResolution: permission);
      } on Exception {
        if (!context.mounted) {
          return PickResult(items: const [], permissionResolution: permission);
        }
        final List<AssetEntity>? selected = await LimitedAccessPicker.show(
          context: context,
          allowMultiple: true,
          maxImages: options.maxImages,
          mediaType: wantsVideo ? MediaType.video : MediaType.image,
        );
        if (selected == null || selected.isEmpty) {
          return PickResult(items: const [], permissionResolution: permission);
        }
        final items = await Future.wait(selected.map((e) async {
          final file = await e.file;
          return file == null
              ? null
              : PickedMedia(
                  path: file.path,
                  mimeType: e.mimeType,
                  width: e.width,
                  height: e.height,
                );
        }));
        return PickResult(items: items.whereType<PickedMedia>().toList(), permissionResolution: permission);
      }
    }

    final XFile? image = await _picker.pickImage(
      source: effectiveSource,
      imageQuality: options.imageQuality,
      maxWidth: options.maxWidth?.toDouble(),
      maxHeight: options.maxHeight?.toDouble(),
    );
    if (image == null) {
      return PickResult(items: const [], permissionResolution: permission);
    }
    return PickResult(
      items: [PickedMedia(path: image.path, mimeType: null)],
      permissionResolution: permission,
    );
  }

  Future<bool> _showOpenSettingsDialog(BuildContext context, PickOptions options) async {
    final bool wantsVideo = options.mediaType == MediaType.video;
    final bool isCamera = options.source == ImageSource.camera;

    final String defaultTitle = 'Permission required';
    String defaultMessage;
    if (isCamera) {
      defaultMessage = wantsVideo
          ? 'Camera and Microphone access is required to record videos. Open Settings to grant access.'
          : 'Camera access is required to take photos. Open Settings to grant access.';
    } else {
      defaultMessage = wantsVideo
          ? 'Photos and Videos access is required to pick videos. Open Settings to grant access.'
          : 'Photos access is required to pick images. Open Settings to grant access.';
    }

    final String title = options.settingsDialogTitle ?? defaultTitle;
    final String message = options.settingsDialogMessage ?? defaultMessage;
    final String settingsLabel = options.settingsButtonLabel ?? 'Open Settings';
    final String cancelLabel = options.cancelButtonLabel ?? 'Cancel';

    if (Platform.isIOS) {
      if (!context.mounted) return false;
      return await showCupertinoDialog<bool>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
                CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(true), child: Text(settingsLabel)),
              ],
            ),
          ) ??
          false;
    }

    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(settingsLabel)),
            ],
          ),
        ) ??
        false;
  }
}
