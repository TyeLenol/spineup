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
    bg: Color(0xFFF6F8F5),
    tint: Color(0xFF2F8668),
    tintSoft: Color(0xFF68736D),
    deep: Color(0xFF1F5F4B),
    headline: ['A private space', 'for your spine journey.'],
    subtext:
        'Notice, learn, and keep going in a space that stays on this phone.',
    cta: 'Next',
    imageAsset: 'assets/onboarding/onboarding_private_space.png',
  ),
  OnboardingScreenData(
    bg: Color(0xFFF6F8F5),
    tint: Color(0xFF2F8668),
    tintSoft: Color(0xFF68736D),
    deep: Color(0xFF1F5F4B),
    headline: ['Made for real life,', 'and real support.'],
    subtext: 'Use it for you, or for someone you care for.',
    cta: 'Next',
    imageAsset: 'assets/onboarding/onboarding_shared_care.png',
  ),
  OnboardingScreenData(
    bg: Color(0xFFF6F8F5),
    tint: Color(0xFF2F8668),
    tintSoft: Color(0xFF68736D),
    deep: Color(0xFF1F5F4B),
    headline: ['Your data', 'stays with you.'],
    subtext:
        'No account is required to begin. Export a protected copy whenever you choose.',
    cta: 'Get started',
    imageAsset: 'assets/onboarding/onboarding_data_stays_yours.png',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 1; // 1-indexed: 1..3
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step >= 1 && step <= kOnboardingScreens.length) {
      setState(() {
        _currentStep = step;
      });
    }
  }

  void _next() {
    if (_currentStep < kOnboardingScreens.length) {
      _goToStep(_currentStep + 1);
    } else {
      _complete();
    }
  }

  void _complete() {
    Navigator.of(context).pushReplacement(localFirstWelcomeRoute());
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
          _currentStep < kOnboardingScreens.length) {
        _next();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
          _currentStep > 1) {
        _goToStep(_currentStep - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = kOnboardingScreens[_currentStep - 1];
    final total = kOnboardingScreens.length;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Container(
          color: s.bg,
          child: SafeArea(
            child: Column(
              children: [
                StepAnnouncer(
                  message:
                      'Step $_currentStep of $total. ${s.headline[0]} ${s.headline[1]}. ${s.subtext}',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: _currentStep > 1
                            ? OnboardingIconButton(
                                icon: Icons.arrow_back_rounded,
                                label: 'Go back',
                                onClick: () => _goToStep(_currentStep - 1),
                                tint: s.tint,
                              )
                            : const SizedBox.shrink(),
                      ),
                      ProgressDots(
                        step: _currentStep,
                        total: total,
                        tint: s.tint,
                      ),
                      SizedBox(
                        height: 48,
                        child: _currentStep > 1
                            ? OnboardingSmallLink(
                                text: 'Skip',
                                ariaLabel: 'Skip onboarding',
                                onClick: _complete,
                                tint: s.tint,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Duration(
                      milliseconds: disableAnimations ? 0 : 350,
                    ),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Padding(
                      key: ValueKey(s.imageAsset),
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
                      child: Image.asset(
                        s.imageAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.headline[0],
                          style: GoogleFonts.fraunces(
                            color: s.tint,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.headline[1],
                          style: GoogleFonts.fraunces(
                            color: s.tintSoft,
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            height: 1.05,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.subtext,
                          style: GoogleFonts.outfit(
                            color: s.tintSoft,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        KeycapCta(
                          label: s.cta,
                          onClick: _next,
                          fill: s.tint,
                          ink: s.deep,
                          text: Colors.white,
                        ),
                      ],
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
