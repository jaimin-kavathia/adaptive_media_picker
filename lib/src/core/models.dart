import 'dart:typed_data';
import 'dart:ui' show Size, Color, Brightness;
import 'package:image_picker/image_picker.dart';

/// Core models used by AdaptiveMediaPicker.
///
/// Includes pick options, media types, picked items, and permission resolution.

/// Media type requested for a pick operation.
enum MediaType {
  /// Still images.
  image,

  /// Videos.
  video,

  /// Images and videos (used by `pickMedia` / `pickMultipleMedia`).
  any,
}

/// Shape of the crop area when [PickOptions.wantToCrop] is true.
enum CropShape {
  /// Rectangular crop box (default).
  rectangle,

  /// Circular crop UI, e.g. for avatars. Implies a locked 1:1 ratio.
  ///
  /// Android/iOS return the square image behind the circle; Web and
  /// desktop return a PNG with transparent corners.
  circle,
}

/// Text used by the package's built-in UI (crop editor, limited-access
/// sheet, native cropper toolbar). Override to translate or rephrase.
///
/// Source sheet labels live in [SourceSheetOptions]; permission dialog
/// texts in the `settingsDialog*` fields of [PickOptions].
class PickerLabels {
  /// Title of the crop screen / native cropper toolbar.
  final String cropTitle;

  /// Chip label for the free-form ratio in the built-in crop editor.
  final String cropFreeRatio;

  /// Shown when the built-in crop editor fails to crop.
  final String cropFailed;

  /// Limited-access sheet title when picking images.
  final String selectImagesTitle;

  /// Limited-access sheet title when picking videos.
  final String selectVideosTitle;

  /// Limited-access sheet title when picking images and videos.
  final String selectMediaTitle;

  /// Confirm button of the multi-select limited-access sheet.
  final String done;

  /// Shown when the limited-access sheet has nothing to show.
  final String nothingAvailable;

  /// Dialog title when the user shared no matching items with the app.
  final String limitedEmptyTitle;

  /// Dialog message when the user shared no matching items with the app.
  final String limitedEmptyMessage;

  /// Opens the system "select more photos" sheet (iOS).
  final String manageSelection;

  /// Opens the app's system settings.
  final String openSettings;

  /// Generic cancel label.
  final String cancel;

  /// Creates labels; every field has an English default.
  const PickerLabels({
    this.cropTitle = 'Crop',
    this.cropFreeRatio = 'Free',
    this.cropFailed = 'Could not crop this image.',
    this.selectImagesTitle = 'Select images',
    this.selectVideosTitle = 'Select videos',
    this.selectMediaTitle = 'Select media',
    this.done = 'Done',
    this.nothingAvailable = 'Nothing to show.',
    this.limitedEmptyTitle = 'Nothing shared yet',
    this.limitedEmptyMessage =
        'This app can only see the photos you chose to share. Select more '
        'items, or allow access to all photos in Settings.',
    this.manageSelection = 'Select more',
    this.openSettings = 'Open Settings',
    this.cancel = 'Cancel',
  });
}

/// Preset aspect ratios usable as the cropper's default via
/// [PickOptions.cropAspectRatio].
enum CropAspectRatioOption {
  /// Free-form, based on the original image's own ratio.
  original,

  /// 1:1
  square,

  /// 3:2
  ratio3x2,

  /// 4:3
  ratio4x3,

  /// 5:4
  ratio5x4,

  /// 7:5
  ratio7x5,

  /// 16:9
  ratio16x9,
}

/// What the user chose in the camera/gallery source sheet.
enum MediaSourceChoice {
  /// Capture with the camera.
  camera,

  /// Pick from the gallery / file system.
  gallery,

  /// Remove the current media (only offered when
  /// [SourceSheetOptions.removeLabel] is set).
  remove,
}

/// Visual style of the source sheet.
enum SourceSheetStyle {
  /// Cupertino action sheet on iOS/macOS, Material bottom sheet elsewhere.
  adaptive,

  /// Always a Material bottom sheet.
  material,

  /// Always a Cupertino action sheet.
  cupertino,
}

/// Configures the "Take photo / Choose from gallery" source sheet.
///
/// Pass it as `sourceSheet:` to `pickImage`, `pickVideo` or `pickMultiImage`
/// to let the user choose the source (overriding [PickOptions.source]), or
/// call `AdaptiveMediaPicker.showSourceSheet` directly.
///
/// The camera option is only offered where camera capture is supported
/// (Android and iOS). When the only remaining option would be the gallery,
/// the sheet is skipped and the gallery opens directly.
class SourceSheetOptions {
  /// Optional title shown at the top of the sheet.
  final String? title;

  /// Optional message shown under [title].
  final String? message;

  /// Label of the camera option. Defaults to "Take photo" for images and
  /// "Record video" for videos.
  final String? cameraLabel;

  /// Label of the gallery option. Defaults to "Choose from gallery".
  final String? galleryLabel;

  /// When non-null, adds a destructive option with this label (e.g.
  /// "Remove photo"). Choosing it yields [MediaSourceChoice.remove]; pick
  /// methods then return `removeRequested: true`.
  final String? removeLabel;

  /// Label of the cancel button (Cupertino style only). Defaults to the
  /// localized Material "Cancel".
  final String? cancelLabel;

  /// Visual style; [SourceSheetStyle.adaptive] by default.
  final SourceSheetStyle style;

  /// Creates source sheet options.
  const SourceSheetOptions({
    this.title,
    this.message,
    this.cameraLabel,
    this.galleryLabel,
    this.removeLabel,
    this.cancelLabel,
    this.style = SourceSheetStyle.adaptive,
  });
}

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
  /// Maximum number of items to return for multi picks (`pickMultiImage`,
  /// `pickMultiVideo`, `pickMultipleMedia`). Ignored by single picks.
  final int? maxImages;

  /// JPEG compression quality (0-100) used for images when supported.
  ///
  /// Also used as the native cropper's output quality.
  final int? imageQuality;

  /// Resize width for images when supported.
  final int? maxWidth;

  /// Resize height for images when supported.
  final int? maxHeight;

  /// Camera or gallery source. On web/desktop, camera falls back to gallery.
  final ImageSource source;

  /// Camera to open for camera picks (e.g. [CameraDevice.front] for
  /// selfies). Not every device honors it.
  final CameraDevice preferredCameraDevice;

  /// Maximum length of recorded videos (camera) or picked videos where the
  /// platform supports it.
  final Duration? maxVideoDuration;

  /// Reject files larger than this (checked on the final file, i.e. after
  /// cropping). Rejected picks return [PickError.fileTooLarge].
  final int? maxFileSizeBytes;

  /// Accepted MIME types, e.g. `['image/jpeg', 'image/png']` or
  /// `['image/*']`. Others return [PickError.unsupportedType]. Files whose
  /// type can't be determined are accepted.
  final List<String>? allowedMimeTypes;

  /// Formerly toggled the package's own "Open Settings" dialog.
  ///
  /// The permission library (`smart_permission`) now handles the
  /// permanently-denied flow itself (dialog, opening Settings, waiting for
  /// the user to return, and re-checking), so this flag is no longer read.
  @Deprecated(
    'The settings dialog is now handled by the permission flow '
    'itself; customize it via the settingsDialog* fields instead.',
  )
  final bool showOpenSettingsDialog;

  /// Title for the permission dialogs (rationale and "Open Settings").
  final String? settingsDialogTitle;

  /// Message for the permission dialogs (rationale and "Open Settings").
  final String? settingsDialogMessage;

  /// Label of the "Open Settings" button in the permission dialogs.
  final String? settingsButtonLabel;

  /// Label of the cancel/deny button in the permission dialogs.
  final String? cancelButtonLabel;

  /// If true and picking a single image, opens a crop editor after
  /// selection.
  ///
  /// Platform support: all platforms. Android and iOS use the native
  /// `image_cropper` UI; Web and desktop use a built-in Flutter editor.
  /// If the user cancels cropping, the uncropped image is returned with
  /// [PickError.cropCanceled].
  ///
  /// Ignored for videos.
  final bool wantToCrop;

  /// Default aspect ratio the cropper opens with when [wantToCrop] is true.
  ///
  /// If null, Android opens with [CropAspectRatioOption.square] (adjustable)
  /// and iOS/Web open free-form, matching prior default behavior.
  ///
  /// Platform support: honored as the initial ratio on Android, Web and
  /// desktop; on iOS it only takes effect when combined with
  /// [lockCropAspectRatio] (see native `image_cropper` behavior).
  final CropAspectRatioOption? cropAspectRatio;

  /// When true, locks the crop box to [cropAspectRatio] so users can't
  /// change it. Has no effect if [cropAspectRatio] is null.
  ///
  /// Platform support: all platforms.
  final bool lockCropAspectRatio;

  /// Shape of the crop area; [CropShape.circle] forces a locked 1:1 ratio.
  final CropShape cropShape;

  /// Text for the package's built-in UI.
  final PickerLabels labels;

  /// Optional tag included in debug logs (e.g. when a pick fails with
  /// [PickError.io]) to help trace flows.
  final String? logTag;

  /// Optional override for UI brightness used by the package-provided
  /// limited-access sheet and the cropper toolbars (when supported).
  ///
  /// If null, the app's current theme brightness is used.
  final Brightness? themeBrightness;

  /// Optional primary color override used by the package-provided
  /// limited-access sheet accents and cropper toolbar color.
  ///
  /// If null, `Theme.of(context).colorScheme.primary` is used.
  final Color? primaryColor;

  /// Create a set of options for a pick operation.
  const PickOptions({
    this.maxImages,
    this.imageQuality,
    this.maxWidth,
    this.maxHeight,
    this.source = ImageSource.gallery,
    this.preferredCameraDevice = CameraDevice.rear,
    this.maxVideoDuration,
    this.maxFileSizeBytes,
    this.allowedMimeTypes,
    this.showOpenSettingsDialog = true,
    this.settingsDialogTitle,
    this.settingsDialogMessage,
    this.settingsButtonLabel,
    this.cancelButtonLabel,
    this.wantToCrop = false,
    this.cropAspectRatio,
    this.lockCropAspectRatio = false,
    this.cropShape = CropShape.rectangle,
    this.labels = const PickerLabels(),
    this.logTag,
    this.themeBrightness,
    this.primaryColor,
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

  /// File name (with extension) when known. On Web, [path] is a blob URL,
  /// so use this for display or uploads.
  final String? name;

  /// File size in bytes when known.
  final int? sizeInBytes;

  /// Creates a picked media item.
  const PickedMedia({
    required this.path,
    this.mimeType,
    this.width,
    this.height,
    this.name,
    this.sizeInBytes,
  });

  /// True when [mimeType] is an image type.
  bool get isImage => mimeType?.startsWith('image/') ?? false;

  /// True when [mimeType] is a video type.
  bool get isVideo => mimeType?.startsWith('video/') ?? false;

  /// Reads the file's bytes. Works on every platform, including Web where
  /// [path] is a blob URL (e.g. for `Image.memory` or uploads).
  Future<Uint8List> readAsBytes() => XFile(path).readAsBytes();

  @override
  String toString() =>
      'PickedMedia(path: $path, mimeType: $mimeType, '
      'size: ${width}x$height, bytes: $sizeInBytes)';
}

/// Result for single-pick flows (image or video). [item] is null if none.
class PickResultSingle {
  /// The picked item, or null when nothing was picked (see [error]).
  final PickedMedia? item;

  /// Permission state after the pick flow.
  final PermissionResolution permissionResolution;

  /// Optional metadata describing how the item was produced (e.g., crop info).
  final PickMetadata metadata;

  /// Optional typed error indicating why the result is empty or special.
  final PickError? error;

  /// True when the user chose the "remove" option of the source sheet.
  /// [error] is then [PickError.canceled], so code that ignores this flag
  /// treats it as a cancel.
  final bool removeRequested;

  /// Creates a single-pick result.
  const PickResultSingle({
    required this.item,
    required this.permissionResolution,
    this.metadata = const PickMetadata(),
    this.error,
    this.removeRequested = false,
  });

  /// True when no item was selected.
  bool get isEmpty => item == null;
}

/// Metadata attached to a single pick result.
///
/// Useful for debugging and post-processing pipelines.
class PickMetadata {
  /// True if a crop step was applied.
  final bool cropApplied;

  /// Size of the original image when known.
  final Size? originalSize;

  /// Size of the final image after transformations when known.
  final Size? finalSize;

  /// Creates pick metadata.
  const PickMetadata({
    this.cropApplied = false,
    this.originalSize,
    this.finalSize,
  });
}

/// Typed error for pick flows to disambiguate empty results.
enum PickError {
  /// User canceled the selection flow.
  canceled,

  /// User canceled the crop operation.
  cropCanceled,

  /// Permission was denied (see [PermissionResolution] for details).
  permissionDenied,

  /// I/O or platform failure.
  io,

  /// The file exceeds [PickOptions.maxFileSizeBytes].
  fileTooLarge,

  /// The file's type isn't in [PickOptions.allowedMimeTypes].
  unsupportedType,

  /// Unknown reason.
  unknown,
}

/// A picked item that failed validation in a multi pick.
class RejectedMedia {
  /// The rejected item.
  final PickedMedia media;

  /// Why it was rejected ([PickError.fileTooLarge] or
  /// [PickError.unsupportedType]).
  final PickError reason;

  /// Creates a rejected-media record.
  const RejectedMedia(this.media, this.reason);
}

/// Result for multi-item flows. [items] may be empty.
class PickResultMultiple {
  /// The picked items; empty when nothing was picked (see [error]).
  final List<PickedMedia> items;

  /// Permission state after the pick flow.
  final PermissionResolution permissionResolution;

  /// Optional typed error indicating why the result is empty or special.
  final PickError? error;

  /// True when the user chose the "remove" option of the source sheet.
  /// [error] is then [PickError.canceled].
  final bool removeRequested;

  /// Items dropped by [PickOptions.maxFileSizeBytes] /
  /// [PickOptions.allowedMimeTypes] validation. When every item was
  /// rejected, [error] is the first rejection's reason.
  final List<RejectedMedia> rejected;

  /// Creates a multi-pick result.
  const PickResultMultiple({
    required this.items,
    required this.permissionResolution,
    this.error,
    this.removeRequested = false,
    this.rejected = const [],
  });

  /// True when no items were selected.
  bool get isEmpty => items.isEmpty;
}

/// Final permission state after a prompt/handling.
class PermissionResolution {
  /// True if access is granted in any form.
  final bool granted;

  /// True if access is limited (iOS "Selected Photos").
  final bool limited;

  /// True if permanently denied (user must change settings).
  final bool permanentlyDenied;

  /// Creates a permission resolution.
  const PermissionResolution({
    required this.granted,
    required this.limited,
    required this.permanentlyDenied,
  });

  /// Access denied, optionally [permanentlyDenied].
  factory PermissionResolution.denied({bool permanentlyDenied = false}) =>
      PermissionResolution(
        granted: false,
        limited: false,
        permanentlyDenied: permanentlyDenied,
      );

  /// Full access granted.
  factory PermissionResolution.grantedFull() => const PermissionResolution(
    granted: true,
    limited: false,
    permanentlyDenied: false,
  );

  /// Limited (user-selected items only) access granted.
  factory PermissionResolution.grantedLimited() => const PermissionResolution(
    granted: true,
    limited: true,
    permanentlyDenied: false,
  );
}
