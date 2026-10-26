import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/models.dart';

/// Whether the package offers camera capture on this platform (it falls back
/// to the gallery on Web and desktop).
bool get cameraCaptureSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Shows the camera/gallery source sheet and resolves with the user's
/// choice, or null if it is dismissed.
///
/// Skips the sheet and resolves with [MediaSourceChoice.gallery] when the
/// gallery would be the only option. [cameraAvailable] overrides platform
/// detection (for tests).
Future<MediaSourceChoice?> showMediaSourceSheet({
  required BuildContext context,
  required MediaType mediaType,
  SourceSheetOptions options = const SourceSheetOptions(),
  Color? primaryColor,
  bool? cameraAvailable,
}) async {
  final bool camera = cameraAvailable ?? cameraCaptureSupported;
  if (!camera && options.removeLabel == null) {
    return MediaSourceChoice.gallery;
  }

  final bool isVideo = mediaType == MediaType.video;
  final String cameraLabel =
      options.cameraLabel ?? (isVideo ? 'Record video' : 'Take photo');
  final String galleryLabel = options.galleryLabel ?? 'Choose from gallery';
  final bool cupertino = switch (options.style) {
    SourceSheetStyle.material => false,
    SourceSheetStyle.cupertino => true,
    SourceSheetStyle.adaptive =>
      defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS,
  };

  if (cupertino) {
    final String cancelLabel =
        options.cancelLabel ??
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.cancelButtonLabel ??
        'Cancel';
    return showCupertinoModalPopup<MediaSourceChoice>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: options.title == null ? null : Text(options.title!),
        message: options.message == null ? null : Text(options.message!),
        actions: [
          if (camera)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(MediaSourceChoice.camera),
              child: Text(cameraLabel),
            ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(MediaSourceChoice.gallery),
            child: Text(galleryLabel),
          ),
          if (options.removeLabel != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop(MediaSourceChoice.remove),
              child: Text(options.removeLabel!),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(cancelLabel),
        ),
      ),
    );
  }

  return showModalBottomSheet<MediaSourceChoice>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final ThemeData theme = Theme.of(ctx);
      final Color accent = primaryColor ?? theme.colorScheme.primary;
      final Color danger = theme.colorScheme.error;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (options.title != null || options.message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (options.title != null)
                      Text(options.title!, style: theme.textTheme.titleMedium),
                    if (options.message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          options.message!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (camera)
              ListTile(
                leading: Icon(
                  isVideo
                      ? Icons.videocam_outlined
                      : Icons.photo_camera_outlined,
                  color: accent,
                ),
                title: Text(cameraLabel),
                onTap: () => Navigator.of(ctx).pop(MediaSourceChoice.camera),
              ),
            ListTile(
              leading: Icon(
                isVideo
                    ? Icons.video_library_outlined
                    : Icons.photo_library_outlined,
                color: accent,
              ),
              title: Text(galleryLabel),
              onTap: () => Navigator.of(ctx).pop(MediaSourceChoice.gallery),
            ),
            if (options.removeLabel != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: danger),
                title: Text(
                  options.removeLabel!,
                  style: TextStyle(color: danger),
                ),
                onTap: () => Navigator.of(ctx).pop(MediaSourceChoice.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
