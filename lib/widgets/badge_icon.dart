import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/milestone.dart';

class BadgeIcon extends StatelessWidget {
  final Milestone milestone;
  final double size;
  final bool isUnlocked;

  const BadgeIcon({
    super.key,
    required this.milestone,
    this.size = 24.0,
    this.isUnlocked = true,
  });

  @override
  Widget build(BuildContext context) {
    // Bronze for tier 1, Gold for tier 2
    final color = milestone.tier == 1
        ? const Color(0xFFCD7F32) // Bronze
        : const Color(0xFFFFD700); // Gold

    return SvgPicture.asset(
      milestone.assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        isUnlocked ? color : Colors.grey.withValues(alpha: 0.5),
        BlendMode.srcIn,
      ),
    );
  }
}
