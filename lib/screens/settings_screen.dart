import 'package:file_picker/file_picker.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/gamification_service.dart';
import '../services/portable_archive_service.dart';
import '../services/profile_store.dart';
import '../services/reminder_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/portable_archive_dialogs.dart';
import '../widgets/quick_tour.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onReplayQuickTour;
  final VoidCallback? onDataChanged;
  final QuickTourTargetRegistry? tutorialRegistry;

  const SettingsScreen({
    super.key,
    this.onReplayQuickTour,
    this.onDataChanged,
    this.tutorialRegistry,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ReminderSettings _reminderSettings = ReminderSettings.defaults;
  bool _reminderLoading = true;
  bool _reminderBusy = false;
  bool _archiveBusy = false;
  final _archiveService = PortableArchiveService();

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
    _scheduleTutorial();
  }

  void _scheduleTutorial() {
    if (tutorialRegistry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showPageQuickTourIfNeeded(
          context,
          page: QuickTourPage.settings,
          registry: tutorialRegistry!,
        ),
      );
    });
  }

  QuickTourTargetRegistry? get tutorialRegistry => widget.tutorialRegistry;

  Future<void> _loadReminderSettings() async {
    try {
      final settings = await ReminderService.load(
        ownerUserId: SessionService.currentUserId,
      );
      if (!mounted) return;
      setState(() {
        _reminderSettings = settings;
        _reminderLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _reminderLoading = false);
    }
  }

  String get _themeName {
    return switch (themeModeNotifier.value) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System default',
    };
  }

  String _formatReminderTime() {
    final time = TimeOfDay(
      hour: _reminderSettings.hour,
      minute: _reminderSettings.minute,
    );
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  Future<TimeOfDay?> _pickReminderTime({required TimeOfDay initialTime}) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Choose a daily reminder time',
      cancelText: 'Not now',
      confirmText: 'Save time',
    );
  }

  Future<void> _toggleReminder(bool enabled) async {
    if (_reminderBusy) return;
    if (enabled) {
      await _enableReminder();
    } else {
      await _disableReminder();
    }
  }

  Future<void> _enableReminder() async {
    final pickedTime = await _pickReminderTime(
      initialTime: TimeOfDay(
        hour: _reminderSettings.hour,
        minute: _reminderSettings.minute,
      ),
    );
    if (pickedTime == null || !mounted) return;

    setState(() => _reminderBusy = true);
    try {
      final enabled = await ReminderService.enable(
        ownerUserId: SessionService.currentUserId,
        hour: pickedTime.hour,
        minute: pickedTime.minute,
      );
      if (!mounted) return;
      if (!enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reminder stays off until Android notifications are allowed.',
            ),
          ),
        );
        return;
      }
      setState(() {
        _reminderSettings = ReminderSettings(
          enabled: true,
          hour: pickedTime.hour,
          minute: pickedTime.minute,
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SpineUp could not set that reminder.')),
      );
    } finally {
      if (mounted) setState(() => _reminderBusy = false);
    }
  }

  Future<void> _changeReminderTime() async {
    if (_reminderBusy || !_reminderSettings.enabled) return;
    final pickedTime = await _pickReminderTime(
      initialTime: TimeOfDay(
        hour: _reminderSettings.hour,
        minute: _reminderSettings.minute,
      ),
    );
    if (pickedTime == null || !mounted) return;

    setState(() => _reminderBusy = true);
    try {
      await ReminderService.updateTime(
        ownerUserId: SessionService.currentUserId,
        hour: pickedTime.hour,
        minute: pickedTime.minute,
      );
      if (!mounted) return;
      setState(() {
        _reminderSettings = _reminderSettings.copyWith(
          hour: pickedTime.hour,
          minute: pickedTime.minute,
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SpineUp could not update that reminder.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _reminderBusy = false);
    }
  }

  Future<void> _disableReminder() async {
    setState(() => _reminderBusy = true);
    try {
      await ReminderService.disable(ownerUserId: SessionService.currentUserId);
      if (!mounted) return;
      setState(() {
        _reminderSettings = _reminderSettings.copyWith(enabled: false);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SpineUp could not turn that reminder off.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _reminderBusy = false);
    }
  }

  void _showAppearanceSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how SpineUp looks on this device.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                RadioGroup<ThemeMode>(
                  groupValue: themeModeNotifier.value,
                  onChanged: (value) {
                    if (value == null) return;
                    themeModeNotifier.value = value;
                    Navigator.of(sheetContext).pop();
                    if (mounted) setState(() {});
                  },
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text('System default'),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _replayQuickTour() async {
    await QuickTourService.resetAll();
    if (!mounted) return;
    if (tutorialRegistry != null) {
      await showPageQuickTourIfNeeded(
        context,
        page: QuickTourPage.settings,
        registry: tutorialRegistry!,
        force: true,
      );
    } else {
      widget.onReplayQuickTour?.call();
    }
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('About SpineUp'),
          content: const Text(
            'SpineUp is a local-first school project for scoliosis self-management support. It helps people make space for routines, notes, measurements, and care questions. It does not diagnose, replace a clinician, or send records to the cloud in this build.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
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
    if (passphrase == null || !mounted) return;

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
                child: const Text('Replace profile'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('How privacy works'),
          content: const Text(
            'SpineUp keeps health data local to this device by default. This school-project build does not send analytics or enable cloud backup. Protected export and import require a passphrase. Database encryption, cloud backup, and diagnosis are not claimed features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteLocalData() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final error = Theme.of(dialogContext).colorScheme.error;
        return AlertDialog(
          title: const Text('Delete all local data?'),
          content: const Text(
            'This permanently removes every locally stored care profile, health record, appointment, routine, progress item, reminder, and setting for this SpineUp session. There is no undo unless you have a protected export.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final userId = SessionService.currentUserId;
                await ReminderService.clear(ownerUserId: userId);
                await GamificationService().clearUserData(userId: userId);
                await ProfileStore.clearProfilesForOwner(userId: userId);
                SessionService.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  localFirstWelcomeRoute(),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(foregroundColor: error),
              child: const Text('Delete local data'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            'Make SpineUp feel right for you.',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Small controls for this device, your privacy, and your way of returning to care.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          const _SettingsGroupLabel(label: 'Preferences'),
          const SizedBox(height: 9),
          _SettingsCard(
            children: [
              quickTourTarget(
                registry: tutorialRegistry,
                page: QuickTourPage.settings,
                id: 'appearance',
                child: _SettingsRow(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: _themeName,
                  onTap: _showAppearanceSheet,
                ),
              ),
              if (ReminderService.isSupported) ...[
                const _RowDivider(),
                quickTourTarget(
                  registry: tutorialRegistry,
                  page: QuickTourPage.settings,
                  id: 'reminder',
                  child: _SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Daily reminder',
                    subtitle: _reminderLoading
                        ? 'Loading…'
                        : _reminderSettings.enabled
                        ? 'Every day at ${_formatReminderTime()}'
                        : 'Off',
                    trailing: _reminderLoading || _reminderBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch.adaptive(
                            value: _reminderSettings.enabled,
                            onChanged: _toggleReminder,
                          ),
                    onTap: _reminderSettings.enabled
                        ? _changeReminderTime
                        : () => _toggleReminder(true),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          const _SettingsGroupLabel(label: 'Help & guidance'),
          const SizedBox(height: 9),
          _SettingsCard(
            children: [
              if (tutorialRegistry != null || widget.onReplayQuickTour != null)
                _SettingsRow(
                  icon: Icons.explore_outlined,
                  title: 'Replay page guides',
                  subtitle: 'See each guide again as you visit a page',
                  onTap: _replayQuickTour,
                ),
              if (tutorialRegistry != null || widget.onReplayQuickTour != null)
                const _RowDivider(),
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                title: 'About SpineUp',
                subtitle: 'What this app is—and is not',
                onTap: _showAboutDialog,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SettingsGroupLabel(label: 'Privacy & portability'),
          const SizedBox(height: 9),
          quickTourTarget(
            registry: tutorialRegistry,
            page: QuickTourPage.settings,
            id: 'privacy',
            child: _SettingsCard(
              children: [
                _SettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'How privacy works',
                  subtitle: 'Stored on this device by default',
                  onTap: _showPrivacyDialog,
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.file_upload_outlined,
                  title: 'Export protected archive',
                  subtitle: 'Move your local profiles to another device',
                  trailing: _archiveBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _archiveBusy ? null : _exportArchive,
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.file_download_outlined,
                  title: 'Import protected archive',
                  subtitle: 'Review before adding or replacing profiles',
                  trailing: _archiveBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _archiveBusy ? null : _importArchive,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SettingsGroupLabel(label: 'Danger zone'),
          const SizedBox(height: 9),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.delete_outline_rounded,
                iconColor: colorScheme.error,
                title: 'Delete all local data',
                titleColor: colorScheme.error,
                subtitle: 'Reset SpineUp on this device',
                onTap: _confirmDeleteLocalData,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  final String label;

  const _SettingsGroupLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.mutedForeground,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderCream),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = iconColor ?? colorScheme.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accent, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 66, endIndent: 14);
  }
}
