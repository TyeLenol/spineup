import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A short, action-first completion acknowledgement for health-support tasks.
///
/// The action remains the headline. XP is shown as a compact secondary signal,
/// so the reward supports the care moment instead of taking it over.
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
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
    );
    HapticFeedback.selectionClick();
    _controller.forward();
    _dismissTimer = Timer(const Duration(milliseconds: 1850), () async {
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
    final motion = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    Widget notice = _RewardCard(
      title: widget.title,
      xpAwarded: widget.xpAwarded,
      dailyBonusAwarded: widget.dailyBonusAwarded,
    );
    if (!disableAnimations) {
      notice = FadeTransition(
        opacity: motion,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(motion),
          child: notice,
        ),
      );
    }

    return Positioned(
      left: 20,
      right: 20,
      bottom: MediaQuery.paddingOf(context).bottom + 88,
      child: Semantics(
        liveRegion: true,
        label: widget.xpAwarded > 0
            ? '${widget.title}. ${widget.xpAwarded} XP added to progress.'
            : '${widget.title}. Progress updated.',
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
    final accent = colorScheme.secondary;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.done_rounded, color: accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dailyBonusAwarded
                          ? 'Saved · daily bonus included'
                          : 'Saved to your progress',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (xpAwarded > 0) ...[
                const SizedBox(width: 10),
                _XpToken(value: xpAwarded, accent: accent),
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
  final Color accent;

  const _XpToken({required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          '+$value XP',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
