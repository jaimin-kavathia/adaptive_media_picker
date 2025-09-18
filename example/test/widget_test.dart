// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('renders ExampleApp and expected controls', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    // AppBar title
    expect(find.text('adaptive_media_picker example'), findsOneWidget);
    // Buttons present
    expect(find.text('Pick image (gallery)'), findsOneWidget);
    expect(find.text('Pick multiple images (gallery)'), findsOneWidget);
    expect(find.text('Pick video (gallery)'), findsOneWidget);

    // Initial status label
    expect(find.text('Ready'), findsOneWidget);

    // Tap a button to ensure no exceptions in basic interaction; we don't assert result content here.
    await tester.tap(find.text('Pick image (gallery)'));
    await tester.pump();

    // Status should update to 'Requesting...' then to some value after async; allow a short settle.
    // We only check it changes from initial to avoid flakiness in headless envs.
    expect(find.text('Ready'), findsNothing);
  });
}
