import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/event.dart';
import '../models/milestone.dart';
import '../models/user_profile.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_display.dart';
import 'cobb_angle_logger_modal.dart';
import 'appointment_logger_modal.dart';

const String _kUserId = 'local_user_001';

class MyJourneyScreen extends StatefulWidget {
  const MyJourneyScreen({super.key});

  @override
  State<MyJourneyScreen> createState() => _MyJourneyScreenState();
}

class _MyJourneyScreenState extends State<MyJourneyScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _gs = GamificationService();
  GamificationSnapshot _snap = GamificationSnapshot.empty;
  List<({DateTime date, double degrees})> _cobbHistory = [];
  List<Event> _allEvents = [];
  bool _loading = true;

  // Chart Filters
  String _chartTimeRange = '30d'; // '7d', '30d', '90d', 'All'
  String _overlayOption = 'None'; // 'None', 'Pain Level', 'Stretches'

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final snap = await _gs.getSnapshot(_kUserId);
    final cobbs = await _gs.getCobbAngleHistory(_kUserId);
    final events = await _gs.getAllEvents(_kUserId);
    if (mounted) {
      setState(() {
        _snap = snap;
        _cobbHistory = cobbs;
        _allEvents = events;
        _loading = false;
      });
    }
  }

  void _handleLogged(LogEventResult result) async {
    await _loadAll();
    if (!mounted) return;
    final bonus = result.dailyBonusAwarded ? ' +5 daily bonus!' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+${result.xpAwarded} XP$bonus'),
        backgroundColor: AppTheme.primarySage,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<({DateTime date, double degrees})> get _filteredCobbHistory {
    if (_chartTimeRange == 'All') return _cobbHistory;
    final days = switch (_chartTimeRange) {
      '7d' => 7,
      '30d' => 30,
      '90d' => 90,
      _ => 30,
    };
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _cobbHistory.where((e) => e.date.isAfter(cutoff)).toList();
  }

  List<({DateTime date, double value})> get _overlayData {
    if (_overlayOption == 'None') return [];
    final days = switch (_chartTimeRange) {
      '7d' => 7,
      '30d' => 30,
      '90d' => 90,
      _ => 365,
    };
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final filtered = _allEvents.where((e) => e.timestamp.isAfter(cutoff)).toList();

    if (_overlayOption == 'Pain Level') {
      final journals = filtered.where((e) => e.type == EventType.journalEntry).toList();
      return journals
          .map((e) => (
                date: e.timestamp,
                value: ((e.payload['pain_level'] as num?) ?? 0).toDouble(),
              ))
          .toList();
    } else if (_overlayOption == 'Stretches') {
      final stretches = filtered.where((e) => e.type == EventType.stretchCompleted).toList();
      final Map<String, int> countsByDay = {};
      for (final s in stretches) {
        final key = '${s.timestamp.year}-${s.timestamp.month.toString().padLeft(2, '0')}-${s.timestamp.day.toString().padLeft(2, '0')}';
        countsByDay[key] = (countsByDay[key] ?? 0) + 1;
      }
      return countsByDay.entries.map((entry) {
        return (
          date: DateTime.parse(entry.key),
          value: entry.value.toDouble(),
        );
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
      backgroundColor: cs.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: cs.surface,
                    surfaceTintColor: Colors.transparent,
                    title: Text('My Journey', style: tt.titleLarge),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Privacy notice ─────────────────────────────────
                        _PrivacyBanner(),
                        const SizedBox(height: 20),

                        // ── Cobb angle graph ───────────────────────────────
                        _SectionHeader(title: 'Cobb Angle Progression'),
                        const SizedBox(height: 12),

                        // Time Range & Overlay Filter Bar
                        Row(
                          children: [
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: '7d', label: Text('7d', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: '30d', label: Text('30d', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: '90d', label: Text('90d', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: 'All', label: Text('All', style: TextStyle(fontSize: 11))),
                              ],
                              selected: {_chartTimeRange},
                              onSelectionChanged: (set) {
                                setState(() => _chartTimeRange = set.first);
                              },
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const Spacer(),
                            DropdownButton<String>(
                              value: _overlayOption,
                              isDense: true,
                              underline: const SizedBox.shrink(),
                              icon: const Icon(Icons.layers_outlined, size: 18, color: AppTheme.primarySage),
                              style: tt.labelSmall?.copyWith(color: AppTheme.primarySage, fontWeight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 'None', child: Text('No Overlay')),
                                DropdownMenuItem(value: 'Pain Level', child: Text('+ Pain Level')),
                                DropdownMenuItem(value: 'Stretches', child: Text('+ Stretches')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _overlayOption = v);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _CobbChart(
                          history: _filteredCobbHistory,
                          overlayData: _overlayData,
                          overlayOption: _overlayOption,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => showCobbAngleLogger(
                                  context: context,
                                  userId: _kUserId,
                                  gamificationService: _gs,
                                  onLogged: _handleLogged,
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Log Cobb Angle'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => showAppointmentLogger(
                                context: context,
                                userId: _kUserId,
                                gamificationService: _gs,
                                onLogged: _handleLogged,
                              ),
                              icon: const Icon(Icons.medical_services_outlined),
                              label: const Text('Appointments'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Badges & Achievements Split ────────────────────
                        _BadgesSection(snap: _snap),
                        const SizedBox(height: 24),
                        _AchievementsSection(snap: _snap, allEvents: _allEvents),
                        const SizedBox(height: 28),

                        // ── Avatar & Profile Settings ─────────────────────
                        _SectionHeader(title: 'Avatar & Profile'),
                        const SizedBox(height: 12),
                        _AvatarSettings(
                          userId: _kUserId,
                          snap: _snap,
                          gamificationService: _gs,
                          onProfileUpdated: _loadAll,
                        ),
                        const SizedBox(height: 28),

                        // ── Activity timeline ──────────────────────────────
                        _SectionHeader(title: 'Activity Log'),
                        const SizedBox(height: 12),
                        if (_allEvents.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'No activity yet.\nStart logging to see your history!',
                                textAlign: TextAlign.center,
                                style: tt.bodyMedium?.copyWith(
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._allEvents
                              .take(30)
                              .map((e) => _EventTile(event: e)),
                      ]),
                    ),
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

  const _CobbChart({
    required this.history,
    this.overlayData = const [],
    this.overlayOption = 'None',
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final hasData = history.isNotEmpty;

    // Seed data for empty state display
    final displayData = hasData
        ? history
        : [
            (
              date: DateTime.now().subtract(const Duration(days: 90)),
              degrees: 32.0,
            ),
            (
              date: DateTime.now().subtract(const Duration(days: 60)),
              degrees: 30.5,
            ),
            (
              date: DateTime.now().subtract(const Duration(days: 30)),
              degrees: 29.0,
            ),
            (date: DateTime.now(), degrees: 28.0),
          ];

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCream),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              size: Size.infinite,
              painter: _CobbChartPainter(
                data: displayData,
                overlayData: overlayData,
                overlayOption: overlayOption,
              ),
            ),
          ),
          if (!hasData)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📐', style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(
                    'No angle logs yet — example data shown',
                    style: tt.bodySmall?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          if (hasData)
            Positioned(
              right: 12,
              top: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${displayData.last.degrees.toStringAsFixed(1)}° Cobb',
                    style: tt.labelSmall?.copyWith(
                      color: AppTheme.accentLavender,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (overlayData.isNotEmpty)
                    Text(
                      '${overlayOption == 'Pain Level' ? 'Pain' : 'Stretches'}: ${overlayData.last.value.toStringAsFixed(0)}',
                      style: tt.labelSmall?.copyWith(
                        color: overlayOption == 'Pain Level' ? AppTheme.secondaryCoral : AppTheme.primarySage,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CobbChartPainter extends CustomPainter {
  final List<({DateTime date, double degrees})> data;
  final List<({DateTime date, double value})> overlayData;
  final String overlayOption;

  const _CobbChartPainter({
    required this.data,
    this.overlayData = const [],
    this.overlayOption = 'None',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minDeg = data.map((e) => e.degrees).reduce(math.min) - 5;
    final maxDeg = data.map((e) => e.degrees).reduce(math.max) + 5;
    final range = maxDeg - minDeg;

    final padL = 16.0, padR = 16.0, padT = 24.0, padB = 24.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    Offset toPoint(int i) {
      final x = padL + (i / (data.length - 1)) * w;
      final y = padT + (1 - (data[i].degrees - minDeg) / range) * h;
      return Offset(x, y);
    }

    // Fill under curve
    final fillPath = Path()..moveTo(padL, padT + h);
    for (int i = 0; i < data.length; i++) {
      fillPath.lineTo(toPoint(i).dx, toPoint(i).dy);
    }
    fillPath.lineTo(padL + w, padT + h);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.accentLavender.withValues(alpha: 0.3),
            AppTheme.accentLavender.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, padT, size.width, h)),
    );

    // Primary Cobb Line
    final linePaint = Paint()
      ..color = AppTheme.accentLavender
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(toPoint(0).dx, toPoint(0).dy);
    for (int i = 1; i < data.length; i++) {
      path.lineTo(toPoint(i).dx, toPoint(i).dy);
    }
    canvas.drawPath(path, linePaint);

    // Primary Dots
    for (int i = 0; i < data.length; i++) {
      canvas.drawCircle(
        toPoint(i),
        4,
        Paint()..color = AppTheme.accentLavender,
      );
      canvas.drawCircle(toPoint(i), 2, Paint()..color = Colors.white);
    }

    // Secondary Overlay Line
    if (overlayData.length >= 2) {
      final overlayColor = overlayOption == 'Pain Level' ? AppTheme.secondaryCoral : AppTheme.primarySage;
      final maxVal = overlayData.map((e) => e.value).reduce(math.max);
      final valRange = maxVal > 0 ? maxVal : 10.0;

      Offset toOverlayPoint(int i) {
        final x = padL + (i / (overlayData.length - 1)) * w;
        final y = padT + (1 - (overlayData[i].value / valRange)) * h;
        return Offset(x, y);
      }

      final overlayPaint = Paint()
        ..color = overlayColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final overlayPath = Path()..moveTo(toOverlayPoint(0).dx, toOverlayPoint(0).dy);
      for (int i = 1; i < overlayData.length; i++) {
        overlayPath.lineTo(toOverlayPoint(i).dx, toOverlayPoint(i).dy);
      }
      canvas.drawPath(overlayPath, overlayPaint);

      for (int i = 0; i < overlayData.length; i++) {
        canvas.drawCircle(toOverlayPoint(i), 3, Paint()..color = overlayColor);
      }
    }
  }

  @override
  bool shouldRepaint(_CobbChartPainter old) =>
      old.data != data || old.overlayData != overlayData || old.overlayOption != overlayOption;
}

// ─── Badges Section (Undated Collectibles) ────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  final GamificationSnapshot snap;
  const _BadgesSection({required this.snap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final unlockedIds = snap.unlockedMilestones.map((m) => m.id).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Badges'),
        Text(
          'Collectible milestone badges',
          style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: allMilestones.map((m) {
              final isUnlocked = unlockedIds.contains(m.id);
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppTheme.primarySage.withValues(alpha: 0.15)
                      : cs.surfaceContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUnlocked ? AppTheme.primarySage : AppTheme.borderCream,
                    width: isUnlocked ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      m.emoji,
                      style: TextStyle(
                        fontSize: 24,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: tt.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                        color: isUnlocked ? AppTheme.primarySage : AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Achievements Section (Chronological Dated History) ────────────────────────

class _AchievementsSection extends StatelessWidget {
  final GamificationSnapshot snap;
  final List<Event> allEvents;

  const _AchievementsSection({
    required this.snap,
    required this.allEvents,
  });

  DateTime? _findEarnedDate(Milestone m) {
    if (m.requiredEventType != null) {
      final matching = allEvents.where((e) => e.type == m.requiredEventType).toList();
      if (matching.isNotEmpty) {
        matching.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final reqCount = m.requiredEventCount ?? 1;
        if (matching.length >= reqCount) {
          return matching[reqCount - 1].timestamp;
        }
      }
    } else if (m.requiredXp != null) {
      int cumulative = 0;
      final sorted = List<Event>.from(allEvents)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (final e in sorted) {
        cumulative += e.xpValue;
        if (cumulative >= m.requiredXp!) {
          return e.timestamp;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final unlocked = snap.unlockedMilestones;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Achievements'),
        Text(
          'Chronological milestone history',
          style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground),
        ),
        const SizedBox(height: 12),
        if (unlocked.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderCream),
            ),
            child: Text(
              'No achievements unlocked yet. Keep logging to earn milestones!',
              style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...unlocked.map((m) {
            final earnedDate = _findEarnedDate(m);
            final dateStr = earnedDate != null
                ? 'Earned ${earnedDate.year}-${earnedDate.month.toString().padLeft(2, '0')}-${earnedDate.day.toString().padLeft(2, '0')}'
                : 'Unlocked';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderCream),
              ),
              child: Row(
                children: [
                  Text(m.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.label, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          dateStr,
                          style: tt.bodySmall?.copyWith(color: AppTheme.primarySage, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded, color: AppTheme.primarySage, size: 20),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ─── Avatar & Profile Settings ────────────────────────────────────────────────

class _AvatarSettings extends StatefulWidget {
  final String userId;
  final GamificationSnapshot snap;
  final GamificationService gamificationService;
  final VoidCallback onProfileUpdated;

  const _AvatarSettings({
    required this.userId,
    required this.snap,
    required this.gamificationService,
    required this.onProfileUpdated,
  });

  @override
  State<_AvatarSettings> createState() => _AvatarSettingsState();
}

class _AvatarSettingsState extends State<_AvatarSettings> {
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final sizeBytes = await file.length();
      if (sizeBytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is too large (cap is ~5MB).')),
        );
        return;
      }

      await widget.gamificationService.updateProfile(
        widget.userId,
        widget.snap.userProfile.presetId,
        pickedFile.path,
      );
      widget.onProfileUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final currentPresetId = widget.snap.userProfile.presetId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AvatarDisplay(
              profile: widget.snap.userProfile,
              size: 64,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Upload Custom Photo'),
                  ),
                  if (widget.snap.userProfile.customPhotoPath != null)
                    TextButton(
                      onPressed: () async {
                        await widget.gamificationService.updateProfile(
                          widget.userId,
                          currentPresetId,
                          null,
                        );
                        widget.onProfileUpdated();
                      },
                      child: const Text('Remove Photo'),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Choose Preset', style: tt.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: presetAvatars.map((preset) {
              final isSelected = currentPresetId == preset.id;
              return GestureDetector(
                onTap: () async {
                  await widget.gamificationService.updateProfile(
                    widget.userId,
                    preset.id,
                    widget.snap.userProfile.customPhotoPath,
                  );
                  widget.onProfileUpdated();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 12),
                  width: 80,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentLavender.withValues(alpha: 0.15)
                        : cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentLavender
                          : AppTheme.borderCream,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        preset.assetPath,
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preset.name,
                        style: tt.labelSmall?.copyWith(
                          fontSize: 10,
                          color: isSelected
                              ? AppTheme.accentLavender
                              : AppTheme.mutedForeground,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Event Tile ───────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final Event event;
  const _EventTile({required this.event});

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
        'Doctor appointment',
        AppTheme.primarySage,
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
