import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/theme/app_theme.dart';
import 'package:spineup/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders logo, title text, and handles tap to finish',
      (WidgetTester tester) async {
    bool finished = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SplashScreen(
          duration: const Duration(seconds: 5),
          onFinish: () {
            finished = true;
          },
        ),
      ),
    );

    // Initial render
    expect(find.text('SpineUp'), findsOneWidget);
    expect(finished, isFalse);

    // Advance animation
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Tap to finish early
    await tester.tap(find.byType(SplashScreen));
    await tester.pump();

    expect(finished, isTrue);
  });
}
