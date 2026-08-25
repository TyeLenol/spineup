import '../models/care_subject.dart';
import '../models/profile_data.dart';
import '../models/user_profile.dart';

/// Converts structured onboarding data into the smaller models used by current
/// runtime surfaces and by the care-subject ownership boundary.
class ProfileMapper {
  ProfileMapper._();

  static UserProfile toRuntimeProfile(
    ProfileData data, {
    UserProfile fallback = const UserProfile(
      presetId: 'preset_sun',
      name: 'You',
      diagnosis: 'Not added',
      braceStatus: 'Not added',
      ageRange: 'Not added',
    ),
  }) {
    final name = data.basics.displayName.trim();
    return UserProfile(
      presetId: fallback.presetId,
      customPhotoPath: fallback.customPhotoPath,
      name: name.isEmpty ? fallback.name : name,
      diagnosis: _diagnosisLabel(data.curve.curveType) ?? fallback.diagnosis,
      braceStatus: _braceStatus(data.brace.wears) ?? fallback.braceStatus,
      ageRange: _ageRange(data.basics.dob) ?? fallback.ageRange,
    );
  }

  /// Creates the subject index record for the profile being completed. The
  /// complete health questionnaire stays attached in [profileData] and is saved
  /// separately through [ProfileStore] under this subject's ID.
  static CareSubject toCareSubject({
    required String id,
    required String ownerUserId,
    required ProfileData data,
    CareSubject? existing,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final requestedName = data.basics.displayName.trim();
    final fallbackName = data.ownership.isSelf ? 'You' : 'Someone I care for';

    return CareSubject(
      id: id,
      ownerUserId: ownerUserId,
      type: data.ownership.subjectType,
      displayName: requestedName.isEmpty
          ? existing?.displayName ?? fallbackName
          : requestedName,
      relationship: data.ownership.isWard
          ? data.ownership.relationship?.trim()
          : null,
      profileData: data,
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
    );
  }

  static String? _diagnosisLabel(CurveType? curveType) {
    switch (curveType) {
      case CurveType.thoracic:
        return 'Thoracic Curve';
      case CurveType.lumbar:
        return 'Lumbar Curve';
      case CurveType.doubleS:
        return 'Double Major';
      case CurveType.thoracolumbar:
        return 'Thoracolumbar Curve';
      case CurveType.unsure:
      case null:
        return null;
    }
  }

  static String? _braceStatus(bool? wears) {
    if (wears == true) return 'Yes';
    if (wears == false) return 'No';
    return null;
  }

  static String? _ageRange(String dob) {
    final birthDate = DateTime.tryParse(dob);
    if (birthDate == null) return null;

    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final birthdayHasPassed =
        (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!birthdayHasPassed) age--;

    if (age < 13) return 'Under 13';
    if (age <= 17) return '13-17';
    if (age <= 25) return '18-25';
    if (age <= 40) return '26-40';
    return '41+';
  }
}
