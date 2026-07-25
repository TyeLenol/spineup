import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class Ob2Illustration extends StatefulWidget {
  const Ob2Illustration({super.key});

  @override
  State<Ob2Illustration> createState() => _Ob2IllustrationState();
}

class _Ob2IllustrationState extends State<Ob2Illustration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _idleController;

  late Animation<double> _cardScale;
  late Animation<double> _badgeScale;
  late Animation<double> _blobAnim;

  // Idle floating offsets
  late Animation<double> _cardIdleY;
  late Animation<double> _badgeIdleY;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _cardScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _badgeScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack),
    );

    _blobAnim = CurvedAnimation(
      parent: _idleController,
      curve: Curves.easeInOut,
    );

    _cardIdleY = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _badgeIdleY = Tween<double>(begin: 2, end: -4).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 270,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Ambient background blur blobs (Left Sage, Right Lavender) ────
          AnimatedBuilder(
            animation: _blobAnim,
            builder: (context, child) {
              final scale1 = 1.0 + (0.15 * _blobAnim.value);
              final scale2 = 1.2 - (0.15 * _blobAnim.value);
              final opacity1 = 0.4 + (0.2 * _blobAnim.value);
              final opacity2 = 0.6 - (0.2 * _blobAnim.value);

              return Stack(
                children: [
                  // Sage Blob (Left)
                  Positioned(
                    left: 20,
                    top: 40,
                    child: Transform.scale(
                      scale: scale1,
                      child: Opacity(
                        opacity: opacity1,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primarySage.withValues(alpha: 0.25),
                                blurRadius: 40,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Lavender Blob (Right)
                  Positioned(
                    right: 20,
                    bottom: 40,
                    child: Transform.scale(
                      scale: scale2,
                      child: Opacity(
                        opacity: opacity2,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentLavender.withValues(alpha: 0.25),
                                blurRadius: 45,
                                spreadRadius: 25,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Central Card ────────────────────────────────────────────────
          ScaleTransition(
            scale: _cardScale,
            child: AnimatedBuilder(
              animation: _cardIdleY,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _cardIdleY.value),
                child: child,
              ),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.cardCream,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: AppTheme.borderCream.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar circle (purple)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentLavender,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Three green dots (...)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primarySage,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating XP / Rewards Badge ───────────────────────────────
          Positioned(
            top: 25,
            right: 40,
            child: ScaleTransition(
              scale: _badgeScale,
              child: AnimatedBuilder(
                animation: _badgeIdleY,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _badgeIdleY.value),
                  child: child,
                ),
                child: Transform.rotate(
                  angle: 12 * math.pi / 180, // 12 degrees
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryCoral,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryCoral.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      '+50 XP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
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
