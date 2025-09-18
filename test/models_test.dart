import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_media_picker/adaptive_media_picker.dart';

void main() {
  group('PickOptions', () {
    test('defaults are as expected', () {
      const opts = PickOptions();
      expect(opts.allowMultiple, false);
      expect(opts.mediaType, MediaType.image);
      expect(opts.maxImages, isNull);
      expect(opts.imageQuality, isNull);
      expect(opts.maxWidth, isNull);
      expect(opts.maxHeight, isNull);
      expect(opts.source, ImageSource.gallery);
      expect(opts.showOpenSettingsDialog, true);
      expect(opts.settingsDialogTitle, isNull);
      expect(opts.settingsDialogMessage, isNull);
      expect(opts.settingsButtonLabel, isNull);
      expect(opts.cancelButtonLabel, isNull);
    });

    test('custom values are stored correctly', () {
      const opts = PickOptions(
        allowMultiple: true,
        mediaType: MediaType.video,
        maxImages: 7,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 768,
        source: ImageSource.camera,
        showOpenSettingsDialog: false,
        settingsDialogTitle: 't',
        settingsDialogMessage: 'm',
        settingsButtonLabel: 's',
        cancelButtonLabel: 'c',
      );
      expect(opts.allowMultiple, true);
      expect(opts.mediaType, MediaType.video);
      expect(opts.maxImages, 7);
      expect(opts.imageQuality, 80);
      expect(opts.maxWidth, 1024);
      expect(opts.maxHeight, 768);
      expect(opts.source, ImageSource.camera);
      expect(opts.showOpenSettingsDialog, false);
      expect(opts.settingsDialogTitle, 't');
      expect(opts.settingsDialogMessage, 'm');
      expect(opts.settingsButtonLabel, 's');
      expect(opts.cancelButtonLabel, 'c');
    });
  });

  group('PermissionResolution', () {
    test('factories set flags correctly', () {
      final denied = PermissionResolution.denied();
      expect(denied.granted, false);
      expect(denied.limited, false);
      expect(denied.permanentlyDenied, false);

      final deniedPerm = PermissionResolution.denied(permanentlyDenied: true);
      expect(deniedPerm.granted, false);
      expect(deniedPerm.limited, false);
      expect(deniedPerm.permanentlyDenied, true);

      final full = PermissionResolution.grantedFull();
      expect(full.granted, true);
      expect(full.limited, false);
      expect(full.permanentlyDenied, false);

      final limited = PermissionResolution.grantedLimited();
      expect(limited.granted, true);
      expect(limited.limited, true);
      expect(limited.permanentlyDenied, false);
    });
  });

  test('ImageSource is exported from package', () {
    // If export is missing, this line will fail to resolve at compile time.
    const source = ImageSource.gallery;
    expect(source, ImageSource.gallery);
  });
}


