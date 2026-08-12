import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'morph_math.dart';

/// Paints the Screen 2 M3-Expressive wavy ring progress fill.
/// Features a rippled active progress arc (with animated phase) and a flat track.
class WavyRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double phase;

  WavyRingPainter({
    required this.progress,
    required this.color,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R = size.width * 0.3175; // Matches 63.5 on 200px viewBox

    // 1. Flat remaining track
    final startTrack = (progress + 0.02).clamp(0.0, 1.0);
    if (startTrack < 1.0) {
      final trackPath = _flatArcPath(startTrack, 1.0, cx, cy, R);
      final trackPaint = Paint()
        ..color = color.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.03 // 6px on 200
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(trackPath, trackPaint);
    }

    // 2. Wavy active progress arc
    if (progress > 0.0005) {
      final activePath = _wavyArcPath(0.0, progress, cx, cy, R, phase);
      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045 // 9px on 200
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(activePath, activePaint);
    }
  }

  Path _flatArcPath(double start, double end, double cx, double cy, double R) {
    final path = Path();
    if (end - start < 0.0005) return path;
    final a0 = -math.pi / 2 + start * kTau;
    final sweepAngle = (end - start) * kTau;

    path.addArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: R),
      a0,
      sweepAngle,
    );
    return path;
  }

  Path _wavyArcPath(
    double start,
    double end,
    double cx,
    double cy,
    double R,
    double phase, {
    double amp = 5.0,
    double waves = 12.0,
    int steps = 160,
  }) {
    if (end - start < 0.0005) return Path();
    final pts = <Offset>[];
    final n = math.max(8, (steps * (end - start)).round());

    for (int i = 0; i <= n; i++) {
      final t = start + ((end - start) * i) / n;
      final a = -math.pi / 2 + t * kTau;
      // Taper ripple to 0 at both ends so caps sit on true radius
      final edge = math.min(1.0, math.min((i / n) * 6.0, ((n - i) / n) * 6.0));
      final r = R + amp * edge * math.sin(waves * t * kTau * 0.16 + phase + t * kTau * waves * 0.84);
      pts.add(Offset(cx + math.cos(a) * r, cy + math.sin(a) * r));
    }

    return catmullRomOpen(pts);
  }

  @override
  bool shouldRepaint(covariant WavyRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.phase != phase;
  }
}
