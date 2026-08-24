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
      expect(find.text('Make room'), findsOneWidget);
      expect(find.text('for care.'), findsOneWidget);

      // Verify subtext
      expect(
        find.textContaining('Keep check-ins, routines, and questions together'),
        findsOneWidget,
      );

      // Verify Next CTA button
      expect(find.text('Next'), findsOneWidget);

      // Advance to Screen 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify Screen 2 content
      expect(find.text('Care can'), findsOneWidget);
      expect(find.text('be shared.'), findsOneWidget);
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
    expect(find.text('Care can'), findsOneWidget);

    // Step 2 -> Step 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your path'), findsOneWidget);
    expect(find.text('close.'), findsOneWidget);
    expect(find.text('Set up my space'), findsOneWidget);
  });
}
