import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../models/care_subject.dart';

/// Defines the session-owner and active-care-subject boundaries used by the app
/// until a real auth provider is wired in.
///
/// Keeping both concepts behind one service prevents screens and repositories
/// from inventing identities. The mock implementation still exposes one local
/// owner, while health records are addressed through [currentCareSubjectId].
class SessionService {
  SessionService._();

  static const String _mockUserId = 'local_user_001';
  static const String _mockDisplayName = 'You';
  static const String _activeSubjectKeyPrefix = 'spineup_active_care_subject_';

  static String? _currentUserId = _mockUserId;
  static String _displayName = _mockDisplayName;
  static CareSubject? _activeCareSubject;

  /// Emits whenever the active subject changes so app-shell context and
  /// subject-aware screens can refresh without inventing a second identity
  /// state.
  static final ValueNotifier<CareSubject?> activeCareSubjectNotifier =
      ValueNotifier<CareSubject?>(null);

  /// The session owner ID. This identifies the person who can manage one or
  /// more care subjects; it is not automatically the health-record scope.
  static String get currentUserId {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('No authenticated user session is available.');
    }
    return userId;
  }

  /// The subject whose profile, events, appointments, and rewards should be
  /// shown. Existing one-person local data remains compatible because, until a
  /// subject is explicitly selected, the owner ID is treated as the legacy self
  /// subject ID.
  static String get currentCareSubjectId =>
      _activeCareSubject?.id ?? currentUserId;

  static CareSubject? get activeCareSubject => _activeCareSubject;
  static String get displayName => _displayName;

  /// Starts a session for a provider-issued owner ID.
  static void start({required String userId, String? displayName}) {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'cannot be empty');
    }
    _currentUserId = userId.trim();
    _setActiveCareSubject(null);
    if (displayName != null && displayName.trim().isNotEmpty) {
      _displayName = displayName.trim();
    }
  }

  /// Sets the care subject whose health data should be visible and writable.
  /// This guard prevents an owner from activating another owner's subject.
  static void setActiveCareSubject(CareSubject subject) {
    if (subject.ownerUserId != currentUserId) {
      throw StateError('Cannot activate a care subject owned by another user.');
    }
    _setActiveCareSubject(subject);
    unawaited(
      _persistActiveSubject(subject).catchError((
        Object error,
        StackTrace stack,
      ) {
        debugPrint('Unable to persist the active care subject: $error\n$stack');
      }),
    );
  }

  /// Restores the last selected subject from the current owner’s local
  /// subject index after login.
  static Future<void> restorePersistedActiveCareSubject() async {
    final subjects = await DatabaseHelper().getCareSubjects(currentUserId);
    await restoreActiveCareSubject(subjects: subjects);
  }

  /// Restores the last selected subject only when it is present in the
  /// owner-scoped subject list. If it is missing, prefer the self subject and
  /// otherwise the first available subject.
  static Future<void> restoreActiveCareSubject({
    required List<CareSubject> subjects,
  }) async {
    final ownerUserId = currentUserId;
    final prefs = await SharedPreferences.getInstance();
    final persistedId = prefs.getString(_activeSubjectKey(ownerUserId));

    CareSubject? selected;
    if (persistedId != null) {
      for (final subject in subjects) {
        if (subject.id == persistedId && subject.ownerUserId == ownerUserId) {
          selected = subject;
          break;
        }
      }
    }
    if (selected == null && subjects.isNotEmpty) {
      selected = subjects.firstWhere(
        (subject) => subject.isSelf,
        orElse: () => subjects.first,
      );
    }

    _setActiveCareSubject(selected);
    if (selected != null) {
      await prefs.setString(_activeSubjectKey(ownerUserId), selected.id);
    }
  }

  static void clearActiveCareSubject() {
    _setActiveCareSubject(null);
  }

  /// Ends the current session without deleting persisted user data.
  static void signOut() {
    _currentUserId = null;
    _displayName = _mockDisplayName;
    _setActiveCareSubject(null);
  }

  /// Restores the local development session for tests and the current mock auth.
  static void startMockSession() {
    _currentUserId = _mockUserId;
    _displayName = _mockDisplayName;
    _setActiveCareSubject(null);
  }

  static void _setActiveCareSubject(CareSubject? subject) {
    _activeCareSubject = subject;
    activeCareSubjectNotifier.value = subject;
  }

  static String _activeSubjectKey(String ownerUserId) =>
      '$_activeSubjectKeyPrefix$ownerUserId';

  static Future<void> _persistActiveSubject(CareSubject subject) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSubjectKey(subject.ownerUserId), subject.id);
  }
}
