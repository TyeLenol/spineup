import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LivingBackground extends StatefulWidget {
  final int step;
  const LivingBackground({super.key, required this.step});

  @override
  State<LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<LivingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = disableAnimations ? 0.0 : _controller.value;
        final size = MediaQuery.of(context).size;

        // Keep the setup background calm and consistent across steps. The
        // step changes the blob position subtly, not the whole color language.
        final color1 = AppTheme.profileSage;
        final color2 = AppTheme.profileWarm;
        final begin = widget.step.isEven
            ? Alignment.topLeft
            : Alignment.topCenter;
        final end = widget.step.isEven
            ? Alignment.bottomRight
            : Alignment.bottomCenter;

        final x1 = sin(t * 2 * pi) * 40;
        final y1 = cos(t * 2 * pi) * 30;
        final x2 = cos(t * 2 * pi + pi) * 50;
        final y2 = sin(t * 2 * pi + pi) * 20;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.profileCanvas, Colors.white],
                  begin: begin,
                  end: end,
                ),
              ),
            ),
            // Blob 1
            Positioned(
              left: -size.width * 0.2 + x1,
              top: size.height * 0.1 + y1,
              child: _Blob(
                color: color1.withValues(alpha: 0.10),
                size: size.width * 1.2,
              ),
            ),
            // Blob 2
            Positioned(
              right: -size.width * 0.3 + x2,
              bottom: -size.height * 0.1 + y2,
              child: _Blob(
                color: color2.withValues(alpha: 0.08),
                size: size.width * 1.4,
              ),
            ),
            // A quiet signature that carries the onboarding thread into setup.
            Positioned(
              top: 76 + y2 * 0.25,
              right: -12 + x1 * 0.15,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(160, 120),
                  painter: _ThreadSignaturePainter(progress: t),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThreadSignaturePainter extends CustomPainter {
  final double progress;

  const _ThreadSignaturePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final coral = Paint()
      ..color = AppTheme.profileWarm.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final sage = Paint()
      ..color = AppTheme.profileSage.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final wave = sin(progress * 2 * pi) * 4;
    final thread = Path()
      ..moveTo(16, 84)
      ..cubicTo(34, 18 + wave, 84, 104 - wave, 144, 30 + wave);
    canvas.drawPath(thread, coral);

    for (final point in [
      Offset(20, 82),
      Offset(78, 68 + wave / 2),
      Offset(140, 32 + wave),
    ]) {
      canvas.drawCircle(point, 3.2, sage);
    }
  }

  @override
  bool shouldRepaint(covariant _ThreadSignaturePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size / 3, spreadRadius: size / 4),
        ],
      ),
    );
  }
}
