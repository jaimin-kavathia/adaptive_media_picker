import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

import 'stub/limited_access_picker_stub.dart'
    if (dart.library.io) 'ui/limited_access_picker.dart';
import 'stub/permission_manager_stub.dart'
    if (dart.library.io) 'platform/permission_manager.dart';

import 'core/models.dart';

/// Adaptive, permission-aware media picker.
///
/// Responsibilities:
/// - Requests and evaluates runtime permissions per platform and API level
/// - Detects and handles "limited access" modes with a built-in grid UI
/// - Delegates to `image_picker` when full access is available
/// - Applies platform caveats (e.g., camera→gallery fallback on web/desktop)
/// - Normalizes behavior across platforms (e.g., always enforcing `maxImages` for multi-pick)
class AdaptiveMediaPicker {
  /// Creates an [AdaptiveMediaPicker].
  ///
  /// You may pass a custom [permissionManager] for testing or advanced use
  /// cases. By default, a platform-aware [PermissionManager] is created.
  AdaptiveMediaPicker({PermissionManager? permissionManager})
    : _permissionManager = permissionManager ?? PermissionManager();

  final PermissionManager _permissionManager;
  final ImagePicker _picker = ImagePicker();

  /// Pick a single image.
  ///
  /// - Honors [PickOptions.source] (camera/gallery). On web/desktop, camera
  ///   transparently falls back to gallery.
  /// - Returns a [PickResultSingle] with either one item or `null`.
  Future<PickResultSingle> pickImage({
    required BuildContext context,
    PickOptions options = const PickOptions(),
  }) async {
    return _pickSingle(context: context, options: options, wantsVideo: false);
  }

  /// Pick a single video.
  ///
  /// Multi-pick videos are not supported by native APIs.
  /// Returns a [PickResultSingle].
  Future<PickResultSingle> pickVideo({
    required BuildContext context,
    PickOptions options = const PickOptions(),
  }) async {
    return _pickSingle(context: context, options: options, wantsVideo: true);
  }

  /// Pick multiple images.
  ///
  /// Enforces [PickOptions.maxImages] across platforms and returns a
  /// [PickResultMultiple].
  Future<PickResultMultiple> pickMultiImage({
    required BuildContext context,
    PickOptions options = const PickOptions(),
  }) async {
    return _pickMultiple(context: context, options: options);
  }

  /// Internal single-pick implementation used by [pickImage] and [pickVideo].
  ///
  /// Flow overview:
  /// - Requests appropriate permissions based on platform and [options]
  /// - If limited access is active (iOS / Android 14+), presents a bottom sheet
  ///   letting users pick from the allowed set
  /// - If full access is available, calls `image_picker` directly
  /// - On web/desktop, camera requests fall back to gallery
  ///
  /// Returns a [PickResultSingle] with selected media and final permission state.
  Future<PickResultSingle> _pickSingle({
    required BuildContext context,
    required PickOptions options,
    required bool wantsVideo,
  }) async {
    // On web and desktop platforms, camera capture is not supported.
    // If the caller requests camera, transparently fall back to gallery.
    final bool isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    final ImageSource effectiveSource =
        (kIsWeb || isDesktop) && options.source == ImageSource.camera
            ? ImageSource.gallery
            : options.source;
    // Web: use image_picker for web directly and avoid any Platform checks.
    if (kIsWeb) {
      if (wantsVideo) {
        final XFile? video = await _picker.pickVideo(source: effectiveSource);
        return PickResultSingle(
          item:
              video == null
                  ? null
                  : PickedMedia(path: video.path, mimeType: null),
          permissionResolution: PermissionResolution.grantedFull(),
        );
      }
      final XFile? image = await _picker.pickImage(
        source: effectiveSource,
        imageQuality: options.imageQuality,
        maxWidth: options.maxWidth?.toDouble(),
        maxHeight: options.maxHeight?.toDouble(),
      );
      return PickResultSingle(
        item:
            image == null
                ? null
                : PickedMedia(path: image.path, mimeType: null),
        permissionResolution: PermissionResolution.grantedFull(),
      );
    }

    final PermissionResolution permission = await _permissionManager
        .ensureMediaPermission(
          source: effectiveSource,
          mediaType: wantsVideo ? MediaType.video : MediaType.image,
        );

    if (!permission.granted) {
      if (permission.permanentlyDenied && options.showOpenSettingsDialog) {
        if (!context.mounted) {
          return PickResultSingle(item: null, permissionResolution: permission);
        }
        final bool open = await _showOpenSettingsDialog(
          context,
          options,
          wantsVideo: wantsVideo,
        );
        if (open) {
          await openAppSettings();
        }
      }
      return PickResultSingle(item: null, permissionResolution: permission);
    }

    // If OS reported limited, go through limited flow.
    if (permission.limited) {
      if (!context.mounted) {
        return PickResultSingle(item: null, permissionResolution: permission);
      }
      final List<AssetEntity>? selected = await LimitedAccessPicker.show(
        context: context,
        allowMultiple: false,
        maxImages: options.maxImages,
        mediaType: wantsVideo ? MediaType.video : MediaType.image,
      );
      if (selected == null || selected.isEmpty) {
        return PickResultSingle(item: null, permissionResolution: permission);
      }
      final items = await Future.wait(
        selected.map((e) async {
          final file = await e.file;
          return file == null
              ? null
              : PickedMedia(
                path: file.path,
                mimeType: e.mimeType,
                width: e.width,
                height: e.height,
              );
        }),
      );
      final List<PickedMedia> picked = items.whereType<PickedMedia>().toList();
      return PickResultSingle(
        item: picked.isEmpty ? null : picked.first,
        permissionResolution: permission,
      );
    }

    if (wantsVideo) {
      if (effectiveSource == ImageSource.camera) {
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.camera,
        );
        if (video == null) {
          return PickResultSingle(item: null, permissionResolution: permission);
        }
        return PickResultSingle(
          item: PickedMedia(path: video.path, mimeType: null),
          permissionResolution: permission,
        );
      } else {
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.gallery,
        );
        if (video == null) {
          return PickResultSingle(item: null, permissionResolution: permission);
        }
        return PickResultSingle(
          item: PickedMedia(path: video.path, mimeType: null),
          permissionResolution: permission,
        );
      }
    }

    // Desktop support is delegated to image_picker's desktop implementations.

    final XFile? image = await _picker.pickImage(
      source: effectiveSource,
      imageQuality: options.imageQuality,
      maxWidth: options.maxWidth?.toDouble(),
      maxHeight: options.maxHeight?.toDouble(),
    );
    if (image == null) {
      return PickResultSingle(item: null, permissionResolution: permission);
    }
    return PickResultSingle(
      item: PickedMedia(path: image.path, mimeType: null),
      permissionResolution: permission,
    );
  }

  /// Internal multi-image implementation used by [pickMultiImage].
  ///
  /// Always returns [PickResultMultiple] and enforces [PickOptions.maxImages]
  /// across platforms.
  Future<PickResultMultiple> _pickMultiple({
    required BuildContext context,
    required PickOptions options,
  }) async {
    final bool isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    final ImageSource effectiveSource =
        (kIsWeb || isDesktop) && options.source == ImageSource.camera
            ? ImageSource.gallery
            : options.source;

    if (kIsWeb) {
      if (effectiveSource == ImageSource.gallery) {
        final images = await _picker.pickMultiImage(
          imageQuality: options.imageQuality,
          limit: options.maxImages,
        );
        List<PickedMedia> items =
            images
                .map((x) => PickedMedia(path: x.path, mimeType: null))
                .toList();
        if (options.maxImages != null && items.length > options.maxImages!) {
          items = items.take(options.maxImages!).toList();
        }
        return PickResultMultiple(
          items: items,
          permissionResolution: PermissionResolution.grantedFull(),
        );
      }
      // Fallback to single image selection path for camera on web/desktop
      final single = await _picker.pickImage(
        source: effectiveSource,
        imageQuality: options.imageQuality,
        maxWidth: options.maxWidth?.toDouble(),
        maxHeight: options.maxHeight?.toDouble(),
      );
      final items =
          single == null
              ? <PickedMedia>[]
              : [PickedMedia(path: single.path, mimeType: null)];
      return PickResultMultiple(
        items: items,
        permissionResolution: PermissionResolution.grantedFull(),
      );
    }

    final PermissionResolution permission = await _permissionManager
        .ensureMediaPermission(
          source: effectiveSource,
          mediaType: MediaType.image,
        );
    if (!permission.granted) {
      if (permission.permanentlyDenied && options.showOpenSettingsDialog) {
        if (!context.mounted) {
          return PickResultMultiple(
            items: const [],
            permissionResolution: permission,
          );
        }
        final bool open = await _showOpenSettingsDialog(
          context,
          options,
          wantsVideo: false,
        );
        if (open) await openAppSettings();
      }
      return PickResultMultiple(
        items: const [],
        permissionResolution: permission,
      );
    }

    if (permission.limited) {
      if (!context.mounted) {
        return PickResultMultiple(
          items: const [],
          permissionResolution: permission,
        );
      }
      final List<AssetEntity>? selected = await LimitedAccessPicker.show(
        context: context,
        allowMultiple: true,
        maxImages: options.maxImages,
        mediaType: MediaType.image,
      );
      if (selected == null || selected.isEmpty) {
        return PickResultMultiple(
          items: const [],
          permissionResolution: permission,
        );
      }
      final items = await Future.wait(
        selected.map((e) async {
          final file = await e.file;
          return file == null
              ? null
              : PickedMedia(
                path: file.path,
                mimeType: e.mimeType,
                width: e.width,
                height: e.height,
              );
        }),
      );
      List<PickedMedia> picked = items.whereType<PickedMedia>().toList();
      if (options.maxImages != null && picked.length > options.maxImages!) {
        picked = picked.take(options.maxImages!).toList();
      }
      return PickResultMultiple(
        items: picked,
        permissionResolution: permission,
      );
    }

    if (effectiveSource == ImageSource.gallery) {
      try {
        final images = await _picker.pickMultiImage(
          imageQuality: options.imageQuality,
          limit: options.maxImages,
        );
        List<PickedMedia> items =
            images
                .map((x) => PickedMedia(path: x.path, mimeType: null))
                .toList();
        if (options.maxImages != null && items.length > options.maxImages!) {
          items = items.take(options.maxImages!).toList();
        }
        return PickResultMultiple(
          items: items,
          permissionResolution: permission,
        );
      } on Exception {
        if (!context.mounted) {
          return PickResultMultiple(
            items: const [],
            permissionResolution: permission,
          );
        }
        final List<AssetEntity>? selected = await LimitedAccessPicker.show(
          context: context,
          allowMultiple: true,
          maxImages: options.maxImages,
          mediaType: MediaType.image,
        );
        if (selected == null || selected.isEmpty) {
          return PickResultMultiple(
            items: const [],
            permissionResolution: permission,
          );
        }
        final items = await Future.wait(
          selected.map((e) async {
            final file = await e.file;
            return file == null
                ? null
                : PickedMedia(
                  path: file.path,
                  mimeType: e.mimeType,
                  width: e.width,
                  height: e.height,
                );
          }),
        );
        List<PickedMedia> picked = items.whereType<PickedMedia>().toList();
        if (options.maxImages != null && picked.length > options.maxImages!) {
          picked = picked.take(options.maxImages!).toList();
        }
        return PickResultMultiple(
          items: picked,
          permissionResolution: permission,
        );
      }
    }

    // Fallback to single image selection for camera
    final XFile? image = await _picker.pickImage(
      source: effectiveSource,
      imageQuality: options.imageQuality,
      maxWidth: options.maxWidth?.toDouble(),
      maxHeight: options.maxHeight?.toDouble(),
    );
    final items =
        image == null
            ? <PickedMedia>[]
            : [PickedMedia(path: image.path, mimeType: null)];
    return PickResultMultiple(items: items, permissionResolution: permission);
  }

  Future<bool> _showOpenSettingsDialog(
    BuildContext context,
    PickOptions options, {
    required bool wantsVideo,
  }) async {
    final bool isCamera = options.source == ImageSource.camera;

    final String defaultTitle = 'Permission required';
    String defaultMessage;
    if (isCamera) {
      defaultMessage =
          wantsVideo
              ? 'Camera and Microphone access is required to record videos. Open Settings to grant access.'
              : 'Camera access is required to take photos. Open Settings to grant access.';
    } else {
      defaultMessage =
          wantsVideo
              ? 'Photos and Videos access is required to pick videos. Open Settings to grant access.'
              : 'Photos access is required to pick images. Open Settings to grant access.';
    }

    final String title = options.settingsDialogTitle ?? defaultTitle;
    final String message = options.settingsDialogMessage ?? defaultMessage;
    final String settingsLabel = options.settingsButtonLabel ?? 'Open Settings';
    final String cancelLabel = options.cancelButtonLabel ?? 'Cancel';

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      if (!context.mounted) return false;
      return await showCupertinoDialog<bool>(
            context: context,
            builder:
                (ctx) => CupertinoAlertDialog(
                  title: Text(title),
                  content: Text(message),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(cancelLabel),
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(settingsLabel),
                    ),
                  ],
                ),
          ) ??
          false;
    }

    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(cancelLabel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(settingsLabel),
                  ),
                ],
              ),
        ) ??
        false;
  }
}
