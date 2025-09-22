import 'package:image_picker/image_picker.dart';

/// Kind of media to pick.
///
/// - [image]: Pick still images (JPEG/PNG/HEIC, etc.)
/// - [video]: Pick a single video file
/// Target media type to pick.
///
/// - **image**: still images (e.g., JPG/PNG/HEIC)
/// - **video**: single video file
enum MediaType { image, video }

/// Configuration options for a pick operation (method-specific defaults apply).
///
/// - [maxImages] limits the number of images in multi-pick. Applies to images only.
/// - [imageQuality], [maxWidth], [maxHeight] are forwarded to `image_picker` when
///   picking images with full access.
/// - [source] chooses camera or gallery. On platforms where camera capture is
///   not supported (web and desktop), `ImageSource.camera` is automatically
///   treated as `ImageSource.gallery`.
/// - The "Open Settings" dialog can be configured for permanently denied cases
///   using the [showOpenSettingsDialog] flags and labels.
///
/// Note:
/// - Use `pickImage` for a single image.
/// - Use `pickVideo` for a single video (multi-select is not supported by native APIs).
/// - Use `pickMultiImage` for multiple images; [maxImages] constrains the count.
///   The limit is enforced cross-platform even if the underlying platform allows
///   selecting more.
/// Options that configure a pick operation.
class PickOptions {
  /// Max number of images to return when using `pickMultiImage`.
  ///
  /// This applies to images only and is ignored by `pickImage`/`pickVideo`.
  final int? maxImages;

  /// JPEG compression quality forwarded to `image_picker` (0-100).
  final int? imageQuality;

  /// Maximum width forwarded to `image_picker` for image scenarios.
  final int? maxWidth;

  /// Maximum height forwarded to `image_picker` for image scenarios.
  final int? maxHeight;

  /// Camera or gallery source.
  ///
  /// Note: On web and desktop (Windows, macOS, Linux), camera capture is not
  /// available in this package. If `ImageSource.camera` is specified, the
  /// picker will transparently fall back to `ImageSource.gallery`.
  final ImageSource source;

  /// When permission is permanently denied, show a dialog guiding users
  /// to open OS settings.
  final bool showOpenSettingsDialog;

  /// Dialog title for "Open Settings" prompt.
  final String? settingsDialogTitle;

  /// Dialog message for "Open Settings" prompt.
  final String? settingsDialogMessage;

  /// Primary action label for "Open Settings".
  final String? settingsButtonLabel;

  /// Cancel action label for "Open Settings".
  final String? cancelButtonLabel;

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
  });
}

/// A single piece of picked media (image or video).
/// A single piece of picked media (image or video).
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

/// Result for single-pick flows (image or video). [item] is null if nothing selected.
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

/// Result for multi-image flows. [items] may be empty if nothing selected.
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

/// Describes the final permission state after a prompt/handling.
/// Permission outcome after attempting to acquire access.
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
