import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/event.dart';
import '../models/milestone.dart';
import '../models/profile_data.dart';
import '../models/user_profile.dart';
import '../services/gamification_service.dart';
import '../services/profile_store.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_display.dart';
import '../widgets/badge_icon.dart';
import 'care_subject_manager.dart';
import 'profile_setup/profile_setup_screen.dart';
import 'settings_screen.dart';

class MeScreen extends StatefulWidget {
  final VoidCallback? onReplayQuickTour;

  const MeScreen({super.key, this.onReplayQuickTour});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _gs = GamificationService();
  GamificationSnapshot _snap = GamificationSnapshot.empty;
  ProfileData _profileData = const ProfileData();
  List<Event> _allEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final careSubjectId = SessionService.currentCareSubjectId;
    final snap = await _gs.getSnapshot(careSubjectId);
    final profileData = await ProfileStore.loadProfile(
      userId: SessionService.currentUserId,
      careSubjectId: careSubjectId,
    );
    final events = await _gs.getAllEvents(careSubjectId);
    if (mounted) {
      setState(() {
        _snap = snap;
        _profileData = profileData;
        _allEvents = events;
        _loading = false;
      });
    }
  }

  Future<void> _openAddWardSetup() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ProfileSetupScreen(createNewWard: true),
      ),
    );
    await _loadAll();
  }

  Future<void> _openProfileEdit() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ProfileSetupScreen(editExisting: true),
      ),
    );
    await _loadAll();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          onReplayQuickTour: widget.onReplayQuickTour,
          onDataChanged: () => _loadAll(),
        ),
      ),
    );
    await _loadAll();
  }

  Future<void> _openSubjectManager() async {
    await showModalBottomSheet<CareSubjectManagerResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CareSubjectManager(
        ownerUserId: SessionService.currentUserId,
        onAddWard: _openAddWardSetup,
      ),
    );
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 120),
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Me', style: tt.titleLarge)),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings_outlined),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Progression Title + Level
                  _IdentitySummary(snap: _snap),
                  const SizedBox(height: 16),
                  _ActiveProfileCard(onManageProfiles: _openSubjectManager),
                  const SizedBox(height: 28),

                  _SectionHeader(title: 'Care profile'),
                  const SizedBox(height: 12),
                  _CareProfileSection(
                    data: _profileData,
                    isWard: SessionService.activeCareSubject?.isWard == true,
                    onEdit: _openProfileEdit,
                  ),
                  const SizedBox(height: 28),

                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        leading: AvatarDisplay(
                          profile: _snap.userProfile,
                          size: 42,
                        ),
                        title: const Text(
                          'Personalize your avatar',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('Choose an icon or local photo'),
                        children: [
                          _AvatarSettings(
                            userId: SessionService.currentCareSubjectId,
                            snap: _snap,
                            gamificationService: _gs,
                            onProfileUpdated: _loadAll,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _ProgressSection(snap: _snap, allEvents: _allEvents),
                  const SizedBox(height: 28),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ActiveProfileCard extends StatelessWidget {
  final VoidCallback onManageProfiles;

  const _ActiveProfileCard({required this.onManageProfiles});

  @override
  Widget build(BuildContext context) {
    final subject = SessionService.activeCareSubject;
    final name = subject?.displayName ?? SessionService.displayName;
    final description = subject?.isWard == true
        ? 'Someone I care for'
        : 'My private profile';

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: Icon(
            subject?.isWard == true
                ? Icons.people_outline_rounded
                : Icons.person_outline_rounded,
          ),
        ),
        title: Text(
          'Active profile: $name',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.swap_horiz_rounded),
        onTap: onManageProfiles,
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

class _IdentitySummary extends StatelessWidget {
  final GamificationSnapshot snap;

  const _IdentitySummary({required this.snap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final title = snap.currentTitle;

    return Row(
      children: [
        AvatarDisplay(profile: snap.userProfile, size: 78),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level ${snap.currentLevel} · $title',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primarySage,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${snap.totalXp} XP total',
                style: tt.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
              ),
              const SizedBox(height: 8),
              Text(
                'Progress stays in the background while your profile leads.',
                style: tt.bodySmall?.copyWith(
                  color: AppTheme.mutedForeground,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Badges Section (Undated Collectibles) ────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final GamificationSnapshot snap;
  final List<Event> allEvents;

  const _ProgressSection({required this.snap, required this.allEvents});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unlockedCount = snap.unlockedMilestones.length;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            backgroundColor: AppTheme.accentLavender.withValues(alpha: 0.16),
            foregroundColor: AppTheme.accentLavender,
            child: const Icon(Icons.emoji_events_outlined),
          ),
          title: const Text(
            'Progress & milestones',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '$unlockedCount badges unlocked · ${snap.totalXp} XP total',
          ),
          children: [
            _BadgesSection(snap: snap),
            const SizedBox(height: 20),
            _AchievementsSection(snap: snap, allEvents: allEvents),
          ],
        ),
      ),
    );
  }
}

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
          height: 100,
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
                    color: isUnlocked
                        ? AppTheme.primarySage
                        : AppTheme.borderCream,
                    width: isUnlocked ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BadgeIcon(milestone: m, size: 32, isUnlocked: isUnlocked),
                    const SizedBox(height: 6),
                    Text(
                      m.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: tt.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: isUnlocked
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isUnlocked
                            ? AppTheme.primarySage
                            : AppTheme.mutedForeground,
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

  const _AchievementsSection({required this.snap, required this.allEvents});

  DateTime? _findEarnedDate(Milestone m) {
    if (m.requiredEventType != null) {
      final matching = allEvents
          .where((e) => e.type == m.requiredEventType)
          .toList();
      if (matching.isNotEmpty) {
        matching.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final reqCount = m.requiredEventCount ?? 1;
        if (matching.length >= reqCount) {
          return matching[reqCount - 1].timestamp;
        }
      }
    } else if (m.requiredXp != null) {
      int cumulative = 0;
      final sorted = List<Event>.from(allEvents)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (final e in sorted) {
        cumulative += e.xpValue;
        if (cumulative >= m.requiredXp!) {
          return e.timestamp;
        }
      }
    }
    return null;
  }

  String _formatEarnedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Earned Today';
    } else if (diff.inDays == 1) {
      return 'Earned Yesterday';
    } else if (diff.inDays < 7) {
      return 'Earned ${diff.inDays}d ago';
    } else {
      return 'Earned ${DateFormat.MMMd().format(date)}';
    }
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
                ? _formatEarnedDate(earnedDate)
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
                  BadgeIcon(milestone: m, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.label,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: tt.bodySmall?.copyWith(
                            color: AppTheme.primarySage,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    color: AppTheme.primarySage,
                    size: 20,
                  ),
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
        userId: widget.userId,
        presetId: widget.snap.userProfile.presetId,
        customPhotoPath: pickedFile.path,
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
            AvatarDisplay(profile: widget.snap.userProfile, size: 64),
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
                          userId: widget.userId,
                          presetId: currentPresetId,
                          customPhotoPath: null,
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
            padding: const EdgeInsets.only(left: 2, right: 16),
            children: presetAvatars.map((preset) {
              final isSelected = currentPresetId == preset.id;
              return GestureDetector(
                onTap: () async {
                  await widget.gamificationService.updateProfile(
                    userId: widget.userId,
                    presetId: preset.id,
                    customPhotoPath: widget.snap.userProfile.customPhotoPath,
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
                      AvatarDisplay.buildPresetGraphic(preset, size: 40),
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

// ─── Structured Care Profile ────────────────────────────────────────────────────

class _CareProfileSection extends StatelessWidget {
  final ProfileData data;
  final bool isWard;
  final VoidCallback onEdit;

  const _CareProfileSection({
    required this.data,
    required this.isWard,
    required this.onEdit,
  });

  String _name() {
    final name = data.basics.displayName.trim();
    if (name.isNotEmpty) return name;
    return isWard ? 'Care profile' : 'Your profile';
  }

  String _curveSummary() {
    final type = switch (data.curve.curveType) {
      CurveType.thoracic => 'Thoracic curve',
      CurveType.lumbar => 'Lumbar curve',
      CurveType.thoracolumbar => 'Thoracolumbar curve',
      CurveType.doubleS => 'Double major curve',
      CurveType.unsure || null => 'Not added',
    };
    final angle = data.curve.cobbPrimary;
    if (angle == null) return type;
    return '$type · ${angle.toStringAsFixed(0)}° recorded';
  }

  String _stageSummary() {
    return switch (data.story.treatmentStage) {
      TreatmentStage.observation => 'Observation',
      TreatmentStage.bracing => 'Bracing',
      TreatmentStage.preOp => 'Preparing for surgery',
      TreatmentStage.postOp => 'After surgery',
      TreatmentStage.adult => 'Adult care',
      TreatmentStage.unsure || null => 'Not added',
    };
  }

  String _braceSummary() {
    return switch (data.brace.wears) {
      true => 'Yes',
      false => 'No',
      null => 'Not added',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.borderCream),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name(),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isWard ? 'Someone I care for' : 'My private profile',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _CareProfileDetailRow(
              label: 'Curve details',
              value: _curveSummary(),
              icon: Icons.straighten_rounded,
            ),
            _CareProfileDetailRow(
              label: 'Care stage',
              value: _stageSummary(),
              icon: Icons.route_outlined,
            ),
            _CareProfileDetailRow(
              label: 'Brace',
              value: _braceSummary(),
              icon: Icons.shield_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _CareProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CareProfileDetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
