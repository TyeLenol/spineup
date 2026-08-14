import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../theme/edge_to_edge_helper.dart';
import 'living_background.dart';

class ProfileShell extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String explainer;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final bool primaryDisabled;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onBack;
  final VoidCallback onClose;
  final Widget child;

  const ProfileShell({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.explainer,
    required this.primaryLabel,
    required this.onPrimaryTap,
    this.primaryDisabled = false,
    this.secondaryLabel,
    this.onSecondaryTap,
    this.onBack,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    EdgeToEdgeHelper.configureSystemUi(context);
    final pct = step / totalSteps;

    return Scaffold(
      backgroundColor: AppTheme.profileCanvas,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: LivingBackground(step: step)),

          // Foreground content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: step > 1 ? onBack : null,
                        icon: const Icon(Icons.arrow_back_rounded, size: 24),
                        color: AppTheme.profileSage,
                        disabledColor: AppTheme.profileMuted.withValues(
                          alpha: 0.35,
                        ),
                      ),

                      // Progress Bar
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'STEP $step OF $totalSteps',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.profileMuted,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Container(
                                height: 5,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.borderCream,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Stack(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 420,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          height: 5,
                                          width: constraints.maxWidth * pct,
                                          decoration: BoxDecoration(
                                            color: AppTheme.profileSage,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Close Button
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded, size: 24),
                        color: AppTheme.profileMuted,
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate.fixed([
                            Text(
                              title,
                              style: GoogleFonts.fraunces(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                letterSpacing: -0.7,
                                color: AppTheme.foregroundDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              explainer,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.profileMuted,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Step specific children
                            child,

                            const SizedBox(height: 32),
                          ]),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton(
                                onPressed: primaryDisabled
                                    ? null
                                    : onPrimaryTap,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.profileSage,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppTheme.profileSage
                                      .withValues(alpha: 0.4),
                                  disabledForegroundColor: Colors.white
                                      .withValues(alpha: 0.7),
                                  minimumSize: const Size.fromHeight(54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  primaryLabel,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (secondaryLabel != null &&
                                  onSecondaryTap != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: onSecondaryTap,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.profileSage,
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    secondaryLabel!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
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
