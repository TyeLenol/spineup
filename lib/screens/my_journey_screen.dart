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
                                    fontWeight: FontWeight.w600,
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
        child: ExpandableFab(
          type: ExpandableFabType.up,
          distance: 70,
          openButtonBuilder: RotateFloatingActionButtonBuilder(
            child: quickTourTarget(
              registry: widget.tutorialRegistry,
              page: QuickTourPage.journey,
              id: 'add-record',
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
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
    final sortedHistory = List<({DateTime date, double degrees})>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedHistory.isEmpty) {
      return Container(
        height: 232,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.surfaceContainerHigh, cs.surfaceContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accentLavender.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  size: 28,
                  color: AppTheme.accentLavender,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your trend will appear here',
                textAlign: TextAlign.center,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                'Log a measurement from your clinic record to start a visual record of what you entered.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: AppTheme.mutedForeground,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final firstDate = sortedHistory.first.date;
    final lastDate = sortedHistory.last.date;
    final startDate = switch (timeRange) {
      'Week' || '7d' => now.subtract(const Duration(days: 7)),
      'Month' || '30d' => now.subtract(const Duration(days: 30)),
      'Year' || '90d' => now.subtract(const Duration(days: 365)),
      _ => firstDate,
    };
    var endDate = lastDate.isAfter(now) ? lastDate : now;
    if (!endDate.isAfter(startDate)) {
      endDate = startDate.add(const Duration(days: 1));
    }

    final minX = startDate.millisecondsSinceEpoch.toDouble();
    final maxX = endDate.millisecondsSinceEpoch.toDouble();
    final rawMin = sortedHistory.map((e) => e.degrees).reduce(math.min);
    final rawMax = sortedHistory.map((e) => e.degrees).reduce(math.max);
    final spread = math.max(10.0, rawMax - rawMin);
    final yPadding = math.max(4.0, spread * 0.16);
    final minY = math.max(0.0, rawMin - yPadding);
    final maxY = math.min(180.0, math.max(minY + 10.0, rawMax + yPadding));
    final cobbSpots = sortedHistory
        .map((e) => FlSpot(e.date.millisecondsSinceEpoch.toDouble(), e.degrees))
        .toList();
    final overlaySpots = List<({DateTime date, double value})>.from(overlayData)
      ..sort((a, b) => a.date.compareTo(b.date));
    final overlayColor = overlayOption == 'Pain Level'
        ? AppTheme.secondaryCoral
        : AppTheme.primarySage;
    final rangeLabel = switch (timeRange) {
      'Week' || '7d' => 'Last 7 days',
      'Month' || '30d' => 'Last 30 days',
      'Year' || '90d' => 'Last year',
      _ => 'All recorded time',
    };

    return Container(
      height: 292,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.surfaceContainerHigh, cs.surfaceContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Angle trend',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$rangeLabel · ${sortedHistory.length} ${sortedHistory.length == 1 ? 'measurement' : 'measurements'}',
                      style: tt.bodySmall?.copyWith(
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap a point for the exact date',
                      style: tt.labelSmall?.copyWith(
                        color: AppTheme.mutedForeground,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentLavender.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LATEST',
                      style: tt.labelSmall?.copyWith(
                        color: AppTheme.accentLavender,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${sortedHistory.last.degrees.toStringAsFixed(1)}°',
                      style: tt.titleMedium?.copyWith(
                        color: AppTheme.accentLavender,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (overlaySpots.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _ChartLegendPill(
                  label: 'Angle',
                  color: AppTheme.accentLavender,
                ),
                _ChartLegendPill(
                  label: overlayOption == 'Pain Level'
                      ? 'Pain context'
                      : 'Stretch context',
                  color: overlayColor,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    overlayOption == 'Pain Level'
                        ? 'Latest: ${overlaySpots.last.value.toInt()}/10'
                        : 'In range: ${overlaySpots.fold<double>(0, (sum, item) => sum + item.value).toInt()} stretches',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 13),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tickCount = math.max<int>(
                  3,
                  math.min<int>(6, (constraints.maxWidth / 70).floor()),
                );
                final xInterval = (maxX - minX) / (tickCount - 1);
                final tickDates = List.generate(
                  tickCount,
                  (index) => DateTime.fromMillisecondsSinceEpoch(
                    (minX + xInterval * index).round(),
                  ),
                );
                final showDots = sortedHistory.length <= 12;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.surface.withValues(alpha: 0.48),
                        cs.surface.withValues(alpha: 0.12),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 6, 0),
                    child: LineChart(
                      LineChartData(
                        minX: minX,
                        maxX: maxX,
                        minY: minY,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 10,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: cs.outlineVariant.withValues(alpha: 0.35),
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
                              reservedSize: 38,
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
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: xInterval,
                              getTitlesWidget: (value, meta) {
                                final rawIndex = ((value - minX) / xInterval)
                                    .round();
                                final tickIndex = rawIndex < 0
                                    ? 0
                                    : rawIndex >= tickCount
                                    ? tickCount - 1
                                    : rawIndex;
                                final label = _formatJourneyChartDate(
                                  tickDates[tickIndex],
                                  timeRange,
                                  startDate,
                                  endDate,
                                );
                                return SideTitleWidget(
                                  meta: meta,
                                  fitInside: SideTitleFitInsideData(
                                    enabled: true,
                                    distanceFromEdge: 6,
                                    parentAxisSize: meta.parentAxisSize,
                                    axisPosition: meta.axisPosition,
                                  ),
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
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
                            isCurved: false,
                            color: AppTheme.accentLavender,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: showDots),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.accentLavender.withValues(
                                alpha: 0.10,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final dt = DateTime.fromMillisecondsSinceEpoch(
                                  spot.x.toInt(),
                                );
                                final dateStr = DateFormat.yMMMd().format(dt);
                                return LineTooltipItem(
                                  '$dateStr\n${spot.y.toStringAsFixed(1)}° angle',
                                  const TextStyle(
                                    color: AppTheme.accentLavender,
                                    fontWeight: FontWeight.w700,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegendPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ChartLegendPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatJourneyChartDate(
  DateTime date,
  String timeRange,
  DateTime start,
  DateTime end,
) {
  switch (timeRange) {
    case 'Week':
    case '7d':
      return DateFormat('EEE').format(date);
    case 'Month':
    case '30d':
      return DateFormat('MMM d').format(date);
    case 'Year':
    case '90d':
      return DateFormat('MMM').format(date);
    default:
      return DateFormat(
        end.difference(start).inDays > 365 ? 'MMM yy' : 'MMM d',
      ).format(date);
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

    final (icon, label, accentColor) = switch (event.type) {
      EventType.stretchCompleted => (
        Icons.self_improvement_rounded,
        'Stretch \u00b7 ${event.payload['exercise_name'] ?? 'Session'}',
        AppTheme.primarySage,
      ),
      EventType.journalEntry => (
        Icons.edit_note_rounded,
        'Journal \u00b7 $painLabel · $moodLabel',
        AppTheme.secondaryCoral,
      ),
      EventType.angleLogged => (
        Icons.architecture_rounded,
        'Cobb angle \u00b7 ${(event.payload['degrees'] as num?)?.toStringAsFixed(1) ?? '?'}°',
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
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor.withValues(alpha: 0.55)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: accentColor, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: tt.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(event.timestamp),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showXp) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Text(
                          '+${event.xpValue} XP',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
