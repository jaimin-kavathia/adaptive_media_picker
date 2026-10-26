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
    expect(find.text('Media Picker Demo'), findsOneWidget);
    // Buttons present
    expect(find.text('Pick image (gallery)'), findsOneWidget);
    expect(find.text('Pick multiple images (gallery)'), findsOneWidget);
    expect(find.text('Pick video (gallery)'), findsOneWidget);

    // Initial status label
    expect(find.text('Ready'), findsOneWidget);

    // Tap a button to ensure no exceptions in basic interaction; we don't assert result content here.
    await tester.tap(find.text('Pick image (gallery)'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    // No picker plugin in tests, so the pick fails; the status must update.
    expect(find.text('Ready'), findsNothing);
  });
}
