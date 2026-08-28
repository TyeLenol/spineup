import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/care_subject.dart';
import '../services/profile_store.dart';
import '../services/session_service.dart';

/// Result returned when a manager action changes the active subject list or
/// selection and the parent screen should refresh its subject-scoped data.
enum CareSubjectManagerResult { changed }

class CareSubjectManager extends StatefulWidget {
  final String ownerUserId;
  final Future<void> Function() onAddWard;

  const CareSubjectManager({
    super.key,
    required this.ownerUserId,
    required this.onAddWard,
  });

  @override
  State<CareSubjectManager> createState() => _CareSubjectManagerState();
}

class _CareSubjectManagerState extends State<CareSubjectManager> {
  final _database = DatabaseHelper();
  List<CareSubject> _subjects = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _loading = true);
    final subjects = await _database.getCareSubjects(widget.ownerUserId);
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _loading = false;
    });
  }

  Future<void> _selectSubject(CareSubject subject) async {
    if (subject.id == SessionService.currentCareSubjectId) return;
    SessionService.setActiveCareSubject(subject);
    if (mounted) Navigator.of(context).pop(CareSubjectManagerResult.changed);
  }

  Future<void> _addWard() async {
    Navigator.of(context).pop();
    await Future<void>.delayed(Duration.zero);
    await widget.onAddWard();
  }

  Future<void> _deleteWard(CareSubject subject) async {
    if (subject.isSelf) return;
    if (_subjects.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Keep at least one profile. Use account deletion for a complete local wipe.',
          ),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${subject.displayName}?'),
        content: Text(
          'This removes ${subject.displayName}’s local profile, history, appointments, and progress from this device. It does not remove any other profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep profile'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete profile'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await _database.clearCareSubjectData(
      ownerUserId: widget.ownerUserId,
      careSubjectId: subject.id,
    );
    await ProfileStore.clearProfile(
      userId: widget.ownerUserId,
      careSubjectId: subject.id,
    );

    if (subject.id == SessionService.currentCareSubjectId) {
      final remaining = await _database.getCareSubjects(widget.ownerUserId);
      if (remaining.isNotEmpty) {
        final next = remaining.firstWhere(
          (candidate) => candidate.isSelf,
          orElse: () => remaining.first,
        );
        SessionService.setActiveCareSubject(next);
      } else {
        SessionService.clearActiveCareSubject();
      }
    }
    await _loadSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final activeId = SessionService.currentCareSubjectId;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Manage profiles',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Switch whose private records you are viewing. A profile change refreshes Today, Journey, appointments, and rewards.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _subjects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    final isActive = subject.id == activeId;
                    return _SubjectTile(
                      subject: subject,
                      active: isActive,
                      onSelect: () => _selectSubject(subject),
                      onDelete: subject.isWard && _subjects.length > 1
                          ? () => _deleteWard(subject)
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _addWard,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add someone I care for'),
              ),
              const SizedBox(height: 8),
              Text(
                'Your own profile cannot be deleted here. Use the account deletion control for a complete local wipe.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final CareSubject subject;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback? onDelete;

  const _SubjectTile({
    required this.subject,
    required this.active,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = subject.isSelf
        ? 'My profile'
        : subject.relationship == null || subject.relationship!.isEmpty
        ? 'Someone I care for'
        : subject.relationship!;

    return Material(
      color: active
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                foregroundColor: active
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                child: Icon(
                  subject.isSelf
                      ? Icons.person_outline_rounded
                      : Icons.people_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                TextButton(onPressed: onSelect, child: const Text('Switch')),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete profile',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
