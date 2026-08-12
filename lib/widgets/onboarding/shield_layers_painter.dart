import 'package:flutter/material.dart';
import 'morph_math.dart';

/// Screen 5 Privacy overlay: Inner concentric shield outline + vertical spine line + 3 vertebrae dots.
class ShieldLayersPainter extends CustomPainter {
  final Color color;
  final double scale;
  final double lineProgress; // 0.0 to 1.0
  final double opacity;

  ShieldLayersPainter({
    required this.color,
    required this.scale,
    required this.lineProgress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final scaleFactor = size.width / 200.0;

    // 1. Inner concentric shield path
    final innerPath = buildMorphedPath(
      4.0, // shield shape
      center: Offset(cx, cy * 0.96),
      radius: 46.0 * scaleFactor * scale,
    );

    final shieldPaint = Paint()
      ..color = color.withValues(alpha: 0.75 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scaleFactor
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(innerPath, shieldPaint);

    // 2. Vertical spine line (Y: 70 to 116)
    if (lineProgress > 0.0) {
      final startY = 70.0 * scaleFactor;
      final totalLen = 46.0 * scaleFactor;
      final currentY = startY + totalLen * lineProgress;

      final spinePaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0 * scaleFactor
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(cx, startY),
        Offset(cx, currentY),
        spinePaint,
      );

      // 3. Vertebrae dots (Y: 80, 93, 106)
      final dotYList = [80.0 * scaleFactor, 93.0 * scaleFactor, 106.0 * scaleFactor];
      final dotPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < dotYList.length; i++) {
        final dotY = dotYList[i];
        if (currentY >= dotY) {
          canvas.drawCircle(Offset(cx, dotY), 4.5 * scaleFactor, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShieldLayersPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.scale != scale ||
        oldDelegate.lineProgress != lineProgress ||
        oldDelegate.opacity != opacity;
  }
}
