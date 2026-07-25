import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class Ob1Illustration extends StatefulWidget {
  const Ob1Illustration({super.key});

  @override
  State<Ob1Illustration> createState() => _Ob1IllustrationState();
}

class _Ob1IllustrationState extends State<Ob1Illustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _card1Slide;
  late Animation<double> _card2Slide;
  late Animation<double> _dotScale;
  late Animation<double> _sunRotate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _card1Slide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _card2Slide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOutBack),
    );

    _dotScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    );

    _sunRotate = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 270,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Unique 3D Sunny Scalloped / Starburst Blob Background
          AnimatedBuilder(
            animation: _sunRotate,
            builder: (context, child) {
              return Transform.rotate(
                angle: _sunRotate.value,
                child: child,
              );
            },
            child: SizedBox(
              width: 250,
              height: 250,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _Sunny3DBlobPainter(
                    baseColor: AppTheme.primarySage.withValues(alpha: 0.22),
                    highlightColor: const Color(0xFF7EE8C4).withValues(alpha: 0.35),
                    shadowColor: AppTheme.borderCream.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),

          // 3D Pixel Diamond Accent Badge (Top Right - Coral)
          Positioned(
            top: 12,
            right: 20,
            child: ScaleTransition(
              scale: _dotScale,
              child: _Pixel3DBadge(
                color: AppTheme.secondaryCoral,
                shadowColor: const Color(0xFF9E3A1A),
                size: 18,
              ),
            ),
          ),

          // 3D Pixel Diamond Accent Badge (Bottom Left - Sage)
          Positioned(
            bottom: 20,
            left: 18,
            child: ScaleTransition(
              scale: _dotScale,
              child: _Pixel3DBadge(
                color: AppTheme.primarySage,
                shadowColor: const Color(0xFF0A3324),
                size: 20,
              ),
            ),
          ),

          // Top Card (Rotated -4deg)
          Positioned(
            top: 20,
            left: 10,
            child: AnimatedBuilder(
              animation: _card1Slide,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _card1Slide.value)),
                  child: Transform.rotate(
                    angle: -0.07, // ~ -4 degrees
                    child: Opacity(
                      opacity: _card1Slide.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardCream,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.borderCream.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primarySage.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.show_chart_rounded,
                            color: AppTheme.onPrimaryDark,
                            size: 22,
                          ),
                        ),
                        const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.primarySage.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 0.65,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primarySage,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 8,
                      width: 110,
                      decoration: BoxDecoration(
                        color: AppTheme.mutedCream,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Card (Rotated +6deg, Overlapping)
          Positioned(
            bottom: 20,
            right: 10,
            child: AnimatedBuilder(
              animation: _card2Slide,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 40 * (1 - _card2Slide.value)),
                  child: Transform.rotate(
                    angle: 0.1, // ~ +6 degrees
                    child: Opacity(
                      opacity: _card2Slide.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                width: 190,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardCream,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.borderCream.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCoral,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 9,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.foregroundDark.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 9,
                            width: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.foregroundDark.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3D Scalloped Sunny Sunburst Blob Painter
class _Sunny3DBlobPainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final Color shadowColor;

  _Sunny3DBlobPainter({
    required this.baseColor,
    required this.highlightColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 12;
    final innerRadius = outerRadius * 0.84;
    const numPoints = 12;

    final path = Path();
    for (int i = 0; i < numPoints * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi) / numPoints;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Control point for smooth scalloped sun ray curves
        final prevAngle = ((i - 1) * math.pi) / numPoints;
        final midAngle = (prevAngle + angle) / 2;
        final midRadius = (outerRadius + innerRadius) / 2;
        final cx = center.dx + midRadius * math.cos(midAngle);
        final cy = center.dy + midRadius * math.sin(midAngle);
        path.quadraticBezierTo(cx, cy, x, y);
      }
    }
    path.close();

    // 1. Drop Shadow for 3D depth
    final shadowPath = path.shift(const Offset(3, 5));
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. Main Sunny Fill with Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          highlightColor,
          baseColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Inner 3D Highlight Border
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _Sunny3DBlobPainter oldDelegate) => false;
}

/// 3D Pixel Diamond Badge Accent Component
class _Pixel3DBadge extends StatelessWidget {
  final Color color;
  final Color shadowColor;
  final double size;

  const _Pixel3DBadge({
    required this.color,
    required this.shadowColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4, // 45 degree diamond shape
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.4),
              offset: const Offset(2, 2),
              blurRadius: 0, // Crisp 3D pixel bevel shadow
            ),
          ],
        ),
      ),
    );
  }
}
