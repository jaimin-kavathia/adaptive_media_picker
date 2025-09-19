import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_media_picker/adaptive_media_picker.dart';

void main() {
  group('PermissionManager on desktop', () {
    setUpAll(() {
      // Initialize Flutter binding for method channel access
      TestWidgetsFlutterBinding.ensureInitialized();
      // Avoid platform channel calls in CI by short-circuiting permission checks
      PermissionManager.bypassPlatformChannelsForTests = true;
    });

    test('returns grantedFull for gallery on desktop platforms', () async {
      if (!(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
        return; // Skip on non-desktop to keep CI cross-platform-safe
      }

      final pm = const PermissionManager();
      final res = await pm.ensureMediaPermission(
        source: ImageSource.gallery,
        mediaType: MediaType.image,
      );
      expect(res.granted, true);
      expect(res.limited, false);
    });

    test('returns grantedFull for camera on desktop platforms', () async {
      if (!(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
        return; // Skip on non-desktop to keep CI cross-platform-safe
      }

      final pm = const PermissionManager();
      final res = await pm.ensureMediaPermission(
        source: ImageSource.camera,
        mediaType: MediaType.video,
      );
      expect(res.granted, true);
      expect(res.limited, false);
    });
  });
}
