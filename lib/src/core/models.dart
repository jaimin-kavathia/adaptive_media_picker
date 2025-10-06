import 'package:image_picker/image_picker.dart';

/// Core models used by AdaptiveMediaPicker.
///
/// Includes pick options, media types, picked items, and permission resolution.

/// Media type requested for a pick operation.
enum MediaType { image, video }

/// Options that configure a pick operation (method-specific defaults apply).
///
/// Use cases:
/// - Call `pickImage` for a single image. Cropping can be enabled via [wantToCrop].
/// - Call `pickVideo` for a single video. Cropping is ignored for videos.
/// - Call `pickMultiImage` for multiple images and optionally cap the count via [maxImages].
///
/// Notes:
/// - [maxImages] limits multi-image picks (images only).
/// - [imageQuality], [maxWidth], [maxHeight] are forwarded to `image_picker` when supported.
/// - [source] chooses camera or gallery. On web/desktop, camera transparently falls back to gallery.
/// - Settings dialog text can be customized via the provided fields.
class PickOptions {
  /// Maximum number of images to return for multi-image picks.
  /// Ignored by `pickImage`/`pickVideo`.
  final int? maxImages;

  /// JPEG compression quality (0-100) used for images when supported.
  final int? imageQuality;

  /// Resize width for images when supported.
  final int? maxWidth;

  /// Resize height for images when supported.
  final int? maxHeight;

  /// Camera or gallery source. On web/desktop, camera falls back to gallery.
  final ImageSource source;

  /// Whether to show an "Open Settings" dialog when permission is permanently denied.
  final bool showOpenSettingsDialog;

  /// Title for the settings dialog.
  final String? settingsDialogTitle;

  /// Message for the settings dialog.
  final String? settingsDialogMessage;

  /// Primary button label for the settings dialog.
  final String? settingsButtonLabel;

  /// Cancel button label for the settings dialog.
  final String? cancelButtonLabel;

  /// If true and picking a single image, opens the platform cropper UI after
  /// selection.
  ///
  /// Platform support: Android, iOS, and Web. On desktop platforms, cropping
  /// is a no-op and the original image path is returned.
  ///
  /// Ignored for videos.
  final bool wantToCrop;

  /// Create a set of options for a pick operation.
  const PickOptions({
    this.maxImages,
    this.imageQuality,
    this.maxWidth,
    this.maxHeight,
    this.source = ImageSource.gallery,
    this.showOpenSettingsDialog = true,
    this.settingsDialogTitle,
    this.settingsDialogMessage,
    this.settingsButtonLabel,
    this.cancelButtonLabel,
    this.wantToCrop = false,
  });
}

/// A single picked media item (image or video).
class PickedMedia {
  /// Local file path (temporary or persistent) to the media.
  final String path;

  /// Optional MIME type if available.
  final String? mimeType;

  /// Pixel width for images when known.
  final int? width;

  /// Pixel height for images when known.
  final int? height;

  const PickedMedia({
    required this.path,
    this.mimeType,
    this.width,
    this.height,
  });
}

/// Result for single-pick flows (image or video). [item] is null if none.
class PickResultSingle {
  final PickedMedia? item;
  final PermissionResolution permissionResolution;
  const PickResultSingle({
    required this.item,
    required this.permissionResolution,
  });

  /// True when no item was selected.
  bool get isEmpty => item == null;
}

/// Result for multi-image flows. [items] may be empty.
class PickResultMultiple {
  final List<PickedMedia> items;
  final PermissionResolution permissionResolution;
  const PickResultMultiple({
    required this.items,
    required this.permissionResolution,
  });

  /// True when no items were selected.
  bool get isEmpty => items.isEmpty;
}

/// Final permission state after a prompt/handling.
class PermissionResolution {
  /// True if access is granted in any form.
  final bool granted;

  /// True if access is limited (iOS/Android 14+ selected photos).
  final bool limited;

  /// True if permanently denied (user must change settings).
  final bool permanentlyDenied;

  const PermissionResolution({
    required this.granted,
    required this.limited,
    required this.permanentlyDenied,
  });

  factory PermissionResolution.denied({bool permanentlyDenied = false}) =>
      PermissionResolution(
        granted: false,
        limited: false,
        permanentlyDenied: permanentlyDenied,
      );

  factory PermissionResolution.grantedFull() => const PermissionResolution(
    granted: true,
    limited: false,
    permanentlyDenied: false,
  );

  factory PermissionResolution.grantedLimited() => const PermissionResolution(
    granted: true,
    limited: true,
    permanentlyDenied: false,
  );
}
