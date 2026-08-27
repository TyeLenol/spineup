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
  final String avatarStyleId;
  final Map<String, String> avatarOptions;
  final String avatarSeed;
  final String avatarMode;
  final String name;
  final String diagnosis;
  final String braceStatus;
  final String ageRange;

  const UserProfile({
    required this.presetId,
    this.customPhotoPath,
    this.avatarStyleId = 'preset',
    this.avatarOptions = const <String, String>{},
    this.avatarSeed = 'spineup-avatar',
    this.avatarMode = 'preset',
    this.name = 'You',
    this.diagnosis = 'Not added',
    this.braceStatus = 'Not added',
    this.ageRange = 'Not added',
  });

  factory UserProfile.defaultProfile() {
    return const UserProfile(
      presetId: 'preset_sun',
      name: 'You',
      diagnosis: 'Not added',
      braceStatus: 'Not added',
      ageRange: 'Not added',
    );
  }

  UserProfile copyWith({
    String? presetId,
    String? customPhotoPath,
    bool clearCustomPhotoPath = false,
    String? avatarStyleId,
    Map<String, String>? avatarOptions,
    String? avatarSeed,
    String? avatarMode,
    String? name,
    String? diagnosis,
    String? braceStatus,
    String? ageRange,
  }) {
    return UserProfile(
      presetId: presetId ?? this.presetId,
      customPhotoPath: clearCustomPhotoPath
          ? null
          : customPhotoPath ?? this.customPhotoPath,
      avatarStyleId: avatarStyleId ?? this.avatarStyleId,
      avatarOptions: avatarOptions ?? this.avatarOptions,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      avatarMode: avatarMode ?? this.avatarMode,
      name: name ?? this.name,
      diagnosis: diagnosis ?? this.diagnosis,
      braceStatus: braceStatus ?? this.braceStatus,
      ageRange: ageRange ?? this.ageRange,
    );
  }

  bool get usesPhoto => avatarMode == 'photo' && customPhotoPath != null;

  bool get usesIllustratedAvatar =>
      avatarMode == 'illustrated' && avatarStyleId != 'preset';

  AvatarPreset get preset {
    return presetAvatars.firstWhere(
      (p) => p.id == presetId,
      orElse: () => presetAvatars.first,
    );
  }
}
