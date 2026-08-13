import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../models/user_profile.dart';
import '../services/gamification_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'my_journey_screen.dart';

class DailyCheckInScreen extends StatefulWidget {
  final UserProfile userProfile;
  final String? userId;
  final Event? existingLogToday;

  const DailyCheckInScreen({
    super.key,
    required this.userProfile,
    this.userId,
    this.existingLogToday,
  });

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final _gs = GamificationService();

  String get _effectiveUserId => widget.userId ?? SessionService.currentUserId;
  final _notesController = TextEditingController();

  double _painLevel = 2;
  double _braceHours = 8;
  String _mood = 'Good';
  final Set<String> _selectedLocations = {};
  String? _tightness;
  String? _fatigue;
  bool _saving = false;

  final List<({String label, IconData icon})> _moodOptions = const [
    (label: 'Awful', icon: Icons.sentiment_very_dissatisfied_rounded),
    (label: 'Low', icon: Icons.sentiment_dissatisfied_rounded),
    (label: 'Okay', icon: Icons.sentiment_neutral_rounded),
    (label: 'Good', icon: Icons.sentiment_satisfied_rounded),
    (label: 'Great', icon: Icons.sentiment_very_satisfied_rounded),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingLogToday != null) {
      final p = widget.existingLogToday!.payload;
      _painLevel = ((p['pain_level'] as num?) ?? 2).toDouble();
      _braceHours = ((p['brace_hours'] as num?) ?? 8).toDouble();
      _mood = (p['mood'] as String?) ?? 'Good';
      if (p['locations'] is List) {
        _selectedLocations.addAll((p['locations'] as List).cast<String>());
      }
      _tightness = p['tightness'] as String?;
      _fatigue = p['fatigue'] as String?;
      _notesController.text = (p['notes'] as String?) ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _painColor(double v) {
    if (v <= 3) return Colors.green;
    if (v <= 6) return Colors.orange;
    return Colors.red;
  }

  String _painLabel(double v) {
    final roundV = v.round();
    if (v <= 3) return 'Mild ($roundV/10) 🟢';
    if (v <= 6) return 'Moderate ($roundV/10) 🟡';
    return 'Severe ($roundV/10) 🔴';
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final payload = {
      'pain_level': _painLevel.round(),
      'brace_hours': _braceHours.round(),
      'mood': _mood,
      'locations': _selectedLocations.toList(),
      'tightness': _tightness,
      'fatigue': _fatigue,
      'notes': _notesController.text.trim(),
      'logged_at': DateTime.now().toIso8601String(),
    };

    if (widget.existingLogToday != null) {
      await _gs.updateJournalEntry(
        eventId: widget.existingLogToday!.id,
        userId: _effectiveUserId,
        payload: payload,
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final result = await _gs.logEvent(
      eventId: const Uuid().v4(),
      userId: _effectiveUserId,
      type: EventType.journalEntry,
      payload: payload,
    );
    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final showBrace =
        widget.userProfile.braceStatus == 'Yes' ||
        widget.userProfile.braceStatus == 'Sometimes';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Daily Check-In',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'View past entries',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyJourneyScreen(
                    initialEventFilter: EventType.journalEntry,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Mood section (5-point scale) ─────────────────────────
            Text(
              'How are you feeling today?',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moodOptions.map((opt) {
                final selected = opt.label == _mood;
                return ChoiceChip(
                  avatar: Icon(
                    opt.icon,
                    size: 20,
                    color: selected ? Colors.white : cs.onSurfaceVariant,
                  ),
                  label: Text(opt.label),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? Colors.white : cs.onSurface,
                  ),
                  selected: selected,
                  selectedColor: AppTheme.primarySage,
                  backgroundColor: cs.surfaceContainerHigh,
                  onSelected: (val) {
                    if (val) setState(() => _mood = opt.label);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Pain level slider ──────────────────────────────────
            Row(
              children: [
                Text(
                  'Pain Level',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  _painLabel(_painLevel),
                  style: tt.labelSmall?.copyWith(
                    color: _painColor(_painLevel),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _painColor(_painLevel),
                inactiveTrackColor: AppTheme.borderCream,
                thumbColor: _painColor(_painLevel),
              ),
              child: Slider(
                value: _painLevel,
                min: 0,
                max: 10,
                divisions: 10,
                label: _painLevel.round().toString(),
                onChanged: (v) => setState(() => _painLevel = v),
              ),
            ),
            const SizedBox(height: 16),

            // ── Location chips ────────────────────────────────────
            Text(
              'Pain Location (optional)',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  [
                    'Neck',
                    'Upper Back',
                    'Lower Back',
                    'Left Hip',
                    'Right Hip',
                    'Other',
                  ].map((loc) {
                    final selected = _selectedLocations.contains(loc);
                    return FilterChip(
                      label: Text(
                        loc,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : cs.onSurface,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppTheme.primarySage,
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            _selectedLocations.remove(loc);
                          } else {
                            _selectedLocations.add(loc);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Tightness chips ────────────────────────────────────
            Text(
              'Tightness (optional)',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['Mild', 'Moderate', 'Severe'].map((option) {
                final selected = _tightness == option;
                return ChoiceChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : cs.onSurface,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppTheme.primarySage,
                  onSelected: (val) =>
                      setState(() => _tightness = val ? option : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Fatigue chips ──────────────────────────────────────
            Text(
              'Fatigue (optional)',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['Mild', 'Moderate', 'Severe'].map((option) {
                final selected = _fatigue == option;
                return ChoiceChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : cs.onSurface,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppTheme.primarySage,
                  onSelected: (val) =>
                      setState(() => _fatigue = val ? option : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Brace wear slider ──────────────────────────────────
            if (showBrace) ...[
              Row(
                children: [
                  Text(
                    'Brace Wear',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${_braceHours.round()} hrs',
                    style: tt.labelSmall?.copyWith(
                      color: AppTheme.primarySage,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primarySage,
                  inactiveTrackColor: AppTheme.borderCream,
                  thumbColor: AppTheme.primarySage,
                ),
                child: Slider(
                  value: _braceHours,
                  min: 0,
                  max: 24,
                  divisions: 24,
                  label: '${_braceHours.round()}h',
                  onChanged: (v) => setState(() => _braceHours = v),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Notes ─────────────────────────────────────────────
            Text(
              'Daily Notes (optional)',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any symptoms, posture notes, or how your back feels today...',
                filled: true,
                fillColor: cs.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderCream),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Save button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Check-In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
