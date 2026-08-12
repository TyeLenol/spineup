import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Material 3 Expressive Squiggly Line components.
///
/// Renders GPU-accelerated wavy bezier curves with dynamic phase ripple animation.

/// Animated squiggly underline for accent headline phrases.
class M3SquigglyUnderline extends StatefulWidget {
  final double width;
  final Color color;
  final double strokeWidth;
  final double amplitude;
  final double frequency;

  const M3SquigglyUnderline({
    super.key,
    required this.width,
    this.color = AppTheme.secondaryCoral,
    this.strokeWidth = 3.5,
    this.amplitude = 3.0,
    this.frequency = 0.08,
  });

  @override
  State<M3SquigglyUnderline> createState() => _M3SquigglyUnderlineState();
}

class _M3SquigglyUnderlineState extends State<M3SquigglyUnderline>
    with SingleTickerProviderStateMixin {
  late AnimationController _phaseCtrl;

  @override
  void initState() {
    super.initState();
    _phaseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _phaseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _phaseCtrl,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.amplitude * 2 + widget.strokeWidth),
          painter: _SquigglyPathPainter(
            phase: _phaseCtrl.value * 2 * math.pi,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
            amplitude: widget.amplitude,
            frequency: widget.frequency,
          ),
        );
      },
    );
  }
}

class _SquigglyPathPainter extends CustomPainter {
  final double phase;
  final Color color;
  final double strokeWidth;
  final double amplitude;
  final double frequency;

  _SquigglyPathPainter({
    required this.phase,
    required this.color,
    required this.strokeWidth,
    required this.amplitude,
    required this.frequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final midY = size.height / 2;

    path.moveTo(0, midY + math.sin(phase) * amplitude);
    for (double x = 0; x <= size.width; x += 2) {
      final y = midY + math.sin(x * frequency + phase) * amplitude;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SquigglyPathPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// Organic M3 Squiggly stage contour divider separating stage from control dock.
class M3SquigglyDivider extends StatelessWidget {
  final Color color;
  final double height;

  const M3SquigglyDivider({
    super.key,
    this.color = Colors.white,
    this.height = 18,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(MediaQuery.of(context).size.width, height),
      painter: _SquigglyDividerPainter(color: color),
    );
  }
}

class _SquigglyDividerPainter extends CustomPainter {
  final Color color;
  const _SquigglyDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(0, h);
    path.lineTo(0, h * 0.4);

    // Organic wavy top edge
    path.cubicTo(w * 0.25, -h * 0.3, w * 0.35, h * 0.9, w * 0.65, h * 0.2);
    path.cubicTo(w * 0.85, -h * 0.2, w * 0.95, h * 0.6, w, h * 0.3);

    path.lineTo(w, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SquigglyDividerPainter oldDelegate) => false;
}
