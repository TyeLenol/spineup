import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../widgets/onboarding/keycap_cta.dart';
import '../widgets/onboarding/onboarding_chrome.dart';

class OnboardingScreenData {
  final Color bg;
  final Color tint;
  final Color tintSoft;
  final Color deep;
  final String eyebrow;
  final List<String> headline;
  final String subtext;
  final String cta;
  final String imageAsset;

  const OnboardingScreenData({
    required this.bg,
    required this.tint,
    required this.tintSoft,
    required this.deep,
    required this.eyebrow,
    required this.headline,
    required this.subtext,
    required this.cta,
    required this.imageAsset,
  });
}

const List<OnboardingScreenData> kOnboardingScreens = [
  OnboardingScreenData(
    bg: Color(0xFFFFF8F0),
    tint: Color(0xFF176B61),
    tintSoft: Color(0xFF7B5A70),
    deep: Color(0xFF104C47),
    eyebrow: 'A gentle place to begin',
    headline: ['Make room', 'for care.'],
    subtext:
        'Keep check-ins, routines, and questions together—so the small things are easier to notice.',
    cta: 'Next',
    imageAsset: 'assets/onboarding/onboarding_make_room_for_care.png',
  ),
  OnboardingScreenData(
    bg: Color(0xFFFFF8F0),
    tint: Color(0xFF176B61),
    tintSoft: Color(0xFF7B5A70),
    deep: Color(0xFF104C47),
    eyebrow: 'For you or someone you care for',
    headline: ['Care can', 'be shared.'],
    subtext:
        'Create a space for yourself or someone you care for, with each person’s records kept separate.',
    cta: 'Next',
    imageAsset: 'assets/onboarding/onboarding_care_can_be_shared.png',
  ),
  OnboardingScreenData(
    bg: Color(0xFFFFF8F0),
    tint: Color(0xFF176B61),
    tintSoft: Color(0xFF7B5A70),
    deep: Color(0xFF104C47),
    eyebrow: 'Yours to carry',
    headline: ['Keep your path', 'close.'],
    subtext:
        'SpineUp works on this phone. When you choose, you can export a protected copy for a new device.',
    cta: 'Set up my space',
    imageAsset: 'assets/onboarding/onboarding_keep_your_path_close.png',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 1;
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _leafController;

  @override
  void initState() {
    super.initState();
    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _leafController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step >= 1 && step <= kOnboardingScreens.length) {
      setState(() => _currentStep = step);
      if (step == kOnboardingScreens.length &&
          !MediaQuery.of(context).disableAnimations) {
        _leafController.forward(from: 0);
      } else {
        _leafController.stop(canceled: false);
      }
    }
  }

  void _next() {
    if (_currentStep < kOnboardingScreens.length) {
      _goToStep(_currentStep + 1);
    } else {
      _complete();
    }
  }

  void _previous() {
    if (_currentStep > 1) _goToStep(_currentStep - 1);
  }

  void _complete() {
    Navigator.of(context).pushReplacement(localFirstWelcomeRoute());
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _next();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _previous();
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -180) {
      _next();
    } else if (velocity > 180) {
      _previous();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = kOnboardingScreens[_currentStep - 1];
    final total = kOnboardingScreens.length;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        child: Scaffold(
          backgroundColor: screen.bg,
          body: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    StepAnnouncer(
                      message:
                          'Step $_currentStep of $total. ${screen.headline[0]} ${screen.headline[1]}. ${screen.subtext}',
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            height: 48,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _currentStep < total
                                  ? OnboardingSmallLink(
                                      text: 'Skip',
                                      ariaLabel: 'Skip onboarding',
                                      onClick: _complete,
                                      tint: screen.tint,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          const Spacer(),
                          ProgressDots(
                            step: _currentStep,
                            total: total,
                            tint: screen.tint,
                          ),
                          const Spacer(),
                          const SizedBox(width: 72, height: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Duration(
                          milliseconds: disableAnimations ? 0 : 380,
                        ),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                              alignment: Alignment.center,
                              children: [...previousChildren, ?currentChild],
                            ),
                        transitionBuilder: (child, animation) {
                          final settle =
                              Tween<Offset>(
                                begin: const Offset(0, 0.018),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                  reverseCurve: Curves.easeInCubic,
                                ),
                              );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: settle,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          key: ValueKey(screen.imageAsset),
                          padding: const EdgeInsets.fromLTRB(22, 8, 22, 2),
                          child: _OnboardingIllustration(
                            asset: screen.imageAsset,
                          ),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Duration(
                        milliseconds: disableAnimations ? 0 : 260,
                      ),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.012),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Padding(
                        key: ValueKey('copy-$_currentStep'),
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                screen.eyebrow.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: screen.tint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                screen.headline[0],
                                style: GoogleFonts.fraunces(
                                  color: screen.tint,
                                  fontSize: 39,
                                  fontWeight: FontWeight.w900,
                                  height: 0.98,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                screen.headline[1],
                                style: GoogleFonts.fraunces(
                                  color: screen.tintSoft,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  height: 1.02,
                                  letterSpacing: -0.9,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                screen.subtext,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF5C4B45),
                                  fontSize: 15,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  if (_currentStep > 1)
                                    OnboardingIconButton(
                                      icon: Icons.arrow_back_rounded,
                                      label: 'Go back',
                                      onClick: _previous,
                                      tint: screen.tint,
                                    )
                                  else
                                    const SizedBox(width: 48, height: 48),
                                  const Spacer(),
                                  KeycapCta(
                                    label: screen.cta,
                                    onClick: _next,
                                    fill: screen.tint,
                                    ink: screen.deep,
                                    text: Colors.white,
                                    icon: Icons.arrow_forward_rounded,
                                    compact: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_currentStep == total && !disableAnimations)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _leafController,
                        builder: (context, child) => CustomPaint(
                          painter: _LandingLeafPainter(
                            progress: _leafController.value,
                            color: screen.tintSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingIllustration extends StatefulWidget {
  final String asset;

  const _OnboardingIllustration({required this.asset});

  @override
  State<_OnboardingIllustration> createState() =>
      _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<_OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final image = Semantics(
      image: true,
      label: 'A hand-drawn SpineUp onboarding illustration',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            border: Border.all(
              color: const Color(0xFF176B61).withValues(alpha: 0.08),
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Image.asset(
            widget.asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );

    if (reduceMotion) {
      if (_ambientController.isAnimating) {
        _ambientController.stop(canceled: false);
      }
      return image;
    }
    if (!_ambientController.isAnimating) {
      _ambientController.repeat();
    }

    return AnimatedBuilder(
      animation: _ambientController,
      child: image,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          child!,
          IgnorePointer(
            child: CustomPaint(
              painter: _AmbientIllustrationPainter(
                asset: widget.asset,
                progress: _ambientController.value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientIllustrationPainter extends CustomPainter {
  final String asset;
  final double progress;

  const _AmbientIllustrationPainter({
    required this.asset,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isShared = asset.contains('care_can_be_shared');
    final isPath = asset.contains('keep_your_path_close');
    final t = progress * math.pi * 2;

    if (isShared) {
      _paintSwayingPlant(canvas, size, t);
    } else if (isPath) {
      _paintBreathingSun(canvas, size, t);
      _paintBreeze(canvas, size, t);
    } else {
      _paintBreathingSun(canvas, size, t);
      _paintSteam(canvas, size, t);
    }
  }

  void _paintBreathingSun(Canvas canvas, Size size, double t) {
    final center = Offset(size.width * 0.27, size.height * 0.28);
    final pulse = 1 + math.sin(t) * 0.08;
    final rayPaint = Paint()
      ..color = const Color(0xFFD96B32).withValues(alpha: 0.48)
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rayLength = 10 * pulse;
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + 0.1;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * 25;
      final end =
          center + Offset(math.cos(angle), math.sin(angle)) * (25 + rayLength);
      canvas.drawLine(start, end, rayPaint);
    }
  }

  void _paintSteam(Canvas canvas, Size size, double t) {
    final sway = math.sin(t * 0.75) * size.width * 0.012;
    final paint = Paint()
      ..color = const Color(0xFF176B61).withValues(alpha: 0.55)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 2; i++) {
      final x = size.width * (0.395 + i * 0.025);
      final path = Path()
        ..moveTo(x, size.height * 0.525)
        ..cubicTo(
          x + sway,
          size.height * 0.50,
          x - sway,
          size.height * 0.485,
          x + sway * 0.8,
          size.height * 0.46,
        );
      canvas.drawPath(path, paint);
    }
  }

  void _paintSwayingPlant(Canvas canvas, Size size, double t) {
    final base = Offset(size.width * 0.16, size.height * 0.78);
    final sway = math.sin(t) * 0.07;
    final stemPaint = Paint()
      ..color = const Color(0xFF3F7859).withValues(alpha: 0.72)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leafPaint = Paint()
      ..color = const Color(0xFF5A8660).withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(sway);
    canvas.drawLine(Offset.zero, const Offset(0, -55), stemPaint);
    canvas.drawOval(const Rect.fromLTWH(-20, -46, 20, 9), leafPaint);
    canvas.drawOval(const Rect.fromLTWH(1, -36, 22, 9), leafPaint);
    canvas.drawOval(const Rect.fromLTWH(-18, -25, 19, 8), leafPaint);
    canvas.restore();
  }

  void _paintBreeze(Canvas canvas, Size size, double t) {
    final drift = math.sin(t * 0.7) * size.width * 0.018;
    final paint = Paint()
      ..color = const Color(0xFF176B61).withValues(alpha: 0.46)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.43)
      ..cubicTo(
        size.width * 0.24 + drift,
        size.height * 0.415,
        size.width * 0.28 - drift,
        size.height * 0.45,
        size.width * 0.33,
        size.height * 0.43,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientIllustrationPainter oldDelegate) =>
      oldDelegate.asset != asset || oldDelegate.progress != progress;
}

class _LandingLeafPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _LandingLeafPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final eased = Curves.easeInOutCubic.transform(progress);
    final start = Offset(size.width * 0.80, size.height * 0.34);
    final target = Offset(size.width * 0.78, size.height * 0.91);
    final controlA = Offset(size.width * 0.96, size.height * 0.50);
    final controlB = Offset(size.width * 0.62, size.height * 0.68);
    final point = _cubicPoint(start, controlA, controlB, target, eased);
    final tangent = _cubicTangent(start, controlA, controlB, target, eased);
    final angle =
        math.atan2(tangent.dy, tangent.dx) +
        math.sin(progress * math.pi * 4) * 0.15;
    final scale = Curves.easeOut.transform(math.min(progress * 1.35, 1));

    canvas.save();
    canvas.translate(point.dx, point.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    final fill = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final ink = Paint()
      ..color = const Color(0xFF4E3942).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final leaf = Path()
      ..moveTo(-2, 0)
      ..cubicTo(8, -12, 23, -10, 26, -2)
      ..cubicTo(18, 7, 6, 9, -2, 0)
      ..close();
    canvas.drawPath(leaf, fill);
    canvas.drawPath(leaf, ink);
    canvas.drawLine(const Offset(0, 0), const Offset(20, -3), ink);
    canvas.restore();
  }

  Offset _cubicPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    return p0 * (u * u * u) +
        p1 * (3 * u * u * t) +
        p2 * (3 * u * t * t) +
        p3 * (t * t * t);
  }

  Offset _cubicTangent(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    return (p1 - p0) * (3 * u * u) +
        (p2 - p1) * (6 * u * t) +
        (p3 - p2) * (3 * t * t);
  }

  @override
  bool shouldRepaint(covariant _LandingLeafPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
