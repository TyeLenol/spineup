import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LivingBackground extends StatelessWidget {
  final int step;

  const LivingBackground({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final alignment = step.isEven ? Alignment.topRight : Alignment.topLeft;

    return IgnorePointer(
      child: Stack(
        children: [
          Container(color: AppTheme.profileCanvas),
          Align(
            alignment: alignment,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.profileSoftSage.withValues(alpha: 0.52),
                    AppTheme.profileCanvas.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 74,
            right: -12,
            child: CustomPaint(
              size: const Size(152, 112),
              painter: _ThreadSignaturePainter(step: step),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadSignaturePainter extends CustomPainter {
  final int step;

  const _ThreadSignaturePainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    final coral = Paint()
      ..color = AppTheme.profileWarm.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final sage = Paint()
      ..color = AppTheme.profileSage.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final offset = step.isEven ? 10.0 : 0.0;
    final thread = Path()
      ..moveTo(12, 82)
      ..cubicTo(34, 22 + offset, 88, 96 - offset, 142, 28 + offset);
    canvas.drawPath(thread, coral);

    for (final point in [Offset(18, 80), Offset(78, 66), Offset(138, 30)]) {
      canvas.drawCircle(point, 3, sage);
    }
  }

  @override
  bool shouldRepaint(covariant _ThreadSignaturePainter oldDelegate) =>
      oldDelegate.step != step;
}
