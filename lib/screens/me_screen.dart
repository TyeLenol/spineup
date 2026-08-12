import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/event.dart';
import '../models/milestone.dart';
import '../models/user_profile.dart';
import '../services/gamification_service.dart';
import '../services/portable_archive_service.dart';
import '../services/profile_store.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_display.dart';
import '../widgets/badge_icon.dart';
import '../widgets/portable_archive_dialogs.dart';
import 'auth_screen.dart';
import 'care_subject_manager.dart';
import 'profile_setup/profile_fields.dart';
import 'profile_setup/profile_setup_screen.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _gs = GamificationService();
  GamificationSnapshot _snap = GamificationSnapshot.empty;
  List<Event> _allEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final snap = await _gs.getSnapshot(SessionService.currentCareSubjectId);
    final events = await _gs.getAllEvents(SessionService.currentCareSubjectId);
    if (mounted) {
      setState(() {
        _snap = snap;
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
                  // App Bar replacement
                  Text('Me', style: tt.titleLarge),
                  const SizedBox(height: 24),
                  // Progression Title + Level
                  _IdentitySummary(snap: _snap),
                  const SizedBox(height: 16),
                  _ActiveProfileCard(onManageProfiles: _openSubjectManager),
                  const SizedBox(height: 28),

                  _SectionHeader(title: 'Profile Info'),
                  const SizedBox(height: 12),
                  _ProfileInfoSection(
                    userId: SessionService.currentCareSubjectId,
                    snap: _snap,
                    gamificationService: _gs,
                    onProfileUpdated: _loadAll,
                  ),
                  const SizedBox(height: 28),

                  _SectionHeader(title: 'Avatar & Identity'),
                  const SizedBox(height: 12),
                  _AvatarSettings(
                    userId: SessionService.currentCareSubjectId,
                    snap: _snap,
                    gamificationService: _gs,
                    onProfileUpdated: _loadAll,
                  ),
                  const SizedBox(height: 28),

                  _BadgesSection(snap: _snap),
                  const SizedBox(height: 24),

                  _AchievementsSection(snap: _snap, allEvents: _allEvents),
                  const SizedBox(height: 28),

                  _SectionHeader(title: 'Settings'),
                  const SizedBox(height: 12),
                  _SettingsSection(
                    userId: SessionService.currentUserId,
                    gamificationService: _gs,
                    onDataChanged: _loadAll,
                  ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AvatarDisplay(profile: snap.userProfile, size: 96),
        const SizedBox(height: 16),
        Text(
          'Level ${snap.currentLevel} — $title',
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primarySage,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${snap.totalXp} XP Total',
          style: tt.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
        ),
      ],
    );
  }
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

// ─── Profile Info Section ──────────────────────────────────────────────────────

class _ProfileInfoSection extends StatelessWidget {
  final String userId;
  final GamificationSnapshot snap;
  final GamificationService gamificationService;
  final VoidCallback onProfileUpdated;

  const _ProfileInfoSection({
    required this.userId,
    required this.snap,
    required this.gamificationService,
    required this.onProfileUpdated,
  });

  void _showEditSheet(BuildContext context) {
    final profile = snap.userProfile;
    final nameCtrl = TextEditingController(text: profile.name);
    String selectedDiagnosis = profile.diagnosis;
    String selectedBraceStatus = profile.braceStatus;
    String selectedAgeRange = profile.ageRange;

    final diagnoses = [
      'Thoracic Curve',
      'Lumbar Curve',
      'Double Major',
      'Kyphosis',
      'Other',
    ];
    if (!diagnoses.contains(selectedDiagnosis)) {
      diagnoses.add(selectedDiagnosis);
    }

    final braceStatuses = ['Yes', 'No', 'Sometimes'];
    if (!braceStatuses.contains(selectedBraceStatus)) {
      braceStatuses.add(selectedBraceStatus);
    }

    final ageRanges = ['Under 13', '13-17', '18-25', '26-40', '41+'];
    if (!ageRanges.contains(selectedAgeRange)) {
      ageRanges.add(selectedAgeRange);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Profile Info',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextInput(
                    controller: nameCtrl,
                    labelText: 'Name',
                    hintText: 'Your name',
                  ),
                  const SizedBox(height: 24),
                  ProfileField(
                    label: 'Diagnosis / Curve Type',
                    child: ProfileChipGroup<String>(
                      columns: 2,
                      selectedValue: selectedDiagnosis,
                      onChanged: (val) {
                        setSheetState(() => selectedDiagnosis = val);
                      },
                      options: diagnoses
                          .map((d) => ChipOption(value: d, label: d))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ProfileField(
                    label: 'Brace Status',
                    child: ProfileChipGroup<String>(
                      columns: 3,
                      selectedValue: selectedBraceStatus,
                      onChanged: (val) {
                        setSheetState(() => selectedBraceStatus = val);
                      },
                      options: braceStatuses
                          .map((b) => ChipOption(value: b, label: b))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ProfileField(
                    label: 'Age Range',
                    child: ProfileChipGroup<String>(
                      columns: 3,
                      selectedValue: selectedAgeRange,
                      onChanged: (val) {
                        setSheetState(() => selectedAgeRange = val);
                      },
                      options: ageRanges
                          .map((a) => ChipOption(value: a, label: a))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await gamificationService.updateProfile(
                          userId: userId,
                          name: nameCtrl.text.trim(),
                          diagnosis: selectedDiagnosis,
                          braceStatus: selectedBraceStatus,
                          ageRange: selectedAgeRange,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                        onProfileUpdated();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primarySage,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = snap.userProfile;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User Details',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showEditSheet(context),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileDetailRow(
              label: 'Name',
              value: profile.name,
              icon: Icons.person_outline,
            ),
            _ProfileDetailRow(
              label: 'Diagnosis',
              value: profile.diagnosis,
              icon: Icons.medical_services_outlined,
            ),
            _ProfileDetailRow(
              label: 'Brace Status',
              value: profile.braceStatus,
              icon: Icons.shield_outlined,
            ),
            _ProfileDetailRow(
              label: 'Age Range',
              value: profile.ageRange,
              icon: Icons.calendar_today_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileDetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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

// ─── Settings Section ──────────────────────────────────────────────────────────

class _SettingsSection extends StatefulWidget {
  final String userId;
  final GamificationService gamificationService;
  final VoidCallback? onDataChanged;

  const _SettingsSection({
    required this.userId,
    required this.gamificationService,
    this.onDataChanged,
  });

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  bool _notificationsEnabled = true;
  bool _archiveBusy = false;
  final _archiveService = PortableArchiveService();

  void _showAppearanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Appearance'),
          content: RadioGroup<ThemeMode>(
            groupValue: themeModeNotifier.value,
            onChanged: (val) {
              if (val != null) {
                themeModeNotifier.value = val;
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                RadioListTile<ThemeMode>(
                  title: Text('System Default'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Light'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Dark'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportArchive() async {
    if (_archiveBusy) return;
    final passphrase = await showArchivePassphraseDialog(
      context,
      confirm: true,
    );
    if (passphrase == null) return;

    setState(() => _archiveBusy = true);
    try {
      final bytes = await _archiveService.exportOwner(
        ownerUserId: SessionService.currentUserId,
        passphrase: passphrase,
      );
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save protected SpineUp export',
        fileName: 'spineup-export-$stamp.spineup',
        allowedExtensions: const ['spineup'],
        bytes: bytes,
      );
      if (!mounted || (savedPath == null && !kIsWeb)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Protected archive exported successfully.'),
        ),
      );
    } on PortableArchiveException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) setState(() => _archiveBusy = false);
    }
  }

  Future<void> _importArchive() async {
    if (_archiveBusy) return;
    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Choose a SpineUp archive',
      type: FileType.custom,
      allowedExtensions: const ['spineup'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final bytes = picked.files.single.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SpineUp could not read that archive.')),
        );
      }
      return;
    }
    if (!mounted) return;

    final passphrase = await showArchivePassphraseDialog(
      context,
      confirm: false,
    );
    if (passphrase == null) return;

    setState(() => _archiveBusy = true);
    try {
      final preview = await _archiveService.inspect(
        archiveBytes: bytes,
        passphrase: passphrase,
      );
      if (!mounted) return;
      final mode = await showArchiveImportPreviewDialog(context, preview);
      if (!mounted || mode == null) return;

      if (mode == ArchiveImportMode.replaceSelectedSubject) {
        final confirmed = await _confirmReplaceImport();
        if (!mounted || !confirmed) return;
      }

      final result = await _archiveService.importArchive(
        ownerUserId: SessionService.currentUserId,
        archiveBytes: bytes,
        passphrase: passphrase,
        mode: mode,
        replaceSubjectId: mode == ArchiveImportMode.replaceSelectedSubject
            ? SessionService.currentCareSubjectId
            : null,
      );
      widget.onDataChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.importedSubjectIds.length} profile(s), ${result.importedEventCount} events, and ${result.importedAppointmentCount} appointments.',
          ),
        ),
      );
    } on PortableArchiveException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $error')));
    } finally {
      if (mounted) setState(() => _archiveBusy = false);
    }
  }

  Future<bool> _confirmReplaceImport() async {
    final target = SessionService.displayName;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Replace this profile?'),
            content: Text(
              'This will delete the current records for "$target" and replace them with the one archived profile shown in the preview. This cannot be undone unless you have another export.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Replace profile'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Privacy & Data'),
          content: const Text(
            'SpineUp keeps health data local to this device by default. '
            'This prototype does not send analytics or enable cloud backup. Protected export/import is available from Me and requires a passphrase; database encryption and cloud backup are not claimed features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Account & Data?'),
          content: const Text(
            'This action is irreversible. It permanently removes all local health history, measurements, appointments, progress, and settings for every profile owned by this app session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final userId = SessionService.currentUserId;
                await widget.gamificationService.clearUserData(userId: userId);
                await ProfileStore.clearProfilesForOwner(userId: userId);
                SessionService.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  authRoute(AuthMode.login),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Everything'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeName = switch (themeModeNotifier.value) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System Default',
    };

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderCream),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            subtitle: Text(themeName),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showAppearanceDialog,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_none_rounded),
            title: const Text('Notifications'),
            subtitle: const Text('Daily stretch & logging reminders'),
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export protected archive'),
            subtitle: const Text('Move your local profiles to another device'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _archiveBusy ? null : _exportArchive,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Import protected archive'),
            subtitle: const Text('Review before adding or replacing profiles'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _archiveBusy ? null : _importArchive,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Privacy & Data'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showPrivacyDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.red,
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Wipe all local health & event data'),
            onTap: _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }
}
