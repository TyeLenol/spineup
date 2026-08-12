import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'morph_math.dart';

/// Screen 4 Community overlay: 5 satellite nodes & connecting chord links.
class ClusterOverlayPainter extends CustomPainter {
  final Color color;
  final double linkProgress; // 0.0 to 1.0
  final double nodeScale; // 0.0 to 1.0
  final double opacity;

  ClusterOverlayPainter({
    required this.color,
    required this.linkProgress,
    required this.nodeScale,
    required this.opacity,
  });

  static List<Offset> getNodePositions(Size size, {int count = 5, double R = 60.0}) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 200.0;
    final scaledR = R * scale;

    return List<Offset>.generate(count, (i) {
      final a = -math.pi / 2 + (i / count) * kTau;
      return Offset(cx + math.cos(a) * scaledR, cy + math.sin(a) * scaledR);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.0) return;

    final nodes = getNodePositions(size);
    final linkPaint = Paint()
      ..color = color.withValues(alpha: 0.55 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * (size.width / 200.0)
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // 1. Draw connecting chord links
    int linkIndex = 0;
    final totalLinks = (nodes.length * (nodes.length - 1)) ~/ 2;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final p1 = nodes[i];
        final p2 = nodes[j];

        // Stagger link animation
        final startThreshold = (linkIndex / totalLinks) * 0.4;
        final linkAnim = ((linkProgress - startThreshold) / 0.6).clamp(0.0, 1.0);

        if (linkAnim > 0.0) {
          final targetOffset = Offset(
            p1.dx + (p2.dx - p1.dx) * linkAnim,
            p1.dy + (p2.dy - p1.dy) * linkAnim,
          );
          canvas.drawLine(p1, targetOffset, linkPaint);
        }
        linkIndex++;
      }
    }

    // 2. Draw satellite node circles
    final nodeRadius = 9.0 * (size.width / 200.0) * nodeScale;
    if (nodeRadius > 0.1) {
      for (final p in nodes) {
        canvas.drawCircle(p, nodeRadius, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ClusterOverlayPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.linkProgress != linkProgress ||
        oldDelegate.nodeScale != nodeScale ||
        oldDelegate.opacity != opacity;
  }
}
