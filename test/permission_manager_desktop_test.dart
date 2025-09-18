import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_media_picker/adaptive_media_picker.dart';
import 'package:adaptive_media_picker/src/permission_manager.dart';

void main() {
  group('PermissionManager on desktop', () {
    final pm = const PermissionManager();

    test('returns grantedFull for gallery on desktop platforms', () async {
      if (!(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
        return; // Skip on non-desktop to keep CI cross-platform-safe
      }
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
      final res = await pm.ensureMediaPermission(
        source: ImageSource.camera,
        mediaType: MediaType.video,
      );
      expect(res.granted, true);
      expect(res.limited, false);
    });
  });
}
