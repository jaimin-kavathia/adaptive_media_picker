import 'dart:convert';
import 'dart:io';

import 'package:adaptive_media_picker/adaptive_media_picker.dart';
import 'package:adaptive_media_picker/src/core/mime.dart';
import 'package:adaptive_media_picker/src/ui/source_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

// 1x1 transparent PNG (70 bytes).
final List<int> _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

/// Returns real temp files so the package can stat and decode them.
class _FakePicker extends ImagePickerPlatform {
  _FakePicker(this.dir);

  final Directory dir;
  List<String> nextFiles = const [];
  ImageSource? lastSource;
  CameraDevice? lastCamera;
  int? lastLimit;

  XFile _file(String name) {
    final File f = File('${dir.path}/$name');
    if (!f.existsSync()) {
      f.writeAsBytesSync(name.endsWith('.png') ? _png : List.filled(5000, 1));
    }
    return XFile(f.path);
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    lastSource = source;
    lastCamera = options.preferredCameraDevice;
    return nextFiles.isEmpty ? null : _file(nextFiles.first);
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    lastLimit = options.limit;
    return nextFiles.map(_file).toList();
  }

  @override
  Future<List<XFile>> getMultiVideoWithOptions({
    MultiVideoPickerOptions options = const MultiVideoPickerOptions(),
  }) async {
    lastLimit = options.limit;
    return nextFiles.map(_file).toList();
  }
}

void main() {
  late Directory dir;
  late _FakePicker fake;

  setUpAll(() {
    PermissionManager.bypassPlatformChannelsForTests = true;
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('amp_test');
    fake = _FakePicker(dir);
    ImagePickerPlatform.instance = fake;
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<BuildContext> host(WidgetTester tester) async {
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
    return ctx;
  }

  group('PickedMedia', () {
    testWidgets('describes picked images and forwards camera options', (
      tester,
    ) async {
      final ctx = await host(tester);
      fake.nextFiles = ['photo.png'];
      final result = await tester.runAsync(
        () => AdaptiveMediaPicker().pickImage(
          context: ctx,
          options: const PickOptions(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.front,
          ),
        ),
      );
      final item = result!.item!;
      expect(result.error, isNull);
      expect(item.mimeType, 'image/png');
      expect(item.name, 'photo.png');
      expect(item.sizeInBytes, _png.length);
      expect((item.width, item.height), (1, 1));
      expect(item.isImage, isTrue);
      expect(await tester.runAsync(item.readAsBytes), _png);
      expect(fake.lastSource, ImageSource.camera);
      expect(fake.lastCamera, CameraDevice.front);
    });
  });

  group('validation', () {
    testWidgets('rejects files over maxFileSizeBytes', (tester) async {
      final ctx = await host(tester);
      fake.nextFiles = ['photo.png'];
      final result = await tester.runAsync(
        () => AdaptiveMediaPicker().pickImage(
          context: ctx,
          options: const PickOptions(maxFileSizeBytes: 10),
        ),
      );
      expect(result!.item, isNull);
      expect(result.error, PickError.fileTooLarge);
    });

    testWidgets('rejects types outside allowedMimeTypes', (tester) async {
      final ctx = await host(tester);
      fake.nextFiles = ['photo.png'];
      final result = await tester.runAsync(
        () => AdaptiveMediaPicker().pickImage(
          context: ctx,
          options: const PickOptions(allowedMimeTypes: ['image/jpeg']),
        ),
      );
      expect(result!.error, PickError.unsupportedType);
    });

    testWidgets('multi pick keeps valid items and reports rejected ones', (
      tester,
    ) async {
      final ctx = await host(tester);
      fake.nextFiles = ['a.png', 'big.jpg', 'b.png'];
      final result = await tester.runAsync(
        () => AdaptiveMediaPicker().pickMultiImage(
          context: ctx,
          options: const PickOptions(maxImages: 5, maxFileSizeBytes: 1000),
        ),
      );
      expect(result!.items.map((m) => m.name), ['a.png', 'b.png']);
      expect(result.rejected.single.media.name, 'big.jpg');
      expect(result.rejected.single.reason, PickError.fileTooLarge);
      expect(result.error, isNull);
      expect(fake.lastLimit, 5);
    });

    testWidgets('multi pick reports the reason when everything is rejected', (
      tester,
    ) async {
      final ctx = await host(tester);
      fake.nextFiles = ['a.png'];
      final result = await tester.runAsync(
        () => AdaptiveMediaPicker().pickMultiImage(
          context: ctx,
          options: const PickOptions(allowedMimeTypes: ['video/*']),
        ),
      );
      expect(result!.items, isEmpty);
      expect(result.error, PickError.unsupportedType);
    });
  });

  group('pickMultiVideo', () {
    testWidgets('returns videos and caps them at maxImages', (tester) async {
      final ctx = await host(tester);
      fake.nextFiles = ['a.mp4', 'b.mov', 'c.mp4'];
      final result = await tester.runAsync(
        () => AdaptiveMediaPicker().pickMultiVideo(
          context: ctx,
          options: const PickOptions(maxImages: 2),
        ),
      );
      expect(result!.items.map((m) => m.mimeType), [
        'video/mp4',
        'video/quicktime',
      ]);
      expect(result.items.first.isVideo, isTrue);
    });
  });

  group('source sheet', () {
    testWidgets('Material sheet offers camera, gallery and remove', (
      tester,
    ) async {
      final ctx = await host(tester);
      final choice = showMediaSourceSheet(
        context: ctx,
        mediaType: MediaType.image,
        options: const SourceSheetOptions(
          title: 'Profile photo',
          removeLabel: 'Remove photo',
          style: SourceSheetStyle.material,
        ),
        cameraAvailable: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Profile photo'), findsOneWidget);
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      expect(await choice, MediaSourceChoice.remove);
    });

    testWidgets('adaptive style uses a Cupertino sheet on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ctx = await host(tester);
      final choice = showMediaSourceSheet(
        context: ctx,
        mediaType: MediaType.video,
        cameraAvailable: true,
      );
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Record video'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await choice, isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('skips the sheet when the gallery is the only option', (
      tester,
    ) async {
      final ctx = await host(tester);
      final choice = await showMediaSourceSheet(
        context: ctx,
        mediaType: MediaType.image,
        cameraAvailable: false,
      );
      expect(choice, MediaSourceChoice.gallery);
    });

    testWidgets('pick methods report remove and dismissal', (tester) async {
      final ctx = await host(tester);
      final picker = AdaptiveMediaPicker();
      const sheet = SourceSheetOptions(
        removeLabel: 'Remove',
        style: SourceSheetStyle.material,
      );

      var pending = picker.pickImage(context: ctx, sourceSheet: sheet);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      var result = await pending;
      expect(result.removeRequested, isTrue);
      expect(result.error, PickError.canceled);

      pending = picker.pickImage(context: ctx, sourceSheet: sheet);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // barrier
      await tester.pumpAndSettle();
      result = await pending;
      expect(result.removeRequested, isFalse);
      expect(result.error, PickError.canceled);
    });
  });

  group('mime helpers', () {
    test('sniffs common image signatures', () {
      expect(mimeTypeFromBytes(_png), 'image/png');
      expect(mimeTypeFromBytes(const [0xFF, 0xD8, 0xFF, 0xE0]), 'image/jpeg');
      expect(mimeTypeFromBytes(ascii.encode('GIF89a')), 'image/gif');
      expect(
        mimeTypeFromBytes(ascii.encode('RIFF\x00\x00\x00\x00WEBP')),
        'image/webp',
      );
      expect(mimeTypeFromBytes(const [1, 2, 3]), isNull);
    });

    test('matches exact and wildcard patterns', () {
      expect(mimeTypeMatches('image/*', 'image/png'), isTrue);
      expect(mimeTypeMatches('IMAGE/PNG', 'image/png'), isTrue);
      expect(mimeTypeMatches('*/*', 'video/mp4'), isTrue);
      expect(mimeTypeMatches('image/*', 'video/mp4'), isFalse);
      expect(mimeTypeMatches('image/jpeg', 'image/png'), isFalse);
    });
  });
}
