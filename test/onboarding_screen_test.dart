import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/theme/app_theme.dart';
import 'package:spineup/screens/onboarding_screen.dart';

void main() {
  testWidgets(
    'OnboardingScreen renders the private-space headline and Next button',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen 1 headline text
      expect(find.text('A calmer place'), findsOneWidget);
      expect(find.text('to keep care together.'), findsOneWidget);

      // Verify subtext
      expect(
        find.textContaining('Build a simple record of check-ins'),
        findsOneWidget,
      );

      // Verify Next CTA button
      expect(find.text('Next'), findsOneWidget);

      // Advance to Screen 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify Screen 2 content
      expect(find.text('Made for real life,'), findsOneWidget);
      expect(find.text('and real support.'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    },
  );

  testWidgets('OnboardingScreen navigates through all 3 screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Step 1 -> Step 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Made for real life,'), findsOneWidget);

    // Step 2 -> Step 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your records'), findsOneWidget);
    expect(find.text('stay in your hands.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
