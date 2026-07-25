import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/edge_to_edge_helper.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final Duration duration;

  const SplashScreen({
    super.key,
    required this.onFinish,
    this.duration = const Duration(milliseconds: 3800),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pathController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _titleFadeAnimation;
  Timer? _navigationTimer;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_mainController);

    _titleFadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _mainController.forward();
    _delayTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        _pathController.forward();
      }
    });

    _navigationTimer = Timer(widget.duration, _finish);
  }

  void _finish() {
    _delayTimer?.cancel();
    _navigationTimer?.cancel();
    if (mounted) {
      widget.onFinish();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _navigationTimer?.cancel();
    _mainController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EdgeToEdgeHelper.configureSystemUi(context);

    return Scaffold(
      backgroundColor: AppTheme.primarySage,
      body: GestureDetector(
        onTap: _finish,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: SizedBox(
                      width: 128,
                      height: 128,
                      child: AnimatedBuilder(
                        animation: _pathController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _SpineLogoPainter(
                              progress: _pathController.value,
                              color: AppTheme.onPrimaryDark,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: Text(
                      'SpineUp',
                      style: GoogleFonts.fraunces(
                        fontSize: 48,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onPrimaryDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpineLogoPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SpineLogoPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Scale 100x100 path to canvas size
    final scaleX = size.width / 100;
    final scaleY = size.height / 100;

    final path = Path();
    path.moveTo(30 * scaleX, 70 * scaleY);
    path.cubicTo(
      30 * scaleX,
      50 * scaleY,
      70 * scaleX,
      50 * scaleY,
      70 * scaleX,
      30 * scaleY,
    );
    path.cubicTo(
      70 * scaleX,
      15 * scaleY,
      50 * scaleX,
      15 * scaleY,
      30 * scaleX,
      30 * scaleY,
    );

    // Measure path for progressive drawing animation
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final extractPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractPath, strokePaint);
    }

    // Draw dot at bottom right (70, 70) with spring appearance when progress > 0.8
    if (progress > 0.7) {
      final dotProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      final radius = 10 * scaleX * dotProgress;
      canvas.drawCircle(
        Offset(70 * scaleX, 70 * scaleY),
        radius,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpineLogoPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
