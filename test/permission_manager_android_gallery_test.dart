import 'package:adaptive_media_picker/adaptive_media_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() {
  group('PermissionManager Android gallery', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Exercise the real Android code path: gallery picks must resolve
      // without touching any permission platform channel (a channel call
      // here would throw MissingPluginException and fail the test).
      PermissionManager.bypassPlatformChannelsForTests = false;
      ImagePickerPlatform.instance = ImagePickerAndroid();
    });

    testWidgets('grants gallery access without requesting permissions', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );

      const pm = PermissionManager();
      final res = await pm.ensureMediaPermission(
        source: ImageSource.gallery,
        mediaType: MediaType.image,
        context: ctx,
      );

      expect(res.granted, true);
      expect(res.limited, false);
      // Gallery picks must opt in to the Android photo picker.
      final platform = ImagePickerPlatform.instance;
      expect(platform, isA<ImagePickerAndroid>());
      expect((platform as ImagePickerAndroid).useAndroidPhotoPicker, true);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
