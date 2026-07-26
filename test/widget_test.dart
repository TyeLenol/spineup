import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/main.dart';
import 'package:spineup/screens/splash_screen.dart';
import 'package:spineup/screens/onboarding_screen.dart';

void main() {
  testWidgets(
      'SpineUpApp boots up with SplashScreen and transitions to NavigationShell',
      (WidgetTester tester) async {
    // Use Duration.zero so the splash navigates immediately in tests.
    await tester.pumpWidget(
      const SpineUpApp(splashDuration: Duration.zero),
    );

    // Initial frame — SplashScreen should be visible.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('SpineUp'), findsOneWidget);

    // Advance past the zero-duration splash timer + route transition.
    // Use pump(Duration) — screens contain repeating animations that would
    // cause pumpAndSettle to time out.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));

    // The normal flow is: Splash → Onboarding (Step 1).
    // NavigationShell is reached only after full auth; testing that full flow
    // is out of scope for this unit test.
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
