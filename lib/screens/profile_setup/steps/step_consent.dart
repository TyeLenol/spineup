import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/profile_data.dart';
import '../../../theme/app_theme.dart';

class StepConsent extends StatefulWidget {
  final ProfileData initialData;
  final ValueChanged<ProfileData> onSave;
  final VoidCallback onNext;

  const StepConsent({super.key, required this.initialData, required this.onSave, required this.onNext});

  @override
  State<StepConsent> createState() => _StepConsentState();
}

class _StepConsentState extends State<StepConsent> {
  late bool analytics;

  @override
  void initState() {
    super.initState();
    analytics = widget.initialData.consent.analytics;
  }

  void _accept() {
    widget.onSave(widget.initialData.copyWith(
      consent: ProfileConsent(
        onDevice: true,
        analytics: analytics,
        acceptedAt: DateTime.now(),
      ),
    ));
  }

  @override
  void didUpdateWidget(covariant StepConsent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Whenever parent saves (e.g. going to next step), we trigger save
    _accept();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConsentRow(
          icon: Icons.security_rounded,
          title: 'On-device by default',
          body: 'Your profile lives in local storage on this phone. No account, no cloud, unless you turn it on later.',
          locked: true,
        ),
        const SizedBox(height: 12),
        _ConsentRow(
          icon: Icons.cloud_rounded,
          title: 'Cloud sync',
          body: 'Off. Enable later in Settings if you want to sync across devices.',
          locked: true,
        ),
        const SizedBox(height: 12),
        _ConsentRow(
          icon: Icons.bar_chart_rounded,
          title: 'Anonymous usage analytics',
          body: 'Help us improve SpineUp with anonymised, non-medical usage data.',
          toggleValue: analytics,
          onToggle: (v) => setState(() => analytics = v),
        ),
        const SizedBox(height: 16),
        Text(
          'Every clinical question in setup is optional. You can skip anything, edit later, and delete your profile any time from Settings.',
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
  final bool locked;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;

  const _ConsentRow({
    required this.icon,
    required this.title,
    required this.body,
    this.locked = false,
    this.toggleValue,
    this.onToggle,
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
          if (locked) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: Text(
                'DEFAULT',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primarySage,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
          if (toggleValue != null && onToggle != null) ...[
            const SizedBox(width: 8),
            Transform.scale(
              scale: 0.85,
              child: CupertinoSwitch(
                value: toggleValue!,
                onChanged: onToggle,
                activeTrackColor: AppTheme.primarySage,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
