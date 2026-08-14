import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/database_helper.dart';
import '../main.dart' show mainAppRoute, onboardingRoute;
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../theme/edge_to_edge_helper.dart';

class SplashScreen extends StatefulWidget {
  final Duration duration;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 4500),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Intro animations ──────────────────────────────────────────────────────
  late AnimationController _mainController;
  late AnimationController _pathController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _titleFadeAnimation;

  Timer? _navigationTimer;
  Timer? _delayTimer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // ── Intro ──
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
        tween: Tween<double>(
          begin: 0.8,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_mainController);
    _titleFadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    // Start intro
    _mainController.forward();
    _delayTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) _pathController.forward();
    });

    // Schedule exit
    _navigationTimer = Timer(widget.duration, () => unawaited(_finish()));
  }

  Future<void> _finish() async {
    if (_isExiting) return;
    _isExiting = true;
    _delayTimer?.cancel();
    _navigationTimer?.cancel();

    final subjects = await DatabaseHelper().getCareSubjects(
      SessionService.currentUserId,
    );
    if (!mounted) return;

    if (subjects.isNotEmpty) {
      await SessionService.restoreActiveCareSubject(subjects: subjects);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(mainAppRoute());
    } else {
      Navigator.of(context).pushReplacement(onboardingRoute(1));
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

    final modalRoute = ModalRoute.of(context);
    final secondaryAnimation = modalRoute?.secondaryAnimation;

    Widget mainContent = Scaffold(
      backgroundColor: AppTheme.primarySage,
      body: GestureDetector(
        onTap: () => unawaited(_finish()),
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
                        builder: (context, _) => RepaintBoundary(
                          child: CustomPaint(
                            painter: _SpineLogoPainter(
                              progress: _pathController.value,
                              color: AppTheme.onPrimaryDark,
                            ),
                          ),
                        ),
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

    if (secondaryAnimation != null) {
      return AnimatedBuilder(
        animation: secondaryAnimation,
        builder: (context, child) {
          final curve = CurvedAnimation(
            parent: secondaryAnimation,
            curve: const Cubic(0.3, 0.0, 1.0, 1.0),
          );
          final opacity = 1.0 - curve.value;
          final scale = 1.0 + (0.05 * curve.value);
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: mainContent,
      );
    }

    return mainContent;
  }
}

class _SpineLogoPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SpineLogoPainter({required this.progress, required this.color});

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

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        strokePaint,
      );
    }

    if (progress > 0.7) {
      final dotProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(70 * scaleX, 70 * scaleY),
        10 * scaleX * dotProgress,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpineLogoPainter old) =>
      old.progress != progress || old.color != color;
}
