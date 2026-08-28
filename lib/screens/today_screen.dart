import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../models/routine.dart';
import '../models/appointment.dart';
import '../models/external_content.dart';
import '../services/external_content_service.dart';
import '../services/gamification_service.dart';
import '../services/session_service.dart';
import '../services/routine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/action_reward_feedback.dart';
import '../widgets/quick_tour.dart';
import '../widgets/avatar_display.dart';
import 'appointment_logger_modal.dart';
import 'daily_check_in_screen.dart';
import 'routine_library_screen.dart';
import 'external_content_screen.dart';

class TodayScreen extends StatefulWidget {
  final QuickTourTargetRegistry? tutorialRegistry;
  final VoidCallback? onGoToMe;

  const TodayScreen({super.key, this.tutorialRegistry, this.onGoToMe});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _gs = GamificationService();

  GamificationSnapshot _snap = GamificationSnapshot.empty;
  List<Event> _todayEvents = [];
  List<Appointment> _appointments = [];
  List<ExternalContentItem> _savedRoutineVideos = [];
  CareSubjectRoutine? _activeRoutine;
  List<RoutineExercise> _routineExercises = [];
  final Set<String> _completedToday = {};
  bool _loadingSnap = true;
  bool _tutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    final snap = await _gs.getSnapshot(SessionService.currentCareSubjectId);
    final todayEvents = await _gs.getTodayEvents(
      SessionService.currentCareSubjectId,
    );
    final appointments = await _gs.getAppointments(
      SessionService.currentCareSubjectId,
    );
    final savedRoutineVideos =
        await ExternalContentService.savedRoutineVideos();
    final activeRoutine = await RoutineService.loadActiveRoutine();
    final routineExercises = RoutineService.exercisesForIds(
      activeRoutine.exerciseIds,
    );
    final routineIds = routineExercises.map((exercise) => exercise.id).toSet();

    final completedIds = todayEvents
        .where((e) => e.type == EventType.stretchCompleted)
        .map((e) => e.payload['exercise_id'] as String?)
        .whereType<String>()
        .where(routineIds.contains)
        .toSet();

    if (mounted) {
      setState(() {
        _snap = snap;
        _todayEvents = todayEvents;
        _appointments = appointments;
        _savedRoutineVideos = savedRoutineVideos;
        _activeRoutine = activeRoutine;
        _routineExercises = routineExercises;
        _completedToday
          ..clear()
          ..addAll(completedIds);
        _loadingSnap = false;
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
          page: QuickTourPage.today,
          registry: widget.tutorialRegistry!,
        ),
      );
    });
  }

  int get _todayXp => _todayEvents.fold(0, (sum, e) => sum + e.xpValue);

  Appointment? get _nextAppointment {
    final scheduled = _appointments.where((a) => a.isScheduled).toList();
    if (scheduled.isEmpty) return null;
    scheduled.sort(
      (a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime),
    );
    return scheduled.first;
  }

  Future<void> _markExerciseDone(RoutineExercise ex) async {
    if (_completedToday.contains(ex.id)) return;
    setState(() => _completedToday.add(ex.id));
    final result = await _gs.logEvent(
      eventId: const Uuid().v4(),
      userId: SessionService.currentCareSubjectId,
      type: EventType.stretchCompleted,
      payload: {
        'exercise_id': ex.id,
        'exercise_name': ex.name,
        'duration': ex.durationLabel,
        'logged_at': DateTime.now().toIso8601String(),
      },
    );
    await _loadSnapshot();
    if (!mounted) return;
    showActionRewardFeedback(
      context,
      title: '${ex.name} complete',
      xpAwarded: result.xpAwarded,
      dailyBonusAwarded: result.dailyBonusAwarded,
    );
  }

  Event? get _latestJournalLogToday {
    final journals = _todayEvents
        .where((e) => e.type == EventType.journalEntry)
        .toList();
    return journals.isNotEmpty ? journals.last : null;
  }

  Future<void> _openRoutineLibrary() async {
    final routine =
        _activeRoutine ??
        const CareSubjectRoutine(name: 'My Routine', exerciseIds: []);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RoutineLibraryScreen(currentRoutine: routine),
      ),
    );
    if (changed == true) await _loadSnapshot();
  }

  void _showRoutineSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _RoutineSheet(
        exercises: _routineExercises,
        savedVideos: _savedRoutineVideos,
        initiallyCompleted: _completedToday,
        onMarkDone: _markExerciseDone,
        onEdit: () {
          Navigator.of(context).pop();
          _openRoutineLibrary();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tt = theme.textTheme;

    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    final name = _snap.userProfile.name;
    final dateStr = DateFormat('EEEE, MMM d').format(now).toUpperCase();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── App bar ───────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                toolbarHeight: 80,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateStr,
                      style: tt.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$greeting, $name',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: widget.onGoToMe,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _loadingSnap
                              ? ColoredBox(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const SizedBox.expand(),
                                )
                              : AvatarDisplay(
                                  profile: _snap.userProfile,
                                  size: 42,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Primary daily action ───────────────────────────────
                    quickTourTarget(
                      registry: widget.tutorialRegistry,
                      page: QuickTourPage.today,
                      id: 'check-in',
                      child: _DailyCheckInSummaryCard(
                        latestLog: _latestJournalLogToday,
                        onTap: () async {
                          final result = await Navigator.push<LogEventResult>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DailyCheckInScreen(
                                userId: SessionService.currentCareSubjectId,
                                userProfile: _snap.userProfile,
                                existingLogToday: _latestJournalLogToday,
                              ),
                            ),
                          );
                          if (result != null) {
                            await _loadSnapshot();
                            if (!context.mounted) return;
                            showActionRewardFeedback(
                              context,
                              title: 'Check-in saved',
                              xpAwarded: result.xpAwarded,
                              dailyBonusAwarded: result.dailyBonusAwarded,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    quickTourTarget(
                      registry: widget.tutorialRegistry,
                      page: QuickTourPage.today,
                      id: 'routine',
                      child: _RoutineEntryCard(
                        routineName: _activeRoutine?.name ?? 'My Routine',
                        completed: _completedToday.length,
                        total: _routineExercises.length,
                        savedVideoCount: _savedRoutineVideos.length,
                        onTap: _showRoutineSheet,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Supporting motivation ──────────────────────────────
                    quickTourTarget(
                      registry: widget.tutorialRegistry,
                      page: QuickTourPage.today,
                      id: 'today-progress',
                      child: _StatPairSection(
                        streakDays: _snap.streakDays,
                        todayXp: _todayXp,
                        targetXp: kDailyXpTarget,
                        loading: _loadingSnap,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LevelXpCard(snap: _snap, loading: _loadingSnap),
                    const SizedBox(height: 16),

                    // ── Next Appointment ──────────────────────────────────
                    _NextAppointmentCard(
                      nextAppointment: _nextAppointment,
                      onTap: () => showAppointmentLogger(
                        context: context,
                        userId: SessionService.currentCareSubjectId,
                        gamificationService: _gs,
                        onLogged: (result) async {
                          await _loadSnapshot();
                          if (!context.mounted) return;
                          showActionRewardFeedback(
                            context,
                            title: 'Appointment recorded',
                            xpAwarded: result.xpAwarded,
                            dailyBonusAwarded: result.dailyBonusAwarded,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Compact Progress Strip ───────────────────────────────────────────────────

class _LevelXpCard extends StatelessWidget {
  final GamificationSnapshot snap;
  final bool loading;

  const _LevelXpCard({required this.snap, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox.shrink();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primarySage.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Level ${snap.currentLevel}',
              style: tt.labelLarge?.copyWith(
                color: AppTheme.primarySage,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snap.currentTitle,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: snap.levelProgress,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation(
                      AppTheme.primarySage,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${snap.totalXp} XP',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─── Exercise Card ────────────────────────────────────────────────────────────

class RoutineExerciseCard extends StatefulWidget {
  final RoutineExercise exercise;
  final bool done;
  final VoidCallback onMarkDone;

  const RoutineExerciseCard({
    super.key,
    required this.exercise,
    required this.done,
    required this.onMarkDone,
  });

  @override
  State<RoutineExerciseCard> createState() => RoutineExerciseCardState();
}

class RoutineExerciseCardState extends State<RoutineExerciseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.done ? cs.surface : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: (!widget.done && _expanded)
            ? Border.all(color: AppTheme.primarySage, width: 1.5)
            : Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
                width: 1.0,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: widget.done
                  ? AppTheme.primarySage.withValues(alpha: 0.2)
                  : AppTheme.primarySage.withValues(alpha: 0.55),
            ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Opacity(
                              opacity: widget.done ? 0.5 : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.exercise.icon,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Opacity(
                                opacity: widget.done ? 0.5 : 1.0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _AnimatedSquigglyStrikethrough(
                                      isStruck: widget.done,
                                      child: Text(
                                        widget.exercise.name,
                                        style: tt.titleSmall?.copyWith(
                                          color: widget.done
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant
                                              : cs.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.exercise.durationLabel}  ·  ${_expanded ? 'Hide steps' : 'View steps'}',
                                      style: tt.bodySmall?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Icon(
                              widget.done
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: widget.done
                                  ? AppTheme.primarySage
                                  : _expanded
                                  ? AppTheme.primarySage
                                  : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.5),
                              size: 28,
                            ),
                          ],
                        ),
                        if (_expanded) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Text(
                            widget.exercise.description,
                            style: tt.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => _showExerciseInstructions(
                              context,
                              widget.exercise,
                              onMarkDone: widget.onMarkDone,
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start Exercise'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primarySage,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showExerciseInstructions(
  BuildContext context,
  RoutineExercise exercise, {
  required VoidCallback onMarkDone,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => RoutineExerciseGuidedFlowSheet(
      exercise: exercise,
      onComplete: () {
        Navigator.of(context).pop();
        onMarkDone();
      },
      onFinishEarly: () {
        Navigator.of(context).pop();
        onMarkDone();
      },
    ),
  );
}

class RoutineExerciseGuidedFlowSheet extends StatefulWidget {
  final RoutineExercise exercise;
  final VoidCallback onComplete;
  final VoidCallback onFinishEarly;

  const RoutineExerciseGuidedFlowSheet({
    super.key,
    required this.exercise,
    required this.onComplete,
    required this.onFinishEarly,
  });

  @override
  State<RoutineExerciseGuidedFlowSheet> createState() =>
      RoutineExerciseGuidedFlowSheetState();
}

class RoutineExerciseGuidedFlowSheetState
    extends State<RoutineExerciseGuidedFlowSheet> {
  int _currentStepIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _timerRunning = false;
  bool _stepCompleted = false;

  @override
  void initState() {
    super.initState();
    _setupStep(_currentStepIndex);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setupStep(int index) {
    _timer?.cancel();
    final step = widget.exercise.steps[index];
    if (step.durationSeconds != null && step.durationSeconds! > 0) {
      _secondsRemaining = step.durationSeconds!;
      _timerRunning = true;
      _stepCompleted = false;
      _startTimer();
    } else {
      _secondsRemaining = 0;
      _timerRunning = false;
      _stepCompleted = true;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        HapticFeedback.lightImpact();
        setState(() {
          _secondsRemaining = 0;
          _timerRunning = false;
          _stepCompleted = true;
        });
      }
    });
  }

  void _toggleTimer() {
    if (_timerRunning) {
      _timer?.cancel();
      setState(() => _timerRunning = false);
    } else {
      if (_secondsRemaining == 0) {
        final step = widget.exercise.steps[_currentStepIndex];
        _secondsRemaining = step.durationSeconds ?? 15;
        _stepCompleted = false;
      }
      setState(() => _timerRunning = true);
      _startTimer();
    }
  }

  void _goToStep(int index) {
    if (index >= 0 && index < widget.exercise.steps.length) {
      setState(() {
        _currentStepIndex = index;
        _setupStep(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final steps = widget.exercise.steps;
    final step = steps[_currentStepIndex];
    final isLastStep = _currentStepIndex == steps.length - 1;
    final progress = (_currentStepIndex + 1) / steps.length;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 14),

          // Header with Finish Early option
          Row(
            children: [
              Icon(widget.exercise.icon, color: AppTheme.primarySage, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.exercise.name,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: widget.onFinishEarly,
                icon: const Icon(Icons.fast_forward_rounded, size: 16),
                label: const Text(
                  'Finish early',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress indicator & Step counter
          Row(
            children: [
              Text(
                'Step ${_currentStepIndex + 1} of ${steps.length}',
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: tt.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: cs.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 20),

          // Step Details Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundCream, // Warm backdrop
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: _stepCompleted
                        ? AppTheme.primarySage.withValues(alpha: 0.6)
                        : AppTheme.secondaryCoral.withValues(
                            alpha: 0.6,
                          ), // Warm coral active state
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.stepText,
                            style: tt.bodyMedium?.copyWith(height: 1.4),
                          ),
                          if (step.cueTags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: step.cueTags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentLavender.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag,
                                    style: tt.labelSmall?.copyWith(
                                      color: AppTheme.accentLavender,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          // Timer display if set
                          if (step.durationSeconds != null &&
                              step.durationSeconds! > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      width: 4,
                                      color: _stepCompleted
                                          ? AppTheme.primarySage.withValues(
                                              alpha: 0.6,
                                            )
                                          : AppTheme.secondaryCoral.withValues(
                                              alpha: 0.6,
                                            ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _stepCompleted
                                                  ? Icons.check_circle_rounded
                                                  : Icons.timer_rounded,
                                              color: _stepCompleted
                                                  ? AppTheme.primarySage
                                                  : AppTheme.secondaryCoral,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _stepCompleted
                                                      ? 'Step Timer Completed! ✓'
                                                      : '${_secondsRemaining.toString().padLeft(2, '0')}s remaining',
                                                  style: tt.labelMedium?.copyWith(
                                                    color: _stepCompleted
                                                        ? AppTheme.primarySage
                                                        : AppTheme
                                                              .secondaryCoral,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (!_stepCompleted)
                                                  Text(
                                                    'Tap Next when ready',
                                                    style: tt.bodySmall
                                                        ?.copyWith(
                                                          fontSize: 10,
                                                          color: AppTheme
                                                              .mutedForeground,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: Icon(
                                                _timerRunning
                                                    ? Icons
                                                          .pause_circle_filled_rounded
                                                    : Icons
                                                          .play_circle_fill_rounded,
                                              ),
                                              color: _stepCompleted
                                                  ? AppTheme.primarySage
                                                  : AppTheme.secondaryCoral,
                                              onPressed: _toggleTimer,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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
          ),
          const SizedBox(height: 20),

          // Navigation buttons
          Row(
            children: [
              if (_currentStepIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goToStep(_currentStepIndex - 1),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Previous'),
                    ),
                  ),
                ),
              if (_currentStepIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isLastStep
                      ? widget.onComplete
                      : () => _goToStep(_currentStepIndex + 1),
                  icon: Icon(
                    isLastStep
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(isLastStep ? 'Mark complete' : 'Next step'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _stepCompleted || isLastStep
                        ? AppTheme.primarySage
                        : cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Daily Check-In Summary Card ──────────────────────────────────────────────

class _DailyCheckInSummaryCard extends StatelessWidget {
  final Event? latestLog;
  final VoidCallback onTap;

  const _DailyCheckInSummaryCard({
    required this.latestLog,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tt = theme.textTheme;
    final logged = latestLog != null;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 140),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Check-in',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary.withValues(alpha: 0.72),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                logged ? 'Done for today!' : 'How is your spine feeling?',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                  fontSize: 18,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      logged ? 'COMPLETE' : 'CHECK IN',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      logged
                          ? Icons.check_rounded
                          : Icons.chevron_right_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Routine Entry + Focused Routine Sheet ─────────────────────────────────────
class _RoutineEntryCard extends StatelessWidget {
  final String routineName;
  final int completed;
  final int total;
  final int savedVideoCount;
  final VoidCallback onTap;

  const _RoutineEntryCard({
    required this.routineName,
    required this.completed,
    required this.total,
    required this.savedVideoCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = total == 0 ? 0.0 : completed / total;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation(
                        AppTheme.primarySage,
                      ),
                    ),
                    Text(
                      '$completed/$total',
                      style: tt.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routineName,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      savedVideoCount > 0
                          ? '$savedVideoCount saved video${savedVideoCount == 1 ? '' : 's'} in My Routine.'
                          : completed == total
                          ? 'All done for today.'
                          : 'A short set of guided movements for today.',
                      style: tt.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      completed == total ? 'Review routine' : 'Open routine',
                      style: tt.labelLarge?.copyWith(
                        color: AppTheme.primarySage,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineSheet extends StatefulWidget {
  final List<RoutineExercise> exercises;
  final List<ExternalContentItem> savedVideos;
  final Set<String> initiallyCompleted;
  final Future<void> Function(RoutineExercise exercise) onMarkDone;
  final VoidCallback onEdit;

  const _RoutineSheet({
    required this.exercises,
    required this.savedVideos,
    required this.initiallyCompleted,
    required this.onMarkDone,
    required this.onEdit,
  });

  @override
  State<_RoutineSheet> createState() => _RoutineSheetState();
}

class _RoutineSheetState extends State<_RoutineSheet> {
  late final Set<String> _completed;

  @override
  void initState() {
    super.initState();
    _completed = {...widget.initiallyCompleted};
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today\'s routine', style: tt.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${_completed.length} of ${widget.exercises.length} complete',
                          style: tt.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit routine',
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Close routine',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                    child: Text(
                      'Guided exercises',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...widget.exercises.map(
                    (exercise) => RoutineExerciseCard(
                      exercise: exercise,
                      done: _completed.contains(exercise.id),
                      onMarkDone: () {
                        if (_completed.add(exercise.id)) {
                          setState(() {});
                          widget.onMarkDone(exercise);
                        }
                      },
                    ),
                  ),
                  if (widget.savedVideos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
                      child: Text(
                        'Saved exercise videos',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      child: Text(
                        'Open a saved video when you want visual guidance. It plays from its original source.',
                        style: tt.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ...widget.savedVideos.map(
                      (item) => _SavedRoutineVideoCard(item: item),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── XP Banner ────────────────────────────────────────────────────────────────

class _SavedRoutineVideoCard extends StatelessWidget {
  final ExternalContentItem item;

  const _SavedRoutineVideoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExternalContentDetailPage(item: item),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accentLavender.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.play_circle_outline_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.sourceName}  ·  Watch from source',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Pair Section (Streak + Daily Goal) ────────────────────────────────

class _StatPairSection extends StatelessWidget {
  final int streakDays;
  final int todayXp;
  final int targetXp;
  final bool loading;

  const _StatPairSection({
    required this.streakDays,
    required this.todayXp,
    required this.targetXp,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = (todayXp / targetXp).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppTheme.secondaryCoral,
                  size: 24,
                ),
                const SizedBox(height: 24),
                Text(
                  '$streakDays',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Day Streak',
                  style: tt.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.flag_rounded,
                  color: AppTheme.primarySage,
                  size: 24,
                ),
                const SizedBox(height: 24),
                Text(
                  '$percentage%',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily Goal',
                  style: tt.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Next Appointment Card ──────────────────────────────────────────────────

class _NextAppointmentCard extends StatelessWidget {
  final Appointment? nextAppointment;
  final VoidCallback onTap;

  const _NextAppointmentCard({
    required this.nextAppointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    String monthStr = '';
    String dayStr = '';
    String titleStr = 'No upcoming appointments';
    String timeStr = 'Tap to schedule';

    if (nextAppointment != null) {
      final dt = nextAppointment!.scheduledDateTime;
      final months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      monthStr = months[dt.month - 1];
      dayStr = '${dt.day}';
      titleStr = nextAppointment!.title;

      String hour = dt.hour > 12
          ? '${dt.hour - 12}'
          : (dt.hour == 0 ? '12' : '${dt.hour}');
      String minute = dt.minute.toString().padLeft(2, '0');
      String ampm = dt.hour >= 12 ? 'PM' : 'AM';
      timeStr = '$hour:$minute $ampm';
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppTheme.primarySage.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.onSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: nextAppointment != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            monthStr,
                            style: tt.labelSmall?.copyWith(
                              color: AppTheme.primarySage,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            dayStr,
                            style: tt.titleMedium?.copyWith(
                              color: cs.surface,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        Icons.add_rounded,
                        color: AppTheme.primarySage,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT APPOINTMENT',
                      style: tt.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (nextAppointment != null)
                      Text(
                        '$titleStr • $timeStr',
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        titleStr,
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated Squiggly Strikethrough ──────────────────────────────────────────

class _AnimatedSquigglyStrikethrough extends StatelessWidget {
  final Widget child;
  final bool isStruck;

  const _AnimatedSquigglyStrikethrough({
    required this.child,
    required this.isStruck,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isStruck ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) {
        return CustomPaint(
          foregroundPainter: value > 0
              ? _SquigglyPainter(progress: value)
              : null,
          child: childWidget,
        );
      },
      child: child,
    );
  }
}

class _SquigglyPainter extends CustomPainter {
  final double progress;

  _SquigglyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = AppTheme.primarySage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final yCenter = size.height / 2;

    // An imperfect, hand-drawn-like curve
    path.moveTo(0, yCenter + 2);
    path.quadraticBezierTo(
      size.width * 0.25,
      yCenter - 4,
      size.width * 0.5,
      yCenter + 1,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      yCenter + 5,
      size.width,
      yCenter - 2,
    );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extractPath = metric.extractPath(0.0, metric.length * progress);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(_SquigglyPainter old) => old.progress != progress;
}
