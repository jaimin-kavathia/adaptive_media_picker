## 0.0.7 — 2025-10-09

Theming support and example toggle.

- Options
  - Added `PickOptions.themeBrightness` and `PickOptions.primaryColor` to control UI theme for the limited-access sheet and cropper
- Limited-access UI
  - Bottom sheet now uses app theme by default; can be overridden via `PickOptions`
- Cropping (Android/iOS/Web)
  - Android: `AndroidUiSettings` colors now derive from theme (toolbar, controls, dim layer, grid/frame)
  - Web: forwards theme context; respects app theme for dialog/page
- Example
  - Added light/dark theme switch and wired theme overrides into picker calls
- Docs
  - README updated with theming section and usage

## 0.0.6 — 2025-10-06

Non-breaking DX improvements: typed errors and richer result metadata.

- Results
  - `PickResultSingle` now exposes `metadata: PickMetadata` with:
    - `cropApplied`, `originalSize`, and `finalSize` (when measurable)
  - Added `error: PickError?` to disambiguate empty results:
    - `canceled` (user canceled), `cropCanceled`, `io`, `unknown`
- Options
  - `PickOptions.logTag` (optional) for easier internal tracing in debug logs
- Behavior
  - Populates `originalSize` and `finalSize` for single-image picks (incl. cropped)
  - Sets `PickError.canceled` when selection dialogs return null/empty
  - Sets `PickError.cropCanceled` when crop UI is dismissed without saving
- Analyzer
  - Guarded context across async gaps where size decoding/crop occurs

## 0.0.5 — 2025-10-06

Cropping feature finalized with platform guards, stubs, and docs updates:

- Feature: Optional cropping for single image picks (`PickOptions.wantToCrop`)
  - Supported on Android, iOS, Web
  - No-op on Desktop (macOS, Windows, Linux) — returns original image
- Limited access: Cropping now works when selecting from the limited-access picker (single image)
- Android: Ensure `UCropActivity` is declared in app manifest (documented)
- Web: Uses `image_cropper` (cropperjs) with dialog style and fixed size; requires including CSS/JS in `index.html`
- Internals:
  - Introduced `PlatformImageCropper` with conditional imports for mobile/web and a desktop stub
  - Removed direct `ImageCropper` usage from the picker; unified call sites
  - Fixed analyzer issues: context guards (mounted checks), removed custom aspect ratio type

## 0.0.4 — 2025-09-23

Analyzer and formatting cleanups; no API changes:

- Lints
  - Resolved "Dangling library doc comment" by adjusting comments in `lib/adaptive_media_picker.dart`
  - Ensured analyzer passes with no issues on the library entrypoint
- Formatting
  - Ran `dart format` across the repository (lib and example) for pub.dev checks
- Tests
  - Verified package and example tests pass under FVM
- Public API
  - No functional or breaking changes

## 0.0.3 — 2025-09-23

Docs and README polish; tests and formatting:

- Docs
  - Added dartdoc across public API (picker, models, limited-access UI)
  - Removed duplicated/ambiguous comments for clearer generated docs
- Public API
  - Cleaned exports in `adaptive_media_picker.dart` (no breaking changes)
- Tests & formatting
  - Updated example test to use the public entrypoint
  - Ran `dart format` on lib to satisfy pub.dev checks
- Internals
  - Minor refactors and comments only; no runtime behavior changes

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
