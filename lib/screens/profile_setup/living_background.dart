import 'dart:math' as math;

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
          Positioned.fill(
            child: CustomPaint(painter: _ProfileDoodlePainter(step: step)),
          ),
        ],
      ),
    );
  }
}

class _ProfileDoodlePainter extends CustomPainter {
  final int step;

  const _ProfileDoodlePainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    final teal = Paint()
      ..color = AppTheme.profileSage.withValues(alpha: 0.19)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final terracotta = Paint()
      ..color = AppTheme.profileWarm.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final berry = Paint()
      ..color = const Color(0xFF7B5A70).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final width = size.width;
    final height = size.height;
    final offset = step.isEven ? 0.018 : 0.0;

    _drawStars(
      canvas,
      Offset(width * (0.84 + offset), height * 0.18),
      teal,
      berry,
    );
    _drawStar(
      canvas,
      Offset(width * 0.18, height * 0.23),
      7,
      terracotta,
      rotation: 0.18,
    );
    _drawSunburst(canvas, Offset(width * 0.88, height * 0.73), terracotta);
    _drawLeafySprig(canvas, Offset(width * 0.10, height * 0.68), teal);
    _drawLooseArc(canvas, Offset(width * 0.75, height * 0.34), berry);
    _drawWavyMark(canvas, Offset(width * 0.18, height * 0.47), teal);
    _drawDotCluster(canvas, Offset(width * 0.76, height * 0.59), terracotta);
  }

  void _drawStars(Canvas canvas, Offset center, Paint teal, Paint berry) {
    _drawStar(canvas, center, 12, teal, rotation: -0.12);
    _drawStar(canvas, center + const Offset(25, 24), 6, berry, rotation: 0.28);
    final dots = Paint()
      ..color = teal.color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + const Offset(-24, 25), 2.1, dots);
    canvas.drawCircle(center + const Offset(-14, 35), 1.4, dots);
    canvas.drawCircle(center + const Offset(34, -15), 1.7, dots);
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    required double rotation,
  }) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = rotation + i * math.pi / 4 - math.pi / 2;
      final length = i.isEven ? radius : radius * 0.38;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * length;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    final echo = Path()
      ..moveTo(center.dx - radius * 0.78, center.dy + radius * 0.18)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 1.05,
        center.dx + radius * 0.70,
        center.dy - radius * 0.16,
      );
    final echoPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.10)
      ..style = paint.style
      ..strokeWidth = paint.strokeWidth
      ..strokeCap = paint.strokeCap
      ..strokeJoin = paint.strokeJoin;
    canvas.drawPath(echo, echoPaint);
  }

  void _drawSunburst(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, 8, paint);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + 0.1;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * 17;
      final end =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (26 + (i.isEven ? 2 : 0));
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawLooseArc(Canvas canvas, Offset center, Paint paint) {
    final arc = Path()
      ..moveTo(center.dx - 20, center.dy + 5)
      ..cubicTo(
        center.dx - 5,
        center.dy - 16,
        center.dx + 18,
        center.dy - 15,
        center.dx + 24,
        center.dy + 2,
      );
    canvas.drawPath(arc, paint);
    canvas.drawCircle(center + const Offset(30, 7), 1.7, paint);
  }

  void _drawWavyMark(Canvas canvas, Offset start, Paint paint) {
    final wave = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + 10,
        start.dy - 9,
        start.dx + 18,
        start.dy + 9,
        start.dx + 28,
        start.dy,
      )
      ..cubicTo(
        start.dx + 38,
        start.dy - 9,
        start.dx + 46,
        start.dy + 9,
        start.dx + 56,
        start.dy,
      );
    canvas.drawPath(wave, paint);
  }

  void _drawDotCluster(Canvas canvas, Offset center, Paint paint) {
    final dotPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.3, dotPaint);
    canvas.drawCircle(center + const Offset(12, -8), 1.5, dotPaint);
    canvas.drawCircle(center + const Offset(18, 5), 1.9, dotPaint);
    canvas.drawCircle(center + const Offset(7, 15), 1.2, dotPaint);
  }

  void _drawLeafySprig(Canvas canvas, Offset base, Paint paint) {
    final stem = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx + 5,
        base.dy - 35,
        base.dx - 7,
        base.dy - 58,
        base.dx + 10,
        base.dy - 84,
      );
    canvas.drawPath(stem, paint);

    final leafPaint = Paint()
      ..color = AppTheme.profileSage.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final leaves = [
      (Offset(-5, -27), Offset(-25, -35)),
      (Offset(0, -45), Offset(22, -53)),
      (Offset(5, -62), Offset(-14, -73)),
      (Offset(9, -78), Offset(29, -85)),
    ];
    for (final leaf in leaves) {
      final tip = base + leaf.$1;
      final side = base + leaf.$2;
      final leafPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..quadraticBezierTo(
          side.dx,
          side.dy - 6,
          side.dx + (tip.dx - side.dx) * 0.45,
          side.dy + 2,
        )
        ..quadraticBezierTo(side.dx + 8, side.dy + 6, tip.dx, tip.dy)
        ..close();
      canvas.drawPath(leafPath, leafPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfileDoodlePainter oldDelegate) =>
      oldDelegate.step != step;
}
