import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/edge_to_edge_helper.dart';
import '../widgets/chunky_3d_button.dart';
import '../widgets/interactive_gradient_canvas.dart';
import '../widgets/m3_squiggly_line.dart';

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

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardCtrl;
  late Animation<double> _cardY;
  late Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final cardCurve = CurvedAnimation(
      parent: _cardCtrl,
      curve: Curves.easeOutCubic,
    );
    _cardY = Tween<double>(begin: 65, end: 0).animate(cardCurve);
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(cardCurve);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardCtrl.forward();
    });
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EdgeToEdgeHelper.configureSystemUi(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final accent = widget.accentColor ?? AppTheme.secondaryCoral;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: InteractiveGradientCanvas(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // ── 1. Top Header Bar (56px) ──────────────────────────────────
              Positioned(
                top: 4,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Chevron (Steps 2 and 3)
                    if (widget.onBack != null)
                      InkWell(
                        onTap: widget.onBack,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppTheme.foregroundDark,
                            size: 26,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 44, height: 44),

                    // Skip Chip
                    _SkipChip(onTap: widget.onSkip),
                  ],
                ),
              ),

              // ── 2. Interactive Game Stage (Upper 58% Height) ──────────────
              Positioned(
                top: 45,
                left: 0,
                right: 0,
                height: screenHeight * 0.50,
                child: Center(
                  child: RepaintBoundary(
                    child: widget.illustration,
                  ),
                ),
              ),

              // ── 3. Frosted Control Dock (Bottom 42% Height) ──────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _cardCtrl,
                  builder: (context, child) => Opacity(
                    opacity: _cardOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _cardY.value),
                      child: child,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Organic M3 Squiggly Stage Contour
                      const M3SquigglyDivider(
                        color: Color(0xBDF5EDD8),
                        height: 16,
                      ),

                      // Control Dock Content
                      ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.74),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.60),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            padding: EdgeInsets.only(
                              left: 26,
                              right: 26,
                              top: 20,
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Headline Plain Text
                                Text(
                                  widget.titlePlain.trimRight(),
                                  style: GoogleFonts.fraunces(
                                    fontSize: 30,
                                    height: 1.15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.foregroundDark,
                                    letterSpacing: -0.4,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                // Headline Accent Text + M3 Squiggly Underline
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.titleAccent,
                                      style: GoogleFonts.fraunces(
                                        fontSize: 30,
                                        height: 1.15,
                                        fontWeight: FontWeight.w700,
                                        fontStyle: FontStyle.italic,
                                        color: accent,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    // Animated M3 Squiggly Underline
                                    M3SquigglyUnderline(
                                      width: 175,
                                      color: accent,
                                      strokeWidth: 3.5,
                                      amplitude: 3.0,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Raw, Authentic Non-AI Body Copy
                                Text(
                                  widget.description,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    height: 1.48,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Action Row: Orb Dots + 3D Push Button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Progress Orbs
                                    _OrbDots(step: widget.step),

                                    // 3D Tactile Push Button
                                    Chunky3DButton(
                                      label: widget.isLast
                                          ? 'Join the App →'
                                          : widget.step == 1
                                              ? 'Tap Vera for +30 XP →'
                                              : 'Try the Streak Stack →',
                                      color: accent,
                                      depthColor: accent == AppTheme.primarySage
                                          ? const Color(0xFF3B8E72)
                                          : const Color(0xFFB33D18),
                                      onTap: widget.onNext,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipChip extends StatelessWidget {
  final VoidCallback onTap;
  const _SkipChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbDots extends StatelessWidget {
  final int step;
  const _OrbDots({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index == (step - 1);
        return Container(
          margin: const EdgeInsets.only(right: 8),
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.secondaryCoral : AppTheme.borderCream,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.secondaryCoral.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1.5,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
