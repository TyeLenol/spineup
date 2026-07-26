import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/user_profile.dart';

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

  @override
  Widget build(BuildContext context) {
    if (!forcePreset && profile.customPhotoPath != null) {
      final file = File(profile.customPhotoPath!);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    
    // Fallback to preset
    final preset = profile.preset;
    return ClipOval(
      child: SvgPicture.asset(
        preset.assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
