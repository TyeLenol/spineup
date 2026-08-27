import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/vera_character.dart';

class Ob3Illustration extends StatefulWidget {
  const Ob3Illustration({super.key});

  @override
  State<Ob3Illustration> createState() => _Ob3IllustrationState();
}

class _Ob3IllustrationState extends State<Ob3Illustration>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _floatCtrl;

  late Animation<double> _veraEntry;
  late Animation<double> _card1Entry;
  late Animation<double> _card2Entry;
  late Animation<double> _card3Entry;
  late Animation<double> _pillEntry;

  late Animation<double> _card1Float;
  late Animation<double> _card2Float;
  late Animation<double> _card3Float;
  late Animation<double> _pillFloat;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _veraEntry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.50, curve: Curves.elasticOut),
    );
    _card1Entry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.20, 0.60, curve: Curves.easeOutBack),
    );
    _card2Entry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.32, 0.72, curve: Curves.easeOutBack),
    );
    _card3Entry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.44, 0.84, curve: Curves.easeOutBack),
    );
    _pillEntry = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutBack),
    );

    _card1Float = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _card2Float = Tween<double>(begin: 4, end: -5).animate(
      CurvedAnimation(
        parent: _floatCtrl,
        curve: const Interval(0.1, 1.0, curve: Curves.easeInOut),
      ),
    );
    _card3Float = Tween<double>(begin: -3, end: 6).animate(
      CurvedAnimation(
        parent: _floatCtrl,
        curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
      ),
    );
    _pillFloat = Tween<double>(begin: 3, end: -4).animate(
      CurvedAnimation(
        parent: _floatCtrl,
        curve: const Interval(0.15, 0.9, curve: Curves.easeInOut),
      ),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 310,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Ambient glow ────────────────────────────────────────────────
          Positioned(
            right: 10,
            top: 30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentLavender.withValues(alpha: 0.18),
                    blurRadius: 70,
                    spreadRadius: 28,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 15,
            bottom: 30,
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

          // ── Community cards fanned behind Vera ───────────────────────────

          // Card 3 — Cobb chart (back, leftmost)
          Positioned(
            left: 10,
            top: 50,
            child: ScaleTransition(
              scale: _card3Entry,
              child: AnimatedBuilder(
                animation: _card3Float,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _card3Float.value),
                  child: child,
                ),
                child: Transform.rotate(
                  angle: -14 * math.pi / 180,
                  child: _CommunityCard(
                    content: '📉 Cobb angle: 28° → 26°',
                    subtext: 'Logged 3 months ago',
                    accent: AppTheme.primarySage,
                  ),
                ),
              ),
            ),
          ),

          // Card 1 — milestone post (front-left)
          Positioned(
            left: 35,
            top: 30,
            child: ScaleTransition(
              scale: _card1Entry,
              child: AnimatedBuilder(
                animation: _card1Float,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _card1Float.value),
                  child: child,
                ),
                child: Transform.rotate(
                  angle: -5 * math.pi / 180,
                  child: _CommunityCard(
                    content: 'Just hit 30 days! 🏆',
                    subtext: 'Mia · Spine Warriors',
                    accent: AppTheme.secondaryCoral,
                  ),
                ),
              ),
            ),
          ),

          // Card 2 — reply (front-right)
          Positioned(
            right: 15,
            top: 55,
            child: ScaleTransition(
              scale: _card2Entry,
              child: AnimatedBuilder(
                animation: _card2Float,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _card2Float.value),
                  child: child,
                ),
                child: Transform.rotate(
                  angle: 9 * math.pi / 180,
                  child: _ReplyCard(text: 'you\'ve got this 💪'),
                ),
              ),
            ),
          ),

          // ── Vera — bottom centre, leaning slightly ───────────────────────
          Positioned(
            bottom: 22,
            child: ScaleTransition(
              scale: _veraEntry,
              child: const VeraCharacter(
                size: 120,
                pose: VeraPose.wave,
                enableIdleBob: true,
              ),
            ),
          ),

          // ── XP tease pill ────────────────────────────────────────────────
          Positioned(
            bottom: 10,
            right: 10,
            child: ScaleTransition(
              scale: _pillEntry,
              child: AnimatedBuilder(
                animation: _pillFloat,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _pillFloat.value),
                  child: child,
                ),
                child: _CoralPill(label: 'Share milestone → +50 XP 👥'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final String content;
  final String subtext;
  final Color accent;

  const _CommunityCard({
    required this.content,
    required this.subtext,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Accent bar
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.foregroundDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: accent, size: 11),
              const SizedBox(width: 3),
              Text(
                '24',
                style: TextStyle(
                  fontSize: 9,
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  final String text;
  const _ReplyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.accentLavender.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(4),
          bottomLeft: Radius.circular(14),
        ),
        border: Border.all(
          color: AppTheme.accentLavender.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.foregroundDark,
        ),
      ),
    );
  }
}

class _CoralPill extends StatelessWidget {
  final String label;
  const _CoralPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryCoral,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryCoral.withValues(alpha: 0.38),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
