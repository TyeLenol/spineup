import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import '../models/event.dart';
import 'learn_screen.dart';
import '../services/gamification_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/action_reward_feedback.dart';
import '../widgets/quick_tour.dart';
import 'activity_history_screen.dart';
import 'cobb_angle_logger_modal.dart';
import 'appointment_logger_modal.dart';

class MyJourneyScreen extends StatefulWidget {
  final EventType? initialEventFilter;
  final QuickTourTargetRegistry? tutorialRegistry;

  const MyJourneyScreen({
    super.key,
    this.initialEventFilter,
    this.tutorialRegistry,
  });

  @override
  State<MyJourneyScreen> createState() => _MyJourneyScreenState();
}

class _MyJourneyScreenState extends State<MyJourneyScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _gs = GamificationService();
  List<({DateTime date, double degrees})> _cobbHistory = [];
  List<Event> _allEvents = [];
  bool _loading = true;
  bool _tutorialScheduled = false;

  // Chart Filters
  String _chartTimeRange = 'Month'; // 'Week', 'Month', 'Year', 'All'
  String _overlayOption = 'None'; // 'None', 'Pain Level', 'Stretches'

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final cobbs = await _gs.getCobbAngleHistory(
      SessionService.currentCareSubjectId,
    );
    final events = await _gs.getAllEvents(SessionService.currentCareSubjectId);
    if (mounted) {
      setState(() {
        _cobbHistory = cobbs;
        _allEvents = events;
        _loading = false;
      });
    }
    _scheduleTutorial();
  }

  void _scheduleTutorial() {
    if (_tutorialScheduled || widget.tutorialRegistry == null) return;
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showPageQuickTourIfNeeded(
          context,
          page: QuickTourPage.journey,
          registry: widget.tutorialRegistry!,
        ),
      );
    });
  }

  void _handleLogged(LogEventResult result) async {
    await _loadAll();
    if (!mounted) return;
    showActionRewardFeedback(
      context,
      title: 'Record saved',
      xpAwarded: result.xpAwarded,
      dailyBonusAwarded: result.dailyBonusAwarded,
    );
  }

  List<({DateTime date, double degrees})> get _filteredCobbHistory {
    if (_chartTimeRange == 'All') return _cobbHistory;
    final days = switch (_chartTimeRange) {
      'Week' || '7d' => 7,
      'Month' || '30d' => 30,
      'Year' || '90d' => 365,
      _ => 30,
    };
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _cobbHistory.where((e) => e.date.isAfter(cutoff)).toList();
  }

  List<Event> get _recentEvents {
    final events = List<Event>.from(_allEvents)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events.take(3).toList();
  }

  List<({DateTime date, double value})> get _overlayData {
    if (_overlayOption == 'None') return [];
    final days = switch (_chartTimeRange) {
      'Week' || '7d' => 7,
      'Month' || '30d' => 30,
      'Year' || '90d' => 365,
      _ => 365,
    };
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final filtered = _allEvents
        .where((e) => e.timestamp.isAfter(cutoff))
        .toList();

    if (_overlayOption == 'Pain Level') {
      final journals = filtered
          .where((e) => e.type == EventType.journalEntry)
          .toList();
      return journals
          .map(
            (e) => (
              date: e.timestamp,
              value: ((e.payload['pain_level'] as num?) ?? 0).toDouble(),
            ),
          )
          .toList();
    } else if (_overlayOption == 'Stretches') {
      final stretches = filtered
          .where((e) => e.type == EventType.stretchCompleted)
          .toList();
      final Map<String, int> countsByDay = {};
      for (final s in stretches) {
        final key =
            '${s.timestamp.year}-${s.timestamp.month.toString().padLeft(2, '0')}-${s.timestamp.day.toString().padLeft(2, '0')}';
        countsByDay[key] = (countsByDay[key] ?? 0) + 1;
      }
      return countsByDay.entries.map((entry) {
        return (date: DateTime.parse(entry.key), value: entry.value.toDouble());
      }).toList()..sort((a, b) => a.date.compareTo(b.date));
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    title: Text('My Journey', style: tt.titleLarge),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Privacy notice ─────────────────────────────────
                        _PrivacyBanner(),
                        const SizedBox(height: 20),

                        // ── Cobb angle graph ───────────────────────────────
                        Row(
                          children: [
                            const Expanded(
                              child: _SectionHeader(
                                title: 'Your Recorded Measurements',
                              ),
                            ),
                            ContextualHelpIcon(topicId: 'measurement-log'),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Time Range & Overlay Filter Bar (Scrollable to prevent edge clipping)
                        quickTourTarget(
                          registry: widget.tutorialRegistry,
                          page: QuickTourPage.journey,
                          id: 'filters',
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'Week',
                                      label: Text(
                                        'Week',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    ButtonSegment(
                                      value: 'Month',
                                      label: Text(
                                        'Month',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    ButtonSegment(
                                      value: 'Year',
                                      label: Text(
                                        'Year',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    ButtonSegment(
                                      value: 'All',
                                      label: Text(
                                        'All',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                  selected: {_chartTimeRange},
                                  onSelectionChanged: (set) {
                                    setState(() => _chartTimeRange = set.first);
                                  },
                                  style: const ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                DropdownButton<String>(
                                  value: _overlayOption,
                                  isDense: true,
                                  underline: const SizedBox.shrink(),
                                  icon: const Icon(
                                    Icons.layers_outlined,
                                    size: 18,
                                    color: AppTheme.primarySage,
                                  ),
                                  style: tt.labelSmall?.copyWith(
                                    color: AppTheme.primarySage,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'None',
                                      child: Text('No Overlay'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Pain Level',
                                      child: Text('+ Pain Level'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Stretches',
                                      child: Text('+ Stretches'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _overlayOption = v);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        quickTourTarget(
                          registry: widget.tutorialRegistry,
                          page: QuickTourPage.journey,
                          id: 'chart',
                          child: _CobbChart(
                            history: _filteredCobbHistory,
                            overlayData: _overlayData,
                            overlayOption: _overlayOption,
                            timeRange: _chartTimeRange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recorded from your entries; not a diagnosis or prediction.',
                          style: tt.bodySmall?.copyWith(
                            color: AppTheme.mutedForeground,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Recent records preview ─────────────────────────
                        Row(
                          children: [
                            const Expanded(
                              child: _SectionHeader(title: 'Recent records'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ActivityHistoryScreen(
                                      initialFilter: widget.initialEventFilter,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View all history'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_allEvents.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Your recorded check-ins, routines, and measurements will appear here.',
                              textAlign: TextAlign.center,
                              style: tt.bodySmall?.copyWith(
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          )
                        else
                          ..._recentEvents.map(
                            (event) => _EventTile(event: event, showXp: false),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96),
        child: quickTourTarget(
          registry: widget.tutorialRegistry,
          page: QuickTourPage.journey,
          id: 'add-record',
          child: ExpandableFab(
            type: ExpandableFabType.up,
            distance: 70,
            openButtonBuilder: RotateFloatingActionButtonBuilder(
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
              fabSize: ExpandableFabSize.regular,
              shape: const CircleBorder(),
            ),
            closeButtonBuilder: DefaultFloatingActionButtonBuilder(
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24,
              ),
              fabSize: ExpandableFabSize.regular,
              shape: const CircleBorder(),
            ),
            children: [
              FloatingActionButton.extended(
                heroTag: 'fab_cobb',
                onPressed: () => showCobbAngleLogger(
                  context: context,
                  userId: SessionService.currentCareSubjectId,
                  gamificationService: _gs,
                  onLogged: _handleLogged,
                ),
                icon: const Icon(Icons.architecture_rounded),
                label: const Text('Log Cobb Angle'),
                backgroundColor: cs.surfaceContainerHigh,
                foregroundColor: cs.onSurface,
              ),
              FloatingActionButton.extended(
                heroTag: 'fab_appointment',
                onPressed: () => showAppointmentLogger(
                  context: context,
                  userId: SessionService.currentCareSubjectId,
                  gamificationService: _gs,
                  onLogged: _handleLogged,
                ),
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('Schedule Visit'),
                backgroundColor: cs.surfaceContainerHigh,
                foregroundColor: cs.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Privacy Banner ───────────────────────────────────────────────────────────

class _PrivacyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primarySage.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primarySage.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Privacy Notice: Your health data, symptom logs, and Cobb angle '
              'readings are stored locally on your device only.',
              style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

// ─── Cobb Angle Chart ─────────────────────────────────────────────────────────

class _CobbChart extends StatelessWidget {
  final List<({DateTime date, double degrees})> history;
  final List<({DateTime date, double value})> overlayData;
  final String overlayOption;
  final String timeRange;

  const _CobbChart({
    required this.history,
    this.overlayData = const [],
    this.overlayOption = 'None',
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    if (history.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderCream),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 36,
                color: AppTheme.accentLavender,
              ),
              const SizedBox(height: 10),
              Text(
                'No data yet — log your first angle to see your trend',
                textAlign: TextAlign.center,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Log a measurement from your clinic record using the + button. SpineUp shows what you recorded and does not interpret clinical change.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    final minDeg = math.max(
      0.0,
      history.map((e) => e.degrees).reduce(math.min) - 5,
    );
    final maxDeg = history.map((e) => e.degrees).reduce(math.max) + 5;

    final now = DateTime.now();
    double minX;
    double maxX = now.millisecondsSinceEpoch.toDouble();
    double xInterval;
    String Function(DateTime) formatX;

    switch (timeRange) {
      case 'Week':
      case '7d':
        minX = now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch
            .toDouble();
        xInterval = const Duration(days: 1).inMilliseconds.toDouble();
        formatX = (dt) => DateFormat.E().format(dt);
        break;
      case 'Month':
      case '30d':
        minX = now
            .subtract(const Duration(days: 30))
            .millisecondsSinceEpoch
            .toDouble();
        xInterval = const Duration(days: 7).inMilliseconds.toDouble();
        formatX = (dt) => DateFormat.Md().format(dt);
        break;
      case 'Year':
      case '90d':
        minX = now
            .subtract(const Duration(days: 365))
            .millisecondsSinceEpoch
            .toDouble();
        xInterval = const Duration(days: 60).inMilliseconds.toDouble();
        formatX = (dt) => DateFormat.MMM().format(dt);
        break;
      default: // 'All'
        final firstDate = history.first.date;
        minX = firstDate.millisecondsSinceEpoch.toDouble();
        final daysDiff = now.difference(firstDate).inDays;
        if (daysDiff > 365) {
          xInterval = const Duration(days: 180).inMilliseconds.toDouble();
          formatX = (dt) => DateFormat.yMMM().format(dt);
        } else {
          xInterval = const Duration(days: 30).inMilliseconds.toDouble();
          formatX = (dt) => DateFormat.MMM().format(dt);
        }
    }

    final cobbSpots = history.map((e) {
      return FlSpot(e.date.millisecondsSinceEpoch.toDouble(), e.degrees);
    }).toList();

    List<FlSpot> overlaySpots = [];
    if (overlayData.isNotEmpty) {
      overlaySpots = overlayData.map((e) {
        return FlSpot(e.date.millisecondsSinceEpoch.toDouble(), e.value);
      }).toList();
    }

    final overlayColor = overlayOption == 'Pain Level'
        ? AppTheme.secondaryCoral
        : AppTheme.primarySage;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCream),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest recorded: ${history.last.degrees.toStringAsFixed(1)}°',
                style: tt.labelSmall?.copyWith(
                  color: AppTheme.accentLavender,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (overlayData.isNotEmpty)
                Text(
                  '${overlayOption == 'Pain Level' ? 'Pain' : 'Stretches'}: ${overlayData.last.value.toStringAsFixed(0)}',
                  style: tt.labelSmall?.copyWith(
                    color: overlayColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minDeg.clamp(0, 180),
                maxY: maxDeg.clamp(0, 180),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.borderCream.withValues(alpha: 0.6),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          fitInside: SideTitleFitInsideData(
                            enabled: true,
                            distanceFromEdge: 4,
                            parentAxisSize: meta.parentAxisSize,
                            axisPosition: meta.axisPosition,
                          ),
                          child: Text(
                            '${value.toInt()}°',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(
                          value.toInt(),
                        );
                        return SideTitleWidget(
                          meta: meta,
                          fitInside: SideTitleFitInsideData(
                            enabled: true,
                            distanceFromEdge: 4,
                            parentAxisSize: meta.parentAxisSize,
                            axisPosition: meta.axisPosition,
                          ),
                          child: Text(
                            formatX(dt),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: cobbSpots,
                    isCurved: true,
                    color: AppTheme.accentLavender,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accentLavender.withValues(alpha: 0.15),
                    ),
                  ),
                  if (overlaySpots.isNotEmpty)
                    LineChartBarData(
                      spots: overlaySpots,
                      isCurved: true,
                      color: overlayColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isCobb = spot.barIndex == 0;
                        final dt = DateTime.fromMillisecondsSinceEpoch(
                          spot.x.toInt(),
                        );
                        final dateStr = DateFormat.MMMd().format(dt);
                        final label = isCobb
                            ? '$dateStr: ${spot.y.toStringAsFixed(1)}°'
                            : '$overlayOption: ${spot.y.toInt()}';
                        return LineTooltipItem(
                          label,
                          TextStyle(
                            color: isCobb
                                ? AppTheme.accentLavender
                                : overlayColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
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

// ─── Event Tile ───────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final Event event;
  final bool showXp;

  const _EventTile({required this.event, this.showXp = true});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final painValue = event.payload['pain_level'];
    final painLabel = painValue is num
        ? 'pain ${painValue.round()}/10'
        : 'pain not recorded';
    final moodLabel = event.payload['mood'] ?? 'mood not recorded';

    final (icon, label, color) = switch (event.type) {
      EventType.stretchCompleted => (
        Icons.self_improvement_rounded,
        'Stretch: ${event.payload['exercise_name'] ?? 'Session'}',
        AppTheme.primarySage,
      ),
      EventType.journalEntry => (
        Icons.edit_note_rounded,
        'Journal: $painLabel · $moodLabel',
        AppTheme.secondaryCoral,
      ),
      EventType.angleLogged => (
        Icons.architecture_rounded,
        'Cobb angle: ${(event.payload['degrees'] as num?)?.toStringAsFixed(1) ?? '?'}°',
        AppTheme.accentLavender,
      ),
      EventType.appointmentAttended => (
        Icons.medical_services_rounded,
        'Doctor appointment',
        AppTheme.primarySage,
      ),
      EventType.profileCompleted => (
        Icons.person_rounded,
        'Profile completed',
        AppTheme.accentLavender,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderCream),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: tt.bodySmall),
                Text(
                  _formatDate(event.timestamp),
                  style: tt.labelSmall?.copyWith(
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (showXp)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${event.xpValue} XP',
                style: tt.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
