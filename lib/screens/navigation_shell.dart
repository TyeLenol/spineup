import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../theme/app_transitions.dart';
import 'today_screen.dart';
import 'my_journey_screen.dart';
import 'community_screen.dart';
import 'me_screen.dart';
import '../widgets/glass_nav_bar.dart';
import 'profile_setup/living_background.dart';

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
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to extend behind the floating nav bar
      body: Stack(
        children: [
          // Dynamic mesh background behind all screens
          const Positioned.fill(child: LivingBackground(step: 1)),
          
          // Page transitions
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
          
          // Floating Glass Navigation Bar
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
