import 'package:flutter/material.dart';
import '../../../theme/spine_fonts.dart';

import '../../../models/profile_data.dart';
import '../../../theme/app_theme.dart';
import '../../learn_screen.dart';

class StepConsent extends StatefulWidget {
  final ProfileData initialData;
  final ValueChanged<ProfileData> onSave;
  final bool isCaregiverMode;

  const StepConsent({
    super.key,
    required this.initialData,
    required this.onSave,
    required this.isCaregiverMode,
  });

  @override
  State<StepConsent> createState() => _StepConsentState();
}

class _StepConsentState extends State<StepConsent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _accept());
  }

  void _accept() {
    widget.onSave(
      widget.initialData.copyWith(
        consent: ProfileConsent(onDevice: true, acceptedAt: DateTime.now()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ConsentRow(
          icon: Icons.phone_android_rounded,
          title: 'On-device by default',
          body:
              'Your profile stays on this phone by default. SpineUp has no analytics or cloud sync, and you control any export or import.',
        ),
        const SizedBox(height: 12),
        const _ConsentRow(
          icon: Icons.folder_shared_outlined,
          title: 'Your data should be portable',
          helpTopicId: 'export-import',
          body:
              'Protected export and import can move a human-readable, passphrase-protected copy to a new phone. You preview an import before it changes anything.',
        ),
        const SizedBox(height: 12),
        _ConsentRow(
          icon: Icons.delete_outline_rounded,
          title: 'Deletion scope',
          body:
              'You can edit your information later. Settings lets you remove this care profile or clear local app data when you choose.',
        ),
        if (widget.isCaregiverMode) ...[
          const SizedBox(height: 12),
          const _ConsentRow(
            icon: Icons.people_alt_outlined,
            title: 'Separate caregiver profile',
            body:
                'This profile belongs to the person you care for. Their records are kept separate from your own and are not shared with a clinician or service by default.',
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Every health question is optional. SpineUp records what you choose to enter and explains terms; it does not diagnose, predict progression, or prescribe treatment.',
          style: SpineFonts.outfit(
            fontSize: 12,
            height: 1.5,
            color: AppTheme.profileMuted,
          ),
        ),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? helpTopicId;

  const _ConsentRow({
    required this.icon,
    required this.title,
    required this.body,
    this.helpTopicId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.profileSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.profileBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.profileSoftSage,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppTheme.profileSage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: SpineFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.foregroundDark,
                        ),
                      ),
                    ),
                    if (helpTopicId != null)
                      ContextualHelpIcon(
                        topicId: helpTopicId!,
                        tooltip: 'Learn about $title',
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: SpineFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.profileMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
