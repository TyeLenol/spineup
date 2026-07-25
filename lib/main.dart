import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_transitions.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/illustrations/ob1_illustration.dart';
import 'screens/illustrations/ob2_illustration.dart';
import 'screens/illustrations/ob3_illustration.dart';
import 'screens/navigation_shell.dart';
import 'screens/auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpineUpApp());
}

class SpineUpApp extends StatelessWidget {
  const SpineUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpineUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Always keep cream canvas behind all routes — prevents black flash
      // when one Scaffold fades out before the next one appears.
      builder: (context, child) => Container(
        color: AppTheme.backgroundCream,
        child: child,
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── Page Routes ─────────────────────────────────────────────────────────────

/// Pushes the onboarding screen with pure fade transition (no slide).
Route<void> onboardingRoute(int step) {
  return AppTransitions.buildFadeRoute<void>(
    duration: const Duration(milliseconds: 350),
    pageBuilder: (context) {
      if (step == 3) {
        return OnboardingScreen(
          step: 3,
          titlePlain: 'Connect with\npeople who\n',
          titleAccent: 'actually get it.',
          accentColor: AppTheme.secondaryCoral,
          description:
              'Share wins, ask questions, and swap tips with others managing '
              'scoliosis — in a space built just for that.',
          illustration: const Ob3Illustration(),
          isLast: true,
          onNext: () => Navigator.of(context).push(authRoute(AuthMode.signup)),
          onBack: () => Navigator.of(context).pop(),
          onSkip: () => Navigator.of(context).push(authRoute(AuthMode.signup)),
        );
      }

      if (step == 2) {
        return OnboardingScreen(
          step: 2,
          titlePlain: 'Build a habit\nthat actually ',
          titleAccent: 'sticks.',
          accentColor: AppTheme.primarySage,
          description:
              'Log your symptom journal, hit your streak, and unlock new '
              'styles for your avatar.',
          illustration: const Ob2Illustration(),
          onNext: () => Navigator.of(context).push(onboardingRoute(3)),
          onBack: () => Navigator.of(context).pop(),
          onSkip: () => Navigator.of(context).push(authRoute(AuthMode.signup)),
        );
      }

      // Default: Step 1
      return OnboardingScreen(
        step: 1,
        titlePlain: 'Track your curve,\n',
        titleAccent: 'earn your rewards.',
        description:
            'A daily habit tracker designed for your scoliosis journey. '
            'Turn your exercises into progress.',
        illustration: const Ob1Illustration(),
        onNext: () => Navigator.of(context).push(onboardingRoute(2)),
        onSkip: () => Navigator.of(context).push(authRoute(AuthMode.signup)),
      );
    },
  );
}

/// Auth route — handles both entrance slide and peer cross-fade mode switching.
Route<void> authRoute(AuthMode mode, {bool isCrossFade = false}) {
  Widget buildPage(BuildContext context) {
    return AuthScreen(
      mode: mode,
      onBack: () => Navigator.of(context).maybePop(),
      onSwitchMode: (newMode) {
        Navigator.of(context).pushReplacement(authRoute(newMode, isCrossFade: true));
      },
      onSuccess: () => Navigator.of(context).pushReplacement(mainAppRoute()),
    );
  }

  if (isCrossFade) {
    return AppTransitions.buildCrossFadeRoute<void>(
      duration: const Duration(milliseconds: 320),
      pageBuilder: buildPage,
    );
  }

  return AppTransitions.buildEmphasizedDecelerateRoute<void>(
    duration: const Duration(milliseconds: 520),
    pageBuilder: buildPage,
  );
}

Route<void> mainAppRoute() {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const NavigationShell(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (AppTransitions.isReducedMotion(context)) {
        return child;
      }
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

