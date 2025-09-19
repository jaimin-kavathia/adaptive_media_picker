# adaptive_media_picker

Adaptive media picking for Flutter with smart permission handling and limited-access UI for iOS/macOS and modern Android.

## Features

- Single image, single video, and multiple images (with max limit)
- Automatic permission handling (Android/iOS) with limited access flow
- Built-in limited-access bottom sheet using `photo_manager`
- Sensible fallbacks (camera → gallery on desktop/web)
- Web-compatible (no dart:io in library code)

> Note: Camera capture is not supported on web or desktop (Windows, macOS, Linux). On these platforms only gallery/file picking is available.

## Quick start

```dart
final picker = AdaptiveMediaPicker();

// Single image
final singleImage = await picker.pickImage(
  context: context,
  options: const PickOptions(
    source: ImageSource.gallery,
    imageQuality: 80,
  ),
);
if (singleImage.item != null) {
  // use singleImage.item
}

// Multiple images (max 5)
final multiImages = await picker.pickMultiImage(
  context: context,
  options: const PickOptions(maxImages: 5, source: ImageSource.gallery),
);
// use multiImages.items

// Single video
final singleVideo = await picker.pickVideo(
  context: context,
  options: const PickOptions(source: ImageSource.gallery),
);
if (singleVideo.item != null) {
  // use singleVideo.item
}
```

## Use cases

- Pick single image (gallery or camera)
- Pick multiple images (gallery only)
- Pick single video (gallery or camera)

### Scenarios

```dart
final picker = AdaptiveMediaPicker();

// 1) Single image from gallery
final singleImage = await picker.pickImage(
  context: context,
  options: const PickOptions(source: ImageSource.gallery),
);

// 2) Multiple images (max 5) from gallery
final multipleImages = await picker.pickMultiImage(
  context: context,
  options: const PickOptions(maxImages: 5, source: ImageSource.gallery),
);

// 3) Single video from gallery
final singleVideo = await picker.pickVideo(
  context: context,
  options: const PickOptions(source: ImageSource.gallery),
);

// 4) Camera request (falls back to gallery on web/desktop)
final cameraAttempt = await picker.pickImage(
  context: context,
  options: const PickOptions(source: ImageSource.camera),
);
```

> Multiple video selection is not supported by native APIs.

## Limited access UX

When the OS is in limited mode and no items are currently shared:

- A dialog appears offering Manage Selection (iOS only; macOS opens settings) and Open Settings
- If the user chooses either action, the limited-access bottom sheet closes by default

Screenshots (limited-access UI):

![Limited access - pick image](assets/images/limited_access_image_pick.jpg)

![Limited access - pick multiple images](assets/images/limited_access_multi_image_pick.jpg)

![Limited access - pick video](assets/images/limited_access_video_pick.jpg)

Note: In full-access mode, the platform system UI is used instead of this sheet.

## Notes

- You do not need to manage permissions yourself when using this package. The picker handles camera/photos permissions (including limited access) for you.
- `PickOptions.maxImages` applies to images only and is enforced on every platform (including web/desktop) even if the platform returns more.

## Platform setup

### Android

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS

Add to Info.plist:

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

### Desktop (Windows, macOS, Linux)

- Uses `file_selector` via `image_picker`.
- No runtime permission prompts; access is granted by the OS file dialog.
- Camera capture is not supported.
- On macOS, ensure:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

### Web

- Camera capture is not supported.
- Image/video selection uses the browser file picker with `ImageSource.gallery`.

## API overview

- `PickOptions`:
  - `maxImages` (images only), `imageQuality`, `maxWidth`, `maxHeight`, `source`
  - Settings dialog: `showOpenSettingsDialog`, `settingsDialogTitle|Message|ButtonLabel|cancelButtonLabel`
- Results:
  - `PickResultSingle { item, permissionResolution }`
  - `PickResultMultiple { items, permissionResolution }`
- Methods:
  - `pickImage`, `pickVideo`, `pickMultiImage`

## License

MIT
