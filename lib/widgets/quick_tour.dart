import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/session_service.dart';

enum QuickTourPage { today, journey, learn, me, settings }

class QuickTourTargetRegistry {
  final Map<String, GlobalKey> _keys = {};

  GlobalKey key(QuickTourPage page, String id) {
    final keyId = '${page.name}:$id';
    return _keys.putIfAbsent(keyId, GlobalKey.new);
  }

  BuildContext? contextFor(QuickTourPage page, String id) =>
      _keys['${page.name}:$id']?.currentContext;

  Rect? rectFor(QuickTourPage page, String id) {
    final renderObject = contextFor(page, id)?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }
}

Widget quickTourTarget({
  required QuickTourTargetRegistry? registry,
  required QuickTourPage page,
  required String id,
  required Widget child,
}) {
  final key = registry?.key(page, id);
  if (key == null) return child;
  return KeyedSubtree(key: key, child: child);
}

class QuickTourService {
  QuickTourService._();

  static const String _seenPrefix = 'spineup_quick_tour_v2_seen_';
  static const String _legacyKeyPrefix = 'spineup_quick_tour_seen_';

  static Future<bool> hasSeen(QuickTourPage page) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(page)) ?? false;
  }

  static Future<void> markSeen(QuickTourPage page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(page), true);
  }

  static Future<void> reset({QuickTourPage? page}) async {
    final prefs = await SharedPreferences.getInstance();
    if (page != null) {
      await prefs.remove(_key(page));
      return;
    }
    await resetAll();
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final page in QuickTourPage.values) {
      await prefs.remove(_key(page));
    }
    await prefs.remove('$_legacyKeyPrefix${SessionService.currentUserId}');
  }

  static String _key(QuickTourPage page) =>
      '$_seenPrefix${SessionService.currentUserId}_${page.name}';
}

Future<void> showPageQuickTourIfNeeded(
  BuildContext context, {
  required QuickTourPage page,
  required QuickTourTargetRegistry registry,
  bool force = false,
}) async {
  if (!force && await QuickTourService.hasSeen(page)) return;
  final target = await _waitForTarget(page, registry, _stepsFor(page).first.id);
  if (!context.mounted || target == null) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '${_pageLabel(page)} tutorial',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) =>
        _PageTourOverlay(page: page, registry: registry, initialTarget: target),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

Future<Rect?> _waitForTarget(
  QuickTourPage page,
  QuickTourTargetRegistry registry,
  String id,
) async {
  for (var attempt = 0; attempt < 18; attempt++) {
    final rect = registry.rectFor(page, id);
    if (rect != null) return rect;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return null;
}

String _pageLabel(QuickTourPage page) => switch (page) {
  QuickTourPage.today => 'Today',
  QuickTourPage.journey => 'My Journey',
  QuickTourPage.learn => 'Learn',
  QuickTourPage.me => 'Me',
  QuickTourPage.settings => 'Settings',
};

List<_TourStep> _stepsFor(QuickTourPage page) => switch (page) {
  QuickTourPage.today => const [
    _TourStep(
      id: 'check-in',
      title: 'Start with a check-in',
      body:
          'Tap here when you want to record how today feels. Answer the short prompts, save, and keep the note private to this profile.',
      icon: Icons.edit_note_rounded,
    ),
    _TourStep(
      id: 'routine',
      title: 'Keep movement close',
      body:
          'Open your routine from this card, choose a movement, and mark it complete when you finish. You can change the routine whenever it stops fitting.',
      icon: Icons.self_improvement_rounded,
    ),
    _TourStep(
      id: 'today-progress',
      title: 'Notice your momentum',
      body:
          'This small strip reflects your recent consistency and today’s progress. It is encouragement—not a measure of your health.',
      icon: Icons.trending_up_rounded,
    ),
  ],
  QuickTourPage.journey => const [
    _TourStep(
      id: 'chart',
      title: 'Read the pattern, not a verdict',
      body:
          'This chart gathers the measurements you choose to record. Use it to notice changes over time, not to diagnose or predict anything.',
      icon: Icons.show_chart_rounded,
    ),
    _TourStep(
      id: 'filters',
      title: 'Change the view',
      body:
          'Try a different time range, then add pain or stretch information when it helps you understand the context around a record.',
      icon: Icons.tune_rounded,
    ),
    _TourStep(
      id: 'add-record',
      title: 'Add a record when it matters',
      body:
          'Use the + button to log a Cobb angle or schedule a visit. The record stays attached to the active local profile.',
      icon: Icons.add_circle_outline_rounded,
    ),
  ],
  QuickTourPage.learn => const [
    _TourStep(
      id: 'movement-library',
      title: 'Start with something useful',
      body:
          'Open the movement library to preview guidance and choose what belongs in your routine. You are allowed to keep it simple.',
      icon: Icons.playlist_play_rounded,
    ),
    _TourStep(
      id: 'search',
      title: 'Search instead of scrolling forever',
      body:
          'Type a question or topic here. SpineUp keeps the library focused on scoliosis support, movement, mindfulness, and everyday coping.',
      icon: Icons.search_rounded,
    ),
    _TourStep(
      id: 'sections',
      title: 'Choose the format that fits',
      body:
          'Switch between topic guides, articles, videos, and saved material. Browse first; open only what feels relevant today.',
      icon: Icons.filter_list_rounded,
    ),
    _TourStep(
      id: 'topic-list',
      title: 'Open a guide and go deeper',
      body:
          'Begin with the short explanation, then use Learn more or the source link when you want fuller context.',
      icon: Icons.menu_book_rounded,
    ),
  ],
  QuickTourPage.me => const [
    _TourStep(
      id: 'active-profile',
      title: 'Choose whose care you are tracking',
      body:
          'This is the active local profile. If you care for someone else, switch profiles here so their notes and progress stay separate.',
      icon: Icons.people_outline_rounded,
    ),
    _TourStep(
      id: 'care-profile',
      title: 'Keep the care profile current',
      body:
          'Review the information you entered during setup and use Edit when something changes. SpineUp records what you provide; it does not diagnose.',
      icon: Icons.assignment_outlined,
    ),
    _TourStep(
      id: 'personalize',
      title: 'Make the space feel like yours',
      body:
          'Choose an icon or local photo for the active profile. This is visual personalization, not a public account.',
      icon: Icons.face_retouching_natural_rounded,
    ),
    _TourStep(
      id: 'progress',
      title: 'Come back to what you have done',
      body:
          'Your progress and milestones live here as encouragement. It is a record of participation, not a score for your health.',
      icon: Icons.flag_outlined,
    ),
    _TourStep(
      id: 'settings',
      title: 'Make the space fit you',
      body:
          'When you want to change the look, set a gentle reminder, or move your records, open Settings here.',
      icon: Icons.settings_outlined,
    ),
  ],
  QuickTourPage.settings => const [
    _TourStep(
      id: 'appearance',
      title: 'Set the atmosphere',
      body:
          'Choose System default, Light, or Dark. This changes how SpineUp looks on this device without changing your local records.',
      icon: Icons.palette_outlined,
    ),
    _TourStep(
      id: 'reminder',
      title: 'Keep one gentle reminder',
      body:
          'If you want a prompt, turn on the daily reminder and choose a time. It is local to Android, quiet, and easy to turn off.',
      icon: Icons.notifications_none_rounded,
    ),
    _TourStep(
      id: 'privacy',
      title: 'Keep your records portable',
      body:
          'SpineUp keeps records on this device. Use the protected export before changing phones, and import it only when you choose.',
      icon: Icons.lock_outline_rounded,
    ),
  ],
};

class _PageTourOverlay extends StatefulWidget {
  final QuickTourPage page;
  final QuickTourTargetRegistry registry;
  final Rect? initialTarget;

  const _PageTourOverlay({
    required this.page,
    required this.registry,
    required this.initialTarget,
  });

  @override
  State<_PageTourOverlay> createState() => _PageTourOverlayState();
}

class _PageTourOverlayState extends State<_PageTourOverlay> {
  int _step = 0;

  List<_TourStep> get _steps => _stepsFor(widget.page);

  Future<void> _close() async {
    await QuickTourService.markSeen(widget.page);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _next() async {
    if (_step == _steps.length - 1) {
      await _close();
      return;
    }
    final nextStep = _steps[_step + 1];
    setState(() => _step++);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final targetContext = widget.registry.contextFor(widget.page, nextStep.id);
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.32,
      );
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final target =
        widget.registry.rectFor(widget.page, step.id) ??
        (_step == 0 ? widget.initialTarget : null);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final placeCardAtTop = target != null && target.bottom > size.height * 0.56;
    final card = _TourCard(
      step: _step,
      total: _steps.length,
      data: step,
      onSkip: _close,
      onNext: _next,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FocusPainter(
                  target: target,
                  accent: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ),
          if (placeCardAtTop)
            Positioned(left: 20, right: 20, top: padding.top + 12, child: card)
          else
            Positioned(
              left: 20,
              right: 20,
              bottom: padding.bottom + 16,
              child: card,
            ),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final int step;
  final int total;
  final _TourStep data;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _TourCard({
    required this.step,
    required this.total,
    required this.data,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLast = step == total - 1;
    return Semantics(
      container: true,
      label:
          '${_pageLabelForSemantics(data)} tutorial step ${step + 1} of $total',
      child: Card(
        elevation: 14,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        color: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(data.icon, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${step + 1} of $total',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Skip guide'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Text(
                data.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.42,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onNext,
                  icon: Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  ),
                  label: Text(isLast ? 'Finish guide' : 'Next'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pageLabelForSemantics(_TourStep data) => data.title;
}

class _TourStep {
  final String id;
  final String title;
  final String body;
  final IconData icon;

  const _TourStep({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
  });
}

class _FocusPainter extends CustomPainter {
  final Rect? target;
  final Color accent;

  const _FocusPainter({required this.target, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(
      bounds,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );

    if (target != null) {
      final focusRect = target!.inflate(10);
      final focusRRect = RRect.fromRectAndRadius(
        focusRect,
        const Radius.circular(20),
      );
      canvas.drawRRect(focusRRect, Paint()..blendMode = BlendMode.clear);
      canvas.drawRRect(
        focusRRect,
        Paint()
          ..color = accent.withValues(alpha: 0.82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawRRect(
        focusRRect,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FocusPainter oldDelegate) =>
      oldDelegate.target != target || oldDelegate.accent != accent;
}
