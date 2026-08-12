import '../models/care_subject.dart';

/// Defines the session-owner and active-care-subject boundaries used by the app
/// until a real auth provider is wired in.
///
/// Keeping both concepts behind one service prevents screens and repositories
/// from inventing identities. The mock implementation still exposes one local
/// owner, while health records are now addressed through [currentCareSubjectId].
class SessionService {
  SessionService._();

  static const String _mockUserId = 'local_user_001';
  static const String _mockDisplayName = 'You';

  static String? _currentUserId = _mockUserId;
  static String _displayName = _mockDisplayName;
  static CareSubject? _activeCareSubject;

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
    _activeCareSubject = null;
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
    _activeCareSubject = subject;
  }

  static void clearActiveCareSubject() {
    _activeCareSubject = null;
  }

  /// Ends the current session without deleting persisted user data.
  static void signOut() {
    _currentUserId = null;
    _displayName = _mockDisplayName;
    _activeCareSubject = null;
  }

  /// Restores the local development session for tests and the current mock auth.
  static void startMockSession() {
    _currentUserId = _mockUserId;
    _displayName = _mockDisplayName;
    _activeCareSubject = null;
  }
}
