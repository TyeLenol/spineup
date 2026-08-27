import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/vera_character.dart';

/// Screen 1 Interactive Stage featuring Vera's articulated S-curve spine.
class Ob1Illustration extends StatefulWidget {
  const Ob1Illustration({super.key});

  @override
  State<Ob1Illustration> createState() => _Ob1IllustrationState();
}

class _Ob1IllustrationState extends State<Ob1Illustration>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _floatCtrl;

  late Animation<double> _veraEntry;
  late Animation<double> _card1Entry;
  late Animation<double> _pillEntry;

  late Animation<double> _card1Float;
  late Animation<double> _pillFloat;

  int _flexCount = 0;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _veraEntry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.60, curve: Curves.elasticOut),
    );
    _card1Entry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOutBack),
    );
    _pillEntry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOutBack),
    );

    _card1Float = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _pillFloat = Tween<double>(begin: 3, end: -4).animate(
      CurvedAnimation(
          parent: _floatCtrl,
          curve: const Interval(0.1, 0.9, curve: Curves.easeInOut)),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _onFlex() {
    setState(() => _flexCount++);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Vera in center stage
          Center(
            child: ScaleTransition(
              scale: _veraEntry,
              child: VeraCharacter(
                size: 160,
                pose: VeraPose.celebrate,
                enableIdleBob: true,
                onTapFlex: _onFlex,
              ),
            ),
          ),

          // Floating Stretch Preview Card (top-left)
          Positioned(
            left: 5,
            top: 25,
            child: ScaleTransition(
              scale: _card1Entry,
              child: AnimatedBuilder(
                animation: _card1Float,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _card1Float.value),
                  child: child,
                ),
                child: Transform.rotate(
                  angle: -7 * math.pi / 180,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.borderCream.withValues(alpha: 0.7),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.self_improvement_rounded,
                          color: AppTheme.primarySage,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Cat-Cow Stretch',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foregroundDark,
                              ),
                            ),
                            Text(
                              '+30 XP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.secondaryCoral,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Interactive Tap Prompt (bottom)
          Positioned(
            bottom: 12,
            child: ScaleTransition(
              scale: _pillEntry,
              child: AnimatedBuilder(
                animation: _pillFloat,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _pillFloat.value),
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCoral,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryCoral.withValues(alpha: 0.38),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _flexCount == 0
                        ? '🔥 Tap Vera to flex her S-curve!'
                        : '🎉 Flexed $_flexCount time${_flexCount > 1 ? 's' : ''}! +${_flexCount * 30} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
