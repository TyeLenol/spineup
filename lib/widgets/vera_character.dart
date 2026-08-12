import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Vera's available emotional poses.
enum VeraPose {
  celebrate,
  wave,
  proud,
  idle,
}

/// Articulated 5-Segment Scoliosis Spine Mascot (Vera).
///
/// Features 5 articulated vertebrae nodes linked along an explicit S-curve backbone
/// by elastic intervertebral disc cushions. Responds to tap/drag with spring flex physics
/// and spawns glowing XP particles.
class VeraCharacter extends StatefulWidget {
  final double size;
  final VeraPose pose;
  final bool enableIdleBob;
  final VoidCallback? onTapFlex;

  const VeraCharacter({
    super.key,
    this.size = 170,
    this.pose = VeraPose.celebrate,
    this.enableIdleBob = true,
    this.onTapFlex,
  });

  @override
  State<VeraCharacter> createState() => _VeraCharacterState();
}

class _VeraCharacterState extends State<VeraCharacter>
    with TickerProviderStateMixin {
  late AnimationController _bobCtrl;
  late AnimationController _flexCtrl;

  late Animation<double> _bobY;
  late Animation<double> _flexDeform;

  final List<_XpSpark> _sparks = [];

  @override
  void initState() {
    super.initState();

    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _bobY = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut),
    );
    if (widget.enableIdleBob) {
      _bobCtrl.repeat(reverse: true);
    }

    _flexCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _flexDeform = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flexCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bobCtrl.dispose();
    _flexCtrl.dispose();
    super.dispose();
  }

  void _triggerFlex() {
    _flexCtrl.forward(from: 0.0);
    setState(() {
      _sparks.add(_XpSpark());
    });
    widget.onTapFlex?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerFlex,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bobCtrl, _flexCtrl]),
        builder: (context, _) {
          final dy = widget.enableIdleBob ? _bobY.value : 0.0;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, dy),
                child: CustomPaint(
                  size: Size(widget.size, widget.size * 1.25),
                  painter: _VeraScurvePainter(
                    pose: widget.pose,
                    flexAmount: _flexDeform.value,
                  ),
                ),
              ),

              // Floating XP sparks on tap
              for (final spark in _sparks)
                _SparkWidget(
                  key: ValueKey(spark.id),
                  onComplete: () {
                    setState(() => _sparks.remove(spark));
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _XpSpark {
  final String id = DateTime.now().microsecondsSinceEpoch.toString();
}

class _SparkWidget extends StatefulWidget {
  final VoidCallback onComplete;
  const _SparkWidget({super.key, required this.onComplete});

  @override
  State<_SparkWidget> createState() => _SparkWidgetState();
}

class _SparkWidgetState extends State<_SparkWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _y;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _y = Tween<double>(begin: 0, end: -55).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Positioned(
        top: 20 + _y.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.secondaryCoral,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryCoral.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              '+30 XP 🎉',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VeraScurvePainter extends CustomPainter {
  final VeraPose pose;
  final double flexAmount;

  const _VeraScurvePainter({
    required this.pose,
    required this.flexAmount,
  });

  static const Color _vertebraBody = Color(0xFF8B84C8); // Dusty lavender
  static const Color _vertebraHighlight = Color(0xFFAAA4DE); // Soft top shine
  static const Color _discColor = AppTheme.secondaryCoral; // Disc cushion
  static const Color _blush = AppTheme.secondaryCoral;
  static const Color _white = Colors.white;
  static const Color _pupil = Color(0xFF2D2824);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Center coordinates for 5 vertebrae nodes (Cervical to Lumbar)
    final flexX = math.sin(flexAmount * math.pi * 2) * 16.0;

    final nodes = [
      Offset(w * 0.50 + flexX, h * 0.20), // Head / Cervical node
      Offset(w * 0.62 + flexX * 0.7, h * 0.37), // Upper Thoracic (curved right)
      Offset(w * 0.44 - flexX * 0.5, h * 0.54), // Mid Thoracic (curved left - S-Curve)
      Offset(w * 0.58 + flexX * 0.3, h * 0.71), // Lumbar (curved right)
      Offset(w * 0.50, h * 0.88), // Sacral Base node
    ];

    // 1. Draw Intervertebral Disc Cushions & Backbone Ribbon
    _drawSpineRibbon(canvas, nodes, w);

    // 2. Draw Arms on Head Node
    _drawArms(canvas, nodes[0], w, h);

    // 3. Draw 5 Articulated Vertebrae Segments (Bottom to Top)
    for (int i = 4; i >= 0; i--) {
      _drawVertebraNode(canvas, nodes[i], i == 0, w);
    }

    // 4. Draw Face on Top Node
    _drawFace(canvas, nodes[0], w);
  }

  void _drawSpineRibbon(Canvas canvas, List<Offset> nodes, double w) {
    final ribbonPaint = Paint()
      ..color = _discColor.withValues(alpha: 0.85)
      ..strokeWidth = w * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(nodes[0].dx, nodes[0].dy);
    for (int i = 1; i < nodes.length; i++) {
      final prev = nodes[i - 1];
      final curr = nodes[i];
      final midY = (prev.dy + curr.dy) / 2;
      path.cubicTo(prev.dx, midY, curr.dx, midY, curr.dx, curr.dy);
    }
    canvas.drawPath(path, ribbonPaint);

    // Draw individual intervertebral disc cushions
    for (int i = 0; i < nodes.length - 1; i++) {
      final discCenter = Offset(
        (nodes[i].dx + nodes[i + 1].dx) / 2,
        (nodes[i].dy + nodes[i + 1].dy) / 2,
      );
      canvas.drawOval(
        Rect.fromCenter(center: discCenter, width: w * 0.22, height: w * 0.08),
        Paint()..color = _discColor,
      );
    }
  }

  void _drawVertebraNode(Canvas canvas, Offset center, bool isHead, double w) {
    final nodeW = isHead ? w * 0.44 : w * 0.38;
    final nodeH = isHead ? w * 0.38 : w * 0.26;

    final rect = Rect.fromCenter(center: center, width: nodeW, height: nodeH);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(nodeH * 0.40));

    // Shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // Main Vertebra Body
    canvas.drawRRect(rrect, Paint()..color = _vertebraBody);

    // Soft Top Surface Highlight
    final highlightRect = Rect.fromLTWH(
      rect.left + 4,
      rect.top + 3,
      rect.width - 8,
      rect.height * 0.35,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, Radius.circular(nodeH * 0.25)),
      Paint()..color = _vertebraHighlight.withValues(alpha: 0.45),
    );
  }

  void _drawArms(Canvas canvas, Offset headCenter, double w, double h) {
    final armPaint = Paint()
      ..color = _vertebraBody
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (pose) {
      case VeraPose.celebrate:
      case VeraPose.wave:
        // Left arm flexing up
        canvas.drawLine(
          Offset(headCenter.dx - w * 0.20, headCenter.dy),
          Offset(headCenter.dx - w * 0.35, headCenter.dy - w * 0.18),
          armPaint,
        );
        // Right arm flexing up
        canvas.drawLine(
          Offset(headCenter.dx + w * 0.20, headCenter.dy),
          Offset(headCenter.dx + w * 0.35, headCenter.dy - w * 0.18),
          armPaint,
        );
      default:
        canvas.drawLine(
          Offset(headCenter.dx - w * 0.20, headCenter.dy),
          Offset(headCenter.dx - w * 0.32, headCenter.dy + w * 0.10),
          armPaint,
        );
        canvas.drawLine(
          Offset(headCenter.dx + w * 0.20, headCenter.dy),
          Offset(headCenter.dx + w * 0.32, headCenter.dy + w * 0.10),
          armPaint,
        );
    }
  }

  void _drawFace(Canvas canvas, Offset headCenter, double w) {
    final eyeY = headCenter.dy - w * 0.04;
    final eyeSpacing = w * 0.10;
    final eyeR = w * 0.06;

    for (final side in [-1.0, 1.0]) {
      final ex = headCenter.dx + side * eyeSpacing;
      // White sclera
      canvas.drawCircle(Offset(ex, eyeY), eyeR, Paint()..color = _white);
      // Pupil
      canvas.drawCircle(
          Offset(ex + side * 1.5, eyeY + 1), eyeR * 0.55, Paint()..color = _pupil);
      // Highlight
      canvas.drawCircle(
          Offset(ex - side * 1.5, eyeY - 2), eyeR * 0.22, Paint()..color = _white);

      // Blush
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx + side * eyeSpacing * 1.35, eyeY + eyeR * 1.1),
          width: eyeR * 1.1,
          height: eyeR * 0.65,
        ),
        Paint()..color = _blush.withValues(alpha: 0.55),
      );
    }

    // Smile
    final smilePaint = Paint()
      ..color = _pupil
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final smileRect = Rect.fromCenter(
      center: Offset(headCenter.dx, eyeY + eyeR * 1.3),
      width: w * 0.14,
      height: w * 0.08,
    );
    canvas.drawArc(smileRect, 0, math.pi, false, smilePaint);
  }

  @override
  bool shouldRepaint(_VeraScurvePainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.flexAmount != flexAmount;
}
