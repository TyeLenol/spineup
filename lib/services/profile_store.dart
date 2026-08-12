import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_data.dart';

/// Persists structured onboarding data locally by session owner and care
/// subject. This prevents a caregiver's own profile from being shown for a
/// ward, while preserving existing single-user data as the owner's self subject.
class ProfileStore {
  ProfileStore._();

  static const String _legacyKey = 'spineup_profile_data';
  static const String _ownerKeyPrefix = 'spineup_profile_data_';
  static const String _subjectKeyPrefix = 'spineup_profile_data_subject_';

  static String _legacyOwnerKey(String ownerUserId) =>
      '$_ownerKeyPrefix$ownerUserId';

  static String _keyFor({
    required String ownerUserId,
    required String careSubjectId,
  }) => _subjectKeyPrefix + ownerUserId + '_' + careSubjectId;

  /// Loads the saved profile for one care subject, or returns a default profile.
  ///
  /// A legacy single-user profile is moved only when the active subject is the
  /// owner’s self subject. A newly added ward must start with its own blank
  /// profile rather than inheriting the caregiver's personal health data.
  static Future<ProfileData> loadProfile({
    required String userId,
    String? careSubjectId,
  }) async {
    final ownerUserId = userId;
    final subjectId = careSubjectId ?? ownerUserId;
    final prefs = await SharedPreferences.getInstance();
    var jsonString = prefs.getString(
      _keyFor(ownerUserId: ownerUserId, careSubjectId: subjectId),
    );

    if ((jsonString == null || jsonString.isEmpty) &&
        subjectId == ownerUserId) {
      final legacyScopedValue = prefs.getString(_legacyOwnerKey(ownerUserId));
      final legacyValue = legacyScopedValue ?? prefs.getString(_legacyKey);
      if (legacyValue != null && legacyValue.isNotEmpty) {
        jsonString = legacyValue;
        await prefs.setString(
          _keyFor(ownerUserId: ownerUserId, careSubjectId: subjectId),
          legacyValue,
        );
        await prefs.remove(_legacyOwnerKey(ownerUserId));
        await prefs.remove(_legacyKey);
      }
    }

    if (jsonString == null || jsonString.isEmpty) {
      return const ProfileData();
    }

    try {
      final jsonMap = jsonDecode(jsonString);
      if (jsonMap is! Map) return const ProfileData();
      return ProfileData.fromJson(Map<String, dynamic>.from(jsonMap));
    } catch (_) {
      return const ProfileData();
    }
  }

  /// Saves [data] for a single care subject belonging to [userId].
  static Future<void> saveProfile({
    required String userId,
    String? careSubjectId,
    required ProfileData data,
  }) async {
    final ownerUserId = userId;
    final subjectId = careSubjectId ?? ownerUserId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(ownerUserId: ownerUserId, careSubjectId: subjectId),
      jsonEncode(data.toJson()),
    );
  }

  /// Deletes the structured profile for one care subject. When omitted, the
  /// owner ID retains the historic self-subject behavior for compatibility.
  static Future<void> clearProfile({
    required String userId,
    String? careSubjectId,
  }) async {
    final ownerUserId = userId;
    final subjectId = careSubjectId ?? ownerUserId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
      _keyFor(ownerUserId: ownerUserId, careSubjectId: subjectId),
    );
  }

  /// Removes every structured profile owned by [userId]. This is used only for
  /// account-wide deletion and mirrors DatabaseHelper.clearUserData.
  static Future<void> clearProfilesForOwner({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final subjectPrefix = _subjectKeyPrefix + userId + '_';
    final keys = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(subjectPrefix) ||
              key == _legacyOwnerKey(userId) ||
              key == _legacyKey,
        )
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
