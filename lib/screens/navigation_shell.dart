import 'package:animations/animations.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/care_subject.dart';
import '../services/external_content_service.dart';
import '../services/session_service.dart';
import '../theme/app_transitions.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/quick_tour.dart';
import 'external_content_screen.dart';
import 'learn_screen.dart';
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
  final _tutorialRegistries = <String, QuickTourTargetRegistry>{};

  QuickTourTargetRegistry _tutorialRegistryFor(String subjectId) {
    return _tutorialRegistries.putIfAbsent(
      subjectId,
      QuickTourTargetRegistry.new,
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_restorePendingContent());
  }

  Future<void> _restorePendingContent() async {
    final item = await ExternalContentService.consumePendingReturn();
    if (!mounted || item == null) return;

    setState(() => _selectedIndex = 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExternalContentDetailPage(item: item),
        ),
      );
    });
  }

  Widget _screenFor(int index, String subjectId) {
    final tutorialRegistry = _tutorialRegistryFor(subjectId);
    return switch (index) {
      0 => TodayScreen(
        key: ValueKey('today-$subjectId'),
        tutorialRegistry: tutorialRegistry,
        onGoToMe: () => _onItemTapped(3),
      ),
      1 => MyJourneyScreen(
        key: ValueKey('journey-$subjectId'),
        tutorialRegistry: tutorialRegistry,
      ),
      2 => LearnScreen(
        key: ValueKey('learn-$subjectId'),
        tutorialRegistry: tutorialRegistry,
      ),
      3 => MeScreen(
        key: ValueKey('me-$subjectId'),
        tutorialRegistry: tutorialRegistry,
        onReplayQuickTour: _replayQuickTour,
      ),
      _ => TodayScreen(
        key: ValueKey('today-$subjectId'),
        tutorialRegistry: tutorialRegistry,
      ),
    };
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  void _replayQuickTour() {
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showPageQuickTourIfNeeded(
        context,
        page: QuickTourPage.today,
        registry: _tutorialRegistryFor(SessionService.currentCareSubjectId),
        force: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: LivingBackground(step: 1)),
          Positioned.fill(
            child: ValueListenableBuilder<CareSubject?>(
              valueListenable: SessionService.activeCareSubjectNotifier,
              builder: (_, subject, _) {
                final subjectId = subject?.id ?? SessionService.currentUserId;
                return PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (child, primaryAnimation, secondaryAnimation) {
                        return AppTransitions.buildTopLevelTransition(
                          context: context,
                          animation: primaryAnimation,
                          secondaryAnimation: secondaryAnimation,
                          child: child,
                        );
                      },
                  child: _screenFor(_selectedIndex, subjectId),
                );
              },
            ),
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
