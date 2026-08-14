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
          ],
        );
      },
    );
  }
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
