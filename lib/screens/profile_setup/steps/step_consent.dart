import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/profile_data.dart';
import '../../../theme/app_theme.dart';

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
              'Your profile is stored locally on this phone. SpineUp does not use analytics, and cloud backup is not enabled in this prototype.',
        ),
        const SizedBox(height: 12),
        const _ConsentRow(
          icon: Icons.folder_shared_outlined,
          title: 'Your data should be portable',
          body:
              'Before release, protected export and import will let you move a human-readable copy to a new phone. Import will show a preview and ask before changing anything.',
        ),
        const SizedBox(height: 12),
        _ConsentRow(
          icon: Icons.delete_outline_rounded,
          title: 'Deletion scope',
          body:
              'You can edit your information later. In this prototype, the Settings deletion action removes all local data for this app session; subject-only deletion will be added before caregiver release.',
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
          'Every health question in setup is optional. SpineUp records what you choose to enter and explains terms; it does not diagnose, predict progression, or prescribe treatment.',
          style: GoogleFonts.outfit(
            fontSize: 11,
            height: 1.5,
            color: AppTheme.mutedForeground,
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

  const _ConsentRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderCream, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primarySage.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppTheme.primarySage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foregroundDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.mutedForeground,
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
