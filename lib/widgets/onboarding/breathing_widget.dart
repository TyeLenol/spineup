import 'package:flutter/material.dart';

/// Screen 1 Breathing loop: infinite repeating scale animation (1 -> 1.055 -> 1, 2.6s, easeInOut).
/// When reduced motion is enabled, skips scale animation entirely.
class BreathingWidget extends StatefulWidget {
  final Widget child;
  const BreathingWidget({super.key, required this.child});

  @override
  State<BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.055).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.055, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (!MediaQuery.of(context).disableAnimations) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      return widget.child;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
