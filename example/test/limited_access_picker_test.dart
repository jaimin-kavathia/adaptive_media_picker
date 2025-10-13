import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_media_picker/src/ui/limited_access_picker.dart';

void main() {
  testWidgets('LimitedAccessPicker shows scaffold structure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LimitedAccessPicker(allowMultiple: true, maxImages: 3))),
    );

    // AppBar title should be for images by default
    expect(find.text('Select images'), findsOneWidget);
    // When allowMultiple is true, Done button exists but disabled initially
    expect(find.text('Done'), findsOneWidget);
  });
}
