class AvatarPreset {
  final String id;
  final String name;
  final String assetPath;

  const AvatarPreset({
    required this.id,
    required this.name,
    required this.assetPath,
  });
}

const List<AvatarPreset> presetAvatars = [
  AvatarPreset(
    id: 'preset_sun',
    name: 'Warm Sun',
    assetPath: 'assets/images/avatars/preset_sun.svg',
  ),
  AvatarPreset(
    id: 'preset_cloud',
    name: 'Soft Cloud',
    assetPath: 'assets/images/avatars/preset_cloud.svg',
  ),
  AvatarPreset(
    id: 'preset_leaf',
    name: 'Gentle Leaf',
    assetPath: 'assets/images/avatars/preset_leaf.svg',
  ),
  AvatarPreset(
    id: 'preset_star',
    name: 'Happy Star',
    assetPath: 'assets/images/avatars/preset_star.svg',
  ),
  AvatarPreset(
    id: 'preset_pebble',
    name: 'Calm Pebble',
    assetPath: 'assets/images/avatars/preset_pebble.svg',
  ),
];

class UserProfile {
  final String presetId;
  final String? customPhotoPath;
  final String name;
  final String diagnosis;
  final String braceStatus;
  final String ageRange;

  const UserProfile({
    required this.presetId,
    this.customPhotoPath,
    this.name = 'Alex',
    this.diagnosis = 'Thoracic Curve',
    this.braceStatus = 'Yes',
    this.ageRange = '13-17',
  });

  factory UserProfile.defaultProfile() {
    return const UserProfile(
      presetId: 'preset_sun',
      name: 'Alex',
      diagnosis: 'Thoracic Curve',
      braceStatus: 'Yes',
      ageRange: '13-17',
    );
  }

  UserProfile copyWith({
    String? presetId,
    String? customPhotoPath,
    String? name,
    String? diagnosis,
    String? braceStatus,
    String? ageRange,
  }) {
    return UserProfile(
      presetId: presetId ?? this.presetId,
      customPhotoPath: customPhotoPath ?? this.customPhotoPath,
      name: name ?? this.name,
      diagnosis: diagnosis ?? this.diagnosis,
      braceStatus: braceStatus ?? this.braceStatus,
      ageRange: ageRange ?? this.ageRange,
    );
  }

  AvatarPreset get preset {
    return presetAvatars.firstWhere(
      (p) => p.id == presetId,
      orElse: () => presetAvatars.first,
    );
  }
}
