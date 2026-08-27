import 'package:flutter/material.dart';
import '../theme/spine_fonts.dart';

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
                'A gentle place to begin',
                style: SpineFonts.outfit(
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
                            'assets/onboarding/onboarding_keep_your_path_close.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Make room for\ncare.',
                        style: SpineFonts.fraunces(
                          color: AppTheme.foregroundDark,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Set up a space for yourself or someone you care for. Keep the small things together from the start—check-ins, routines, and questions.',
                        style: SpineFonts.outfit(
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
                  backgroundColor: AppTheme.profileAction,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: SpineFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Set up my space'),
              ),
              const SizedBox(height: 10),
              Text(
                'Your records stay on this phone unless you choose to export a protected copy.',
                textAlign: TextAlign.center,
                style: SpineFonts.outfit(
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
