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
                        width: 72,
                        height: 48,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _currentStep > 1
                              ? OnboardingIconButton(
                                  icon: Icons.arrow_back_rounded,
                                  label: 'Go back',
                                  onClick: _previous,
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
                      SizedBox(
                        width: 72,
                        height: 48,
                        child: Align(
                          alignment: Alignment.centerRight,
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
                    layoutBuilder: (currentChild, previousChildren) => Stack(
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
                        child: SlideTransition(position: settle, child: child),
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
                  duration: Duration(milliseconds: disableAnimations ? 0 : 260),
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

class _OnboardingIllustration extends StatefulWidget {
  final String asset;

  const _OnboardingIllustration({required this.asset});

  @override
  State<_OnboardingIllustration> createState() =>
      _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<_OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loopController;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _breath = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _loopController.dispose();
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
      if (_loopController.isAnimating) {
        _loopController.stop(canceled: false);
      }
      return image;
    }
    if (!_loopController.isAnimating) {
      _loopController.repeat(reverse: true);
    }

    return AnimatedBuilder(
      animation: _breath,
      child: image,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _breath.value * 2),
        child: child,
      ),
    );
  }
}
