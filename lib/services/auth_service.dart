import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// MOCK AUTH SERVICE
/// -----------------
/// All methods here simulate a successful sign-in locally without connecting
/// to a real auth backend. google_sign_in v7 requires initialize() before use
/// and a real OAuth client ID, so Google auth is fully mocked until configured.
///
/// TODO(backend): Replace every method body with real API calls when auth
/// backend is available. For Google auth, call GoogleSignIn.instance.initialize()
/// in main() and then GoogleSignIn.instance.authenticate() here.
/// Remove this comment block when done.
class AuthService {
  AuthService._();

  /// Returns null on success or an error message string.
  static Future<String?> signInWithEmail(String email, String password) async {
    // MOCK: simulate network delay, then succeed
    await Future<void>.delayed(const Duration(milliseconds: 800));
    debugPrint('[MOCK AUTH] signInWithEmail: $email — success (mock)');
    return null; // null = success
  }

  /// Returns null on success or an error message string.
  static Future<String?> signUpWithEmail(String email, String password) async {
    // MOCK: simulate network delay, then succeed
    await Future<void>.delayed(const Duration(milliseconds: 800));
    debugPrint('[MOCK AUTH] signUpWithEmail: $email — success (mock)');
    return null;
  }

  /// Google sign-in — MOCK.
  ///
  /// TODO(backend): Replace with:
  ///   await GoogleSignIn.instance.initialize(clientId: 'YOUR_CLIENT_ID');
  ///   final account = await GoogleSignIn.instance.authenticate();
  ///   // use account.email, account.displayName, etc.
  static Future<String?> signInWithGoogle() async {
    // MOCK FALLBACK — replace with real implementation once OAuth is configured
    debugPrint('[MOCK AUTH] Google sign-in — mock success (no OAuth configured yet)');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return null;
  }

  /// Apple sign-in: attempts real flow but falls back to mock success
  /// if Apple credentials are not configured.
  ///
  /// TODO(backend): Remove the try/catch mock fallback once Sign in with Apple
  /// is configured in your Apple developer account and Xcode project.
  static Future<String?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );
      debugPrint('[MOCK AUTH] Apple sign-in: ${credential.email} — success (mock session)');
      return null;
    } catch (e) {
      // MOCK FALLBACK — remove once Apple credentials are configured
      debugPrint('[MOCK AUTH] Apple sign-in failed ($e), using mock success');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return null;
    }
  }
}
