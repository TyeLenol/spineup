import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/session_service.dart';
import '../theme/app_theme.dart';

class QuickTourService {
  QuickTourService._();

  static const String _seenPrefix = 'spineup_quick_tour_seen_';

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key()) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(), true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key());
  }

  static String _key() => '$_seenPrefix${SessionService.currentUserId}';
}

Future<void> showQuickTour(BuildContext context) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Quick tour',
    barrierColor: Colors.black.withValues(alpha: 0.58),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => const _QuickTourOverlay(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class QuickTourEntryCard extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onLater;

  const QuickTourEntryCard({
    super.key,
    required this.onStart,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppTheme.profileSurface.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppTheme.profileWarm.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 12, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.profileWarm.withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: colors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Want a quick look around?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'See where to check in, learn, and keep track of your journey.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: onStart,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Show me around'),
                      ),
                      TextButton(
                        onPressed: onLater,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Maybe later'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTourOverlay extends StatefulWidget {
  const _QuickTourOverlay();

  @override
  State<_QuickTourOverlay> createState() => _QuickTourOverlayState();
}

class _QuickTourOverlayState extends State<_QuickTourOverlay> {
  int _step = 0;

  static const _steps = [
    _TourStep(
      title: 'Start with today',
      body:
          'Your daily check-in and care actions live here, ready when you are.',
      icon: Icons.today_rounded,
      target: _TourTarget.today,
    ),
    _TourStep(
      title: 'Capture what matters',
      body:
          'Log a check-in, routine moment, appointment, or personal note when useful.',
      icon: Icons.edit_note_rounded,
      target: _TourTarget.checkIn,
    ),
    _TourStep(
      title: 'Look back on your journey',
      body: 'Review the records you choose to keep, at your own pace.',
      icon: Icons.show_chart_rounded,
      target: _TourTarget.journey,
    ),
    _TourStep(
      title: 'Learn at your pace',
      body:
          'Browse curated articles, videos, and routines whenever you want to explore.',
      icon: Icons.menu_book_rounded,
      target: _TourTarget.learn,
    ),
  ];

  Future<void> _close() async {
    await QuickTourService.markSeen();
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_step == _steps.length - 1) {
      _close();
      return;
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final current = _steps[_step];
            final target = _targetOffset(
              current.target,
              constraints.biggest,
              MediaQuery.paddingOf(context).bottom,
            );
            final cardBottom =
                current.target == _TourTarget.journey ||
                    current.target == _TourTarget.learn
                ? 116.0
                : 110.0;

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TourPointerPainter(
                      target: target,
                      accent: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: cardBottom,
                  child: _TourCard(
                    step: _step,
                    total: _steps.length,
                    data: current,
                    onSkip: _close,
                    onNext: _next,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Offset _targetOffset(_TourTarget target, Size size, double bottomInset) {
    switch (target) {
      case _TourTarget.today:
        return Offset(size.width * 0.5, 82);
      case _TourTarget.checkIn:
        return Offset(size.width * 0.5, size.height * 0.33);
      case _TourTarget.journey:
        return Offset(size.width * 0.31, size.height - bottomInset - 34);
      case _TourTarget.learn:
        return Offset(size.width * 0.52, size.height - bottomInset - 34);
    }
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
      label: 'Quick tour step ${step + 1} of $total: ${data.title}',
      child: Card(
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.24),
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
                    child: const Text('Skip'),
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
              const SizedBox(height: 6),
              Text(
                data.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
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
                  label: Text(isLast ? 'Done' : 'Next'),
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
}

enum _TourTarget { today, checkIn, journey, learn }

class _TourStep {
  final String title;
  final String body;
  final IconData icon;
  final _TourTarget target;

  const _TourStep({
    required this.title,
    required this.body,
    required this.icon,
    required this.target,
  });
}

class _TourPointerPainter extends CustomPainter {
  final Offset target;
  final Color accent;

  const _TourPointerPainter({required this.target, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final inner = Paint()
      ..color = accent.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(target, 25, inner);
    canvas.drawCircle(target, 28, ring);

    final cardTop = size.height - 110 - 230;
    final start = Offset(size.width * 0.5, cardTop);
    final control = Offset(
      target.dx + (start.dx - target.dx) * 0.45,
      target.dy + (start.dy - target.dy) * 0.32,
    );
    final pointer = Path()
      ..moveTo(target.dx, target.dy)
      ..quadraticBezierTo(control.dx, control.dy, start.dx, start.dy);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    _drawDashedPath(canvas, pointer, line);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 8, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TourPointerPainter oldDelegate) =>
      oldDelegate.target != target || oldDelegate.accent != accent;
}
