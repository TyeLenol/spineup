import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart';
import '../../models/event.dart';
import '../../models/profile_data.dart';
import '../../services/gamification_service.dart';
import '../../services/profile_mapper.dart';
import '../../services/profile_store.dart';
import '../../services/session_service.dart';
import '../auth_screen.dart';
import 'profile_shell.dart';
import 'steps/step_basics.dart';
import 'steps/step_care.dart';
import 'steps/step_consent.dart';
import 'steps/step_curve.dart';
import 'steps/step_goals.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _step = 1;
  ProfileData _data = const ProfileData();
  bool _stepValid = true;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final data = await ProfileStore.loadProfile(
      userId: SessionService.currentUserId,
    );
    if (mounted) {
      setState(() {
        _data = data;
      });
    }
  }

  void _nextStep() {
    if (_finishing) return;
    if (_step < 5) {
      setState(() {
        _step++;
        _stepValid = false;
      });
    } else {
      unawaited(_finish());
    }
  }

  void _prevStep() {
    if (_step > 1 && !_finishing) {
      setState(() {
        _step--;
        _stepValid = true;
      });
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    try {
      final userId = SessionService.currentUserId;
      final runtimeProfile = ProfileMapper.toRuntimeProfile(_data);

      await ProfileStore.saveProfile(
        userId: userId,
        data: _data,
      );
      final gamification = GamificationService();
      await gamification.updateProfile(
        userId: userId,
        presetId: runtimeProfile.presetId,
        customPhotoPath: runtimeProfile.customPhotoPath,
        name: runtimeProfile.name,
        diagnosis: runtimeProfile.diagnosis,
        braceStatus: runtimeProfile.braceStatus,
        ageRange: runtimeProfile.ageRange,
      );

      final hasCompletionEvent = (await gamification.getAllEvents(userId))
          .any((event) => event.type == EventType.profileCompleted);
      if (!hasCompletionEvent) {
        await gamification.logEvent(
          eventId: const Uuid().v4(),
          userId: userId,
          type: EventType.profileCompleted,
          includeDailyBonus: false,
          payload: {
            'goals': _data.goals.map((goal) => goal.name).toList(),
            'completed_at': DateTime.now().toIso8601String(),
          },
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        mainAppRoute(),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    String title = '';
    String explainer = '';
    String primaryLabel = 'Continue';
    VoidCallback onPrimaryTap = _nextStep;
    String? secondaryLabel;
    VoidCallback? onSecondaryTap;

    switch (_step) {
      case 1:
        title = 'Your data, your body, your rules.';
        explainer = 'Health info is sensitive. Everything you enter stays on this device by default. You choose what — if anything — to share.';
        child = StepConsent(
          initialData: _data,
          onSave: (d) => _data = d,
          onNext: _nextStep,
        );
        _stepValid = true;
        break;
      case 2:
        title = 'Nice to meet you.';
        explainer = 'Just the essentials so Spry can tailor your journey. Sex-at-birth is optional — it only affects progression-risk insights.';
        child = StepBasics(
          initialData: _data,
          onSave: (d) => _data = d,
          onValidityChanged: (valid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _stepValid != valid) {
                setState(() => _stepValid = valid);
              }
            });
          },
        );
        break;
      case 3:
        title = 'Curve details.';
        explainer = 'Only fill what you know from your last clinic visit. If you don\'t have your X-ray report handy, skip — you can add these later.';
        secondaryLabel = 'I don\'t have this info';
        onSecondaryTap = _nextStep;
        child = StepCurve(
          initialData: _data,
          onSave: (d) => _data = d,
        );
        _stepValid = true;
        break;
      case 4:
        title = 'Your care routine.';
        explainer = 'A quick snapshot of your brace and physio — we\'ll use it to shape your daily quests and reminders.';
        secondaryLabel = 'Skip';
        onSecondaryTap = _nextStep;
        child = StepCare(
          initialData: _data,
          onSave: (d) => _data = d,
          onValidityChanged: (valid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _stepValid != valid) {
                setState(() => _stepValid = valid);
              }
            });
          },
        );
        break;
      case 5:
        title = 'Pick your quests.';
        explainer = 'What matters to you right now? Pick at least one — this shapes your daily quests, XP goals, and home screen.';
        primaryLabel = _finishing ? 'Saving profile…' : 'Complete profile · +250 XP';
        child = StepGoals(
          initialData: _data,
          onSave: (d) => _data = d,
          onValidityChanged: (valid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _stepValid != valid) {
                setState(() => _stepValid = valid);
              }
            });
          },
        );
        break;
      default:
        child = const SizedBox.shrink();
    }

    return ProfileShell(
      step: _step,
      totalSteps: 5,
      title: title,
      explainer: explainer,
      primaryLabel: primaryLabel,
      primaryDisabled: !_stepValid || _finishing,
      onPrimaryTap: onPrimaryTap,
      secondaryLabel: secondaryLabel,
      onSecondaryTap: _finishing ? null : onSecondaryTap,
      onBack: _finishing ? null : _prevStep,
      onClose: () => Navigator.of(context).pushAndRemoveUntil(
        authRoute(AuthMode.signup),
        (route) => false,
      ),
      child: child,
    );
  }
}
