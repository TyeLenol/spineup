import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../widgets/onboarding/breathing_widget.dart';
import '../widgets/onboarding/count_up_widget.dart';
import '../widgets/onboarding/keycap_cta.dart';
import '../widgets/onboarding/morph_shape.dart';
import '../widgets/onboarding/onboarding_chrome.dart';
import 'auth_screen.dart';

class OnboardingScreenData {
  final Color bg;
  final Color edge;
  final Color shape;
  final Color accent;
  final Color tint;
  final Color tintSoft;
  final Color deep;
  final List<String> headline;
  final String subtext;
  final String cta;
  final bool overshoot;

  const OnboardingScreenData({
    required this.bg,
    required this.edge,
    required this.shape,
    required this.accent,
    required this.tint,
    required this.tintSoft,
    required this.deep,
    required this.headline,
    required this.subtext,
    required this.cta,
    required this.overshoot,
  });
}

const List<OnboardingScreenData> kOnboardingScreens = [
  // Screen 1: Sage
  OnboardingScreenData(
    bg: Color(0xFF0F6E56),
    edge: Color(0xFF04342C),
    shape: Color(0xFF2F8F74),
    accent: Color(0xFF7FD3B6),
    tint: Color(0xFFE8F7F1),
    tintSoft: Color(0xFFC6EAD9),
    deep: Color(0xFF04342C),
    headline: ['Your spine has a story.', "Let's track it."],
    subtext: 'Log brace time and exercises daily, and watch the picture of your curve come together.',
    cta: 'Next',
    overshoot: false,
  ),

  // Screen 2: Lavender
  OnboardingScreenData(
    bg: Color(0xFF3C3489),
    edge: Color(0xFF26215C),
    shape: Color(0xFF5A51B0),
    accent: Color(0xFFA79FF0),
    tint: Color(0xFFEEECFB),
    tintSoft: Color(0xFFC5BFF2),
    deep: Color(0xFF221D55),
    headline: ['Every stretch counts', 'toward something.'],
    subtext: 'Brace hours and stretches feed one daily ring — fill it and your streak keeps going.',
    cta: 'Next',
    overshoot: true,
  ),

  // Screen 3: Coral
  OnboardingScreenData(
    bg: Color(0xFF993C1D),
    edge: Color(0xFF712B13),
    shape: Color(0xFFBF5730),
    accent: Color(0xFFF0A181),
    tint: Color(0xFFFDEEE7),
    tintSoft: Color(0xFFF5C6AE),
    deep: Color(0xFF5C2210),
    headline: ['Show up,', 'level up.'],
    subtext: 'Real actions earn real XP, so every session pushes your level and streak forward.',
    cta: 'Next',
    overshoot: true,
  ),

  // Screen 4: Azure
  OnboardingScreenData(
    bg: Color(0xFF10556C),
    edge: Color(0xFF082F3E),
    shape: Color(0xFF1C7592),
    accent: Color(0xFF7FCBE4),
    tint: Color(0xFFE6F5FA),
    tintSoft: Color(0xFFB9E2F0),
    deep: Color(0xFF052430),
    headline: ["You're not doing", 'this alone.'],
    subtext: "Follow others managing scoliosis, swap what actually helps, and cheer each other's streaks on.",
    cta: 'Next',
    overshoot: true,
  ),

  // Screen 5: Lavender Privacy
  OnboardingScreenData(
    bg: Color(0xFF3C3489),
    edge: Color(0xFF26215C),
    shape: Color(0xFF5A51B0),
    accent: Color(0xFFA79FF0),
    tint: Color(0xFFEEECFB),
    tintSoft: Color(0xFFC5BFF2),
    deep: Color(0xFF221D55),
    headline: ['Your data', 'stays yours.'],
    subtext: 'Stored on this device, never sold or shared, and deletable anytime in Settings.',
    cta: 'Get started',
    overshoot: false,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 1; // 1-indexed: 1..5
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
    Navigator.of(context).push(authRoute(AuthMode.signup));
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight && _currentStep < kOnboardingScreens.length) {
        _next();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && _currentStep > 1) {
        _goToStep(_currentStep - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = kOnboardingScreens[_currentStep - 1];
    final total = kOnboardingScreens.length;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: AnimatedContainer(
          duration: Duration(milliseconds: disableAnimations ? 0 : 400),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.3),
              radius: 1.2,
              colors: [s.bg, s.bg, s.edge],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                StepAnnouncer(
                  message: 'Step $_currentStep of $total. ${s.headline[0]} ${s.headline[1]}. ${s.subtext}',
                ),

                // ── Header Chrome ───────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    top: topPadding > 0 ? 8.0 : 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (hidden on screen 1)
                      SizedBox(
                        width: 48.0,
                        height: 48.0,
                        child: _currentStep > 1
                            ? OnboardingIconButton(
                                icon: Icons.arrow_back_rounded,
                                label: 'Go back',
                                onClick: () => _goToStep(_currentStep - 1),
                                tint: s.tint,
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Progress dots (1..5)
                      ProgressDots(
                        step: _currentStep,
                        total: total,
                        tint: s.tint,
                      ),

                      // Skip link (hidden on screen 1)
                      SizedBox(
                        height: 48.0,
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

                // ── Central Graphic Area ─────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_currentStep == 1)
                          BreathingWidget(
                            child: MorphShape(
                              index: 0.0,
                              fill: s.shape,
                              accent: s.accent,
                              overshoot: false,
                              size: 300.0,
                            ),
                          )
                        else
                          MorphShape(
                            index: (_currentStep - 1).toDouble(),
                            fill: s.shape,
                            accent: s.accent,
                            overshoot: s.overshoot,
                            ringProgress: _currentStep == 2 ? 0.70 : null,
                            nodes: _currentStep == 4,
                            layered: _currentStep == 5,
                            size: _currentStep == 5 ? 232.0 : 300.0,
                          ),

                        if (_currentStep == 3)
                          CountUpWidget(
                            to: 120,
                            color: s.tint,
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Content & Bottom CTA ────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    bottom: bottomPadding > 0 ? bottomPadding + 12.0 : 24.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Headline
                        Text(
                          s.headline[0],
                          style: TextStyle(
                            color: s.tint,
                            fontSize: 38.0,
                            fontWeight: FontWeight.w900,
                            height: 1.02,
                            letterSpacing: -0.5,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          s.headline[1],
                          style: TextStyle(
                            color: s.tintSoft,
                            fontSize: 30.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            height: 1.1,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // Subtext
                        Text(
                          s.subtext,
                          style: TextStyle(
                            color: s.tintSoft,
                            fontSize: 14.0,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 32.0),

                        // Keycap CTA button
                        KeycapCta(
                          label: s.cta,
                          onClick: _next,
                          fill: s.tint,
                          ink: s.deep,
                          text: s.edge,
                        ),
                        const SizedBox(height: 8.0),
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
