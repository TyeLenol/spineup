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
              const SizedBox(height: 6),
              Text(
                'Before you begin',
                style: GoogleFonts.outfit(
                  color: AppTheme.profileMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 340,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/onboarding/onboarding_data_stays_yours_textured.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Build your\ncare space.',
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
                        'Set up a profile for yourself or someone you care for. You can keep simple records, routines, and questions together from the start.',
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
                child: const Text('Set up a profile'),
              ),
              const SizedBox(height: 10),
              Text(
                'Your records stay on this phone unless you choose to export a protected copy.',
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
