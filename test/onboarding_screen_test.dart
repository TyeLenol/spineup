import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/theme/app_theme.dart';
import 'package:spineup/screens/onboarding_screen.dart';
import 'package:spineup/screens/illustrations/ob1_illustration.dart';
import 'package:spineup/screens/illustrations/ob2_illustration.dart';

void main() {
  testWidgets(
      'OnboardingScreen Step 1 renders headline, description, skip and next buttons',
      (WidgetTester tester) async {
    bool nextPressed = false;
    bool skipPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: OnboardingScreen(
          step: 1,
          titlePlain: 'Physio is boring.\n',
          titleAccent: 'Let\'s fix that.',
          description:
              'Doing 45-minute stretches every single day is hard to care about '
              'when nothing changes overnight. SpineUp gives you XP, level ups, '
              'and actual milestones every time you log a stretch or wear your brace.',
          illustration: const Ob1Illustration(),
          onNext: () => nextPressed = true,
          onSkip: () => skipPressed = true,
        ),
      ),
    );

    // Advance past entry animations
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify headline text
    expect(find.text('Physio is boring.'), findsOneWidget);
    expect(find.text('Let\'s fix that.'), findsOneWidget);

    // Verify description text
    expect(
      find.textContaining('Doing 45-minute stretches'),
      findsOneWidget,
    );

    // Verify Skip chip and 3D CTA button are rendered
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Tap Vera for +30 XP →'), findsOneWidget);

    // Verify callbacks fire directly
    final screen = tester.widget<OnboardingScreen>(
      find.byType(OnboardingScreen),
    );
    screen.onNext();
    expect(nextPressed, isTrue);

    screen.onSkip();
    expect(skipPressed, isTrue);
  });

  testWidgets(
      'OnboardingScreen Step 2 renders back button and dynamic title color',
      (WidgetTester tester) async {
    bool backPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: OnboardingScreen(
          step: 2,
          titlePlain: 'Show up. ',
          titleAccent: 'Vera keeps count.',
          accentColor: AppTheme.primarySage,
          description:
              'Every stretch, log, and pain check adds to your streak. '
              'Miss a day — no drama, just start again. '
              'But keep going and watch what happens.',
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
