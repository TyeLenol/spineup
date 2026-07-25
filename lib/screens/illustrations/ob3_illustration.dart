import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class Ob3Illustration extends StatefulWidget {
  const Ob3Illustration({super.key});

  @override
  State<Ob3Illustration> createState() => _Ob3IllustrationState();
}

class _Ob3IllustrationState extends State<Ob3Illustration>
    with TickerProviderStateMixin {
  late AnimationController _card1Ctrl;
  late AnimationController _card2Ctrl;
  late AnimationController _badgeCtrl;

  late Animation<double> _card1X;
  late Animation<double> _card1Opacity;
  late Animation<double> _card2X;
  late Animation<double> _card2Opacity;
  late Animation<double> _badgeY;
  late Animation<double> _badgeOpacity;

  late AnimationController _idleCtrl;
  late Animation<double> _card1IdleY;
  late Animation<double> _card2IdleY;
  late Animation<double> _badgeIdleY;
  late Animation<double> _blobAnim;

  @override
  void initState() {
    super.initState();

    _card1Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    final card1Curve = CurvedAnimation(parent: _card1Ctrl, curve: Curves.easeOutBack);
    _card1X = Tween<double>(begin: -40.0, end: 0.0).animate(card1Curve);
    _card1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _card1Ctrl, curve: Curves.easeOut));

    _card2Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    final card2Curve = CurvedAnimation(parent: _card2Ctrl, curve: Curves.easeOutBack);
    _card2X = Tween<double>(begin: 40.0, end: 0.0).animate(card2Curve);
    _card2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _card2Ctrl, curve: Curves.easeOut));

    _badgeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    final badgeCurve = CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOutBack);
    _badgeY = Tween<double>(begin: 30.0, end: 0.0).animate(badgeCurve);
    _badgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOut));

    _idleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);

    _card1IdleY = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _idleCtrl, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)));
    _card2IdleY = Tween<double>(begin: 4.0, end: -5.0).animate(
      CurvedAnimation(parent: _idleCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeInOut)));
    _badgeIdleY = Tween<double>(begin: -3.0, end: 4.0).animate(
      CurvedAnimation(parent: _idleCtrl, curve: const Interval(0.1, 1.0, curve: Curves.easeInOut)));
    _blobAnim = CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut);

    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _card1Ctrl.forward(); });
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _card2Ctrl.forward(); });
    Future.delayed(const Duration(milliseconds: 700), () { if (mounted) _badgeCtrl.forward(); });
  }

  @override
  void dispose() {
    _card1Ctrl.dispose();
    _card2Ctrl.dispose();
    _badgeCtrl.dispose();
    _idleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ambient blobs
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _blobAnim,
              builder: (context, _) {
                final scale1 = 1.0 + (0.15 * _blobAnim.value);
                final scale2 = 1.2 - (0.12 * _blobAnim.value);
                final opacity1 = 0.35 + (0.2 * _blobAnim.value);
                final opacity2 = 0.55 - (0.15 * _blobAnim.value);
                return Stack(
                  children: [
                    Positioned(
                      top: 10, right: 10,
                      child: Transform.scale(scale: scale1,
                        child: Opacity(opacity: opacity1,
                          child: Container(width: 90, height: 90,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppTheme.primarySage.withValues(alpha: 0.28),
                                blurRadius: 48, spreadRadius: 24)])))),
                    ),
                    Positioned(
                      bottom: 20, left: 15,
                      child: Transform.scale(scale: scale2,
                        child: Opacity(opacity: opacity2,
                          child: Container(width: 80, height: 80,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppTheme.secondaryCoral.withValues(alpha: 0.22),
                                blurRadius: 42, spreadRadius: 20)])))),
                    ),
                  ],
                );
              },
            ),
          ),

          // Card 1: top-left, -2 deg tilt, slides from left
          Positioned(
            top: 16, left: 12,
            child: AnimatedBuilder(
              animation: Listenable.merge([_card1Ctrl, _idleCtrl]),
              builder: (context, child) => Opacity(
                opacity: _card1Opacity.value,
                child: Transform.translate(
                  offset: Offset(_card1X.value, _card1IdleY.value),
                  child: Transform.rotate(angle: -0.035, child: child))),
              child: RepaintBoundary(child: _buildCard1()),
            ),
          ),

          // Card 2: bottom-right, +4 deg tilt, slides from right
          Positioned(
            bottom: 52, right: 8,
            child: AnimatedBuilder(
              animation: Listenable.merge([_card2Ctrl, _idleCtrl]),
              builder: (context, child) => Opacity(
                opacity: _card2Opacity.value,
                child: Transform.translate(
                  offset: Offset(_card2X.value, _card2IdleY.value),
                  child: Transform.rotate(angle: 0.07, child: child))),
              child: RepaintBoundary(child: _buildCard2()),
            ),
          ),

          // "You and 12 others" badge
          Positioned(
            bottom: 12, left: 40,
            child: AnimatedBuilder(
              animation: Listenable.merge([_badgeCtrl, _idleCtrl]),
              builder: (context, child) => Opacity(
                opacity: _badgeOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _badgeY.value + _badgeIdleY.value),
                  child: child)),
              child: _buildBadge(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard1() {
    return Container(
      width: 188,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderCream.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppTheme.accentLavender.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.sentiment_satisfied_alt_rounded, color: AppTheme.accentLavender, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                _skeletonLine(width: 60, opacity: 0.40),
                const SizedBox(height: 6),
                _skeletonLine(width: double.infinity, opacity: 0.18),
                const SizedBox(height: 4),
                _skeletonLine(width: double.infinity, opacity: 0.18),
                const SizedBox(height: 4),
                _skeletonLine(width: 80, opacity: 0.13),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard2() {
    return Container(
      width: 196,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderCream.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppTheme.secondaryCoral.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: const Icon(Icons.group_rounded, color: AppTheme.secondaryCoral, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                _skeletonLine(width: 80, opacity: 0.40),
                const SizedBox(height: 6),
                _skeletonLine(width: double.infinity, opacity: 0.18),
                const SizedBox(height: 4),
                _skeletonLine(width: 110, opacity: 0.13),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primarySage,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primarySage.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: const Text(
        'You and 12 others',
        style: TextStyle(color: AppTheme.onPrimaryDark, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
    );
  }

  Widget _skeletonLine({required double width, required double opacity}) {
    return Container(
      width: width == double.infinity ? null : width,
      height: 7,
      decoration: BoxDecoration(
        color: AppTheme.foregroundDark.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
