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
  final List<String> headline;
  final String subtext;
  final String cta;
  final String imageAsset;

  const OnboardingScreenData({
    required this.bg,
    required this.tint,
    required this.tintSoft,
    required this.deep,
    required this.headline,
    required this.subtext,
    required this.cta,
    required this.imageAsset,
  });
}

const List<OnboardingScreenData> kOnboardingScreens = [
  OnboardingScreenData(
    bg: Color(0xFFF7FAF8),
    tint: Color(0xFF2F8668),
    tintSoft: Color(0xFF68736D),
    deep: Color(0xFF1F5F4B),
    headline: ['A calmer place', 'to keep care together.'],
    subtext:
        'Build a simple record of check-ins, routines, and questions around what matters to you.',
    cta: 'Next',
    imageAsset: 'assets/onboarding/onboarding_private_space_textured.png',
  ),
  OnboardingScreenData(
    bg: Color(0xFFF7FAF8),
    tint: Color(0xFF2F8668),
    tintSoft: Color(0xFF68736D),
    deep: Color(0xFF1F5F4B),
    headline: ['Made for real life,', 'and real support.'],
    subtext:
        'Set up a profile for yourself or someone you care for, with each person’s records kept separate.',
    cta: 'Next',
    imageAsset: 'assets/onboarding/onboarding_shared_care_textured.png',
  ),
  OnboardingScreenData(
    bg: Color(0xFFF7FAF8),
    tint: Color(0xFF2F8668),
    tintSoft: Color(0xFF68736D),
    deep: Color(0xFF1F5F4B),
    headline: ['Your records', 'stay in your hands.'],
    subtext:
        'SpineUp works on this phone. When you choose, you can make a protected copy before moving to another device.',
    cta: 'Get started',
    imageAsset: 'assets/onboarding/onboarding_data_stays_yours_textured.png',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 1;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step >= 1 && step <= kOnboardingScreens.length) {
      setState(() => _currentStep = step);
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
            child: Column(
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
                        width: 48,
                        height: 48,
                        child: _currentStep > 1
                            ? OnboardingIconButton(
                                icon: Icons.arrow_back_rounded,
                                label: 'Go back',
                                onClick: _previous,
                                tint: screen.tint,
                              )
                            : const SizedBox.shrink(),
                      ),
                      const Spacer(),
                      ProgressDots(
                        step: _currentStep,
                        total: total,
                        tint: screen.tint,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: _currentStep < total
                            ? OnboardingSmallLink(
                                text: 'Skip',
                                ariaLabel: 'Skip onboarding',
                                onClick: _complete,
                                tint: screen.tint,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Duration(
                      milliseconds: disableAnimations ? 0 : 520,
                    ),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.center,
                      children: [...previousChildren, ?currentChild],
                    ),
                    transitionBuilder: (child, animation) {
                      final slide =
                          Tween<Offset>(
                            begin: const Offset(0.08, 0.025),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                      final scale = Tween<double>(begin: 0.965, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slide,
                          child: ScaleTransition(scale: scale, child: child),
                        ),
                      );
                    },
                    child: Padding(
                      key: ValueKey(screen.imageAsset),
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 2),
                      child: _OnboardingIllustration(asset: screen.imageAsset),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: disableAnimations ? 0 : 360),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
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
                              color: screen.tintSoft,
                              fontSize: 14.5,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          KeycapCta(
                            label: screen.cta,
                            onClick: _next,
                            fill: screen.tint,
                            ink: screen.deep,
                            text: Colors.white,
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
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  final String asset;

  const _OnboardingIllustration({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'A hand-drawn SpineUp onboarding illustration',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF8),
            border: Border.all(
              color: const Color(0xFF2F8668).withValues(alpha: 0.08),
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
