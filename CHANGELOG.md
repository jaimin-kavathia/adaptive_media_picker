## 0.0.2 — 2025-09-19

Refactor, clearer API, and docs/readiness improvements:

- New concrete result types returned directly:
  - `PickResultSingle { item, permissionResolution }`
  - `PickResultMultiple { items, permissionResolution }`
- New public methods:
  - `pickImage` (single image), `pickVideo` (single video), `pickMultiImage` (multi images)
- `PickOptions` simplified:
  - Removed `allowMultiple` and `mediaType`
  - `maxImages` now applies only to images and is enforced cross-platform
- Limited access bottom sheet UX:
  - Closes by default after Manage/Open Settings when no items are visible
- Codebase reorg:
  - `src/core/` (models), `src/platform/` (permission manager), `src/ui/` (limited picker)
- Web compatibility: removed `dart:io` from library code
- README overhauled (quick start, use cases, API overview)
- Tests updated; FVM test run green

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
