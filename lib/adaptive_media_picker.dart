/// Adaptive Media Picker
///
/// A cross-platform media picker for Flutter apps with smart permission handling
/// and built-in limited-access UI (powered by `photo_manager`).
///
/// Import this library to:
/// - Pick single/multiple images or a single video.
/// - Handle Android/iOS permission states gracefully.
/// - Use `ImageSource` convenience constants.
/// - Show the limited-access bottom sheet for restricted gallery access.
///
/// Example:
/// ```dart
/// final picker = AdaptiveMediaPicker();
/// final files = await picker.pickImages();
/// ```
export 'src/core/models.dart';
export 'src/adaptive_media_picker_impl.dart' show AdaptiveMediaPicker;
export 'package:image_picker/image_picker.dart' show ImageSource;

// Conditional exports for platform-specific code
export 'src/stub/permission_manager_stub.dart'
    if (dart.library.io) 'src/platform/permission_manager.dart';

export 'src/stub/limited_access_picker_stub.dart'
    if (dart.library.io) 'src/ui/limited_access_picker.dart';
