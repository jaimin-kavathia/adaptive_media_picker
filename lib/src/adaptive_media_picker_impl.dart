import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

// Conditional imports for image cropping.
// `dart.library.js_interop` (instead of `dart.library.html`) keeps the
// package compatible with both the JS and WASM web runtimes.
import 'stub/image_cropper_stub.dart'
    if (dart.library.io) 'platform/image_cropper_impl.dart'
    if (dart.library.js_interop) 'platform/image_cropper_web.dart';

import 'stub/limited_access_picker_stub.dart'
    if (dart.library.io) 'ui/limited_access_picker.dart';
import 'stub/permission_manager_stub.dart'
    if (dart.library.io) 'platform/permission_manager.dart';

import 'core/mime.dart';
import 'core/models.dart';
import 'ui/source_sheet.dart';

/// Adaptive, permission-aware media picker.
///
/// Responsibilities:
/// - Requests and evaluates runtime permissions per platform and API level
/// - Detects and handles "limited access" modes with a built-in grid UI
/// - Delegates to `image_picker` when full access is available
/// - Applies platform caveats (e.g., camera→gallery fallback on web/desktop)
/// - Normalizes behavior across platforms (e.g., always enforcing `maxImages` for multi-pick)
///
/// Every pick method accepts an optional `sourceSheet`: when given, the user
/// first chooses camera or gallery in an adaptive sheet (Cupertino on
/// iOS/macOS, Material elsewhere), overriding [PickOptions.source]. If the
/// sheet is dismissed or "remove" is chosen, no permission is requested, the
/// result has [PickError.canceled] (plus `removeRequested` for remove) and
/// its `permissionResolution` reports full access.
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
  /// Use cases:
  /// - Simple avatar/photo selection from gallery or camera.
  /// - Enable cropping with [PickOptions.wantToCrop] (native cropper on
  ///   Android/iOS, built-in Flutter editor on Web and desktop).
  ///
  /// Behavior:
  /// - Honors [PickOptions.source] (camera/gallery), or asks via
  ///   [sourceSheet]. On web/desktop, camera falls back to gallery.
  /// - Returns a [PickResultSingle] with either one item or `null`.
  Future<PickResultSingle> pickImage({
    required BuildContext context,
    PickOptions options = const PickOptions(),
    SourceSheetOptions? sourceSheet,
  }) => _pickSingle(context, options, MediaType.image, sourceSheet);

  /// Pick a single video from the gallery or record one with the camera.
  ///
  /// Honors [PickOptions.maxVideoDuration] and
  /// [PickOptions.preferredCameraDevice].
  Future<PickResultSingle> pickVideo({
    required BuildContext context,
    PickOptions options = const PickOptions(),
    SourceSheetOptions? sourceSheet,
  }) => _pickSingle(context, options, MediaType.video, sourceSheet);

  /// Pick a single image **or** video from the gallery.
  ///
  /// With the camera source it captures a photo. Images can be cropped with
  /// [PickOptions.wantToCrop]; videos are returned as-is.
  Future<PickResultSingle> pickMedia({
    required BuildContext context,
    PickOptions options = const PickOptions(),
    SourceSheetOptions? sourceSheet,
  }) => _pickSingle(context, options, MediaType.any, sourceSheet);

  /// Pick multiple images.
  ///
  /// Enforces [PickOptions.maxImages] across platforms. The camera source
  /// captures a single image.
  Future<PickResultMultiple> pickMultiImage({
    required BuildContext context,
    PickOptions options = const PickOptions(),
    SourceSheetOptions? sourceSheet,
  }) => _pickMultiple(context, options, MediaType.image, sourceSheet);

  /// Pick multiple videos from the gallery.
  ///
  /// Enforces [PickOptions.maxImages] as the item cap. The camera source
  /// records a single video.
  Future<PickResultMultiple> pickMultiVideo({
    required BuildContext context,
    PickOptions options = const PickOptions(),
    SourceSheetOptions? sourceSheet,
  }) => _pickMultiple(context, options, MediaType.video, sourceSheet);

  /// Pick multiple images and videos from the gallery in one go.
  ///
  /// Enforces [PickOptions.maxImages] as the item cap. The camera source
  /// captures a single photo.
  Future<PickResultMultiple> pickMultipleMedia({
    required BuildContext context,
    PickOptions options = const PickOptions(),
    SourceSheetOptions? sourceSheet,
  }) => _pickMultiple(context, options, MediaType.any, sourceSheet);

  /// Shows the adaptive "Take photo / Choose from gallery" sheet on its own
  /// and returns the user's choice, or `null` if dismissed.
  ///
  /// Useful for custom flows; the pick methods do this for you when given a
  /// `sourceSheet`.
  Future<MediaSourceChoice?> showSourceSheet({
    required BuildContext context,
    MediaType mediaType = MediaType.image,
    SourceSheetOptions options = const SourceSheetOptions(),
    Color? primaryColor,
  }) => showMediaSourceSheet(
    context: context,
    mediaType: mediaType,
    options: options,
    primaryColor: primaryColor,
  );

  /// Recovers media picked right before Android destroyed the app's
  /// activity (common on low-memory devices while the camera is open).
  ///
  /// Call it on startup, e.g. in `initState` of your first screen. Returns
  /// null when there is nothing to recover or on non-Android platforms.
  Future<PickResultMultiple?> recoverLostData({
    PickOptions options = const PickOptions(),
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    final LostDataResponse response;
    try {
      response = await _picker.retrieveLostData();
    } catch (e) {
      // Includes UnimplementedError from platforms without lost-data support.
      _log(options, 'Lost data retrieval failed', e);
      return null;
    }
    if (response.isEmpty) return null;
    if (response.exception != null) {
      _log(options, 'Recovered pick had failed', response.exception!);
      return PickResultMultiple(
        items: const [],
        permissionResolution: PermissionResolution.grantedFull(),
        error: PickError.io,
      );
    }
    final List<XFile> files =
        response.files ?? [if (response.file != null) response.file!];
    final List<PickedMedia> items = await Future.wait(files.map(_describe));
    return _multipleResult(items, PermissionResolution.grantedFull(), options);
  }

  /// Single-pick flow used by [pickImage], [pickVideo] and [pickMedia].
  ///
  /// Flow overview:
  /// - Optionally asks for the source via the source sheet
  /// - Requests appropriate permissions based on platform and [options]
  /// - If limited access is active (iOS), presents a bottom sheet letting
  ///   users pick from the allowed set
  /// - Otherwise calls `image_picker` directly (web and desktop are always
  ///   treated as full access; camera falls back to gallery there)
  /// - Validates the type, optionally crops images, then validates the size
  Future<PickResultSingle> _pickSingle(
    BuildContext context,
    PickOptions options,
    MediaType type,
    SourceSheetOptions? sourceSheet,
  ) async {
    final (ImageSource? requested, bool remove) = await _chooseSource(
      context,
      options,
      type,
      sourceSheet,
    );
    if (requested == null || !context.mounted) {
      return PickResultSingle(
        item: null,
        permissionResolution: PermissionResolution.grantedFull(),
        error: PickError.canceled,
        removeRequested: remove,
      );
    }
    final ImageSource source = _effectiveSource(requested);
    final PermissionResolution permission = await _ensurePermission(
      context,
      options,
      type,
      source,
    );
    if (!permission.granted) {
      // The permission flow already offered the rationale and, when the
      // permission is permanently denied, an "Open Settings" dialog.
      return PickResultSingle(
        item: null,
        permissionResolution: permission,
        error: PickError.permissionDenied,
      );
    }

    final PickedMedia media;
    if (permission.limited) {
      if (!context.mounted) {
        return PickResultSingle(item: null, permissionResolution: permission);
      }
      final selected = await LimitedAccessPicker.show(
        context: context,
        allowMultiple: false,
        mediaType: type,
        themeBrightness: options.themeBrightness,
        primaryColor: options.primaryColor,
        labels: options.labels,
      );
      if (selected == null || selected.isEmpty) {
        return PickResultSingle(
          item: null,
          permissionResolution: permission,
          error: PickError.canceled,
        );
      }
      final List<PickedMedia> picked = await _fromAssets(selected, options);
      if (picked.isEmpty) {
        return PickResultSingle(
          item: null,
          permissionResolution: permission,
          error: PickError.io,
        );
      }
      media = picked.first;
    } else {
      final XFile? file;
      try {
        file = switch (type) {
          MediaType.video => await _picker.pickVideo(
            source: source,
            preferredCameraDevice: options.preferredCameraDevice,
            maxDuration: options.maxVideoDuration,
          ),
          MediaType.any when source == ImageSource.gallery =>
            await _picker.pickMedia(
              imageQuality: options.imageQuality,
              maxWidth: options.maxWidth?.toDouble(),
              maxHeight: options.maxHeight?.toDouble(),
            ),
          _ => await _picker.pickImage(
            source: source,
            imageQuality: options.imageQuality,
            maxWidth: options.maxWidth?.toDouble(),
            maxHeight: options.maxHeight?.toDouble(),
            preferredCameraDevice: options.preferredCameraDevice,
          ),
        };
      } on Exception catch (e) {
        _log(options, 'Picking failed', e);
        return PickResultSingle(
          item: null,
          permissionResolution: permission,
          error: PickError.io,
        );
      }
      if (file == null) {
        return PickResultSingle(
          item: null,
          permissionResolution: permission,
          error: PickError.canceled,
        );
      }
      final bool image =
          type == MediaType.image ||
          (type == MediaType.any &&
              (_mimeOf(file)?.startsWith('image/') ?? false));
      media = await _describe(file, inspectImage: image);
    }

    final PickError? typeError = _checkType(media, options);
    if (typeError != null) {
      return PickResultSingle(
        item: null,
        permissionResolution: permission,
        error: typeError,
      );
    }
    if (type == MediaType.video || (type == MediaType.any && !media.isImage)) {
      return _singleResult(media, permission, options, const PickMetadata());
    }

    final Size? originalSize = _sizeOf(media);
    final PickMetadata uncropped = PickMetadata(
      cropApplied: false,
      originalSize: originalSize,
      finalSize: originalSize,
    );
    if (!options.wantToCrop || !context.mounted) {
      return _singleResult(media, permission, options, uncropped);
    }

    // The native cropper can't read the Flutter theme, so resolve it here.
    final ThemeData theme = Theme.of(context);
    final String? croppedPath = await PlatformImageCropper.cropImage(
      sourcePath: media.path,
      context: context,
      // Keep PNGs (and their transparency) as PNG.
      compressFormat: media.mimeType == 'image/png' ? 'png' : 'jpg',
      compressQuality: options.imageQuality ?? 100,
      themeBrightness: options.themeBrightness ?? theme.brightness,
      primaryColor: options.primaryColor ?? theme.colorScheme.primary,
      cropAspectRatio: options.cropAspectRatio,
      lockCropAspectRatio: options.lockCropAspectRatio,
      cropShape: options.cropShape,
      labels: options.labels,
    );
    if (croppedPath == null) {
      return _singleResult(
        media,
        permission,
        options,
        uncropped,
        error: PickError.cropCanceled,
      );
    }
    final PickedMedia cropped = await _describe(
      XFile(croppedPath),
      inspectImage: true,
    );
    return _singleResult(
      cropped,
      permission,
      options,
      PickMetadata(
        cropApplied: true,
        originalSize: originalSize,
        finalSize: _sizeOf(cropped),
      ),
    );
  }

  /// Multi-pick flow used by [pickMultiImage], [pickMultiVideo] and
  /// [pickMultipleMedia]. Enforces [PickOptions.maxImages] across platforms.
  Future<PickResultMultiple> _pickMultiple(
    BuildContext context,
    PickOptions options,
    MediaType type,
    SourceSheetOptions? sourceSheet,
  ) async {
    final (ImageSource? requested, bool remove) = await _chooseSource(
      context,
      options,
      type,
      sourceSheet,
    );
    if (requested == null || !context.mounted) {
      return PickResultMultiple(
        items: const [],
        permissionResolution: PermissionResolution.grantedFull(),
        error: PickError.canceled,
        removeRequested: remove,
      );
    }
    final ImageSource source = _effectiveSource(requested);
    final int? maxItems = (options.maxImages ?? 0) > 0
        ? options.maxImages
        : null;

    final PermissionResolution permission = await _ensurePermission(
      context,
      options,
      type,
      source,
    );
    if (!permission.granted) {
      // The permission flow already offered the rationale and, when the
      // permission is permanently denied, an "Open Settings" dialog.
      return PickResultMultiple(
        items: const [],
        permissionResolution: permission,
        error: PickError.permissionDenied,
      );
    }

    List<PickedMedia> items;
    if (permission.limited) {
      if (!context.mounted) {
        return PickResultMultiple(
          items: const [],
          permissionResolution: permission,
        );
      }
      final selected = await LimitedAccessPicker.show(
        context: context,
        allowMultiple: true,
        maxImages: maxItems,
        mediaType: type,
        themeBrightness: options.themeBrightness,
        primaryColor: options.primaryColor,
        labels: options.labels,
      );
      items = selected == null
          ? <PickedMedia>[]
          : await _fromAssets(selected, options);
    } else {
      try {
        final List<XFile> files;
        if (source == ImageSource.gallery) {
          files = switch (type) {
            MediaType.image => await _picker.pickMultiImage(
              imageQuality: options.imageQuality,
              maxWidth: options.maxWidth?.toDouble(),
              maxHeight: options.maxHeight?.toDouble(),
              limit: maxItems,
            ),
            // The multi-video picker rejects a limit of 1 on Android.
            MediaType.video when maxItems == 1 => [
              ?await _picker.pickVideo(
                source: source,
                maxDuration: options.maxVideoDuration,
              ),
            ],
            MediaType.video => await _picker.pickMultiVideo(
              maxDuration: options.maxVideoDuration,
              limit: maxItems,
            ),
            MediaType.any => await _picker.pickMultipleMedia(
              imageQuality: options.imageQuality,
              maxWidth: options.maxWidth?.toDouble(),
              maxHeight: options.maxHeight?.toDouble(),
              limit: maxItems,
            ),
          };
        } else {
          // The camera captures a single item.
          files = [
            ?type == MediaType.video
                ? await _picker.pickVideo(
                    source: source,
                    preferredCameraDevice: options.preferredCameraDevice,
                    maxDuration: options.maxVideoDuration,
                  )
                : await _picker.pickImage(
                    source: source,
                    imageQuality: options.imageQuality,
                    maxWidth: options.maxWidth?.toDouble(),
                    maxHeight: options.maxHeight?.toDouble(),
                    preferredCameraDevice: options.preferredCameraDevice,
                  ),
          ];
        }
        items = await Future.wait(files.map(_describe));
      } on Exception catch (e) {
        _log(options, 'Picking failed', e);
        return PickResultMultiple(
          items: const [],
          permissionResolution: permission,
          error: PickError.io,
        );
      }
    }

    if (maxItems != null && items.length > maxItems) {
      items = items.take(maxItems).toList();
    }
    return _multipleResult(items, permission, options);
  }

  /// Shows the source sheet when [sheet] is given. Returns the source to
  /// pick from, or a null source when the flow ends (with `remove` telling
  /// whether the user asked to remove the current media).
  Future<(ImageSource?, bool)> _chooseSource(
    BuildContext context,
    PickOptions options,
    MediaType type,
    SourceSheetOptions? sheet,
  ) async {
    if (sheet == null) return (options.source, false);
    final MediaSourceChoice? choice = await showMediaSourceSheet(
      context: context,
      mediaType: type,
      options: sheet,
      primaryColor: options.primaryColor,
    );
    return switch (choice) {
      MediaSourceChoice.camera => (ImageSource.camera, false),
      MediaSourceChoice.gallery => (ImageSource.gallery, false),
      MediaSourceChoice.remove => (null, true),
      null => (null, false),
    };
  }

  Future<PermissionResolution> _ensurePermission(
    BuildContext context,
    PickOptions options,
    MediaType type,
    ImageSource source,
  ) => _permissionManager.ensureMediaPermission(
    source: source,
    mediaType: type,
    context: context,
    dialogTitle: options.settingsDialogTitle,
    dialogMessage: options.settingsDialogMessage,
    settingsButtonLabel: options.settingsButtonLabel,
    cancelButtonLabel: options.cancelButtonLabel,
  );

  /// On web and desktop, camera capture is not supported: transparently
  /// fall back to the gallery.
  ImageSource _effectiveSource(ImageSource requested) {
    final bool isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    return (kIsWeb || isDesktop) && requested == ImageSource.camera
        ? ImageSource.gallery
        : requested;
  }

  /// Applies the size limit to a finished single pick.
  PickResultSingle _singleResult(
    PickedMedia media,
    PermissionResolution permission,
    PickOptions options,
    PickMetadata metadata, {
    PickError? error,
  }) {
    final PickError? sizeError = _checkSize(media, options);
    return PickResultSingle(
      item: sizeError == null ? media : null,
      permissionResolution: permission,
      metadata: metadata,
      error: sizeError ?? error,
    );
  }

  /// Validates every item of a multi pick, moving failures to `rejected`.
  PickResultMultiple _multipleResult(
    List<PickedMedia> items,
    PermissionResolution permission,
    PickOptions options,
  ) {
    final List<PickedMedia> accepted = [];
    final List<RejectedMedia> rejected = [];
    for (final PickedMedia item in items) {
      final PickError? error =
          _checkType(item, options) ?? _checkSize(item, options);
      error == null
          ? accepted.add(item)
          : rejected.add(RejectedMedia(item, error));
    }
    return PickResultMultiple(
      items: accepted,
      permissionResolution: permission,
      rejected: rejected,
      error: accepted.isNotEmpty
          ? null
          : rejected.isNotEmpty
          ? rejected.first.reason
          : PickError.canceled,
    );
  }

  PickError? _checkType(PickedMedia media, PickOptions options) {
    final List<String>? allowed = options.allowedMimeTypes;
    final String? mime = media.mimeType;
    if (allowed == null || allowed.isEmpty || mime == null) return null;
    return allowed.any((pattern) => mimeTypeMatches(pattern, mime))
        ? null
        : PickError.unsupportedType;
  }

  PickError? _checkSize(PickedMedia media, PickOptions options) {
    final int? max = options.maxFileSizeBytes;
    final int? size = media.sizeInBytes;
    return max != null && size != null && size > max
        ? PickError.fileTooLarge
        : null;
  }

  /// Converts limited-access assets into [PickedMedia], dropping any whose
  /// file can't be resolved.
  ///
  /// Typed as `List<dynamic>` because naming `photo_manager`'s `AssetEntity`
  /// here would pull `dart:io` into web/WASM builds.
  Future<List<PickedMedia>> _fromAssets(
    List<dynamic> assets,
    PickOptions options,
  ) async {
    final items = await Future.wait(
      assets.map((dynamic asset) async {
        try {
          final dynamic file = await asset.file;
          if (file == null) return null;
          final String path = file.path as String;
          return PickedMedia(
            path: path,
            mimeType: (asset.mimeType as String?) ?? mimeTypeFromPath(path),
            width: asset.width as int?,
            height: asset.height as int?,
            name: _baseName(path),
            sizeInBytes: await file.length() as int,
          );
        } catch (e) {
          _log(options, 'Could not resolve selected asset', e);
          return null;
        }
      }),
    );
    return items.whereType<PickedMedia>().toList();
  }

  /// Builds a [PickedMedia] for [file]. With [inspectImage], also decodes
  /// the image for its pixel size (and sniffs its type if unknown).
  Future<PickedMedia> _describe(XFile file, {bool inspectImage = false}) async {
    String? mime = _mimeOf(file);
    int? length;
    try {
      length = await file.length();
    } catch (_) {}
    Size? size;
    if (inspectImage) {
      try {
        final Uint8List bytes = await file.readAsBytes();
        mime ??= mimeTypeFromBytes(bytes);
        length ??= bytes.length;
        size = await _decodeSize(bytes);
      } catch (_) {}
    }
    return PickedMedia(
      path: file.path,
      mimeType: mime,
      width: size?.width.toInt(),
      height: size?.height.toInt(),
      name: _baseName(file.name),
      sizeInBytes: length,
    );
  }

  /// Last path segment of [path] (either separator), or null if empty.
  String? _baseName(String path) {
    final String name = path.split(RegExp(r'[/\\]')).last;
    return name.isEmpty ? null : name;
  }

  Size? _sizeOf(PickedMedia media) =>
      media.width == null || media.height == null
      ? null
      : Size(media.width!.toDouble(), media.height!.toDouble());

  String? _mimeOf(XFile file) => file.mimeType ?? mimeTypeFromPath(file.path);

  Future<Size?> _decodeSize(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  void _log(PickOptions options, String message, Object error) {
    final String tag = options.logTag == null ? '' : ' ${options.logTag}';
    debugPrint('[AdaptiveMediaPicker$tag] $message: $error');
  }
}
