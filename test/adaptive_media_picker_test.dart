import 'dart:convert';
import 'dart:typed_data';

import 'package:adaptive_media_picker/adaptive_media_picker.dart';
import 'package:adaptive_media_picker/src/core/mime.dart';
import 'package:adaptive_media_picker/src/platform/builtin_cropper.dart';
import 'package:adaptive_media_picker/src/ui/crop_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1x1 transparent PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  group('mimeTypeFromPath', () {
    test('maps common image and video extensions', () {
      expect(mimeTypeFromPath('/a/b/photo.JPG'), 'image/jpeg');
      expect(mimeTypeFromPath('/a/b/photo.png'), 'image/png');
      expect(mimeTypeFromPath(r'C:\tmp\clip.mov'), 'video/quicktime');
      expect(mimeTypeFromPath('/a/b/clip.mp4'), 'video/mp4');
    });

    test('returns null when there is no usable extension', () {
      expect(mimeTypeFromPath('blob:http://localhost/1234'), isNull);
      expect(mimeTypeFromPath('/a.dir/file'), isNull);
      expect(mimeTypeFromPath(r'C:\a.dir\file'), isNull);
      expect(mimeTypeFromPath('/a/b/file.unknown'), isNull);
    });
  });

  group('built-in cropper helpers', () {
    test('encodedImageExtension detects JPEG, defaults to PNG', () {
      expect(
        encodedImageExtension(Uint8List.fromList([0xFF, 0xD8, 0xFF])),
        'jpg',
      );
      expect(encodedImageExtension(_png), 'png');
    });

    test('ratioValue maps every option', () {
      expect(BuiltInCropPage.ratioValue(null), isNull);
      expect(
        BuiltInCropPage.ratioValue(CropAspectRatioOption.original),
        isNull,
      );
      expect(BuiltInCropPage.ratioValue(CropAspectRatioOption.square), 1);
      expect(
        BuiltInCropPage.ratioValue(CropAspectRatioOption.ratio16x9),
        16 / 9,
      );
    });
  });

  group('BuiltInCropPage', () {
    Future<Future<Uint8List?>> open(
      WidgetTester tester, {
      CropAspectRatioOption? ratio,
      bool lock = false,
      bool circle = false,
    }) async {
      late Future<Uint8List?> result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = BuiltInCropPage.show(
                context: context,
                image: _png,
                aspectRatio: ratio,
                lockAspectRatio: lock,
                circle: circle,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      // The editor shows a spinner while decoding, so it never "settles".
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      return result;
    }

    testWidgets('shows ratio choices and returns null on close', (
      tester,
    ) async {
      final result = await open(tester, ratio: CropAspectRatioOption.ratio4x3);
      expect(find.text('Crop'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(7));
      final ChoiceChip selected = tester.widget(
        find.ancestor(of: find.text('4:3'), matching: find.byType(ChoiceChip)),
      );
      expect(selected.selected, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(await result, isNull);
    });

    testWidgets('hides ratio choices when the ratio is locked', (tester) async {
      await open(tester, ratio: CropAspectRatioOption.square, lock: true);
      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets('circle crop is a locked 1:1 without ratio choices', (
      tester,
    ) async {
      await open(tester, ratio: CropAspectRatioOption.ratio16x9, circle: true);
      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets('keeps ratio choices when locking without a ratio', (
      tester,
    ) async {
      await open(tester, lock: true);
      expect(find.byType(ChoiceChip), findsNWidgets(7));
    });
  });
}
