import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/theme/app_theme.dart';
import 'package:spineup/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders logo and title text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SplashScreen(
          duration: Duration(seconds: 5),
        ),
      ),
    );

    // Initial render: intro animation starts
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Logo text should be visible after intro fade-in
    expect(find.text('SpineUp'), findsOneWidget);
  });
}
