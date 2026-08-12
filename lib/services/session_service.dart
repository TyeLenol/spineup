/// Defines the identity boundary used by the app until a real auth provider is wired in.
///
/// Keeping this behind one service prevents screens and repositories from inventing
/// their own user IDs. The mock implementation intentionally exposes one local
/// session today; replacing the implementation later will not require changing
/// every screen that consumes user-scoped data.
class SessionService {
  SessionService._();

  static const String _mockUserId = 'local_user_001';
  static const String _mockDisplayName = 'You';

  static String? _currentUserId = _mockUserId;
  static String _displayName = _mockDisplayName;

  /// The authenticated user ID for the current session.
  ///
  /// Throws when a screen attempts to access user data without an active
  /// session, making missing-auth flows fail explicitly instead of silently
  /// falling back to shared data.
  static String get currentUserId {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('No authenticated user session is available.');
    }
    return userId;
  }

  static String get displayName => _displayName;

  /// Starts a session for a provider-issued user ID.
  static void start({required String userId, String? displayName}) {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'cannot be empty');
    }
    _currentUserId = userId.trim();
    if (displayName != null && displayName.trim().isNotEmpty) {
      _displayName = displayName.trim();
    }
  }

  /// Ends the current session without deleting persisted user data.
  static void signOut() {
    _currentUserId = null;
    _displayName = _mockDisplayName;
  }

  /// Restores the local development session for tests and the current mock auth.
  static void startMockSession() {
    _currentUserId = _mockUserId;
    _displayName = _mockDisplayName;
  }
}
