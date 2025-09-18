# adaptive_media_picker

Adaptive media picking for Flutter with smart permission handling and limited-access UI for iOS/macOS and modern Android.

## What this package does

- Picks images (single/multiple) and videos (single) across platforms
- Handles permissions automatically per platform and API level
- Detects limited access (iOS and Android 14+) and presents a built-in grid UI to select from allowed items
- Prompts to manage limited selection or open settings when nothing is shared yet

> Platform support note: Camera capture is not supported on web or desktop (Windows, macOS, Linux). On these platforms only gallery/file picking is available.

## Quick start

```dart
final picker = AdaptiveMediaPicker();
final result = await picker.pickImage(
  context: context,
  options: const PickOptions(
    mediaType: MediaType.image,
    allowMultiple: true,
    maxImages: 5,
    source: ImageSource.gallery,
    imageQuality: 80,
  ),
);
```

## Use cases

- Pick single image (gallery or camera)
- Pick multiple images (gallery only)
- Pick single video (gallery or camera)

### Quick scenarios

```dart
final picker = AdaptiveMediaPicker();

// 1) Single image from gallery
final singleImage = await picker.pickImage(
  context: context,
  options: const PickOptions(mediaType: MediaType.image, source: ImageSource.gallery),
);

// 2) Multiple images (max 5) from gallery
final multipleImages = await picker.pickImage(
  context: context,
  options: const PickOptions(allowMultiple: true, maxImages: 5),
);

// 3) Single video from gallery
final singleVideo = await picker.pickImage(
  context: context,
  options: const PickOptions(mediaType: MediaType.video, source: ImageSource.gallery),
);

// 4) Camera request (falls back to gallery on web/desktop)
final cameraAttempt = await picker.pickImage(
  context: context,
  options: const PickOptions(mediaType: MediaType.image, source: ImageSource.camera),
);
```

> Note: Multiple video selection is not supported yet.

## Limited access UX

When the OS is in limited mode and no items are currently shared:

- A dialog appears offering:
  - Manage Selection (iOS only; macOS opens settings)
  - Open Settings
- After adjustment, the grid reloads with available items.

## Desktop (Windows, macOS, Linux)

- Uses `file_selector` under the hood via `image_picker`.
- No runtime permission prompts are shown; access is granted by the OS file dialog.
- Camera capture is not supported on desktop; only gallery/file picking is available.
- macOS requires:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

## Web

- Camera capture is not supported on web.
- Image and video selection works via the browser file picker when using `ImageSource.gallery`.

## Android setup

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## iOS setup

- Info.plist keys:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to pick images.</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access when recording videos.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app may save images/videos to your photo library.</string>
```

- Podfile macros: enable only the permissions you use (see permission_handler docs).

## API overview

- `PickOptions` config:
  - `mediaType`, `allowMultiple`, `maxImages`, `imageQuality`, `maxWidth`, `maxHeight`, `source`
  - Settings dialog: `showOpenSettingsDialog`, `settingsDialogTitle|Message|ButtonLabel|cancelButtonLabel`
- `PickResult`: `items` + `permissionResolution` (granted/limited/permanentlyDenied)
- `AdaptiveMediaPicker.pickImage`: main entry point

## Behavior matrix

- Full access → `image_picker` is used directly
- Limited access → built-in grid UI (images/videos)
- Denied → optional Open Settings dialog

## Acknowledgments

- device_info_plus, flutter_screenutil, image_picker, permission_handler, photo_manager

## License

See `LICENSE`.

## Android configuration

- Use recent toolchain versions:
  - Gradle wrapper 7.5.1+ (example uses 8.x)
  - Kotlin 1.7.22+ (example uses 2.x)
  - Android Gradle Plugin 7.2.2+ (managed by Flutter tooling)
- Android 10 (API 29) scoped storage:
  - Avoid `android:requestLegacyExternalStorage="true"` as Play may reject it.
  - If you target 29 and rely on file paths, consider caching via `PhotoManager.clearFileCache()` at startup.
- Glide:
  - `photo_manager` uses Glide for thumbnails. If you see Glide warnings, add an `AppGlideModule` per Glide docs in your Android app.
