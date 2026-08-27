import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/vera_character.dart';

class Ob2Illustration extends StatefulWidget {
  const Ob2Illustration({super.key});

  @override
  State<Ob2Illustration> createState() => _Ob2IllustrationState();
}

class _Ob2IllustrationState extends State<Ob2Illustration>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _pulseCtrl;

  // Entry animations
  late Animation<double> _veraEntry;
  late Animation<double> _towerEntry; // grows from bottom
  late Animation<double> _pillEntry;

  // Idle float
  late Animation<double> _veraFloat;
  late Animation<double> _pillFloat;

  // Crown pulse on top block
  late Animation<double> _crownPulse;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _veraEntry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    _towerEntry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.20, 0.75, curve: Curves.easeOutBack),
    );
    _pillEntry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOutBack),
    );

    _veraFloat = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _pillFloat = Tween<double>(begin: 3, end: -4).animate(
      CurvedAnimation(parent: _floatCtrl,
          curve: const Interval(0.15, 1.0, curve: Curves.easeInOut)),
    );
    _crownPulse = Tween<double>(begin: 1.0, end: 1.20).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Ambient glow ────────────────────────────────────────────────
          Positioned(
            left: 20,
            top: 50,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryCoral.withValues(alpha: 0.18),
                    blurRadius: 70,
                    spreadRadius: 25,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primarySage.withValues(alpha: 0.18),
                    blurRadius: 70,
                    spreadRadius: 25,
                  ),
                ],
              ),
            ),
          ),

          // ── Streak Tower (right side) ────────────────────────────────────
          Positioned(
            right: 28,
            bottom: 40,
            child: ScaleTransition(
              scale: _towerEntry,
              alignment: Alignment.bottomCenter,
              child: _StreakTower(crownPulse: _crownPulse),
            ),
          ),

          // ── Vera (left / centre) ─────────────────────────────────────────
          Positioned(
            left: 28,
            bottom: 36,
            child: ScaleTransition(
              scale: _veraEntry,
              child: AnimatedBuilder(
                animation: _veraFloat,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _veraFloat.value),
                  child: child,
                ),
                child: const VeraCharacter(
                  size: 128,
                  pose: VeraPose.celebrate,
                  enableIdleBob: false, // float handled externally
                ),
              ),
            ),
          ),

          // ── XP tease pill ────────────────────────────────────────────────
          Positioned(
            top: 16,
            child: ScaleTransition(
              scale: _pillEntry,
              child: AnimatedBuilder(
                animation: _pillFloat,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _pillFloat.value),
                  child: child,
                ),
                child: _SagePill(label: '🔥 7-Day Streak = Bonus XP'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stacked day-block tower with a glowing crown on top.
class _StreakTower extends StatelessWidget {
  final Animation<double> crownPulse;
  const _StreakTower({required this.crownPulse});

  @override
  Widget build(BuildContext context) {
    const litColor = AppTheme.secondaryCoral;
    const unlitColor = AppTheme.borderCream;
    final days = [
      (lit: true, label: 'M'),
      (lit: true, label: 'T'),
      (lit: true, label: 'W'),
      (lit: true, label: 'T'),
      (lit: false, label: 'F'),
      (lit: false, label: 'S'),
      (lit: false, label: 'S'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown
        AnimatedBuilder(
          animation: crownPulse,
          builder: (context, child) => Transform.scale(
            scale: crownPulse.value,
            child: const Text('🏆', style: TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(height: 6),
        // Blocks — stacked bottom-to-top in reverse
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < days.length; i++)
              _DayBlock(
                lit: days[i].lit,
                label: days[i].label,
                height: 22.0 + i * 10.0,
                litColor: litColor,
                unlitColor: unlitColor,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayBlock extends StatelessWidget {
  final bool lit;
  final String label;
  final double height;
  final Color litColor;
  final Color unlitColor;

  const _DayBlock({
    required this.lit,
    required this.label,
    required this.height,
    required this.litColor,
    required this.unlitColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = lit ? litColor : unlitColor;
    return Container(
      width: 20,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        boxShadow: lit
            ? [
                BoxShadow(
                  color: litColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: lit ? Colors.white : AppTheme.mutedForeground,
        ),
      ),
    );
  }
}

class _SagePill extends StatelessWidget {
  final String label;
  const _SagePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.primarySage,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primarySage.withValues(alpha: 0.38),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
