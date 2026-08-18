# 📸 Adaptive Media Picker

<p align="center">
  <a href="https://pub.dev/packages/adaptive_media_picker"><img src="https://img.shields.io/pub/v/adaptive_media_picker.svg?label=pub.dev&color=blueviolet&logo=dart" alt="Pub.dev Badge"></a>
  <a href="https://github.com/jaimin-kavathia/adaptive_media_picker/actions/workflows/ci.yml"><img src="https://github.com/jaimin-kavathia/adaptive_media_picker/actions/workflows/ci.yml/badge.svg" alt="Build Badge"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/platform-Flutter-ff69b4.svg" alt="Flutter Badge">
</p>

<p align="center">
  <strong>🚀 Adaptive, permission-aware media picker for Flutter</strong><br/>
  <em>Handles limited & full access gracefully — with native-like UX on Android, iOS, Web, and Desktop.</em>
</p>

<p align="center">
  <img src="assets/images/adaptive_media_picker.png" alt="Adaptive Media Picker" width="100%">
</p>

---

## ✨ Why Adaptive Media Picker?

Most media pickers only open the gallery or camera — but fail when permissions are **limited** or **restricted**.
`adaptive_media_picker` is designed to **handle every case automatically**, making your UX seamless.

### 💡 What makes it different?

- ✅ Auto permission handling
- ✅ Built-in **limited-access sheet** (for iOS & Android)
- ✅ Optional **image cropping** (Android / iOS / Web)
- ✅ Works seamlessly on **Web, Desktop, and Mobile**
- ✅ **Single unified API** for images & videos

<p align="center">
  <img src="assets/images/limited_access_image_pick.jpg" alt="Pick image" width="28%"/>
  <img src="assets/images/limited_access_multi_image_pick.jpg" alt="Pick multiple images" width="28%" style="margin:0 8px"/>
  <img src="assets/images/limited_access_video_pick.jpg" alt="Pick video" width="28%"/>
</p>

<p align="center">
  <em>✨ Built-in limited access bottom sheet UI (native full-access flow on Android/iOS)</em>
</p>

---

## 🚀 Features at a Glance

| Feature                       | Description                                  |
| :---------------------------- | :------------------------------------------- |
| 📷 Image & Video Picker       | Pick single/multiple images or single videos |
| ✂️ Cropping                   | Optional crop (Android, iOS, Web)            |
| 🔐 Permission-aware           | Handles full, limited, denied states         |
| 🧭 Cross-platform             | Works on mobile, web, and desktop            |
| 🖼️ Built-in Limited Access UI | Native-like bottom sheet                     |
| 🧩 Fallbacks                  | Smart fallbacks for unsupported platforms    |
| 🎯 Web Safe                   | No `dart:io` — works on Flutter Web          |

> ⚠️ Multiple video selection is **not supported** by native APIs.

---

## 🗂️ Platform Support Matrix

| Feature                 | Android | iOS | Web | macOS | Windows | Linux |
| ----------------------- | :-----: | :-: | :-: | :---: | :-----: | :---: |
| Single image pick       |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| Multi-image pick        |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| Single video pick       |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| Multiple videos         |   ❌    | ❌  | ❌  |  ❌   |   ❌    |  ❌   |
| Camera capture          |   ✅    | ✅  | ❌  |  ❌   |   ❌    |  ❌   |
| Limited-access UX       |   ✅    | ✅  | ❌  |  ✅   |   ❌    |  ❌   |
| Cropping (single image) |   ✅    | ✅  | ✅  |  ❌   |   ❌    |  ❌   |

---

## ⚡ Quick Start

```dart
final picker = AdaptiveMediaPicker();

// Pick a single image
final singleImage = await picker.pickImage(
  context: context,
  options: const PickOptions(source: ImageSource.gallery, imageQuality: 80),
);

// Pick and crop
final croppedImage = await picker.pickImage(
  context: context,
  options: const PickOptions(source: ImageSource.gallery, wantToCrop: true),
);

// Pick and crop with a locked default aspect ratio (e.g. a square avatar)
final avatarImage = await picker.pickImage(
  context: context,
  options: const PickOptions(
    source: ImageSource.gallery,
    wantToCrop: true,
    cropAspectRatio: CropAspectRatioOption.square,
    lockCropAspectRatio: true,
  ),
);

// Pick multiple images
final multiImages = await picker.pickMultiImage(
  context: context,
  options: const PickOptions(maxImages: 5, source: ImageSource.gallery),
);

// Pick a single video
final singleVideo = await picker.pickVideo(
  context: context,
  options: const PickOptions(source: ImageSource.gallery),
);
```

---

## 🎨 Theming

Both the built-in limited-access bottom sheet and the optional cropper can follow your app theme or be overridden via `PickOptions`:

- **Automatic**: By default, the package uses `Theme.of(context)` for surfaces and text.
- **Override**: Set these optional fields on `PickOptions`:
  - `themeBrightness`: `Brightness.light` or `Brightness.dark`
  - `primaryColor`: the primary accent color (e.g. `Colors.blue`)

Example:

```dart
final result = await picker.pickImage(
  context: context,
  options: const PickOptions(
    wantToCrop: true,
    themeBrightness: Brightness.dark,
    primaryColor: Colors.blue,
  ),
);
```

Notes:

- Limited-access bottom sheet inherits your app theme when overrides are not provided.
- Android cropper toolbar, controls, and grid/frame colors derive from `themeBrightness` and `primaryColor`.
- Web cropper uses the provided `context` (dialog/page) and will follow your theme colors; primary accent applies to available UI elements.

---

## 📌 Common Use Cases

- 🖼️ Select & crop a profile picture
- 📸 Capture or choose multiple images for a gallery/post
- 🎥 Pick single video from camera or gallery
- 🔐 Handle **limited access** permissions gracefully

---

## ✂️ Cropping Setup

Cropping is supported on **Android**, **iOS**, and **Web**.

### 📱 Android

Add `UCropActivity` to your `AndroidManifest.xml`:

```xml
<activity
        android:name="com.yalantis.ucrop.UCropActivity"
        android:screenOrientation="portrait"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

> ✅ Android embedding v2 required

> ℹ️ If you enable cropping and build a release APK/AAB (R8/minify), UCrop may reference OkHttp classes. Add these dependencies to your app’s `build.gradle(.kts)` to avoid missing-class errors (only needed when cropping on Android):

```kts
dependencies {
  implementation("com.squareup.okhttp3:okhttp:4.12.0")
  implementation("com.squareup.okio:okio:3.6.0")
}
```

### 🍏 iOS

No additional setup required.

### 🌐 Web

Add **cropperjs** to `web/index.html`:

```html
<link
        rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.css"
/>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.js"></script>
```

---

## 🔐 Limited Access UX

When the user grants **limited access**, the picker automatically shows a native-like dialog with options:

- 📁 **Manage Selection** (iOS only)
- ⚙️ **Open Settings** (iOS/macOS/Android)
- 🕓 Auto-dismisses after interaction

---

## ⚙️ Permissions Setup

### 🧱 Android

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

> ⚠️ `permission_handler` 13 (used via `smart_permission`) requires **`compileSdk = 37`**. Flutter's default is still 36, so set it explicitly in `android/app/build.gradle(.kts)`:

```kts
android {
    compileSdk = 37
}
```

### 🍎 iOS

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

To ensure your app works smoothly with media picking and cropping on iOS, you'll need to configure the required permissions in your `Podfile` for Flutter.

**Add the following code to the `post_install` section of your `Podfile`:**

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      # Enable only the permissions you need in your app
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_PHOTOS=1',
        # Examples of other permissions you might enable:
        # 'PERMISSION_NOTIFICATIONS=1',
        # 'PERMISSION_MEDIA_LIBRARY=1',
        # 'PERMISSION_BLUETOOTH=1',
        # 'PERMISSION_APP_TRACKING_TRANSPARENCY=1',
      ]
    end
  end
end
```

This will make sure the necessary permissions for Camera, Microphone, and Photos are enabled in your iOS project, allowing the picker to function properly.

### 💻 macOS

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

> 🧩 Desktop platforms use native file dialogs.
> Camera capture is not supported on desktop.

---

## 🧩 API Overview

| Method             | Description                            |
| :----------------- | :------------------------------------- |
| `pickImage()`      | Pick single image (optionally cropped) |
| `pickMultiImage()` | Pick multiple images                   |
| `pickVideo()`      | Pick single video                      |

## 📘 Data Models Overview

### 🧩 **PickOptions**

Configuration options for image/video picking operations.

| Field                    | Type          | Description                                                                    |
| :----------------------- | :------------ | :----------------------------------------------------------------------------- |
| `maxImages`              | `int?`        | Maximum number of images for multi-image pick. Ignored for single image/video. |
| `imageQuality`           | `int?`        | JPEG compression quality (0–100).                                              |
| `maxWidth`               | `int?`        | Resize width for images when supported.                                        |
| `maxHeight`              | `int?`        | Resize height for images when supported.                                       |
| `source`                 | `ImageSource` | Source — `gallery` or `camera`. Falls back to gallery on web/desktop.          |
| `showOpenSettingsDialog` | `bool`        | **Deprecated.** The permission flow shows its own settings dialog.             |
| `settingsDialogTitle`    | `String?`     | Custom title for the permission dialogs (rationale / open settings).           |
| `settingsDialogMessage`  | `String?`     | Custom message for the permission dialogs.                                     |
| `settingsButtonLabel`    | `String?`     | Label for the “Open Settings” button.                                          |
| `cancelButtonLabel`      | `String?`     | Label for the cancel/deny button.                                              |
| `wantToCrop`             | `bool`        | Enable crop flow (Android/iOS/Web only, single image only).                    |
| `cropAspectRatio`        | `CropAspectRatioOption?` | Default aspect ratio the cropper opens with (e.g. `square`, `ratio4x3`). Defaults to `square` on Android and free-form on iOS/Web when unset. |
| `lockCropAspectRatio`    | `bool`        | Locks the crop box to `cropAspectRatio` (Android/iOS only; ignored on Web).     |
| `themeBrightness`        | `Brightness?` | Override theme for limited sheet & cropper (`light`/`dark`).                   |
| `primaryColor`           | `Color?`      | Primary accent color for limited sheet & cropper (e.g., blue).                 |
| `logTag`                 | `String?`     | Optional debug tag for internal logging.                                       |

---

### 🖼️ **PickedMedia**

Represents a single picked image or video.

| Field      | Type      | Description                          |
| :--------- | :-------- | :----------------------------------- |
| `path`     | `String`  | Local file path to the picked media. |
| `mimeType` | `String?` | MIME type if available.              |
| `width`    | `int?`    | Image width (when known).            |
| `height`   | `int?`    | Image height (when known).           |

---

### 🧾 **PickResultSingle**

Returned from `pickImage()` or `pickVideo()`.

| Field                  | Type                   | Description                                |
| :--------------------- | :--------------------- | :----------------------------------------- |
| `item`                 | `PickedMedia?`         | Picked item, or `null` if none.            |
| `permissionResolution` | `PermissionResolution` | Final permission state after operation.    |
| `metadata`             | `PickMetadata`         | Metadata about crop and sizes.             |
| `error`                | `PickError?`           | Indicates if operation failed or canceled. |

> 💡 Use `.isEmpty` to check if no item was selected.

---

### 🧾 **PickResultMultiple**

Returned from `pickMultiImage()`.

| Field                  | Type                   | Description                                |
| :--------------------- | :--------------------- | :----------------------------------------- |
| `items`                | `List<PickedMedia>`    | All picked images. Empty if none.          |
| `permissionResolution` | `PermissionResolution` | Final permission state.                    |
| `error`                | `PickError?`           | Indicates if operation failed or canceled. |

> 💡 Use `.isEmpty` to check if no images were selected.

---

### 🧠 **PickMetadata**

Extra info for debugging and analytics.

| Field          | Type    | Description                   |
| :------------- | :------ | :---------------------------- |
| `cropApplied`  | `bool`  | Whether cropping was applied. |
| `originalSize` | `Size?` | Size before transformations.  |
| `finalSize`    | `Size?` | Size after transformations.   |

---

### ⚠️ **PickError**

Typed error codes for pick operations.

| Value              | Description                                             |
| :----------------- | :------------------------------------------------------ |
| `canceled`         | User canceled selection.                                |
| `cropCanceled`     | User canceled cropping.                                 |
| `permissionDenied` | Permission denied (see `permissionResolution`).         |
| `io`               | I/O or platform failure.                                |
| `unknown`          | Unknown reason.                                         |

---

### 🔐 **PermissionResolution**

Represents the final permission outcome.

| Field               | Type   | Description                                  |
| :------------------ | :----- | :------------------------------------------- |
| `granted`           | `bool` | True if any form of access was granted.      |
| `limited`           | `bool` | True if access is limited (iOS/Android 14+). |
| `permanentlyDenied` | `bool` | True if user must change settings manually.  |

#### Factories

| Factory                                 | Description                           |
| :-------------------------------------- | :------------------------------------ |
| `PermissionResolution.grantedFull()`    | Full access granted.                  |
| `PermissionResolution.grantedLimited()` | Limited access granted.               |
| `PermissionResolution.denied()`         | Access denied (optionally permanent). |

---

## 👤 Author

Created with ❤️ by [**Jaimin Kavathia**](https://jaimin-kavathia.github.io/) - 💼 [LinkedIn](https://in.linkedin.com/in/jaimin-kavathia-flutter-developer)

---

## 📜 License

Licensed under the [**MIT License**](LICENSE).
Free for personal & commercial use.

---

<p align="center">
  ⭐ <strong>If you like this package, give it a star on <a href="https://github.com/jaimin-kavathia/adaptive_media_picker">GitHub</a> & <a href="https://pub.dev/packages/adaptive_media_picker">pub.dev</a>!</strong>
</p>
