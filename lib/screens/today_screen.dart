import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../models/appointment.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_display.dart';
import 'appointment_logger_modal.dart';

// ─── Hardcoded user ID (mock auth) ───────────────────────────────────────────
const String _kUserId = 'local_user_001';

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
        stepText: 'Start on all fours with hands under shoulders and knees directly beneath hips.',
        durationSeconds: 10,
        cueTags: ['Positioning', 'Neutral spine'],
      ),
      ExerciseStep(
        stepText: 'Inhale as you arch your back gently, dropping stomach toward floor and looking up (Cow).',
        durationSeconds: 15,
        cueTags: ['Deep inhale', 'Gentle arch'],
      ),
      ExerciseStep(
        stepText: 'Exhale as you draw belly button in, rounding your spine toward ceiling (Cat).',
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
        stepText: 'Lie on your side with elbow directly beneath shoulder and legs straight.',
        durationSeconds: 10,
        cueTags: ['Alignment'],
      ),
      ExerciseStep(
        stepText: 'Engage your core and lift hips off the floor until your body forms a straight line.',
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
        stepText: 'Rest one leg vertically against the wall while keeping the other flat on floor.',
        durationSeconds: 20,
        cueTags: ['Leg vertical', 'Hold 20s'],
      ),
      ExerciseStep(
        stepText: 'Flex your foot gently until a deep stretch is felt in the hamstring.',
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
        stepText: 'Sit upright in a firm chair or place a foam roller under mid-back.',
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
        stepText: 'Reach right arm forward and extend left leg straight back simultaneously.',
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
        stepText: 'Flatten lower back against floor by tightening core muscles.',
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
        stepText: 'Walk both hands 45 degrees to one side to target lateral spine curve.',
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
        stepText: 'Stand with back, head, and buttocks flat against a smooth wall.',
        durationSeconds: 10,
        cueTags: ['Posture reset'],
      ),
      ExerciseStep(
        stepText: 'Raise arms to 90 degrees (cactus arms), keeping elbows and wrists touching wall.',
        durationSeconds: 25,
        cueTags: ['Cactus arms', 'Wrists on wall'],
      ),
      ExerciseStep(
        stepText: 'Slowly slide arms overhead along wall without arching lower back.',
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

  // Daily log fields
  double _painLevel = 2;
  double _braceHours = 0;
  String _mood = '😊';
  final Set<String> _selectedLocations = {};
  String? _tightness;
  String? _fatigue;
  final _journalNotesController = TextEditingController();
  bool _loggingJournal = false;

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
    _journalNotesController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSnapshot() async {
    final snap = await _gs.getSnapshot(_kUserId);
    final todayEvents = await _gs.getTodayEvents(_kUserId);
    final appointments = await _gs.getAppointments(_kUserId);

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
  int get _stretchesTodayCount => _todayEvents.where((e) => e.type == EventType.stretchCompleted).length;

  Appointment? get _nextAppointment {
    final scheduled = _appointments.where((a) => a.isScheduled).toList();
    if (scheduled.isEmpty) return null;
    scheduled.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
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
      userId: _kUserId,
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

  Future<void> _submitJournal() async {
    setState(() => _loggingJournal = true);
    final result = await _gs.logEvent(
      eventId: const Uuid().v4(),
      userId: _kUserId,
      type: EventType.journalEntry,
      payload: {
        'pain_level': _painLevel.round(),
        'brace_hours': _braceHours.round(),
        'mood': _mood,
        'locations': _selectedLocations.toList(),
        'tightness': _tightness,
        'fatigue': _fatigue,
        'notes': _journalNotesController.text.trim(),
        'logged_at': DateTime.now().toIso8601String(),
      },
    );
    await _loadSnapshot();
    setState(() => _loggingJournal = false);
    final bonus = result.dailyBonusAwarded ? ' +5 daily bonus!' : '';
    _showBanner('+${result.xpAwarded} XP$bonus');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── App bar ───────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: cs.surface,
                surfaceTintColor: Colors.transparent,
                title: Text('Today', style: tt.titleLarge),
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
                    // ── Welcome back banner (presentational only) ─────────
                    _WelcomeBackCard(snap: _snap, loading: _loadingSnap),
                    const SizedBox(height: 16),

                    // ── Level & XP header ─────────────────────────────────
                    _XpHeader(snap: _snap, loading: _loadingSnap),
                    const SizedBox(height: 16),

                    // ── Daily XP Target card ──────────────────────────────
                    _DailyXpTargetCard(
                      todayXp: _todayXp,
                      targetXp: kDailyXpTarget,
                      loading: _loadingSnap,
                    ),
                    const SizedBox(height: 16),

                    // ── Stat Chips (Next Appointment & Stretches Today) ────
                    _DailyStatChipsCard(
                      nextAppointment: _nextAppointment,
                      stretchesTodayCount: _stretchesTodayCount,
                      onAppointmentTap: () => showAppointmentLogger(
                        context: context,
                        userId: _kUserId,
                        gamificationService: _gs,
                        onLogged: (result) async {
                          await _loadSnapshot();
                          final bonus = result.dailyBonusAwarded ? ' +5 daily bonus!' : '';
                          _showBanner('+${result.xpAwarded} XP$bonus');
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Exercise cards ────────────────────────────────────
                    Text('Stretch Library', style: tt.titleMedium),
                    const SizedBox(height: 12),
                    ..._exercises.map((ex) => _ExerciseCard(
                          exercise: ex,
                          done: _completedToday.contains(ex.id),
                          onMarkDone: () => _markExerciseDone(ex),
                        )),
                    const SizedBox(height: 24),

                    // ── Daily log ─────────────────────────────────────────
                    Text('Daily Check-In', style: tt.titleMedium),
                    const SizedBox(height: 12),
                    _DailyLogCard(
                      painLevel: _painLevel,
                      braceHours: _braceHours,
                      mood: _mood,
                      selectedLocations: _selectedLocations,
                      tightness: _tightness,
                      fatigue: _fatigue,
                      isFirstLogToday: _todayEvents.isEmpty,
                      notesController: _journalNotesController,
                      loading: _loggingJournal,
                      onPainChanged: (v) => setState(() => _painLevel = v),
                      onBraceChanged: (v) => setState(() => _braceHours = v),
                      onMoodChanged: (v) => setState(() => _mood = v),
                      onLocationToggled: (loc) {
                        setState(() {
                          if (_selectedLocations.contains(loc)) {
                            _selectedLocations.remove(loc);
                          } else {
                            _selectedLocations.add(loc);
                          }
                        });
                      },
                      onTightnessChanged: (v) => setState(() => _tightness = v),
                      onFatigueChanged: (v) => setState(() => _fatigue = v),
                      onSubmit: _submitJournal,
                    ),
                    const SizedBox(height: 16),

                    // ── Log appointment button ────────────────────────────
                    _AppointmentButton(
                      onTap: () => showAppointmentLogger(
                        context: context,
                        userId: _kUserId,
                        gamificationService: _gs,
                        onLogged: (result) async {
                          await _loadSnapshot();
                          final bonus =
                              result.dailyBonusAwarded ? ' +5 daily bonus!' : '';
                          _showBanner('+${result.xpAwarded} XP$bonus');
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Today's Timeline ──────────────────────────────────
                    _TodayTimelineSection(
                      todayEvents: _todayEvents,
                      loading: _loadingSnap,
                    ),
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

// ─── Welcome Back Card ────────────────────────────────────────────────────────

class _WelcomeBackCard extends StatelessWidget {
  final GamificationSnapshot snap;
  final bool loading;
  const _WelcomeBackCard({required this.snap, required this.loading});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primarySage.withValues(alpha: 0.15),
            AppTheme.accentLavender.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primarySage.withValues(alpha: 0.3)),
      ),
      child: loading
          ? const SizedBox(height: 36, child: Center(child: LinearProgressIndicator()))
          : Row(
              children: [
                AvatarDisplay(
                  profile: snap.userProfile,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back 👋', style: tt.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'You\'re on a ${snap.streakDays}-day streak · Level ${snap.currentLevel} — ${snap.currentTitle}',
                        style: tt.bodySmall?.copyWith(
                            color: AppTheme.mutedForeground),
                      ),
                    ],
                  ),
                ),
                if (snap.streakDays > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryCoral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text('${snap.streakDays}',
                            style: tt.labelLarge?.copyWith(
                              color: AppTheme.secondaryCoral,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─── XP Header ────────────────────────────────────────────────────────────────

class _XpHeader extends StatelessWidget {
  final GamificationSnapshot snap;
  final bool loading;
  const _XpHeader({required this.snap, required this.loading});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (loading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCream),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Level badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentLavender,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level ${snap.currentLevel} — ${snap.currentTitle}',
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${snap.totalXp} XP total',
                  style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground),
                ),
              ),
              // Streak
              if (snap.streakDays > 0)
                Text(
                  '🔥 ${snap.streakDays}-day streak',
                  style: tt.labelSmall?.copyWith(
                    color: AppTheme.secondaryCoral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // XP progress bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.borderCream,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                widthFactor: snap.levelProgress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primarySage, AppTheme.accentLavender],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${snap.xpInLevel} / ${100 + (snap.currentLevel - 1) * 25} XP to next level',
            style: tt.labelSmall?.copyWith(color: AppTheme.mutedForeground),
          ),

          // Milestones row
          if (snap.unlockedMilestones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: snap.unlockedMilestones
                  .take(4)
                  .map((m) => Tooltip(
                        message: m.label,
                        child: Text(m.emoji,
                            style: const TextStyle(fontSize: 20)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Exercise Card ────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final _Exercise exercise;
  final bool done;
  final VoidCallback onMarkDone;

  const _ExerciseCard({
    required this.exercise,
    required this.done,
    required this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: done
            ? AppTheme.primarySage.withValues(alpha: 0.08)
            : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? AppTheme.primarySage.withValues(alpha: 0.4)
              : AppTheme.borderCream,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: () => _showExerciseInstructions(context, exercise, onMarkDone: onMarkDone),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: done
                ? AppTheme.primarySage.withValues(alpha: 0.15)
                : AppTheme.borderCream.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            done ? Icons.check_rounded : exercise.icon,
            color: done ? AppTheme.primarySage : AppTheme.mutedForeground,
          ),
        ),
        title: Text(
          exercise.name,
          style: tt.titleSmall?.copyWith(
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? AppTheme.mutedForeground : null,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${exercise.duration} · +$kXpStretch XP',
              style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primarySage),
          ],
        ),
        trailing: done
            ? const Icon(Icons.check_circle_rounded,
                color: AppTheme.primarySage)
            : FilledButton.tonal(
                onPressed: onMarkDone,
                child: const Text('Done'),
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
  State<_ExerciseGuidedFlowSheet> createState() => _ExerciseGuidedFlowSheetState();
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
                label: const Text('Finish early', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress indicator & Step counter
          Row(
            children: [
              Text(
                'Step ${_currentStepIndex + 1} of ${steps.length}',
                style: tt.labelSmall?.copyWith(color: AppTheme.primarySage, fontWeight: FontWeight.bold),
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primarySage),
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
                color: _stepCompleted ? AppTheme.primarySage.withValues(alpha: 0.5) : AppTheme.borderCream,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLavender.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: tt.labelSmall?.copyWith(color: AppTheme.accentLavender, fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Timer display if set
                if (step.durationSeconds != null && step.durationSeconds! > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _stepCompleted
                          ? AppTheme.primarySage.withValues(alpha: 0.15)
                          : AppTheme.accentLavender.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _stepCompleted ? Icons.check_circle_rounded : Icons.timer_rounded,
                          color: _stepCompleted ? AppTheme.primarySage : AppTheme.accentLavender,
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
                                color: _stepCompleted ? AppTheme.primarySage : AppTheme.accentLavender,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!_stepCompleted)
                              Text(
                                'Tap Next when ready',
                                style: tt.bodySmall?.copyWith(fontSize: 10, color: AppTheme.mutedForeground),
                              ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(_timerRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                          color: _stepCompleted ? AppTheme.primarySage : AppTheme.accentLavender,
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
                    label: const Text('Previous'),
                  ),
                ),
              if (_currentStepIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isLastStep ? widget.onComplete : () => _goToStep(_currentStepIndex + 1),
                  icon: Icon(isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 18),
                  label: Text(isLastStep ? 'Mark Complete (+30 XP)' : 'Next Step'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _stepCompleted || isLastStep ? AppTheme.primarySage : cs.primary,
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

// ─── Daily Log Card ───────────────────────────────────────────────────────────

class _DailyLogCard extends StatelessWidget {
  final double painLevel;
  final double braceHours;
  final String mood;
  final Set<String> selectedLocations;
  final String? tightness;
  final String? fatigue;
  final bool isFirstLogToday;
  final TextEditingController notesController;
  final bool loading;
  final ValueChanged<double> onPainChanged;
  final ValueChanged<double> onBraceChanged;
  final ValueChanged<String> onMoodChanged;
  final ValueChanged<String> onLocationToggled;
  final ValueChanged<String?> onTightnessChanged;
  final ValueChanged<String?> onFatigueChanged;
  final VoidCallback onSubmit;

  const _DailyLogCard({
    required this.painLevel,
    required this.braceHours,
    required this.mood,
    required this.selectedLocations,
    required this.tightness,
    required this.fatigue,
    required this.isFirstLogToday,
    required this.notesController,
    required this.loading,
    required this.onPainChanged,
    required this.onBraceChanged,
    required this.onMoodChanged,
    required this.onLocationToggled,
    required this.onTightnessChanged,
    required this.onFatigueChanged,
    required this.onSubmit,
  });

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

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    const moods = ['😊', '😐', '😣'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCream),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Pain Level', style: tt.titleSmall),
              const Spacer(),
              Text(_painLabel(painLevel),
                  style: tt.labelSmall?.copyWith(
                      color: _painColor(painLevel),
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: painLevel,
            min: 0,
            max: 10,
            divisions: 10,
            label: painLevel.round().toString(),
            onChanged: onPainChanged,
          ),
          const SizedBox(height: 12),

          // Location Chip Group
          Text('Pain Location (optional)', style: tt.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['Neck', 'Upper Back', 'Lower Back', 'Left Hip', 'Right Hip', 'Other'].map((loc) {
              final selected = selectedLocations.contains(loc);
              return FilterChip(
                label: Text(loc, style: TextStyle(fontSize: 12, color: selected ? Colors.white : cs.onSurface)),
                selected: selected,
                selectedColor: AppTheme.primarySage,
                onSelected: (_) => onLocationToggled(loc),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Tightness & Fatigue 3-point scales
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tightness', style: tt.titleSmall),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: tightness,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      hint: const Text('Select'),
                      items: const [
                        DropdownMenuItem(value: 'Mild', child: Text('Mild')),
                        DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                        DropdownMenuItem(value: 'Severe', child: Text('Severe')),
                      ],
                      onChanged: onTightnessChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fatigue', style: tt.titleSmall),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: fatigue,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      hint: const Text('Select'),
                      items: const [
                        DropdownMenuItem(value: 'Mild', child: Text('Mild')),
                        DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                        DropdownMenuItem(value: 'Severe', child: Text('Severe')),
                      ],
                      onChanged: onFatigueChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Text('Brace Wear', style: tt.titleSmall),
              const Spacer(),
              Text('${braceHours.round()} hrs',
                  style: tt.labelSmall?.copyWith(
                      color: AppTheme.primarySage,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: braceHours,
            min: 0,
            max: 24,
            divisions: 24,
            label: '${braceHours.round()}h',
            onChanged: onBraceChanged,
          ),
          const SizedBox(height: 12),

          Text('Mood', style: tt.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: moods.map((m) {
              final selected = m == mood;
              return GestureDetector(
                onTap: () => onMoodChanged(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.accentLavender.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppTheme.accentLavender
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(m, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Optional Journal Notes
          TextField(
            controller: notesController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Journal Notes (optional)',
              hintText: 'e.g. "Stiff after long sitting today"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Itemized XP breakdown display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primarySage.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppTheme.primarySage, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isFirstLogToday
                        ? 'Journal +$kXpJournal, Daily First-Log Bonus +$kXpDailyBonus → Total +${kXpJournal + kXpDailyBonus} XP'
                        : 'Journal +$kXpJournal XP',
                    style: tt.labelSmall?.copyWith(
                      color: AppTheme.primarySage,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onSubmit,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(
                loading
                    ? 'Saving…'
                    : isFirstLogToday
                        ? 'Confirm Log  +${kXpJournal + kXpDailyBonus} XP'
                        : 'Confirm Log  +$kXpJournal XP',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Appointment button ───────────────────────────────────────────────────────

class _AppointmentButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AppointmentButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.medical_services_outlined),
      label: const Text('Manage Appointments'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

// ─── Daily XP Target Card ─────────────────────────────────────────────────────

class _DailyXpTargetCard extends StatelessWidget {
  final int todayXp;
  final int targetXp;
  final bool loading;

  const _DailyXpTargetCard({
    required this.todayXp,
    required this.targetXp,
    required this.loading,
  });

  String get encouragement {
    if (todayXp == 0) {
      return 'Start your day with a quick stretch or check-in!';
    } else if (todayXp < targetXp * 0.8) {
      return 'Great start! Keep going to hit today\'s goal.';
    } else if (todayXp < targetXp) {
      return 'Almost there — one more log to hit today\'s goal.';
    } else {
      return 'Goal smashed! Outstanding commitment today! 🎉';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = loading ? 0.0 : (todayXp / targetXp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCream),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppTheme.primarySage, size: 20),
              const SizedBox(width: 8),
              Text("Today's Goal", style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                '$todayXp / $targetXp XP',
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primarySage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppTheme.borderCream,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primarySage),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            encouragement,
            style: tt.bodySmall?.copyWith(
              color: AppTheme.mutedForeground,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Chips Card ──────────────────────────────────────────────────────────

class _DailyStatChipsCard extends StatelessWidget {
  final Appointment? nextAppointment;
  final int stretchesTodayCount;
  final VoidCallback onAppointmentTap;

  const _DailyStatChipsCard({
    required this.nextAppointment,
    required this.stretchesTodayCount,
    required this.onAppointmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    String aptTitle = 'No upcoming visits';
    String aptTimeStr = '+ Schedule';
    if (nextAppointment != null) {
      final dt = nextAppointment!.scheduledDateTime;
      aptTitle = nextAppointment!.title;
      aptTimeStr = '${dt.month}/${dt.day} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Row(
      children: [
        // Appointment Chip Card
        Expanded(
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: cs.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderCream),
            ),
            child: InkWell(
              onTap: onAppointmentTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLavender.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medical_services_outlined, size: 20, color: AppTheme.accentLavender),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aptTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            aptTimeStr,
                            style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Stretches Today Chip Card
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: cs.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderCream),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySage.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.self_improvement_rounded, size: 20, color: AppTheme.primarySage),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$stretchesTodayCount Stretches',
                      style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Completed today',
                      style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Today's Timeline Section ─────────────────────────────────────────────────

class _TodayTimelineSection extends StatelessWidget {
  final List<Event> todayEvents;
  final bool loading;

  const _TodayTimelineSection({
    required this.todayEvents,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Today's Timeline", style: tt.titleMedium),
            const Spacer(),
            Text('${todayEvents.length} events', style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground)),
          ],
        ),
        const SizedBox(height: 12),
        if (todayEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderCream),
            ),
            child: Center(
              child: Text(
                'No activity logged today yet.\nComplete a stretch or check-in above!',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground),
              ),
            ),
          )
        else
          ...todayEvents.map((e) => _TodayEventTile(event: e)),
      ],
    );
  }
}

class _TodayEventTile extends StatelessWidget {
  final Event event;
  const _TodayEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final (icon, label, color) = switch (event.type) {
      EventType.stretchCompleted => (
        Icons.self_improvement_rounded,
        'Stretch: ${event.payload['exercise_name'] ?? 'Session'}',
        AppTheme.primarySage,
      ),
      EventType.journalEntry => (
        Icons.edit_note_rounded,
        'Journal: pain ${event.payload['pain_level']}/5 · ${event.payload['mood']}',
        AppTheme.secondaryCoral,
      ),
      EventType.angleLogged => (
        Icons.architecture_rounded,
        'Cobb angle: ${(event.payload['degrees'] as num?)?.toStringAsFixed(1) ?? '?'}°',
        AppTheme.accentLavender,
      ),
      EventType.appointmentAttended => (
        Icons.medical_services_rounded,
        'Doctor appointment: ${event.payload['title'] ?? 'Visit'}',
        AppTheme.primarySage,
      ),
    };

    final timeStr = '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}';

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
                Text(label, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  timeStr,
                  style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primarySage.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${event.xpValue} XP',
              style: const TextStyle(
                color: AppTheme.primarySage,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
