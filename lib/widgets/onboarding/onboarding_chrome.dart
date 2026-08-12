import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// ProgressDots displays step pills (active step: 16dp wide pill, inactive: 6dp dot).
class ProgressDots extends StatelessWidget {
  final int step;
  final int total;
  final Color tint;

  const ProgressDots({
    super.key,
    required this.step,
    this.total = 5,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Onboarding progress: step $step of $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) {
          final isCurrent = i + 1 == step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 3.0),
            height: 4.0,
            width: isCurrent ? 16.0 : 6.0,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: isCurrent ? 1.0 : 0.55),
              borderRadius: BorderRadius.circular(2.0),
            ),
          );
        }),
      ),
    );
  }
}

/// 48dp minimum touch target tonal icon button.
class OnboardingIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onClick;
  final Color tint;

  const OnboardingIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onClick,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(24.0),
        child: Container(
          width: 48.0,
          height: 48.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: tint,
            size: 20.0,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}

/// 48dp minimum touch target small text link.
class OnboardingSmallLink extends StatelessWidget {
  final String text;
  final VoidCallback onClick;
  final Color tint;
  final String? ariaLabel;

  const OnboardingSmallLink({
    super.key,
    required this.text,
    required this.onClick,
    required this.tint,
    this.ariaLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            text,
            semanticsLabel: ariaLabel ?? text,
            style: TextStyle(
              color: tint,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Announces step changes to screen readers.
class StepAnnouncer extends StatefulWidget {
  final String message;
  const StepAnnouncer({super.key, required this.message});

  @override
  State<StepAnnouncer> createState() => _StepAnnouncerState();
}

class _StepAnnouncerState extends State<StepAnnouncer> {
  @override
  void initState() {
    super.initState();
    _announce();
  }

  @override
  void didUpdateWidget(covariant StepAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _announce();
    }
  }

  void _announce() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final view = View.maybeOf(context);
      if (view != null) {
        SemanticsService.sendAnnouncement(view, widget.message, TextDirection.ltr);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
