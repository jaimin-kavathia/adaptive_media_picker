/// A cross-platform, permission-aware media picker for Flutter.
///
/// - Pick single/multiple images or a single video with one API.
/// - Handles camera/Photos permissions, including iOS limited access
///   (built-in selection sheet) and permanently-denied states.
/// - Optional cropping on every platform: native on Android/iOS, a built-in
///   Flutter editor on Web and desktop.
/// - Android gallery picks use the system photo picker, so no
///   `READ_MEDIA_*` permission is needed.
///
/// ```dart
/// final picker = AdaptiveMediaPicker();
/// final result = await picker.pickImage(context: context);
/// if (result.item != null) print(result.item!.path);
/// ```
library;

export 'src/core/models.dart';
export 'src/adaptive_media_picker_impl.dart' show AdaptiveMediaPicker;
export 'package:image_picker/image_picker.dart' show ImageSource, CameraDevice;

// Conditional exports for platform-specific code
export 'src/stub/permission_manager_stub.dart'
    if (dart.library.io) 'src/platform/permission_manager.dart';

export 'src/stub/limited_access_picker_stub.dart'
    if (dart.library.io) 'src/ui/limited_access_picker.dart';
