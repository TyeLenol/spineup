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

  const UserProfile({
    required this.presetId,
    this.customPhotoPath,
  });

  factory UserProfile.defaultProfile() {
    return const UserProfile(presetId: 'preset_sun');
  }

  AvatarPreset get preset {
    return presetAvatars.firstWhere(
      (p) => p.id == presetId,
      orElse: () => presetAvatars.first,
    );
  }
}
