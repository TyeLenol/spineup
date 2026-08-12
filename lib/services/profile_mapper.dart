import '../models/profile_data.dart';
import '../models/user_profile.dart';

/// Converts the structured onboarding profile into the compact profile used by
/// the current runtime and gamification surfaces.
///
/// ProfileData remains the onboarding/editing DTO, while UserProfile remains
/// the runtime summary until the two models are replaced by one domain
/// aggregate. Keeping this mapping explicit prevents screens from silently
/// maintaining different conversion rules.
class ProfileMapper {
  ProfileMapper._();

  static UserProfile toRuntimeProfile(
    ProfileData data, {
    UserProfile fallback = const UserProfile(
      presetId: 'preset_sun',
      name: 'Alex',
      diagnosis: 'Thoracic Curve',
      braceStatus: 'Yes',
      ageRange: '13-17',
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
    final birthdayHasPassed = (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!birthdayHasPassed) age--;

    if (age < 13) return 'Under 13';
    if (age <= 17) return '13-17';
    if (age <= 25) return '18-25';
    if (age <= 40) return '26-40';
    return '41+';
  }
}
