import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';

/// Unified modal sheet for managing doctor appointments.
/// Allows scheduling, viewing upcoming/past visits, editing, deleting, and marking visits attended.
class AppointmentManagerModal extends StatefulWidget {
  final String userId;
  final GamificationService gamificationService;
  final void Function(LogEventResult result) onLogged;

  const AppointmentManagerModal({
    super.key,
    required this.userId,
    required this.gamificationService,
    required this.onLogged,
  });

  @override
  State<AppointmentManagerModal> createState() =>
      _AppointmentManagerModalState();
}

class _AppointmentManagerModalState extends State<AppointmentManagerModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Appointment> _allAppointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    final appointments = await widget.gamificationService.getAppointments(
      widget.userId,
    );
    if (mounted) {
      setState(() {
        _allAppointments = appointments;
        _loading = false;
      });
    }
  }

  List<Appointment> get _upcomingAppointments {
    final list = _allAppointments.where((a) => a.isScheduled).toList();
    list.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return list;
  }

  List<Appointment> get _pastAppointments {
    final list = _allAppointments
        .where((a) => a.isCompleted || a.isCancelled)
        .toList();
    list.sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));
    return list;
  }

  void _openScheduleForm([Appointment? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ScheduleFormSheet(
        userId: widget.userId,
        existing: existing,
        gamificationService: widget.gamificationService,
        onSaved: () async {
          await _loadAppointments();
        },
      ),
    );
  }

  void _openDetailSheet(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AppointmentDetailSheet(
        appointment: appointment,
        userId: widget.userId,
        gamificationService: widget.gamificationService,
        onEdit: () {
          Navigator.of(context).pop();
          _openScheduleForm(appointment);
        },
        onDeleted: () async {
          Navigator.of(context).pop();
          await _loadAppointments();
        },
        onCompleted: (result) async {
          Navigator.of(context).pop();
          await _loadAppointments();
          widget.onLogged(result);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySage.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: AppTheme.primarySage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Appointments', style: tt.titleLarge),
                      Text(
                        'Keep appointments and visit notes together',
                        style: tt.bodySmall?.copyWith(
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openScheduleForm(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Schedule'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primarySage,
            labelColor: AppTheme.primarySage,
            unselectedLabelColor: AppTheme.mutedForeground,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past Visits'),
            ],
          ),

          // Tab Views
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentsList(
                        _upcomingAppointments,
                        isUpcoming: true,
                      ),
                      _buildAppointmentsList(
                        _pastAppointments,
                        isUpcoming: false,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<Appointment> items, {
    required bool isUpcoming,
  }) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUpcoming
                    ? Icons.event_available_rounded
                    : Icons.history_toggle_off_rounded,
                size: 48,
                color: AppTheme.mutedForeground.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                isUpcoming
                    ? 'No upcoming appointments'
                    : 'No past appointments logged',
                style: tt.titleSmall?.copyWith(color: AppTheme.mutedForeground),
              ),
              const SizedBox(height: 4),
              Text(
                isUpcoming
                    ? 'Tap "+ Schedule" above to book your doctor or therapy visit.'
                    : 'Recorded visits will show up here for your reference.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: AppTheme.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final apt = items[index];
        final dt = apt.scheduledDateTime;
        final dateStr = DateFormat('MMM d, y · h:mm a').format(dt);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderCream),
          ),
          color: cs.surfaceContainer,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openDetailSheet(apt),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          apt.title,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _buildStatusBadge(apt),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: AppTheme.primarySage,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: tt.bodySmall?.copyWith(
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  if (apt.notes != null && apt.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      apt.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        color: AppTheme.mutedForeground,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(Appointment apt) {
    Color bg;
    Color fg;
    String label;

    if (apt.isCompleted) {
      bg = AppTheme.primarySage.withValues(alpha: 0.15);
      fg = AppTheme.primarySage;
      label = 'Visit recorded';
    } else if (apt.isCancelled) {
      bg = AppTheme.mutedForeground.withValues(alpha: 0.15);
      fg = AppTheme.mutedForeground;
      label = 'Cancelled';
    } else {
      bg = AppTheme.accentLavender.withValues(alpha: 0.15);
      fg = AppTheme.accentLavender;
      label = 'Scheduled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Schedule & Edit Form Sheet ───────────────────────────────────────────────

class _ScheduleFormSheet extends StatefulWidget {
  final String userId;
  final Appointment? existing;
  final GamificationService gamificationService;
  final VoidCallback onSaved;

  const _ScheduleFormSheet({
    required this.userId,
    this.existing,
    required this.gamificationService,
    required this.onSaved,
  });

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDateTime;
  bool _loading = false;
  bool _titleError = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    _titleController.addListener(() {
      if (_titleError && _titleController.text.isNotEmpty) {
        setState(() => _titleError = false);
      }
    });
    _notesController = TextEditingController(
      text: widget.existing?.notes ?? '',
    );

    final initial =
        widget.existing?.scheduledDateTime ?? _defaultAppointmentTime();
    // Ensure initial selected datetime is not in the past
    _selectedDateTime = initial.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(hours: 1))
        : initial;
  }

  DateTime _defaultAppointmentTime() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // 1. Date picker — block past dates at UI level
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isBefore(todayStart)
          ? todayStart
          : _selectedDateTime,
      firstDate: todayStart, // Disables all past dates in UI
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    // 2. Time picker
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (pickedTime == null || !mounted) return;

    // 3. Combined validation — prevent selecting earlier time on today's date
    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (combined.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please choose a future date and time.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedDateTime = combined;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }

    // Safety re-check for future datetime on save
    if (_selectedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a future date and time.')),
      );
      return;
    }

    setState(() => _loading = true);

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        title: title,
        scheduledDateTime: _selectedDateTime,
        notes: _notesController.text.trim(),
      );
      await widget.gamificationService.updateAppointment(updated);
    } else {
      await widget.gamificationService.scheduleAppointment(
        userId: widget.userId,
        title: title,
        scheduledDateTime: _selectedDateTime,
        notes: _notesController.text.trim(),
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final dt = _selectedDateTime;
    final dateStr = DateFormat('MMM d, y · h:mm a').format(dt);

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
          const SizedBox(height: 16),

          Text(
            widget.existing == null
                ? 'Schedule Appointment'
                : 'Edit Appointment',
            style: tt.titleMedium,
          ),
          const SizedBox(height: 16),

          // Title input
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Appointment Title / Type',
              hintText: 'e.g. Orthopedist or physical therapy',
              prefixIcon: const Icon(Icons.badge_outlined),
              errorText: _titleError ? 'Please enter a title for this appointment' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _titleError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _titleError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Date & Time Picker button
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderCream),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: AppTheme.primarySage,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled Date & Time',
                        style: tt.labelSmall?.copyWith(
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Notes input
          TextField(
            controller: _notesController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. "Bring latest X-ray scan report"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                widget.existing == null ? 'Save visit' : 'Save changes',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Appointment Detail Sheet ─────────────────────────────────────────────────

class _AppointmentDetailSheet extends StatefulWidget {
  final Appointment appointment;
  final String userId;
  final GamificationService gamificationService;
  final VoidCallback onEdit;
  final VoidCallback onDeleted;
  final void Function(LogEventResult result) onCompleted;

  const _AppointmentDetailSheet({
    required this.appointment,
    required this.userId,
    required this.gamificationService,
    required this.onEdit,
    required this.onDeleted,
    required this.onCompleted,
  });

  @override
  State<_AppointmentDetailSheet> createState() =>
      _AppointmentDetailSheetState();
}

class _AppointmentDetailSheetState extends State<_AppointmentDetailSheet> {
  bool _loading = false;

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text(
          'Are you sure you want to delete this scheduled appointment? This removes the visit record from this profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.gamificationService.deleteAppointment(widget.appointment.id);
      widget.onDeleted();
    }
  }

  Future<void> _markDone() async {
    if (!widget.appointment.canBeCompleted) return;
    setState(() => _loading = true);

    try {
      final result = await widget.gamificationService.completeAppointment(
        appointmentId: widget.appointment.id,
        userId: widget.userId,
      );
      if (mounted) {
        widget.onCompleted(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error marking done: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final apt = widget.appointment;
    final dt = apt.scheduledDateTime;
    final dateStr = DateFormat('MMM d, y · h:mm a').format(dt);

    final canComplete = apt.canBeCompleted;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Icon(
                Icons.medical_services_rounded,
                color: AppTheme.primarySage,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(apt.title, style: tt.titleMedium)),
            ],
          ),
          const SizedBox(height: 16),

          // Info card
          Container(
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
                    const Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: AppTheme.primarySage,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (apt.notes != null && apt.notes!.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text(
                    'Notes:',
                    style: tt.labelSmall?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(apt.notes!, style: tt.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scheduled Status Action Options
          if (apt.isScheduled) ...[
            // Mark as attended button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canComplete && !_loading ? _markDone : null,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: const Text('Mark as attended'),
              ),
            ),
            if (!canComplete) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Can be marked done once appointment time has arrived.',
                  style: tt.bodySmall?.copyWith(
                    color: AppTheme.mutedForeground,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Edit & Delete row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (apt.isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primarySage.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primarySage,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Visit recorded',
                    style: tt.titleMedium?.copyWith(
                      color: AppTheme.primarySage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Helper function to display the unified Appointment Manager modal.
Future<void> showAppointmentManager({
  required BuildContext context,
  required String userId,
  required GamificationService gamificationService,
  required void Function(LogEventResult result) onLogged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AppointmentManagerModal(
      userId: userId,
      gamificationService: gamificationService,
      onLogged: onLogged,
    ),
  );
}
