import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/edge_to_edge_helper.dart';

class LocalFirstWelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;

  const LocalFirstWelcomeScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    EdgeToEdgeHelper.configureSystemUi(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.profileCanvas,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 18, 24, 20 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SPINEUP',
                    style: GoogleFonts.outfit(
                      color: AppTheme.profileSage,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.profileSoftSage,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Private by default',
                      style: GoogleFonts.outfit(
                        color: AppTheme.profileSage,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 330,
                        child: Image.asset(
                          'assets/onboarding/onboarding_data_stays_yours.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Start with\nprivacy.',
                        style: GoogleFonts.fraunces(
                          color: AppTheme.foregroundDark,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Set up a private care profile for you or someone you care for. No account is required to begin.',
                        style: GoogleFonts.outfit(
                          color: AppTheme.profileMuted,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.profileSage,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Start privately'),
              ),
              const SizedBox(height: 10),
              Text(
                'Your data stays on this phone by default. You can export a protected copy later.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: AppTheme.profileMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
