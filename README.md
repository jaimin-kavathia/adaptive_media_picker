# Adaptive Media Picker

[![pub package](https://img.shields.io/pub/v/adaptive_media_picker.svg?label=pub.dev&color=blueviolet&logo=dart)](https://pub.dev/packages/adaptive_media_picker)
[![pub points](https://img.shields.io/pub/points/adaptive_media_picker?logo=dart)](https://pub.dev/packages/adaptive_media_picker/score)
[![likes](https://img.shields.io/pub/likes/adaptive_media_picker?logo=dart)](https://pub.dev/packages/adaptive_media_picker/score)
[![CI](https://github.com/jaimin-kavathia/adaptive_media_picker/actions/workflows/ci.yml/badge.svg)](https://github.com/jaimin-kavathia/adaptive_media_picker/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**Pick images and videos in Flutter with one call — permissions, a camera/gallery chooser, cropping and validation included.**
Works on Android, iOS, Web (JS & WASM), macOS, Windows and Linux.

![Adaptive Media Picker](https://raw.githubusercontent.com/jaimin-kavathia/adaptive_media_picker/main/assets/images/banner.png)

| Source sheet (Android) | Source sheet (iOS) | Circle crop | Results |
| :---: | :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/jaimin-kavathia/adaptive_media_picker/main/assets/images/screen_sheet_material.png" width="200" alt="Material source sheet"> | <img src="https://raw.githubusercontent.com/jaimin-kavathia/adaptive_media_picker/main/assets/images/screen_sheet_ios.png" width="200" alt="Cupertino source sheet"> | <img src="https://raw.githubusercontent.com/jaimin-kavathia/adaptive_media_picker/main/assets/images/screen_crop_circle.png" width="200" alt="Circle crop"> | <img src="https://raw.githubusercontent.com/jaimin-kavathia/adaptive_media_picker/main/assets/images/screen_results.png" width="200" alt="Picked items"> |

---

## Why this package?

`image_picker` opens the system picker. Everything around it — asking for permissions, letting the user choose camera or gallery, cropping, checking file size — every app writes again. This package does it for you, on top of `image_picker`.

| You need…                                         | `image_picker` alone          | `adaptive_media_picker`                     |
| :------------------------------------------------ | :---------------------------- | :------------------------------------------ |
| Camera / Photos permission prompts + Settings flow | DIY (`permission_handler`)    | ✅ Built in, customizable text              |
| "Take photo / Choose from gallery" chooser         | DIY                           | ✅ `sourceSheet:` (Cupertino on iOS)        |
| Cropping, incl. circle avatars                     | Separate package + setup      | ✅ `wantToCrop: true`                       |
| Cropping on Web and desktop                        | ❌                            | ✅ Built-in editor, no setup                |
| iOS "Selected Photos" (limited access)             | DIY                           | ✅ Built-in selection sheet                 |
| Max file size / allowed types                      | DIY                           | ✅ `maxFileSizeBytes`, `allowedMimeTypes`   |
| Why nothing was picked                             | `null`                        | ✅ Typed `PickError` + permission state     |
| File name, size, MIME type, bytes on Web           | Partly                        | ✅ On every `PickedMedia`                   |
| Google Play photo policy                           | Your responsibility           | ✅ No `READ_MEDIA_*` permission needed      |

---

## Installation

```bash
flutter pub add adaptive_media_picker
```

```dart
import 'package:adaptive_media_picker/adaptive_media_picker.dart';
```

Then follow the short [platform setup](#platform-setup) for the features you use.

## Quick start

```dart
final picker = AdaptiveMediaPicker();

final result = await picker.pickImage(context: context);
final photo = result.item; // null if the user canceled
```

That's it: permissions are requested (and explained) when needed, iOS limited access is handled, and failures come back as a typed `result.error` instead of an exception.

---

## Usage

### Profile photo: camera or gallery, circle crop, remove

```dart
final result = await picker.pickImage(
  context: context,
  sourceSheet: SourceSheetOptions(
    title: 'Profile photo',
    removeLabel: hasAvatar ? 'Remove photo' : null, // optional
  ),
  options: const PickOptions(
    wantToCrop: true,
    cropShape: CropShape.circle,
    preferredCameraDevice: CameraDevice.front,
    maxFileSizeBytes: 5 * 1024 * 1024, // 5 MB
  ),
);

if (result.removeRequested) {
  // the user tapped "Remove photo"
} else if (result.item case final photo?) {
  final bytes = await photo.readAsBytes(); // works on Web too
}
```

The sheet is a Cupertino action sheet on iOS/macOS and a Material bottom sheet elsewhere (`style:` overrides it). Where there is no camera (Web, desktop) the camera option is hidden, and if only the gallery is left the sheet is skipped. Need just the choice? `await picker.showSourceSheet(context: context)` returns a `MediaSourceChoice`.

### Multiple images

```dart
final result = await picker.pickMultiImage(
  context: context,
  options: const PickOptions(maxImages: 5, imageQuality: 80),
);
for (final image in result.items) { /* ... */ }
```

### Videos, and photos + videos together

```dart
// One video, or record one (max 30 s) with the camera
final video = await picker.pickVideo(
  context: context,
  options: const PickOptions(
    source: ImageSource.camera,
    maxVideoDuration: Duration(seconds: 30),
  ),
);

// Several videos
final videos = await picker.pickMultiVideo(context: context);

// Photos and videos in one picker
final media = await picker.pickMultipleMedia(
  context: context,
  options: const PickOptions(maxImages: 10),
);
final onlyVideos = media.items.where((m) => m.isVideo);
```

### Cropping

```dart
const PickOptions(
  wantToCrop: true,
  cropAspectRatio: CropAspectRatioOption.ratio16x9, // initial ratio
  lockCropAspectRatio: true,                         // keep it fixed
  // cropShape: CropShape.circle,                    // or a circle (1:1)
)
```

Android and iOS use the native cropper (uCrop / TOCropViewController). Web, macOS, Windows and Linux use a built-in Flutter crop editor with ratio presets. If the user backs out of cropping you still get the original image, with `PickError.cropCanceled`.

<img src="https://raw.githubusercontent.com/jaimin-kavathia/adaptive_media_picker/main/assets/images/screen_crop_ratio.png" width="220" alt="Built-in crop editor with ratio presets">

### Size and type limits

```dart
final result = await picker.pickMultiImage(
  context: context,
  options: const PickOptions(
    maxFileSizeBytes: 10 * 1024 * 1024,
    allowedMimeTypes: ['image/jpeg', 'image/png'], // or ['image/*']
  ),
);
// Valid files are in result.items; the others are in result.rejected,
// each with its reason (PickError.fileTooLarge / unsupportedType).
```

### Uploading (including Web)

On Web, `path` is a blob URL, so use `name` and `readAsBytes()`:

```dart
final item = result.item!;
final bytes = await item.readAsBytes();
upload(bytes, filename: item.name, contentType: item.mimeType);
```

### Handling the result

```dart
final result = await picker.pickImage(context: context);
switch (result.error) {
  case null:
    final media = result.item; // name, path, mimeType, sizeInBytes, width, height
  case PickError.canceled:
    break; // user backed out
  case PickError.cropCanceled:
    break; // result.item is the uncropped image
  case PickError.permissionDenied:
    // result.permissionResolution.permanentlyDenied tells you whether the
    // user must change it in Settings (the package already offered that).
    break;
  case PickError.fileTooLarge:
  case PickError.unsupportedType:
    break; // failed maxFileSizeBytes / allowedMimeTypes
  case PickError.io:
  case PickError.unknown:
    break; // platform failure; set PickOptions.logTag to find it in logs
}
```

### Recover a pick after Android kills your app

On low-memory Android devices the system can destroy your activity while the camera is open. Call this on startup to get that photo back:

```dart
final lost = await picker.recoverLostData();
if (lost != null) handle(lost.items);
```

### Theming and translations

The built-in UI follows your app theme. Override per call, and translate every built-in string:

```dart
const PickOptions(
  themeBrightness: Brightness.dark,
  primaryColor: Colors.teal,
  settingsDialogTitle: 'Camera access needed',
  labels: PickerLabels(cropTitle: 'Recortar', done: 'Listo', cancel: 'Cancelar'),
)
```

Source sheet texts are set in `SourceSheetOptions` (`cameraLabel`, `galleryLabel`, `removeLabel`, `cancelLabel`).

---

## Platform setup

### Android

**Gallery picks need no permission.** They go through the [Android photo picker](https://developer.android.com/training/data-storage/shared/photopicker), so do **not** declare `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` or `READ_EXTERNAL_STORAGE` for this package — Google Play's [Photo and Video Permissions policy](https://support.google.com/googleplay/android-developer/answer/14115180) rejects apps that declare them for occasional media use.

Only if you use the camera, add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<!-- Only when recording videos: -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

`permission_handler` 13 (used internally) needs **compileSdk 37**; Flutter's default is 36. In `android/app/build.gradle(.kts)`:

```kts
android {
    compileSdk = 37
}
```

Only if you use cropping, add the cropper activity to `AndroidManifest.xml`:

```xml
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

<details>
<summary>Release build fails with missing OkHttp classes (R8)?</summary>

uCrop references OkHttp. Add to `android/app/build.gradle(.kts)`:

```kts
dependencies {
  implementation("com.squareup.okhttp3:okhttp:4.12.0")
  implementation("com.squareup.okio:okio:3.6.0")
}
```

</details>

### iOS

Add the usage descriptions you need to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Choose photos and videos to share.</string>
<key>NSCameraUsageDescription</key>
<string>Take photos and videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Record audio with videos.</string>
```

Enable the matching permissions in the `post_install` block of `ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_PHOTOS=1',
      ]
    end
  end
end
```

When the user shares only some photos ("Selected Photos"), the package shows its own grid of those photos, with **Select more** and **Open Settings** if the selection is empty.

### macOS

Add to both `DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

### Web, Windows, Linux

No setup. Camera requests fall back to the file chooser.

---

## Platform support

| Feature                     | Android | iOS | Web | macOS | Windows | Linux |
| :-------------------------- | :-----: | :-: | :-: | :---: | :-----: | :---: |
| Images (single / multiple)  |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| Videos (single / multiple)  |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| Photos + videos together    |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| Camera capture              |   ✅    | ✅  |  —  |   —   |    —    |   —   |
| Source sheet                |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| Cropping (rect & circle)    |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| Limited-access sheet        |    —    | ✅  |  —  |   —   |    —    |   —   |
| Size / type validation      |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| Lost-data recovery          |   ✅    |  —  |  —  |   —   |    —    |   —   |

"—" means the platform has no such concept; the call still works (e.g. camera falls back to the gallery).

---

## API reference

Full docs: [pub.dev API reference](https://pub.dev/documentation/adaptive_media_picker/latest/).

### Methods on `AdaptiveMediaPicker`

| Method                 | Returns              | What it does                                   |
| :--------------------- | :------------------- | :--------------------------------------------- |
| `pickImage`            | `PickResultSingle`   | One image, optionally cropped                  |
| `pickVideo`            | `PickResultSingle`   | One video from the gallery or camera           |
| `pickMedia`            | `PickResultSingle`   | One image or video                             |
| `pickMultiImage`       | `PickResultMultiple` | Several images                                 |
| `pickMultiVideo`       | `PickResultMultiple` | Several videos                                 |
| `pickMultipleMedia`    | `PickResultMultiple` | Several images and videos                      |
| `showSourceSheet`      | `MediaSourceChoice?` | Just the camera / gallery / remove choice      |
| `recoverLostData`      | `PickResultMultiple?`| A pick lost when Android killed the app        |

Every pick method takes `context`, `options` (`PickOptions`) and an optional `sourceSheet` (`SourceSheetOptions`).

### `PickOptions`

| Option                  | Default     | Description                                                    |
| :---------------------- | :---------- | :------------------------------------------------------------- |
| `source`                | `gallery`   | `ImageSource.gallery` or `.camera` (ignored with `sourceSheet`) |
| `maxImages`             | —           | Item cap for multi picks                                       |
| `imageQuality`          | —           | JPEG quality 0–100 (also used for cropping)                    |
| `maxWidth` / `maxHeight`| —           | Downscale images                                               |
| `preferredCameraDevice` | `rear`      | `CameraDevice.front` for selfies                               |
| `maxVideoDuration`      | —           | Max recording length                                           |
| `maxFileSizeBytes`      | —           | Reject larger files                                            |
| `allowedMimeTypes`      | —           | e.g. `['image/*']`, `['video/mp4']`                            |
| `wantToCrop`            | `false`     | Open the crop editor for single images                         |
| `cropAspectRatio`       | —           | Initial ratio (`square`, `ratio4x3`, `ratio16x9`, …)          |
| `lockCropAspectRatio`   | `false`     | Keep the ratio fixed                                           |
| `cropShape`             | `rectangle` | `CropShape.circle` for avatars                                 |
| `themeBrightness`       | app theme   | Light/dark for the built-in UI                                 |
| `primaryColor`          | app theme   | Accent color for the built-in UI                               |
| `labels`                | English     | `PickerLabels` for every built-in string                       |
| `settingsDialogTitle`, `settingsDialogMessage`, `settingsButtonLabel`, `cancelButtonLabel` | — | Permission dialog texts |
| `logTag`                | —           | Tag for debug logs                                             |

### Results

`PickResultSingle` — `item` (`PickedMedia?`), `error` (`PickError?`), `permissionResolution`, `metadata` (crop info, sizes), `removeRequested`.

`PickResultMultiple` — `items`, `rejected` (`List<RejectedMedia>`), `error`, `permissionResolution`, `removeRequested`.

`PickedMedia` — `path`, `name`, `mimeType`, `sizeInBytes`, `width`, `height`, `isImage`, `isVideo`, `readAsBytes()`.

`PickError` — `canceled`, `cropCanceled`, `permissionDenied`, `fileTooLarge`, `unsupportedType`, `io`, `unknown`.

---

## Upgrading to 2.0

Most apps need no changes. Check these:

- `PickError` gained `fileTooLarge` and `unsupportedType`, and `MediaType` gained `any`; exhaustive `switch` statements need the new cases.
- Multi picks return `PickError.canceled` when nothing was picked (previously `null`).
- `wantToCrop` now opens a crop editor on desktop (previously it returned the original image).
- Web: you can delete the cropperjs `<script>`/`<link>` tags from `web/index.html`.

See the [changelog](CHANGELOG.md) for everything else.

## FAQ

**Do I need `READ_MEDIA_IMAGES` on Android?** No. Gallery picks use the system photo picker, which needs no permission. Leaving it out keeps you compliant with Google Play's photo and video policy.

**Why does my Android build ask for compileSdk 37?** `permission_handler` 13 requires it; set `compileSdk = 37` as shown in [Android setup](#android).

**Can I use my own UI and only use the permission handling?** Yes — `PermissionManager().ensureMediaPermission(...)` is public.

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/jaimin-kavathia/adaptive_media_picker/issues). The README images are rendered from the real widgets; regenerate them with `cd example && flutter test tool/screenshots_test.dart`.

## License

MIT — see [LICENSE](LICENSE). Created by [Jaimin Kavathia](https://jaimin-kavathia.github.io/) · [LinkedIn](https://in.linkedin.com/in/jaimin-kavathia-flutter-developer).
