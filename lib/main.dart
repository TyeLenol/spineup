import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_transitions.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/navigation_shell.dart';
import 'screens/profile_setup/profile_setup_screen.dart';
import 'screens/local_first_welcome_screen.dart';
import 'services/session_service.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpineUpApp());
}

class SpineUpApp extends StatelessWidget {
  /// Override the splash screen duration — useful in tests to set [Duration.zero].
  final Duration? splashDuration;

  const SpineUpApp({super.key, this.splashDuration});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'SpineUp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          // Always keep cream canvas behind all routes — prevents black flash
          // when one Scaffold fades out before the next one appears.
          builder: (context, child) =>
              Container(color: AppTheme.backgroundCream, child: child),
          home: SplashScreen(
            duration: splashDuration ?? const Duration(milliseconds: 4500),
          ),
        );
      },
    );
  }
}

// ─── Page Routes ─────────────────────────────────────────────────────────────

/// Pushes the onboarding screen with pure fade transition (no slide).
Route<void> onboardingRoute([int step = 1]) {
  return AppTransitions.buildFadeRoute<void>(
    duration: const Duration(milliseconds: 350),
    pageBuilder: (context) => const OnboardingScreen(),
  );
}

Route<void> localFirstWelcomeRoute() {
  return AppTransitions.buildEmphasizedDecelerateRoute<void>(
    duration: const Duration(milliseconds: 420),
    pageBuilder: (context) => LocalFirstWelcomeScreen(
      onStart: () {
        SessionService.startMockSession();
        Navigator.of(context).pushReplacement(profileSetupRoute());
      },
    ),
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

/// Profile Setup route — fade in
Route<void> profileSetupRoute() {
  return AppTransitions.buildFadeRoute<void>(
    duration: const Duration(milliseconds: 350),
    pageBuilder: (context) => const ProfileSetupScreen(),
  );
}
