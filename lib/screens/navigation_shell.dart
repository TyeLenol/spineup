import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../models/care_subject.dart';
import '../services/session_service.dart';
import '../theme/app_transitions.dart';
import '../widgets/glass_nav_bar.dart';
import 'community_screen.dart';
import 'me_screen.dart';
import 'my_journey_screen.dart';
import 'profile_setup/living_background.dart';
import 'today_screen.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    TodayScreen(key: ValueKey(0)),
    MyJourneyScreen(key: ValueKey(1)),
    CommunityScreen(key: ValueKey(2)),
    MeScreen(key: ValueKey(3)),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: LivingBackground(step: 1)),
          Positioned.fill(
            child: PageTransitionSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                return AppTransitions.buildTopLevelTransition(
                  context: context,
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              },
              child: _screens[_selectedIndex],
            ),
          ),
          ValueListenableBuilder<CareSubject?>(
            valueListenable: SessionService.activeCareSubjectNotifier,
            builder: (_, __, ___) => const _ActiveCareSubjectIndicator(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassNavigationBar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCareSubjectIndicator extends StatelessWidget {
  const _ActiveCareSubjectIndicator();

  @override
  Widget build(BuildContext context) {
    final subject = SessionService.activeCareSubject;
    final name = subject?.displayName ?? SessionService.displayName;
    final label = subject?.isWard == true
        ? 'Care profile: $name'
        : 'Profile: $name';

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      right: 16,
      child: IgnorePointer(
        child: Semantics(
          label: 'Active care subject, $label',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
