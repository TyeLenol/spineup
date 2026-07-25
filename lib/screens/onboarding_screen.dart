import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/edge_to_edge_helper.dart';

class OnboardingScreen extends StatefulWidget {
  final int step;
  final String titlePlain;
  final String titleAccent;
  final String description;
  final Widget illustration;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final bool isLast;

  final Color? accentColor;

  const OnboardingScreen({
    super.key,
    required this.step,
    required this.titlePlain,
    required this.titleAccent,
    required this.description,
    required this.illustration,
    required this.onNext,
    this.onBack,
    required this.onSkip,
    this.isLast = false,
    this.accentColor,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Screen-level entrance (x:50→0, opacity:0→1) is driven by [onboardingRoute]
/// in main.dart. Internal elements use staggered rise animations matching
/// reference_ui App.tsx lines 406–422.
class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Illustration: delay 300ms, 700ms duration — scale+fade in
  late AnimationController _illustrationCtrl;
  late Animation<double> _illustrationOpacity;
  late Animation<double> _illustrationY;

  // Skip button: delay 200ms, 600ms duration — right to left
  late AnimationController _skipCtrl;
  late Animation<double> _skipOpacity;
  late Animation<double> _skipX;

  // Text block: delay 500ms, 600ms duration
  late AnimationController _textCtrl;
  late Animation<double> _textOpacity;
  late Animation<double> _textY;

  // Bottom row: delay 700ms, 600ms duration
  late AnimationController _bottomCtrl;
  late Animation<double> _bottomOpacity;
  late Animation<double> _bottomY;

  @override
  void initState() {
    super.initState();

    _illustrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final illCurve =
        CurvedAnimation(parent: _illustrationCtrl, curve: Curves.easeOut);
    _illustrationOpacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(illCurve);
    _illustrationY =
        Tween<double>(begin: 30.0, end: 0.0).animate(illCurve);

    _skipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final skipCurve = CurvedAnimation(parent: _skipCtrl, curve: Curves.easeOut);
    _skipOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(skipCurve);
    _skipX = Tween<double>(begin: 20.0, end: 0.0).animate(skipCurve);

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final textCurve = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(textCurve);
    _textY = Tween<double>(begin: 20.0, end: 0.0).animate(textCurve);

    _bottomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final bottomCurve =
        CurvedAnimation(parent: _bottomCtrl, curve: Curves.easeOut);
    _bottomOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(bottomCurve);
    _bottomY = Tween<double>(begin: 20.0, end: 0.0).animate(bottomCurve);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _skipCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _illustrationCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _bottomCtrl.forward();
    });
  }

  @override
  void dispose() {
    _skipCtrl.dispose();
    _illustrationCtrl.dispose();
    _textCtrl.dispose();
    _bottomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EdgeToEdgeHelper.configureSystemUi(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: Back & Skip ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onBack != null)
                    InkWell(
                      onTap: widget.onBack,
                      borderRadius: BorderRadius.circular(24),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: AppTheme.mutedForeground,
                          size: 28,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48, height: 48),
                  AnimatedBuilder(
                    animation: _skipCtrl,
                    builder: (context, child) => Opacity(
                      opacity: _skipOpacity.value,
                      child: Transform.translate(
                        offset: Offset(_skipX.value, 0),
                        child: child,
                      ),
                    ),
                    child: InkWell(
                      onTap: widget.onSkip,
                      borderRadius: BorderRadius.circular(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Illustration ────────────────────────────────────────────────
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _illustrationCtrl,
                  builder: (context, child) => Opacity(
                    opacity: _illustrationOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _illustrationY.value),
                      child: child,
                    ),
                  ),
                  child: RepaintBoundary(
                    child: widget.illustration,
                  ),
                ),
              ),
            ),

            // ── Text & Bottom Actions ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 28, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Headline + Description: rise from y=20 after 200ms delay
                  // Ref: initial={{ y: 20, opacity: 0 }}, delay: 0.2, duration: 0.6
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (context, child) => Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textY.value),
                        child: child,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                               TextSpan(
                                 text: widget.titlePlain,
                                 style: GoogleFonts.fraunces(
                                   fontSize: 34,
                                   height: 1.15,
                                   fontWeight: FontWeight.w600,
                                   color: AppTheme.foregroundDark,
                                   letterSpacing: -0.5,
                                 ),
                                ),
                                TextSpan(
                                  text: widget.titleAccent,
                                  style: GoogleFonts.fraunces(
                                    fontSize: 34,
                                    height: 1.15,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                    color: widget.accentColor ?? AppTheme.secondaryCoral,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.description,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            height: 1.45,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Bottom row: rise from y=20 after 400ms delay
                  // Ref: initial={{ y: 20, opacity: 0 }}, delay: 0.4, duration: 0.6
                  AnimatedBuilder(
                    animation: _bottomCtrl,
                    builder: (context, child) => Opacity(
                      opacity: _bottomOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _bottomY.value),
                        child: child,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page indicator dots
                        Row(
                          children: List.generate(3, (index) {
                            final isActive = index == (widget.step - 1);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.only(right: 6),
                              width: isActive ? 32 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.foregroundDark
                                    : AppTheme.borderCream,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),

                        // Next / Get Started button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onNext,
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              height: 56,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySage,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.isLast ? 'Get Started' : 'Next',
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onPrimaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const FaIcon(
                                    FontAwesomeIcons.arrowRight,
                                    color: AppTheme.onPrimaryDark,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
