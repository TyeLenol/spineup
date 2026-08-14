import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/screens/auth_screen.dart';

void main() {
  testWidgets('guest confirmation uses the dedicated guest callback', (
    WidgetTester tester,
  ) async {
    var normalSuccessCalled = false;
    var guestSuccessCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          mode: AuthMode.login,
          onBack: () {},
          onSwitchMode: (_) {},
          onSuccess: () => normalSuccessCalled = true,
          onGuestSuccess: () => guestSuccessCalled = true,
        ),
      ),
    );

    await tester.tap(find.text('Continue as guest'));
    await tester.pump();
    expect(find.text('Continue as guest?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();

    expect(guestSuccessCalled, isTrue);
    expect(normalSuccessCalled, isFalse);
  });
}
