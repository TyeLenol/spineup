import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/screens/local_first_welcome_screen.dart';

void main() {
  testWidgets('local-first welcome starts private profile setup', (
    WidgetTester tester,
  ) async {
    var started = false;

    await tester.pumpWidget(
      MaterialApp(home: LocalFirstWelcomeScreen(onStart: () => started = true)),
    );

    expect(find.text('Set up a profile'), findsOneWidget);
    expect(find.text('Continue as guest'), findsNothing);

    await tester.tap(find.text('Set up a profile'));
    await tester.pump();

    expect(started, isTrue);
  });
}
