import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../models/appointment.dart';
import '../services/gamification_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'appointment_logger_modal.dart';
import 'daily_check_in_screen.dart';

// ─── Exercise catalogue ───────────────────────────────────────────────────────

class ExerciseStep {
  final String stepText;
  final int? durationSeconds;
  final List<String> cueTags;

  const ExerciseStep({
    required this.stepText,
    this.durationSeconds,
    this.cueTags = const [],
  });
}

class _Exercise {
  final String id;
  final String name;
  final String description;
  final String duration;
  final IconData icon;
  final List<ExerciseStep> steps;

  const _Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.icon,
    required this.steps,
  });
}

const List<_Exercise> _exercises = [
  _Exercise(
    id: 'cat_cow',
    name: 'Cat-Cow Mobilization',
    description: 'Alternating spinal flexion and extension on all fours.',
    duration: '45 s',
    icon: Icons.self_improvement_rounded,
    steps: [
      ExerciseStep(
        stepText:
            'Start on all fours with hands under shoulders and knees directly beneath hips.',
        durationSeconds: 10,
        cueTags: ['Positioning', 'Neutral spine'],
      ),
      ExerciseStep(
        stepText:
            'Inhale as you arch your back gently, dropping stomach toward floor and looking up (Cow).',
        durationSeconds: 15,
        cueTags: ['Deep inhale', 'Gentle arch'],
      ),
      ExerciseStep(
        stepText:
            'Exhale as you draw belly button in, rounding your spine toward ceiling (Cat).',
        durationSeconds: 15,
        cueTags: ['Slow exhale', 'Core activation'],
      ),
      ExerciseStep(
        stepText: 'Move slowly between both positions for final stabilization.',
        durationSeconds: 15,
        cueTags: ['Fluid motion', 'Repeat x3'],
      ),
    ],
  ),
  _Exercise(
    id: 'side_plank',
    name: 'Side-Plank Core Hold',
    description: 'Lateral core stabilization — keep hips level.',
    duration: '60 s',
    icon: Icons.fitness_center_rounded,
    steps: [
      ExerciseStep(
        stepText:
            'Lie on your side with elbow directly beneath shoulder and legs straight.',
        durationSeconds: 10,
        cueTags: ['Alignment'],
      ),
      ExerciseStep(
        stepText:
            'Engage your core and lift hips off the floor until your body forms a straight line.',
        durationSeconds: 25,
        cueTags: ['Core hold', 'Hips level'],
      ),
      ExerciseStep(
        stepText: 'Switch sides and hold steady while breathing deeply.',
        durationSeconds: 25,
        cueTags: ['Switch side', 'Deep breathing'],
      ),
    ],
  ),
  _Exercise(
    id: 'hamstring_wall',
    name: 'Hamstring Wall Stretch',
    description: 'Lie on back, extend leg vertically against wall.',
    duration: '45 s',
    icon: Icons.airline_seat_flat_angled_rounded,
    steps: [
      ExerciseStep(
        stepText: 'Lie flat on your back near a doorway or wall corner.',
        durationSeconds: 10,
        cueTags: ['Flat back'],
      ),
      ExerciseStep(
        stepText:
            'Rest one leg vertically against the wall while keeping the other flat on floor.',
        durationSeconds: 20,
        cueTags: ['Leg vertical', 'Hold 20s'],
      ),
      ExerciseStep(
        stepText:
            'Flex your foot gently until a deep stretch is felt in the hamstring.',
        durationSeconds: 20,
        cueTags: ['Flex foot', 'Switch leg'],
      ),
    ],
  ),
  _Exercise(
    id: 'thoracic_extension',
    name: 'Thoracic Extension',
    description: 'Foam roller or chair-back thoracic extension over T6–T9.',
    duration: '60 s',
    icon: Icons.accessibility_new_rounded,
    steps: [
      ExerciseStep(
        stepText:
            'Sit upright in a firm chair or place a foam roller under mid-back.',
        durationSeconds: 10,
        cueTags: ['Seated upright'],
      ),
      ExerciseStep(
        stepText: 'Support head gently with hands clasped behind neck.',
        durationSeconds: 15,
        cueTags: ['Neck support'],
      ),
      ExerciseStep(
        stepText: 'Lean backward over chair back or roller to open chest.',
        durationSeconds: 35,
        cueTags: ['Open chest', 'Breathe deep'],
      ),
    ],
  ),
  _Exercise(
    id: 'bird_dog',
    name: 'Bird-Dog Core Balance',
    description: 'Opposite arm and leg extension for spine stability.',
    duration: '45 s',
    icon: Icons.sports_gymnastics_rounded,
    steps: [
      ExerciseStep(
        stepText: 'Begin on hands and knees with a neutral spine posture.',
        durationSeconds: 10,
        cueTags: ['Quadruped'],
      ),
      ExerciseStep(
        stepText:
            'Reach right arm forward and extend left leg straight back simultaneously.',
        durationSeconds: 20,
        cueTags: ['Opposite reach', 'Hold 3s'],
      ),
      ExerciseStep(
        stepText: 'Return to start and alternate sides for 45 seconds.',
        durationSeconds: 20,
        cueTags: ['Alternate sides', 'Keep hips level'],
      ),
    ],
  ),
  _Exercise(
    id: 'pelvic_tilt',
    name: 'Pelvic Tilt & Bridge',
    description: 'Lower back flattening and glute activation.',
    duration: '60 s',
    icon: Icons.unfold_more_rounded,
    steps: [
      ExerciseStep(
        stepText: 'Lie on back with knees bent and feet flat on floor.',
        durationSeconds: 10,
        cueTags: ['Supine position'],
      ),
      ExerciseStep(
        stepText:
            'Flatten lower back against floor by tightening core muscles.',
        durationSeconds: 20,
        cueTags: ['Tuck pelvis', 'Core firm'],
      ),
      ExerciseStep(
        stepText: 'Press through heels to lift hips into a bridge position.',
        durationSeconds: 30,
        cueTags: ['Glute bridge', 'Hold 5s'],
      ),
    ],
  ),
  _Exercise(
    id: 'childs_pose',
    name: 'Child’s Pose & Side Reach',
    description: 'Spinal decompression with lateral ribcage stretch.',
    duration: '45 s',
    icon: Icons.nightlight_round,
    steps: [
      ExerciseStep(
        stepText: 'Kneel on floor, touch toes together, and sit back on heels.',
        durationSeconds: 10,
        cueTags: ['Decompress'],
      ),
      ExerciseStep(
        stepText: 'Fold torso forward, extending arms straight ahead on floor.',
        durationSeconds: 20,
        cueTags: ['Reach forward'],
      ),
      ExerciseStep(
        stepText:
            'Walk both hands 45 degrees to one side to target lateral spine curve.',
        durationSeconds: 20,
        cueTags: ['Lateral reach', 'Deep rib stretch'],
      ),
    ],
  ),
  _Exercise(
    id: 'wall_angels',
    name: 'Wall Angels',
    description: 'Postural alignment and scapular mobility against wall.',
    duration: '60 s',
    icon: Icons.auto_awesome_rounded,
    steps: [
      ExerciseStep(
        stepText:
            'Stand with back, head, and buttocks flat against a smooth wall.',
        durationSeconds: 10,
        cueTags: ['Posture reset'],
      ),
      ExerciseStep(
        stepText:
            'Raise arms to 90 degrees (cactus arms), keeping elbows and wrists touching wall.',
        durationSeconds: 25,
        cueTags: ['Cactus arms', 'Wrists on wall'],
      ),
      ExerciseStep(
        stepText:
            'Slowly slide arms overhead along wall without arching lower back.',
        durationSeconds: 25,
        cueTags: ['Overhead slide', 'Repeat 5x'],
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

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
  final Set<String> _completedToday = {};
  bool _loadingSnap = true;
  bool _allExpanded = false;

  // Celebration banner
  String? _xpBannerText;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSnapshot() async {
    final snap = await _gs.getSnapshot(SessionService.currentCareSubjectId);
    final todayEvents = await _gs.getTodayEvents(
      SessionService.currentCareSubjectId,
    );
    final appointments = await _gs.getAppointments(
      SessionService.currentCareSubjectId,
    );

    final completedIds = todayEvents
        .where((e) => e.type == EventType.stretchCompleted)
        .map((e) => e.payload['exercise_id'] as String?)
        .whereType<String>()
        .toSet();

    if (mounted) {
      setState(() {
        _snap = snap;
        _todayEvents = todayEvents;
        _appointments = appointments;
        _completedToday.addAll(completedIds);
        _loadingSnap = false;
      });
    }
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

  void _showBanner(String text) {
    _bannerTimer?.cancel();
    setState(() => _xpBannerText = text);
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _xpBannerText = null);
    });
  }

  Future<void> _markExerciseDone(_Exercise ex) async {
    if (_completedToday.contains(ex.id)) return;
    setState(() => _completedToday.add(ex.id));
    final result = await _gs.logEvent(
      eventId: const Uuid().v4(),
      userId: SessionService.currentCareSubjectId,
      type: EventType.stretchCompleted,
      payload: {
        'exercise_id': ex.id,
        'exercise_name': ex.name,
        'duration': ex.duration,
        'logged_at': DateTime.now().toIso8601String(),
      },
    );
    await _loadSnapshot();
    final bonus = result.dailyBonusAwarded ? ' +5 daily bonus!' : '';
    _showBanner('+${result.xpAwarded} XP$bonus');
  }

  Event? get _latestJournalLogToday {
    final journals = _todayEvents
        .where((e) => e.type == EventType.journalEntry)
        .toList();
    return journals.isNotEmpty ? journals.last : null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                        color: AppTheme.mutedForeground,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$greeting, $name',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadSnapshot,
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Level & XP header ─────────────────────────────────
                    _LevelXpCard(snap: _snap, loading: _loadingSnap),
                    const SizedBox(height: 16),
                    // ── Streak + Daily Goal ───────────────────────────────
                    _StatPairSection(
                      streakDays: _snap.streakDays,
                      todayXp: _todayXp,
                      targetXp: kDailyXpTarget,
                      loading: _loadingSnap,
                    ),
                    const SizedBox(height: 16),

                    // ── Check-In & Routine Progress ───────────────────────
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _DailyCheckInSummaryCard(
                              latestLog: _latestJournalLogToday,
                              onTap: () async {
                                final result =
                                    await Navigator.push<LogEventResult>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DailyCheckInScreen(
                                          userId: SessionService
                                              .currentCareSubjectId,
                                          userProfile: _snap.userProfile,
                                          existingLogToday:
                                              _latestJournalLogToday,
                                        ),
                                      ),
                                    );
                                if (result != null) {
                                  await _loadSnapshot();
                                  final bonus = result.dailyBonusAwarded
                                      ? ' +5 daily bonus!'
                                      : '';
                                  _showBanner('+${result.xpAwarded} XP$bonus');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _RoutineProgressCard(
                              completed: _completedToday.length,
                              total: _exercises.length,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          final bonus = result.dailyBonusAwarded
                              ? ' +5 daily bonus!'
                              : '';
                          _showBanner('+${result.xpAwarded} XP$bonus');
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Today's Routine ───────────────────────────────────
                    Row(
                      children: [
                        Text('Today\'s Routine', style: tt.titleMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_exercises.length} EXERCISES',
                            style: tt.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _allExpanded = !_allExpanded),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _allExpanded ? 'COLLAPSE ALL' : 'EXPAND ALL',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primarySage,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._exercises.map(
                      (ex) => _ExerciseCard(
                        exercise: ex,
                        done: _completedToday.contains(ex.id),
                        forceExpanded: _allExpanded,
                        onMarkDone: () => _markExerciseDone(ex),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),

          // ── XP celebration banner ─────────────────────────────────────────
          if (_xpBannerText != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 24,
              right: 24,
              child: _XpBanner(text: _xpBannerText!),
            ),
        ],
      ),
    );
  }
}

// ─── Level & XP Card ────────────────────────────────────────────────────────

class _LevelXpCard extends StatelessWidget {
  final GamificationSnapshot snap;
  final bool loading;
  const _LevelXpCard({required this.snap, required this.loading});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (loading) return const SizedBox.shrink();

    // Determine next title (if any)
    final nextXpReq =
        100 + (snap.currentLevel - 1) * 25; // using existing logic
    final xpNeeded = nextXpReq - snap.xpInLevel;

    // We can infer next title or just use a generic one if we don't have the full list accessible here.
    // The existing titles are Newcomer → Mover → Wonder → Voyager → Guardian → Wizard.
    String nextTitle = 'Next Level';
    if (snap.currentLevel == 1) {
      nextTitle = 'Mover';
    } else if (snap.currentLevel == 2) {
      nextTitle = 'Wonder';
    } else if (snap.currentLevel == 3) {
      nextTitle = 'Voyager';
    } else if (snap.currentLevel == 4) {
      nextTitle = 'Guardian';
    } else if (snap.currentLevel == 5) {
      nextTitle = 'Wizard';
    } else if (snap.currentLevel >= 6) {
      nextTitle = 'Max Level';
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primarySage.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -30,
            child: Text(
              snap.currentLevel < 10
                  ? '0${snap.currentLevel}'
                  : '${snap.currentLevel}',
              style: TextStyle(
                fontSize: 160,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: cs.onSurface.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySage.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LEVEL ${snap.currentLevel}',
                              style: tt.labelSmall?.copyWith(
                                color: AppTheme.primarySage,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snap.currentTitle,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${snap.totalXp}',
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'TOTAL XP',
                          style: tt.labelSmall?.copyWith(
                            color: AppTheme.mutedForeground,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NEXT: ${nextTitle.toUpperCase()}',
                      style: tt.labelSmall?.copyWith(
                        color: AppTheme.mutedForeground,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$xpNeeded XP NEEDED',
                      style: tt.labelSmall?.copyWith(
                        color: AppTheme.primarySage,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      alignment: Alignment.centerLeft,
                      widthFactor: snap.levelProgress,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.primarySage,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Exercise Card ────────────────────────────────────────────────────────────

class _ExerciseCard extends StatefulWidget {
  final _Exercise exercise;
  final bool done;
  final bool forceExpanded;
  final VoidCallback onMarkDone;

  const _ExerciseCard({
    required this.exercise,
    required this.done,
    this.forceExpanded = false,
    required this.onMarkDone,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.forceExpanded;
  }

  @override
  void didUpdateWidget(_ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.forceExpanded != widget.forceExpanded) {
      _expanded = widget.forceExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.done ? cs.surface : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: (!widget.done && _expanded)
            ? Border.all(color: AppTheme.primarySage, width: 1.5)
            : Border.all(
                color: cs.onSurface.withValues(alpha: 0.1),
                width: 1.0,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          color: AppTheme.mutedForeground,
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
                                      ? AppTheme.mutedForeground
                                      : cs.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.exercise.duration}  ·  +$kXpStretch XP',
                              style: tt.bodySmall?.copyWith(
                                color: AppTheme.mutedForeground,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
                          : AppTheme.mutedForeground.withValues(alpha: 0.5),
                      size: 28,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(widget.exercise.description, style: tt.bodyMedium),
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
    );
  }
}

void _showExerciseInstructions(
  BuildContext context,
  _Exercise exercise, {
  required VoidCallback onMarkDone,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ExerciseGuidedFlowSheet(
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

class _ExerciseGuidedFlowSheet extends StatefulWidget {
  final _Exercise exercise;
  final VoidCallback onComplete;
  final VoidCallback onFinishEarly;

  const _ExerciseGuidedFlowSheet({
    required this.exercise,
    required this.onComplete,
    required this.onFinishEarly,
  });

  @override
  State<_ExerciseGuidedFlowSheet> createState() =>
      _ExerciseGuidedFlowSheetState();
}

class _ExerciseGuidedFlowSheetState extends State<_ExerciseGuidedFlowSheet> {
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
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                  color: AppTheme.primarySage,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: tt.labelSmall?.copyWith(color: AppTheme.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.borderCream,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primarySage,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Step Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _stepCompleted
                    ? AppTheme.primarySage.withValues(alpha: 0.5)
                    : AppTheme.borderCream,
                width: _stepCompleted ? 1.5 : 1.0,
              ),
            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _stepCompleted
                          ? AppTheme.primarySage.withValues(alpha: 0.15)
                          : AppTheme.accentLavender.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _stepCompleted
                              ? Icons.check_circle_rounded
                              : Icons.timer_rounded,
                          color: _stepCompleted
                              ? AppTheme.primarySage
                              : AppTheme.accentLavender,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _stepCompleted
                                  ? 'Step Timer Completed! ✓'
                                  : '${_secondsRemaining.toString().padLeft(2, '0')}s remaining',
                              style: tt.labelMedium?.copyWith(
                                color: _stepCompleted
                                    ? AppTheme.primarySage
                                    : AppTheme.accentLavender,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!_stepCompleted)
                              Text(
                                'Tap Next when ready',
                                style: tt.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _timerRunning
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                          ),
                          color: _stepCompleted
                              ? AppTheme.primarySage
                              : AppTheme.accentLavender,
                          onPressed: _toggleTimer,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
                    child: Text(
                      isLastStep ? 'Mark Complete (+30 XP)' : 'Next Step',
                    ),
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
    final tt = Theme.of(context).textTheme;
    final logged = latestLog != null;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppTheme.primarySage,
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
                  fontWeight: FontWeight.w900,
                  color: Colors.black54,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                logged ? 'Done for today!' : 'How is your spine feeling?',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
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
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      logged
                          ? Icons.check_rounded
                          : Icons.chevron_right_rounded,
                      color: AppTheme.primarySage,
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

// ─── Routine Progress Card ────────────────────────────────────────────────
class _RoutineProgressCard extends StatelessWidget {
  final int completed;
  final int total;

  const _RoutineProgressCard({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(total, (index) {
              final isActive = index < completed;
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppTheme.primarySage
                      : cs.surfaceContainerHighest,
                ),
              );
            }),
          ),
          const Spacer(),
          Text(
            '$completed / $total',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ROUTINE',
            style: tt.labelSmall?.copyWith(
              color: AppTheme.mutedForeground,
              letterSpacing: 1.1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── XP Banner ────────────────────────────────────────────────────────────────

class _XpBanner extends StatelessWidget {
  final String text;
  const _XpBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primarySage, AppTheme.accentLavender],
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primarySage.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: tt.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Day Streak',
                  style: tt.labelSmall?.copyWith(
                    color: AppTheme.mutedForeground,
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
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily Goal',
                  style: tt.labelSmall?.copyWith(
                    color: AppTheme.mutedForeground,
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
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            dayStr,
                            style: tt.titleMedium?.copyWith(
                              color: cs.surface,
                              fontWeight: FontWeight.w900,
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
                        color: AppTheme.mutedForeground,
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (nextAppointment != null)
                      Text(
                        '$titleStr • $timeStr',
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        titleStr,
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primarySage,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.mutedForeground,
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
