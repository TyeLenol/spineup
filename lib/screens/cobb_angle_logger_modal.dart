import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cobb Angle Logger Modal
// Dual-entry: (A) manual degree input  |  (B) trace-on-protractor tool
// Both write angle_logged (+50 XP) with method='manual'|'traced'
// ─────────────────────────────────────────────────────────────────────────────

class CobbAngleLoggerModal extends StatefulWidget {
  final String userId;
  final GamificationService gamificationService;
  final void Function(LogEventResult result) onLogged;

  const CobbAngleLoggerModal({
    super.key,
    required this.userId,
    required this.gamificationService,
    required this.onLogged,
  });

  @override
  State<CobbAngleLoggerModal> createState() => _CobbAngleLoggerModalState();
}

enum _EntryMethod { manual, traced }

class _CobbAngleLoggerModalState extends State<CobbAngleLoggerModal>
    with TickerProviderStateMixin {
  _EntryMethod _method = _EntryMethod.manual;

  // Manual entry
  final _manualCtrl = TextEditingController();

  // Protractor tool state
  double _lineAAngle = -30; // degrees from horizontal
  double _lineBAngle = 30;
  double get _tracedAngle => (_lineBAngle - _lineAAngle).abs().clamp(0, 180);

  bool _loading = false;

  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      setState(() {
        _method =
            _tabCtrl.index == 0 ? _EntryMethod.manual : _EntryMethod.traced;
      });
    });
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  double? get _entryDegrees {
    if (_method == _EntryMethod.manual) {
      return double.tryParse(_manualCtrl.text.trim());
    }
    return _tracedAngle;
  }

  Future<void> _submit() async {
    final deg = _entryDegrees;
    if (deg == null || deg <= 0 || deg > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid angle (1–180°).')),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await widget.gamificationService.logEvent(
      eventId: const Uuid().v4(),
      userId: widget.userId,
      type: EventType.angleLogged,
      payload: {
        'degrees': deg,
        'method': _method.name,
        'logged_at': DateTime.now().toIso8601String(),
      },
    );

    if (mounted) {
      Navigator.of(context).pop();
      widget.onLogged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) {
          return SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLavender.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.architecture_rounded,
                          color: AppTheme.accentLavender),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Log Cobb Angle', style: tt.titleMedium),
                        Text('+$kXpAngle XP',
                            style: tt.labelSmall?.copyWith(
                              color: AppTheme.accentLavender,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Disclaimer
                _DisclaimerBanner(),
                const SizedBox(height: 16),

                // Method tabs
                TabBar(
                  controller: _tabCtrl,
                  tabs: const [
                    Tab(icon: Icon(Icons.edit_outlined), text: 'Manual entry'),
                    Tab(
                        icon: Icon(Icons.straighten_rounded),
                        text: 'Trace tool'),
                  ],
                ),
                const SizedBox(height: 20),

                // Tab content
                if (_method == _EntryMethod.manual) ...[
                  _ManualEntryPanel(controller: _manualCtrl),
                ] else ...[
                  _ProtractorPanel(
                    lineAAngle: _lineAAngle,
                    lineBAngle: _lineBAngle,
                    tracedAngle: _tracedAngle,
                    onLineAChanged: (v) => setState(() => _lineAAngle = v),
                    onLineBChanged: (v) => setState(() => _lineBAngle = v),
                  ),
                ],

                const SizedBox(height: 28),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_loading ? 'Saving…' : 'Log Angle'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Disclaimer banner ────────────────────────────────────────────────────────

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryCoral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.secondaryCoral.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.secondaryCoral, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Not a diagnostic tool. This estimate is for personal '
              'tracking only — always rely on your doctor\'s X-ray '
              'measurements for clinical decisions.',
              style: tt.bodySmall?.copyWith(color: AppTheme.secondaryCoral),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Manual entry panel ───────────────────────────────────────────────────────

class _ManualEntryPanel extends StatelessWidget {
  final TextEditingController controller;
  const _ManualEntryPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type the Cobb angle value from your X-ray report.',
          style: tt.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Cobb angle (degrees)',
            hintText: 'e.g. 28',
            suffixText: '°',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Protractor panel ─────────────────────────────────────────────────────────

class _ProtractorPanel extends StatelessWidget {
  final double lineAAngle;
  final double lineBAngle;
  final double tracedAngle;
  final ValueChanged<double> onLineAChanged;
  final ValueChanged<double> onLineBChanged;

  const _ProtractorPanel({
    required this.lineAAngle,
    required this.lineBAngle,
    required this.tracedAngle,
    required this.onLineAChanged,
    required this.onLineBChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drag the two sliders to align the lines with the end-plates '
          'of the curve on your X-ray. The angle between them is your '
          'estimated Cobb angle.',
          style: tt.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
        ),
        const SizedBox(height: 20),

        // Protractor canvas
        Center(
          child: CustomPaint(
            size: const Size(240, 240),
            painter: _ProtractorPainter(
              lineADeg: lineAAngle,
              lineBDeg: lineBAngle,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Angle readout
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.accentLavender.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '${tracedAngle.toStringAsFixed(1)}°',
              style: tt.headlineMedium?.copyWith(
                color: AppTheme.accentLavender,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Line A slider
        _LineSlider(
          label: 'Line A (top end-plate)',
          color: AppTheme.primarySage,
          value: lineAAngle,
          min: -90,
          max: 90,
          onChanged: onLineAChanged,
        ),
        const SizedBox(height: 12),

        // Line B slider
        _LineSlider(
          label: 'Line B (bottom end-plate)',
          color: AppTheme.secondaryCoral,
          value: lineBAngle,
          min: -90,
          max: 90,
          onChanged: onLineBChanged,
        ),
      ],
    );
  }
}

class _LineSlider extends StatelessWidget {
  final String label;
  final Color color;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _LineSlider({
    required this.label,
    required this.color,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 3, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${value.toStringAsFixed(0)}°',
                style: tt.labelSmall?.copyWith(color: color)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.25),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 180,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── Protractor CustomPainter ─────────────────────────────────────────────────

class _ProtractorPainter extends CustomPainter {
  final double lineADeg;
  final double lineBDeg;

  const _ProtractorPainter({required this.lineADeg, required this.lineBDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circle
    final bgPaint = Paint()
      ..color = AppTheme.backgroundCream
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Protractor arc outline
    final outlinePaint = Paint()
      ..color = AppTheme.borderCream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, outlinePaint);

    // Tick marks every 10 degrees
    final tickPaint = Paint()
      ..color = AppTheme.mutedForeground.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (int deg = 0; deg < 180; deg += 10) {
      final angle = (deg - 90) * math.pi / 180;
      final inner = Offset(
        center.dx + (radius - 10) * math.cos(angle),
        center.dy + (radius - 10) * math.sin(angle),
      );
      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Horizontal baseline
    final basePaint = Paint()
      ..color = AppTheme.mutedForeground.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      basePaint,
    );

    // Helper to draw an angled line
    void drawLine(double deg, Color color) {
      final rad = deg * math.pi / 180;
      final end = Offset(
        center.dx + radius * 0.8 * math.cos(rad),
        center.dy + radius * 0.8 * math.sin(rad),
      );
      final start = Offset(
        center.dx - radius * 0.5 * math.cos(rad),
        center.dy - radius * 0.5 * math.sin(rad),
      );
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
    }

    drawLine(lineADeg, AppTheme.primarySage);
    drawLine(lineBDeg, AppTheme.secondaryCoral);

    // Arc showing the Cobb angle
    final arcAngle = (lineBDeg - lineADeg).abs() * math.pi / 180;
    final startRad = math.min(lineADeg, lineBDeg) * math.pi / 180;
    final arcPaint = Paint()
      ..color = AppTheme.accentLavender.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.4),
      startRad,
      arcAngle,
      true,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ProtractorPainter old) =>
      old.lineADeg != lineADeg || old.lineBDeg != lineBDeg;
}

// ─── Helper ───────────────────────────────────────────────────────────────────

Future<void> showCobbAngleLogger({
  required BuildContext context,
  required String userId,
  required GamificationService gamificationService,
  required void Function(LogEventResult result) onLogged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CobbAngleLoggerModal(
      userId: userId,
      gamificationService: gamificationService,
      onLogged: onLogged,
    ),
  );
}
