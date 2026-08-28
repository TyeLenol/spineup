import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';
import 'learn_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cobb Angle Logger Modal
// Single-entry: manual degree input
// Writes an angle_logged event with method='manual'
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

class _CobbAngleLoggerModalState extends State<CobbAngleLoggerModal> {
  final _manualCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  double? get _entryDegrees {
    return double.tryParse(_manualCtrl.text.trim());
  }

  Future<void> _submit() async {
    final degrees = _entryDegrees;
    if (degrees == null || degrees <= 0 || degrees > 180) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid angle between 1 and 180.'),
          ),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await widget.gamificationService.logEvent(
        eventId: const Uuid().v4(),
        userId: widget.userId,
        type: EventType.angleLogged,
        payload: {
          'degrees': degrees,
          'method': 'manual',
          'logged_at': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onLogged(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to log angle: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.95,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLavender.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.architecture_rounded,
                        color: AppTheme.accentLavender,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Log Cobb Angle', style: tt.titleMedium),
                    ),
                    const ContextualHelpIcon(topicId: 'measurement-log'),
                  ],
                ),
                const SizedBox(height: 16),

                // Disclaimer
                _DisclaimerBanner(),
                const SizedBox(height: 20),

                _ManualEntryPanel(controller: _manualCtrl),

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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_loading ? 'Saving…' : 'Log Angle'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SpineUp is not a diagnostic tool. Measurements are for tracking '
              'personal progress. Always consult your orthopedic specialist.',
              style: tt.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
          'Enter the Cobb angle value from your X-ray report.',
          style: tt.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Cobb angle (degrees)',
            hintText: 'e.g. 28',
            suffixText: '°',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
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
