import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../services/gamification_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class ActivityHistoryScreen extends StatefulWidget {
  final EventType? initialFilter;

  const ActivityHistoryScreen({super.key, this.initialFilter});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final _gamificationService = GamificationService();
  late EventType? _filter = widget.initialFilter;
  List<Event> _events = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await _gamificationService.getAllEvents(
      SessionService.currentCareSubjectId,
    );
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  List<Event> get _filteredEvents {
    final events =
        _events
            .where((event) => _filter == null || event.type == _filter)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity history'),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    'Everything recorded for this profile',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review check-ins, routines, measurements, and visits in one place.',
                    style: tt.bodySmall?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      children: [
                        _HistoryFilter(
                          label: 'All',
                          selected: _filter == null,
                          onTap: () => setState(() => _filter = null),
                        ),
                        _HistoryFilter(
                          label: 'Check-ins',
                          selected: _filter == EventType.journalEntry,
                          onTap: () =>
                              setState(() => _filter = EventType.journalEntry),
                        ),
                        _HistoryFilter(
                          label: 'Routines',
                          selected: _filter == EventType.stretchCompleted,
                          onTap: () => setState(
                            () => _filter = EventType.stretchCompleted,
                          ),
                        ),
                        _HistoryFilter(
                          label: 'Measurements',
                          selected: _filter == EventType.angleLogged,
                          onTap: () =>
                              setState(() => _filter = EventType.angleLogged),
                        ),
                        _HistoryFilter(
                          label: 'Visits',
                          selected: _filter == EventType.appointmentAttended,
                          onTap: () => setState(
                            () => _filter = EventType.appointmentAttended,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_filteredEvents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 44,
                            color: AppTheme.mutedForeground.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No records in this view yet.',
                            textAlign: TextAlign.center,
                            style: tt.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your records will appear here after you log them.',
                            textAlign: TextAlign.center,
                            style: tt.bodySmall?.copyWith(
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._filteredEvents.map(
                      (event) => _HistoryEventTile(event: event),
                    ),
                ],
              ),
            ),
    );
  }
}

class _HistoryFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _HistoryEventTile extends StatelessWidget {
  final Event event;

  const _HistoryEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final (icon, label, color) = switch (event.type) {
      EventType.stretchCompleted => (
        Icons.self_improvement_rounded,
        'Routine: ${event.payload['exercise_name'] ?? 'Session'}',
        AppTheme.primarySage,
      ),
      EventType.journalEntry => (
        Icons.edit_note_rounded,
        'Daily check-in',
        AppTheme.secondaryCoral,
      ),
      EventType.angleLogged => (
        Icons.architecture_rounded,
        'Recorded measurement',
        AppTheme.accentLavender,
      ),
      EventType.appointmentAttended => (
        Icons.medical_services_rounded,
        'Visit recorded',
        AppTheme.primarySage,
      ),
      EventType.profileCompleted => (
        Icons.person_rounded,
        'Profile completed',
        AppTheme.accentLavender,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCream),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: tt.bodyMedium),
                const SizedBox(height: 3),
                Text(
                  DateFormat.yMMMd().add_jm().format(event.timestamp),
                  style: tt.bodySmall?.copyWith(
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${event.xpValue} XP',
            style: tt.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
