import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

/// Centralized Material 3 Motion & Transitions Utility.
///
/// Strictly adheres to M3 motion guidelines:
/// - **Top Level**: [FadeThroughTransition] for navigation tabs.
/// - **Forward & Backward**: Smooth horizontal slide for step/hierarchy navigation.
/// - **Reduced Motion**: Automatically checks [MediaQuery.of(context).disableAnimations]
///   and falls back to non-disorienting subtle fades.
abstract class AppTransitions {
  /// Checks whether reduced motion is enabled at the OS level.
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// M3 Top-Level transition for bottom nav tab switching (Today, My Journey, Community).
  ///
  /// Fades exiting screen out, then fades entering screen in.
  /// If reduced motion is enabled, uses a simple static fade.
  static Widget buildTopLevelTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    if (isReducedMotion(context)) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.linear),
        child: child,
      );
    }
    return FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }

  /// M3 Forward & Backward step sequence route transition.
  ///
  /// Horizontal slide with cubic curve `[0.32, 0.72, 0.0, 1.0]`.
  /// If reduced motion is enabled, falls back to an accessible fade transition.
  static Route<T> buildForwardBackwardRoute<T>({
    required WidgetBuilder pageBuilder,
    Duration duration = const Duration(milliseconds: 500),
    Duration reverseDuration = const Duration(milliseconds: 360),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => pageBuilder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (isReducedMotion(context)) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        }

        final isPopping = animation.status == AnimationStatus.reverse;
        final isReentering = secondaryAnimation.status == AnimationStatus.reverse;

        double slideX = 0.0;

        if (secondaryAnimation.value > 0) {
          final curve = CurvedAnimation(
            parent: secondaryAnimation,
            curve: const Cubic(0.32, 0.72, 0.0, 1.0),
          );
          slideX = isReentering ? curve.value : -curve.value;
        } else {
          final curve = CurvedAnimation(
            parent: animation,
            curve: const Cubic(0.32, 0.72, 0.0, 1.0),
          );
          slideX = isPopping ? -(1.0 - curve.value) : (1.0 - curve.value);
        }

        return FractionalTranslation(
          translation: Offset(slideX, 0.0),
          child: child,
        );
      },
    );
  }

  /// Pure Fade transition route (no sliding).
  static Route<T> buildFadeRoute<T>({
    required WidgetBuilder pageBuilder,
    Duration duration = const Duration(milliseconds: 350),
    Duration reverseDuration = const Duration(milliseconds: 250),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => pageBuilder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }

  /// Classy M3 Emphasized Decelerate entrance route (no bounce, zero rubber-banding).
  ///
  /// Uses M3 `md.sys.motion.easing.emphasized.decelerate` (`Cubic(0.05, 0.7, 0.1, 1.0)`)
  /// over 520ms (`md.sys.motion.duration.long2`) for a sleek, unhurried, premium slide entrance.
  static Route<T> buildEmphasizedDecelerateRoute<T>({
    required WidgetBuilder pageBuilder,
    Duration duration = const Duration(milliseconds: 520),
    Duration reverseDuration = const Duration(milliseconds: 380),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => pageBuilder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (isReducedMotion(context)) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        }

        final curve = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.05, 0.7, 0.1, 1.0),
          reverseCurve: const Cubic(0.3, 0.0, 0.8, 0.15),
        );

        return FractionalTranslation(
          translation: Offset(1.0 - curve.value, 0.0),
          child: child,
        );
      },
    );
  }

  /// Classy M3 Peer Cross-Fade route for switching modes (e.g. Login ↔ Sign-up).
  static Route<T> buildCrossFadeRoute<T>({
    required WidgetBuilder pageBuilder,
    Duration duration = const Duration(milliseconds: 320),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => pageBuilder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (isReducedMotion(context)) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.linear),
            child: child,
          );
        }
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
          child: child,
        );
      },
    );
  }
}
