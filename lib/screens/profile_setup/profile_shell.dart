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
      backgroundColor: AppTheme.backgroundCream,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background
          Positioned.fill(child: LivingBackground(step: step)),
          
          // Foreground Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: step > 1 ? onBack : null,
                        icon: const Icon(Icons.arrow_back_rounded, size: 24),
                        color: AppTheme.foregroundDark,
                        disabledColor: AppTheme.foregroundDark.withValues(alpha: 0.3),
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.mutedForeground,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 6,
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
                                          duration: const Duration(milliseconds: 500),
                                          curve: Curves.easeOutCubic,
                                          height: 6,
                                          width: constraints.maxWidth * pct,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primarySage,
                                            borderRadius: BorderRadius.circular(3),
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
                        color: AppTheme.mutedForeground,
                      ),
                    ],
                  ),
                ),
                
                // Body
                Expanded(
                  child: CustomScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 16),
                        sliver: SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          Text(
                            title,
                            style: GoogleFonts.fraunces(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                              letterSpacing: -0.5,
                              color: AppTheme.foregroundDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            explainer,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.mutedForeground,
                              height: 1.4,
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
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton(
                                onPressed: primaryDisabled ? null : onPrimaryTap,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primarySage,
                                  foregroundColor: AppTheme.onPrimaryDark,
                                  disabledBackgroundColor: AppTheme.primarySage.withValues(alpha: 0.4),
                                  disabledForegroundColor: AppTheme.onPrimaryDark.withValues(alpha: 0.4),
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
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
                              if (secondaryLabel != null && onSecondaryTap != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: onSecondaryTap,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.mutedForeground,
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                  child: Text(
                                    secondaryLabel!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
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
