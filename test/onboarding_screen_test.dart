import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/theme/app_theme.dart';
import 'package:spineup/screens/onboarding_screen.dart';

void main() {
  testWidgets(
    'OnboardingScreen renders Screen 1 headline, subtext, and Next button',
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
      expect(find.text('Your spine has a story.'), findsOneWidget);
      expect(find.text("Let's track it."), findsOneWidget);

      // Verify subtext
      expect(
        find.textContaining('Log brace time and exercises daily'),
        findsOneWidget,
      );

      // Verify Next CTA button
      expect(find.text('Next'), findsOneWidget);

      // Advance to Screen 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify Screen 2 content
      expect(find.text('Every stretch counts'), findsOneWidget);
      expect(find.text('toward something.'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    },
  );

  testWidgets('OnboardingScreen navigates through all 5 screens', (
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
    expect(find.text('Every stretch counts'), findsOneWidget);

    // Step 2 -> Step 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Show up,'), findsOneWidget);

    // Step 3 -> Step 4
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Clear answers,'), findsOneWidget);

    // Step 4 -> Step 5
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your data'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
