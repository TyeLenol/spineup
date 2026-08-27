import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/user_profile.dart';
import 'dicebear_avatar.dart';

class AvatarDisplay extends StatelessWidget {
  final UserProfile profile;
  final double size;
  final bool forcePreset;

  const AvatarDisplay({
    super.key,
    required this.profile,
    this.size = 64.0,
    this.forcePreset = false,
  });

  static Widget buildPresetGraphic(AvatarPreset preset, {double size = 40.0}) {
    return ClipOval(
      child: SvgPicture.asset(
        preset.assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => buildFallbackShape(preset, size),
        errorBuilder: (_, _, _) => buildFallbackShape(preset, size),
      ),
    );
  }

  static Widget buildFallbackShape(AvatarPreset preset, double size) {
    final (bg, fg, icon) = switch (preset.id) {
      'preset_sun' => (
        const Color(0xFFFFF3E0),
        const Color(0xFFFF9800),
        Icons.wb_sunny_rounded,
      ),
      'preset_cloud' => (
        const Color(0xFFE3F2FD),
        const Color(0xFF64B5F6),
        Icons.cloud_rounded,
      ),
      'preset_leaf' => (
        const Color(0xFFE8F5E9),
        const Color(0xFF66BB6A),
        Icons.eco_rounded,
      ),
      'preset_star' => (
        const Color(0xFFFFF8E1),
        const Color(0xFFFFCA28),
        Icons.star_rounded,
      ),
      'preset_pebble' => (
        const Color(0xFFEFEBE9),
        const Color(0xFF8D6E63),
        Icons.circle_rounded,
      ),
      _ => (
        const Color(0xFFFFF3E0),
        const Color(0xFFFF9800),
        Icons.face_rounded,
      ),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Icon(icon, color: fg, size: size * 0.55),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!forcePreset && profile.usesPhoto) {
      final file = File(profile.customPhotoPath!);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(file, width: size, height: size, fit: BoxFit.cover),
        );
      }
    }

    if (!forcePreset && profile.usesIllustratedAvatar) {
      return ClipOval(
        child: DiceBearAvatar(
          styleId: profile.avatarStyleId,
          seed: profile.avatarSeed,
          selections: profile.avatarOptions,
          size: size,
          fallback: buildFallbackShape(profile.preset, size),
        ),
      );
    }

    return buildPresetGraphic(profile.preset, size: size);
  }
}
