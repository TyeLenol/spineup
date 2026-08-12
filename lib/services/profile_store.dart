import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_data.dart';

class ProfileStore {
  static const String _key = 'spineup_profile_data';

  /// Loads the saved ProfileData from SharedPreferences, or returns a default instance.
  static Future<ProfileData> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return ProfileData.fromJson(jsonMap);
      } catch (e) {
        // If there's an error parsing, return default
        return const ProfileData();
      }
    }
    return const ProfileData();
  }

  /// Saves the ProfileData to SharedPreferences.
  static Future<void> saveProfile(ProfileData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data.toJson());
    await prefs.setString(_key, jsonString);
  }

  /// Clears the saved ProfileData.
  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
