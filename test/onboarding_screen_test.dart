import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/theme/app_theme.dart';
import 'package:spineup/screens/onboarding_screen.dart';
import 'package:spineup/screens/illustrations/ob1_illustration.dart';
import 'package:spineup/screens/illustrations/ob2_illustration.dart';

void main() {
  testWidgets('OnboardingScreen Step 1 renders headline, description, skip and next buttons',
      (WidgetTester tester) async {
    bool nextPressed = false;
    bool skipPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: OnboardingScreen(
          step: 1,
          titlePlain: 'Track your curve,',
          titleAccent: 'earn your rewards.',
          description:
              'A daily habit tracker designed for your scoliosis journey. Turn your exercises into progress.',
          illustration: const Ob1Illustration(),
          onNext: () => nextPressed = true,
          onSkip: () => skipPressed = true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify RichText headline exists
    expect(find.byType(RichText), findsWidgets);
    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    final hasHeadline = richTexts.any(
      (r) => r.text.toPlainText().contains('Track your curve'),
    );
    expect(hasHeadline, isTrue);

    // Verify description
    expect(
      find.text(
        'A daily habit tracker designed for your scoliosis journey. Turn your exercises into progress.',
      ),
      findsOneWidget,
    );

    // Verify Skip and Next buttons
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(nextPressed, isTrue);

    // Tap Skip
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(skipPressed, isTrue);
  });

  testWidgets('OnboardingScreen Step 2 renders back button and dynamic title color',
      (WidgetTester tester) async {
    bool backPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: OnboardingScreen(
          step: 2,
          titlePlain: 'Build a habit\nthat actually ',
          titleAccent: 'sticks.',
          accentColor: AppTheme.primarySage,
          description:
              'Log your symptom journal, hit your streak, and unlock new styles for your avatar.',
          illustration: const Ob2Illustration(),
          onNext: () {},
          onBack: () => backPressed = true,
          onSkip: () {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify back button chevron exists
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pump();
    expect(backPressed, isTrue);
  });
}
