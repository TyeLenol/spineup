import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A short, action-first completion acknowledgement for health-support tasks.
///
/// The completed action is the headline. XP remains visible as a secondary
/// progress marker, avoiding a game-style reward taking over the care moment.
void showActionRewardFeedback(
  BuildContext context, {
  required String title,
  required int xpAwarded,
  bool dailyBonusAwarded = false,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ActionRewardOverlay(
      title: title,
      xpAwarded: xpAwarded,
      dailyBonusAwarded: dailyBonusAwarded,
      onDismiss: entry.remove,
    ),
  );
  overlay.insert(entry);
}

class _ActionRewardOverlay extends StatefulWidget {
  final String title;
  final int xpAwarded;
  final bool dailyBonusAwarded;
  final VoidCallback onDismiss;

  const _ActionRewardOverlay({
    required this.title,
    required this.xpAwarded,
    required this.dailyBonusAwarded,
    required this.onDismiss,
  });

  @override
  State<_ActionRewardOverlay> createState() => _ActionRewardOverlayState();
}

class _ActionRewardOverlayState extends State<_ActionRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 180),
    );
    HapticFeedback.selectionClick();
    _controller.forward();
    _dismissTimer = Timer(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final offset =
        Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    final scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    Widget notice = _RewardCard(
      title: widget.title,
      xpAwarded: widget.xpAwarded,
      dailyBonusAwarded: widget.dailyBonusAwarded,
    );
    if (!disableAnimations) {
      notice = FadeTransition(
        opacity: opacity,
        child: SlideTransition(
          position: offset,
          child: ScaleTransition(scale: scale, child: notice),
        ),
      );
    }

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 20,
      right: 20,
      child: Semantics(
        liveRegion: true,
        label: '${widget.title}. ${widget.xpAwarded} XP added to progress.',
        child: IgnorePointer(child: notice),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String title;
  final int xpAwarded;
  final bool dailyBonusAwarded;

  const _RewardCard({
    required this.title,
    required this.xpAwarded,
    required this.dailyBonusAwarded,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dailyBonusAwarded
                          ? 'A small daily boost was added too.'
                          : 'Added to your progress for today.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (xpAwarded > 0) ...[
                const SizedBox(width: 10),
                _XpToken(value: xpAwarded),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _XpToken extends StatelessWidget {
  final int value;

  const _XpToken({required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Text(
          '+$value XP',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
