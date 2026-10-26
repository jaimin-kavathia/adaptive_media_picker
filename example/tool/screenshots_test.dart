// Regenerates the README images in ../assets/images from the real widgets.
//
//   cd example && flutter test tool/screenshots_test.dart
//
// Sample photos are drawn in code, so no personal media ends up in the repo.

// ignore_for_file: implementation_imports

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:adaptive_media_picker/adaptive_media_picker.dart';
import 'package:adaptive_media_picker/src/ui/crop_page.dart';
import 'package:example/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

const Size _phone = Size(390, 844);
const double _scale = 2;
final String _out = '../assets/images';

void main() {
  late Directory tmp;
  late Map<String, String> photos;

  setUpAll(() async {
    await _loadFonts();
    PermissionManager.bypassPlatformChannelsForTests = true;
    tmp = Directory.systemTemp.createTempSync('amp_shots');
  });

  tearDownAll(() => tmp.deleteSync(recursive: true));

  final Map<String, Uint8List> screens = {};

  testWidgets('generate screenshots', (tester) async {
    photos = (await tester.runAsync(() => _writePhotos(tmp)))!;
    final picker = _FakePicker(photos);
    ImagePickerPlatform.instance = picker;
    tester.view.physicalSize = _phone * _scale;
    tester.view.devicePixelRatio = _scale;
    addTearDown(tester.view.reset);

    // 1. Results list after a multi pick.
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const ExampleApp()),
    );
    picker.next = ['portrait.png'];
    await tester.tap(find.byType(GestureDetector).first); // avatar
    await _settle(tester);
    await tester.tap(find.text('Choose from gallery'));
    await _settle(tester);
    picker.next = ['mountains.png', 'beach.png', 'city.png', 'forest.png'];
    await tester.tap(find.text('Pick multiple images (gallery)'));
    await _settle(tester);
    screens['results'] = await _capture(tester, key);

    // 2. Material source sheet (with "Remove photo", since an avatar is set).
    await tester.tap(find.byType(GestureDetector).first);
    await _settle(tester);
    screens['sheet_material'] = await _capture(tester, key);
    await tester.tapAt(const Offset(20, 20));
    await _settle(tester);

    // 3. Cupertino source sheet on iOS.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const ExampleApp(key: ValueKey('ios')),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('Pick image (choose source)'));
    await _settle(tester);
    screens['sheet_ios'] = await _capture(tester, key);
    debugDefaultTargetPlatformOverride = null;

    // 4./5. Built-in crop editor: circle and ratio presets.
    final Uint8List portrait = File(photos['portrait.png']!).readAsBytesSync();
    final Uint8List mountains = File(
      photos['mountains.png']!,
    ).readAsBytesSync();
    for (final (name, image, circle, ratio) in [
      ('crop_circle', portrait, true, null),
      ('crop_ratio', mountains, false, CropAspectRatioOption.ratio16x9),
    ]) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            ),
            home: BuiltInCropPage(
              key: ValueKey(name),
              image: image,
              circle: circle,
              aspectRatio: ratio,
            ),
          ),
        ),
      );
      await _settle(tester, rounds: 40);
      screens[name] = await _capture(tester, key);
    }

    for (final MapEntry(:key, :value) in screens.entries) {
      File('$_out/screen_$key.png').writeAsBytesSync(value);
    }

    // 6. Banner composed from the real screens.
    tester.view.physicalSize = const Size(1280, 640) * 1.5;
    tester.view.devicePixelRatio = 1.5;
    for (final bytes in screens.values) {
      await tester.runAsync(
        () =>
            precacheImage(MemoryImage(bytes), tester.element(find.byKey(key))),
      );
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: _Banner(
          screens: [
            screens['sheet_ios']!,
            screens['crop_circle']!,
            screens['results']!,
          ],
        ),
      ),
    );
    await _settle(tester);
    File(
      '$_out/banner.png',
    ).writeAsBytesSync(await _capture(tester, key, pixelRatio: 1.5));
  });
}

/// Pumps frames while letting real async work (file IO, decoding) finish.
Future<void> _settle(WidgetTester tester, {int rounds = 15}) async {
  for (int i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<Uint8List> _capture(
  WidgetTester tester,
  GlobalKey key, {
  double pixelRatio = _scale,
}) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

Future<void> _loadFonts() async {
  // <flutter>/bin/cache/artifacts/engine/<platform>/flutter_tester
  final Directory artifacts = File(
    Platform.resolvedExecutable,
  ).parent.parent.parent;
  final String fonts = '${artifacts.path}/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File('$fonts/$f').readAsBytesSync())),
      );
    }
    await loader.load();
  }

  const roboto = [
    'roboto-light.ttf',
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ];
  await load('MaterialIcons', ['materialicons-regular.otf']);
  for (final family in [
    'Roboto',
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
    '.SF Pro Text',
    '.SF Pro Display',
    '.SF UI Text',
    '.SF UI Display',
  ]) {
    await load(family, roboto);
  }
}

class _FakePicker extends ImagePickerPlatform {
  _FakePicker(this.photos);

  final Map<String, String> photos;
  List<String> next = const [];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => next.isEmpty ? null : XFile(photos[next.first]!);

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async => [for (final n in next) XFile(photos[n]!)];

  @override
  Future<LostDataResponse> getLostData() async => LostDataResponse.empty();
}

// ---------------------------------------------------------------------------
// Sample "photos", drawn in code.

Future<Map<String, String>> _writePhotos(Directory dir) async {
  final scenes = <String, void Function(Canvas, Size)>{
    'portrait.png': _portrait,
    'mountains.png': _mountains,
    'beach.png': _beach,
    'city.png': _city,
    'forest.png': _forest,
  };
  final out = <String, String>{};
  for (final MapEntry(:key, :value) in scenes.entries) {
    final size = key == 'portrait.png'
        ? const Size(1000, 1000)
        : const Size(1200, 900);
    final recorder = ui.PictureRecorder();
    value(Canvas(recorder), size);
    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${dir.path}/$key')
      ..writeAsBytesSync(data!.buffer.asUint8List());
    out[key] = file.path;
  }
  return out;
}

void _sky(Canvas c, Size s, List<Color> colors) {
  c.drawRect(
    Offset.zero & s,
    Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), colors, [
        for (int i = 0; i < colors.length; i++) i / (colors.length - 1),
      ]),
  );
}

Path _ridge(Size s, double base, double amp, double freq, double phase) {
  final p = Path()..moveTo(0, s.height);
  for (double x = 0; x <= s.width; x += 10) {
    final y =
        base +
        math.sin(x / s.width * freq * math.pi + phase) * amp +
        math.sin(x / s.width * freq * 2.7 * math.pi) * amp * 0.35;
    p.lineTo(x, y);
  }
  return p
    ..lineTo(s.width, s.height)
    ..close();
}

void _mountains(Canvas c, Size s) {
  _sky(c, s, const [Color(0xFF2B2D6E), Color(0xFFE8746A), Color(0xFFF7C873)]);
  c.drawCircle(
    Offset(s.width * 0.68, s.height * 0.52),
    90,
    Paint()..color = const Color(0xFFFFE3A3),
  );
  c.drawPath(
    _ridge(s, s.height * 0.55, 90, 3, 0.4),
    Paint()..color = const Color(0xFF7A4E7E),
  );
  c.drawPath(
    _ridge(s, s.height * 0.68, 70, 4, 1.7),
    Paint()..color = const Color(0xFF4B3566),
  );
  c.drawPath(
    _ridge(s, s.height * 0.82, 40, 5, 2.4),
    Paint()..color = const Color(0xFF2A2142),
  );
}

void _beach(Canvas c, Size s) {
  _sky(c, s, const [Color(0xFF6EC6F5), Color(0xFFBDE8FF)]);
  c.drawCircle(
    Offset(s.width * 0.2, s.height * 0.22),
    70,
    Paint()..color = const Color(0xFFFFF4C2),
  );
  c.drawRect(
    Rect.fromLTWH(0, s.height * 0.5, s.width, s.height * 0.25),
    Paint()..color = const Color(0xFF1E88C7),
  );
  c.drawPath(
    _ridge(s, s.height * 0.72, 18, 6, 0),
    Paint()..color = const Color(0xFFF3D9A4),
  );
  c.drawPath(
    _ridge(s, s.height * 0.7, 14, 6, 0.6),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8,
  );
}

void _city(Canvas c, Size s) {
  _sky(c, s, const [Color(0xFF0F1335), Color(0xFF3B2A6B)]);
  final rnd = math.Random(7);
  for (int i = 0; i < 60; i++) {
    c.drawCircle(
      Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.5),
      rnd.nextDouble() * 2.5 + 0.5,
      Paint()..color = Colors.white70,
    );
  }
  double x = 0;
  while (x < s.width) {
    final w = 70 + rnd.nextDouble() * 90;
    final h = s.height * (0.3 + rnd.nextDouble() * 0.4);
    final r = Rect.fromLTWH(x, s.height - h, w - 6, h);
    c.drawRect(r, Paint()..color = const Color(0xFF1C1F4A));
    for (double wy = r.top + 16; wy < r.bottom - 10; wy += 26) {
      for (double wx = r.left + 10; wx < r.right - 14; wx += 20) {
        if (rnd.nextDouble() < 0.45) {
          c.drawRect(
            Rect.fromLTWH(wx, wy, 9, 13),
            Paint()..color = const Color(0xFFFFD27A),
          );
        }
      }
    }
    x += w;
  }
}

void _forest(Canvas c, Size s) {
  _sky(c, s, const [Color(0xFFCDEFD8), Color(0xFF8FD3A5)]);
  final rnd = math.Random(3);
  for (final (base, color) in [
    (0.62, const Color(0xFF5DAA78)),
    (0.78, const Color(0xFF2F7A50)),
    (0.95, const Color(0xFF1B4D33)),
  ]) {
    for (double x = -40; x < s.width + 40; x += 55 + rnd.nextDouble() * 40) {
      final h = 160 + rnd.nextDouble() * 160;
      final y = s.height * base;
      c.drawPath(
        Path()
          ..moveTo(x, y - h)
          ..lineTo(x - h * 0.32, y)
          ..lineTo(x + h * 0.32, y)
          ..close(),
        Paint()..color = color,
      );
    }
  }
}

void _portrait(Canvas c, Size s) {
  c.drawRect(
    Offset.zero & s,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(s.width * 0.5, s.height * 0.35),
        s.width * 0.7,
        const [Color(0xFFFFD5B8), Color(0xFFF08A9B), Color(0xFF7D5BD6)],
        const [0, 0.55, 1],
      ),
  );
  final center = Offset(s.width / 2, s.height * 0.42);
  // Shoulders
  c.drawOval(
    Rect.fromCenter(
      center: Offset(center.dx, s.height * 1.02),
      width: 620,
      height: 520,
    ),
    Paint()..color = const Color(0xFF2E3A8C),
  );
  // Neck and head
  c.drawRect(
    Rect.fromCenter(
      center: Offset(center.dx, s.height * 0.66),
      width: 110,
      height: 120,
    ),
    Paint()..color = const Color(0xFFE0A47C),
  );
  c.drawCircle(center, 150, Paint()..color = const Color(0xFFF1BE95));
  // Hair
  c.drawArc(
    Rect.fromCircle(center: center.translate(0, -12), radius: 162),
    math.pi * 1.02,
    math.pi * 0.96,
    true,
    Paint()..color = const Color(0xFF3B2416),
  );
  // Eyes and smile
  final dark = Paint()..color = const Color(0xFF3B2416);
  c.drawCircle(center.translate(-52, 18), 11, dark);
  c.drawCircle(center.translate(52, 18), 11, dark);
  c.drawArc(
    Rect.fromCenter(center: center.translate(0, 62), width: 90, height: 50),
    0.15 * math.pi,
    0.7 * math.pi,
    false,
    Paint()
      ..color = const Color(0xFFB4523F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round,
  );
}

// ---------------------------------------------------------------------------

class _Banner extends StatelessWidget {
  const _Banner({required this.screens});

  final List<Uint8List> screens;

  @override
  Widget build(BuildContext context) {
    const chips = [
      'Permissions',
      'Camera / gallery sheet',
      'Crop · circle',
      'Validation',
      'Web · WASM · Desktop',
    ];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF7C3AED)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 0, 40, 0),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adaptive\nMedia Picker',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 60,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Images & videos for Flutter, with permissions,\n'
                      'cropping and validation handled for you.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 22,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in chips)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              child: Text(
                                c,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < screens.length; i++)
                      Transform.translate(
                        offset: Offset(0, i == 1 ? -24 : 24),
                        child: _PhoneFrame(image: screens[i]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.image});

  final Uint8List image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190 * _phone.height / _phone.width,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B12),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.memory(image, fit: BoxFit.cover),
      ),
    );
  }
}
