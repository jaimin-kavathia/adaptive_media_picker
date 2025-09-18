## 0.0.1 — 2025-09-18

Initial release

- Adaptive media picker with unified API across platforms (Android, iOS, Web, Desktop).
- Permission handling via `permission_handler`, including:
  - Android 13+ granular Photos/Videos permissions and limited access detection.
  - iOS Photos limited/full access handling with settings prompt.
  - Desktop: treated as granted; relies on system file dialogs.
- Limited access flow with built-in bottom-sheet picker powered by `photo_manager`.
- Image/video picking backed by `image_picker` with desktop/web camera fallback to gallery.
- Options for multi-select, max image count, and image quality/size hints.
- Re-exports `ImageSource` for consumer convenience.
- Example app demonstrating common flows and UI states.
- Test suite (package and example) and FVM compatibility.
