# 📸 Adaptive Media Picker

<p align="center">
  <a href="https://pub.dev/packages/adaptive_media_picker"><img src="https://img.shields.io/pub/v/adaptive_media_picker.svg" alt="Pub.dev Badge"></a>
  <a href="https://github.com/jaimin-kavathia/adaptive_media_picker/actions/workflows/ci.yml"><img src="https://github.com/jaimin-kavathia/adaptive_media_picker/actions/workflows/ci.yml/badge.svg" alt="Build Badge"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/platform-flutter-ff69b4.svg" alt="Flutter Badge">
</p>

<p align="center">
  <strong>🚀 Adaptive, permission-aware media picker for Flutter</strong><br/>
  <em>Handles limited & full access gracefully, with native-like UX across Android, iOS, Web, and Desktop.</em>
</p>

---

## ✨ Why Adaptive Media Picker?

Most media pickers only open the gallery or camera — but don’t handle **modern permission flows** like *limited access* on iOS/Android.

This package makes it **super easy** for developers by:

✅ Automatically handling permissions  
✅ Providing a **built-in limited-access sheet**  
✅ Falling back smartly for unsupported platforms (desktop/web)  
✅ Offering **one simple API** for images & videos

<p align="center">
  <img src="assets/images/limited_access_image_pick.jpg" alt="Pick image" width="28%"/>
  <img src="assets/images/limited_access_multi_image_pick.jpg" alt="Pick multiple images" width="28%" style="margin:0 8px"/>
  <img src="assets/images/limited_access_video_pick.jpg" alt="Pick video" width="28%"/>
</p>

<p align="center">
  <em>Built-in Limited Access UI (system-native UI used for full access)</em>
</p>

---

## 🚀 Features

- 📷 Pick **single image**, **multiple images**, or **single video**
- 🔐 **Permission-aware** (handles full, limited, denied states)
- 🖼️ Custom **limited-access bottom sheet** (powered by `photo_manager`)
- 🌍 Works on **mobile, web, and desktop**
- 🎯 **No dart:io** → safe for web builds
- 🎥 Fallback to gallery when camera unavailable (e.g., web/desktop)

⚠️ **Note**: Multiple video selection is not supported by native APIs.

---

## ⚡ Quick Start

```dart
final picker = AdaptiveMediaPicker();

// Pick a single image
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

// Pick multiple images (max 5)
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

## 📌 Common Use Cases

✅ Pick profile picture (single image)  
✅ Select multiple images for an album/post  
✅ Pick a single video from gallery/camera  
✅ Handle limited-access gracefully with a **ready-to-use bottom sheet**

---

## 🔐 Limited Access UX

When the user grants **limited access**:

- A dialog is shown with:
  - **Manage Selection** (iOS only)
  - **Open Settings** (iOS/macOS/Android)
- If the user interacts, the sheet closes automatically

You don’t need to handle permissions manually — the picker does it for you.

---

## ⚙️ Platform Setup

### 📱 Android

Add required permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### 🍎 iOS

Add to `Info.plist`:

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

### 💻 Desktop (Windows, macOS, Linux)

- Uses `file_selector` via `image_picker`
- No runtime permissions (file dialog is native)
- Camera capture not supported
- On **macOS**, add to `Info.plist`:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

### 🌐 Web

- Uses browser file picker
- Camera capture not supported

---

## 🧩 API Overview

### Options
- `maxImages` → Limit for multi-image picking
- `imageQuality`, `maxWidth`, `maxHeight` → Resize/compression options
- `source` → `ImageSource.gallery` | `ImageSource.camera`
- Settings dialog options → `showOpenSettingsDialog`, `settingsDialogTitle`, `settingsDialogMessage`, etc.

### Results
- `PickResultSingle { item, permissionResolution }`
- `PickResultMultiple { items, permissionResolution }`

### Methods
- `pickImage` → Single image
- `pickMultiImage` → Multiple images
- `pickVideo` → Single video

---

## 👤 Author

Created with ❤️ by **[Jaimin Kavathia](https://jaimin-kavathia.github.io/)**

---

## 📜 License

Licensed under the **MIT License** → [Open Source, Free to Use](LICENSE)

---

<p align="center">⭐ If you like this package, give it a star on GitHub & pub.dev!</p>