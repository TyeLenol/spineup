import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Screen 3 Odometer count-up counter (+0 to +120 over 0.9s), landing with a spring scale bounce.
class CountUpWidget extends StatefulWidget {
  final int to;
  final Color color;

  const CountUpWidget({super.key, required this.to, required this.color});

  @override
  State<CountUpWidget> createState() => _CountUpWidgetState();
}

class _CountUpWidgetState extends State<CountUpWidget>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late AnimationController _scaleController;

  int _displayValue = 0;

  @override
  void initState() {
    super.initState();

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final countAnimation = IntTween(begin: 0, end: widget.to).animate(
      CurvedAnimation(
        parent: _countController,
        curve: const Cubic(0.05, 0.7, 0.1, 1.0),
      ),
    );

    countAnimation.addListener(() {
      setState(() {
        _displayValue = countAnimation.value;
      });
    });

    _countController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerBounce();
      }
    });

    _scaleController = AnimationController.unbounded(vsync: this);
    _scaleController.value = 1.0;
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _startCount();
    }
  }

  void _startCount() {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      _displayValue = widget.to;
      _scaleController.value = 1.0;
    } else {
      _countController.forward(from: 0.0);
    }
  }

  void _triggerBounce() {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) return;

    // Spring scale bounce: 1.0 -> 1.18 -> 1.0 (stiffness: 320, damping: 9)
    final simulation = SpringSimulation(
      const SpringDescription(mass: 1.0, stiffness: 320.0, damping: 9.0),
      1.18, // start overshoot target
      1.0, // final rest
      0.0,
    );
    _scaleController.animateWith(simulation);
  }

  @override
  void didUpdateWidget(covariant CountUpWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.to != widget.to) {
      _startCount();
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleController.value,
          child: Text(
            '+$_displayValue',
            style: TextStyle(
              color: widget.color,
              fontFamily: 'serif',
              fontSize: 48.0,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
      },
    );
  }
}
