import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/appointment.dart';
import '../models/event.dart';
import '../models/milestone.dart';
import '../models/user_profile.dart';

// ─── XP Constants ─────────────────────────────────────────────────────────────

const int kXpStretch = 30;
const int kXpJournal = 25;
const int kXpAngle = 50;
const int kXpAppointment = 40;
const int kXpProfileCompletion = 250;
const int kXpDailyBonus = 5;
const int kDailyXpTarget = 600;

// ─── Snapshot ─────────────────────────────────────────────────────────────────

/// Immutable snapshot of a user's current gamification state.
class GamificationSnapshot {
  final int totalXp;
  final int currentLevel;

  /// 0.0–1.0 progress towards next level.
  final double levelProgress;

  /// XP position within the current level (e.g. 40 out of 100).
  final int xpInLevel;

  /// Consecutive calendar days the user has logged at least one event.
  final int streakDays;

  final List<Milestone> unlockedMilestones;
  final UserProfile userProfile;

  const GamificationSnapshot({
    required this.totalXp,
    required this.currentLevel,
    required this.levelProgress,
    required this.xpInLevel,
    required this.streakDays,
    required this.unlockedMilestones,
    required this.userProfile,
  });

  String get currentTitle {
    if (currentLevel < 5) return 'Newcomer';
    if (currentLevel < 10) return 'Mover';
    if (currentLevel < 20) return 'Wonder';
    if (currentLevel < 35) return 'Voyager';
    if (currentLevel < 50) return 'Guardian';
    return 'Wizard';
  }

  static GamificationSnapshot empty = GamificationSnapshot(
    totalXp: 0,
    currentLevel: 1,
    levelProgress: 0,
    xpInLevel: 0,
    streakDays: 0,
    unlockedMilestones: [],
    userProfile: UserProfile.defaultProfile(),
  );
}

// ─── Result of logging an event ───────────────────────────────────────────────

class LogEventResult {
  /// Total XP awarded (base + optional daily bonus).
  final int xpAwarded;

  /// True when the +5 daily first-log bonus was included.
  final bool dailyBonusAwarded;

  /// Any milestones newly unlocked by this event.
  final List<Milestone> newMilestones;

  const LogEventResult({
    required this.xpAwarded,
    required this.dailyBonusAwarded,
    required this.newMilestones,
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// Central gamification service that reads from and writes to SQLite.
class GamificationService {
  final DatabaseHelper _db;
  UserProfile _userProfile = UserProfile.defaultProfile();

  GamificationService({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper();

  // ── Base XP helper ─────────────────────────────────────────────────────────

  static int baseXpFor(EventType type) {
    switch (type) {
      case EventType.stretchCompleted:
        return kXpStretch;
      case EventType.journalEntry:
        return kXpJournal;
      case EventType.angleLogged:
        return kXpAngle;
      case EventType.appointmentAttended:
        return kXpAppointment;
      case EventType.profileCompleted:
        return kXpProfileCompletion;
    }
  }

  // ── Check: first event today? ───────────────────────────────────────────────

  Future<bool> isFirstEventToday(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final events = await _db.getEventsByDateRange(userId, startOfDay, endOfDay);
    return events.isEmpty;
  }

  Future<bool> hasLoggedAngleToday(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final events = await _db.getEventsByDateRange(userId, startOfDay, endOfDay);
    return events.any((e) => e.type == EventType.angleLogged);
  }

  // ── Log an event ────────────────────────────────────────────────────────────

  Future<LogEventResult> logEvent({
    required String eventId,
    required String userId,
    required EventType type,
    required Map<String, dynamic> payload,
    bool includeDailyBonus = true,
  }) async {
    int base = baseXpFor(type);

    final eventsBefore = await _db.getEventsByUser(userId);
    final previousTotalXp = eventsBefore.fold<int>(
      0,
      (sum, event) => sum + event.xpValue,
    );
    final firstToday = await isFirstEventToday(userId);

    if (type == EventType.angleLogged) {
      final alreadyLoggedToday = await hasLoggedAngleToday(userId);
      if (alreadyLoggedToday) {
        base = 0;
      }
    }

    final bonus = includeDailyBonus && firstToday ? kXpDailyBonus : 0;
    final total = base + bonus;

    final event = Event(
      id: eventId,
      userId: userId,
      type: type,
      timestamp: DateTime.now(),
      payload: payload,
      xpValue: total,
    );

    await _db.insertEvent(event);

    final snapshot = await getSnapshot(userId);
    final eventsAfter = await _db.getEventsByUser(userId);

    final newMilestones = _detectNewMilestones(
      type: type,
      snapshot: snapshot,
      allEvents: eventsAfter,
      previousTotalXp: previousTotalXp,
    );

    return LogEventResult(
      xpAwarded: total,
      dailyBonusAwarded: includeDailyBonus && firstToday,
      newMilestones: newMilestones,
    );
  }

  /// Updates an existing journal entry owned by [userId] without awarding XP again.
  Future<void> updateJournalEntry({
    required String eventId,
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final existing = await _db.getEventById(eventId, userId);
    if (existing == null) {
      throw StateError('Journal entry not found for the active user: $eventId');
    }
    if (existing.type != EventType.journalEntry) {
      throw ArgumentError.value(eventId, 'eventId', 'Event is not a journal entry.');
    }

    await _db.updateEvent(existing.copyWith(payload: payload));
  }

  Future<void> reportPost(String postId, String userId) async {
    // Await db method once added to schema
    // await _db.reportPost(postId, userId);
  }

  /// Update the user's selected profile details.
  Future<void> updateProfile({
    required String userId,
    String? presetId,
    String? customPhotoPath,
    String? name,
    String? diagnosis,
    String? braceStatus,
    String? ageRange,
  }) async {
    _userProfile = _userProfile.copyWith(
      presetId: presetId,
      customPhotoPath: customPhotoPath,
      name: name,
      diagnosis: diagnosis,
      braceStatus: braceStatus,
      ageRange: ageRange,
    );
    await _db.updateUserProfile(
      userId: userId,
      presetId: _userProfile.presetId,
      customPhotoPath: _userProfile.customPhotoPath,
      name: _userProfile.name,
      diagnosis: _userProfile.diagnosis,
      braceStatus: _userProfile.braceStatus,
      ageRange: _userProfile.ageRange,
    );
  }

  /// Deletes all local data belonging to [userId] for account deletion.
  Future<void> clearUserData({required String userId}) async {
    await _db.clearUserData(userId);
    _userProfile = UserProfile.defaultProfile();
  }

  /// Detect milestones that first become satisfied by [type] being logged and
  /// [snapshot] reflecting the post-insert state.
  List<Milestone> _detectNewMilestones({
    required EventType type,
    required GamificationSnapshot snapshot,
    required List<Event> allEvents,
    required int previousTotalXp,
  }) {
    final result = <Milestone>[];
    for (final m in allMilestones) {
      if (m.requiredXp != null) {
        // XP-gated: newly unlocked only when this event crosses the threshold.
        if (snapshot.totalXp >= m.requiredXp! && previousTotalXp < m.requiredXp!) {
          result.add(m);
        }
      } else if (m.requiredEventType != null && m.requiredEventCount != null) {
        if (type == m.requiredEventType) {
          final count = allEvents.where((e) => e.type == type).length;
          if (count == m.requiredEventCount) {
            result.add(m);
          }
        }
      } else if (m.requiredStreakDays != null) {
        if (snapshot.streakDays == m.requiredStreakDays) {
          result.add(m);
        }
      }
    }
    return result;
  }

  // ── Snapshot ────────────────────────────────────────────────────────────────

  /// Compute a full [GamificationSnapshot] for [userId] by reading all events.
  Future<GamificationSnapshot> getSnapshot(String userId) async {
    final events = await _db.getEventsByUser(userId);

    final userProfileMap = await _db.getUserProfile(userId);
    if (userProfileMap != null) {
      _userProfile = UserProfile(
        presetId: userProfileMap['preset_id'] as String? ?? 'preset_sun',
        customPhotoPath: userProfileMap['custom_photo_path'] as String?,
        name: userProfileMap['name'] as String? ?? 'Alex',
        diagnosis: userProfileMap['diagnosis'] as String? ?? 'Thoracic Curve',
        braceStatus: userProfileMap['brace_status'] as String? ?? 'Yes',
        ageRange: userProfileMap['age_range'] as String? ?? '13-17',
      );
    }

    final totalXp = events.fold(0, (sum, e) => sum + e.xpValue);
    
    int level = 1;
    int remainingXp = totalXp;
    while (true) {
      int xpForNext = 100 + (level - 1) * 25;
      if (remainingXp >= xpForNext) {
        remainingXp -= xpForNext;
        level++;
      } else {
        break;
      }
    }
    
    final xpInLevel = remainingXp;
    final progress = xpInLevel / (100 + (level - 1) * 25);

    final streak = _computeStreak(events);

    // Unlock milestones.
    final unlockedMilestones = _computeUnlockedMilestones(
      totalXp: totalXp,
      events: events,
      streakDays: streak,
    );

    return GamificationSnapshot(
      totalXp: totalXp,
      currentLevel: level,
      levelProgress: progress,
      xpInLevel: xpInLevel,
      streakDays: streak,
      unlockedMilestones: unlockedMilestones,
      userProfile: _userProfile,
    );
  }

  // ── Streak computation ──────────────────────────────────────────────────────

  /// Counts consecutive calendar days (ending today or yesterday) on which
  /// the user logged at least one event.
  int _computeStreak(List<Event> events) {
    if (events.isEmpty) return 0;

    // Collect unique calendar dates (UTC-normalised for consistency).
    final dates = events
        .map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // descending

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Streak must include today or yesterday to be active.
    if (dates.first.difference(today).inDays.abs() > 1) return 0;

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i - 1].difference(dates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Milestone unlock check ──────────────────────────────────────────────────

  List<Milestone> _computeUnlockedMilestones({
    required int totalXp,
    required List<Event> events,
    required int streakDays,
  }) {
    final result = <Milestone>[];
    final eventCountByType = <EventType, int>{};
    for (final e in events) {
      eventCountByType[e.type] = (eventCountByType[e.type] ?? 0) + 1;
    }

    for (final m in allMilestones) {
      if (m.requiredXp != null && totalXp >= m.requiredXp!) {
        result.add(m);
      } else if (m.requiredEventType != null && m.requiredEventCount != null) {
        final count = eventCountByType[m.requiredEventType] ?? 0;
        if (count >= m.requiredEventCount!) {
          result.add(m);
        }
      } else if (m.requiredStreakDays != null && streakDays >= m.requiredStreakDays!) {
        result.add(m);
      }
    }
    return result;
  }

  // ── Cobb angle history ──────────────────────────────────────────────────────

  /// Returns a chronological list of (date, degrees) for the Cobb angle trend.
  Future<List<({DateTime date, double degrees})>> getCobbAngleHistory(
    String userId,
  ) async {
    final events = await _db.getEventsByUserAndType(userId, EventType.angleLogged);
    final result = <({DateTime date, double degrees})>[];
    for (final e in events) {
      final deg = e.payload['degrees'];
      if (deg != null) {
        result.add((
          date: e.timestamp,
          degrees: (deg as num).toDouble(),
        ));
      }
    }
    // Return in ascending order for the chart.
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  // ── Journal / symptom history ───────────────────────────────────────────────

  Future<List<Event>> getJournalHistory(String userId) async {
    return _db.getEventsByUserAndType(userId, EventType.journalEntry);
  }

  Future<List<Event>> getTodayEvents(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return _db.getEventsByDateRange(userId, startOfDay, endOfDay);
  }

  Future<List<Event>> getAllEvents(String userId) async {
    return _db.getEventsByUser(userId);
  }

  // ── Appointments ────────────────────────────────────────────────────────────

  Future<List<Appointment>> getAppointments(String userId) async {
    return _db.getAppointmentsByUser(userId);
  }

  Future<Appointment> scheduleAppointment({
    required String userId,
    required String title,
    required DateTime scheduledDateTime,
    String? notes,
  }) async {
    final appointment = Appointment(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      scheduledDateTime: scheduledDateTime,
      notes: notes,
      status: AppointmentStatus.scheduled,
    );
    await _db.insertAppointment(appointment);
    return appointment;
  }

  Future<void> updateAppointment(Appointment appointment) async {
    await _db.updateAppointment(appointment);
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await _db.deleteAppointment(appointmentId);
  }

  /// Completes a scheduled appointment once its time has arrived/passed.
  /// Logs an `appointment_attended` event (+40 XP), links `completed_event_id`, and sets status to `completed`.
  Future<LogEventResult> completeAppointment({
    required String appointmentId,
    required String userId,
  }) async {
    final appointment = await _db.getAppointmentById(appointmentId);
    if (appointment == null) {
      throw ArgumentError('Appointment not found: $appointmentId');
    }
    if (appointment.userId != userId) {
      throw StateError('Appointment does not belong to the active user.');
    }
    if (appointment.isCompleted || appointment.completedEventId != null) {
      throw StateError('Appointment has already been completed.');
    }
    if (appointment.isCancelled) {
      throw StateError('Cannot complete a cancelled appointment.');
    }
    if (appointment.scheduledDateTime.isAfter(DateTime.now())) {
      throw StateError('Cannot complete future appointment before scheduled date/time.');
    }

    final eventId = const Uuid().v4();
    final result = await logEvent(
      eventId: eventId,
      userId: userId,
      type: EventType.appointmentAttended,
      payload: {
        'appointment_id': appointment.id,
        'title': appointment.title,
        'notes': appointment.notes,
        'completed_at': DateTime.now().toIso8601String(),
      },
    );

    final updated = appointment.copyWith(
      status: AppointmentStatus.completed,
      completedEventId: eventId,
    );
    await _db.updateAppointment(updated);

    return result;
  }
}
