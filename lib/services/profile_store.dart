import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_data.dart';

/// Persists the structured onboarding profile locally, scoped to a user session.
class ProfileStore {
  ProfileStore._();

  static const String _legacyKey = 'spineup_profile_data';
  static const String _keyPrefix = 'spineup_profile_data_';

  static String _keyFor(String userId) => '$_keyPrefix$userId';

  /// Loads the saved profile for [userId], or returns a default profile.
  ///
  /// A profile written by the earlier single-user prototype is migrated to the
  /// current user's scoped key once, then the legacy key is removed.
  static Future<ProfileData> loadProfile({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    var jsonString = prefs.getString(_keyFor(userId));

    if (jsonString == null || jsonString.isEmpty) {
      final legacyValue = prefs.getString(_legacyKey);
      if (legacyValue != null && legacyValue.isNotEmpty) {
        jsonString = legacyValue;
        await prefs.setString(_keyFor(userId), legacyValue);
        await prefs.remove(_legacyKey);
      }
    }

    if (jsonString == null || jsonString.isEmpty) {
      return const ProfileData();
    }

    try {
      final jsonMap = jsonDecode(jsonString);
      if (jsonMap is! Map) {
        return const ProfileData();
      }
      return ProfileData.fromJson(Map<String, dynamic>.from(jsonMap));
    } catch (_) {
      return const ProfileData();
    }
  }

  /// Saves [data] for [userId].
  static Future<void> saveProfile({
    required String userId,
    required ProfileData data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(userId), jsonEncode(data.toJson()));
  }

  /// Deletes the structured profile for [userId].
  static Future<void> clearProfile({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(userId));
  }
}
