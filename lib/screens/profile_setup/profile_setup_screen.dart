import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/database_helper.dart';
import '../../main.dart';
import '../../models/event.dart';
import '../../models/profile_data.dart';
import '../../models/user_profile.dart';
import '../../services/gamification_service.dart';
import '../../services/profile_mapper.dart';
import '../../services/profile_store.dart';
import '../../services/session_service.dart';
import '../avatar_studio_screen.dart';
import '../../theme/app_theme.dart';
import 'profile_shell.dart';
import 'steps/step_basics.dart';
import 'steps/step_care.dart';
import 'steps/step_consent.dart';
import 'steps/step_curve.dart';
import 'steps/step_goals.dart';
import 'steps/step_ownership.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool createNewWard;
  final bool editExisting;

  const ProfileSetupScreen({
    super.key,
    this.createNewWard = false,
    this.editExisting = false,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _step = 1;
  ProfileData _data = const ProfileData();
  bool _stepValid = true;
  bool _finishing = false;
  bool _initialDataReady = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final data = widget.createNewWard
        ? const ProfileData(
            ownership: ProfileOwnership(subjectType: CareSubjectType.ward),
          )
        : await ProfileStore.loadProfile(
            userId: SessionService.currentUserId,
            careSubjectId: SessionService.currentCareSubjectId,
          );
    if (mounted) {
      setState(() {
        _data = data;
        _initialDataReady = true;
      });
    }
  }

  void _nextStep() {
    if (_finishing) return;
    if (_step < 6) {
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

  void _saveOwnership(ProfileData data) {
    final changedToWard =
        _data.ownership.subjectType != data.ownership.subjectType &&
        data.ownership.isWard;

    // A ward must never inherit a caregiver's locally saved health profile.
    // Retain only the explicit ownership selection when the flow switches mode.
    setState(() {
      _data = changedToWard ? ProfileData(ownership: data.ownership) : data;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    try {
      final ownerUserId = SessionService.currentUserId;
      final existingSubject = widget.createNewWard
          ? null
          : SessionService.activeCareSubject;
      final careSubjectId =
          existingSubject?.id ??
          (_data.ownership.isSelf ? ownerUserId : const Uuid().v4());
      final careSubject = ProfileMapper.toCareSubject(
        id: careSubjectId,
        ownerUserId: ownerUserId,
        data: _data,
        existing: existingSubject,
      );
      final gamification = GamificationService();
      final existingRuntime = widget.editExisting
          ? (await gamification.getSnapshot(careSubjectId)).userProfile
          : const UserProfile(
              presetId: 'preset_sun',
              name: 'You',
              diagnosis: 'Not added',
              braceStatus: 'Not added',
              ageRange: 'Not added',
            );
      final runtimeProfile = ProfileMapper.toRuntimeProfile(
        _data,
        fallback: existingRuntime,
      );

      await DatabaseHelper().upsertCareSubject(careSubject);
      await ProfileStore.saveProfile(
        userId: ownerUserId,
        careSubjectId: careSubject.id,
        data: _data,
      );

      await gamification.updateProfile(
        userId: careSubject.id,
        presetId: runtimeProfile.presetId,
        customPhotoPath: runtimeProfile.customPhotoPath,
        name: runtimeProfile.name,
        diagnosis: runtimeProfile.diagnosis,
        braceStatus: runtimeProfile.braceStatus,
        ageRange: runtimeProfile.ageRange,
        avatarStyleId: runtimeProfile.avatarStyleId,
        avatarOptions: runtimeProfile.avatarOptions,
        avatarSeed: runtimeProfile.avatarSeed,
        avatarMode: runtimeProfile.avatarMode,
      );

      final hasCompletionEvent = (await gamification.getAllEvents(
        careSubject.id,
      )).any((event) => event.type == EventType.profileCompleted);
      if (!hasCompletionEvent) {
        await gamification.logEvent(
          eventId: const Uuid().v4(),
          userId: careSubject.id,
          type: EventType.profileCompleted,
          includeDailyBonus: false,
          payload: {
            'goals': _data.goals.map((goal) => goal.name).toList(),
            'completed_at': DateTime.now().toIso8601String(),
          },
        );
      }
      SessionService.setActiveCareSubject(careSubject);

      if (!widget.editExisting && mounted) {
        final chooseAvatarNow = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Make this care space yours'),
            content: const Text(
              'Choose a local avatar now, or keep the default and do it later from Me.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Do this later'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Choose an avatar'),
              ),
            ],
          ),
        );
        if (chooseAvatarNow == true && mounted) {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AvatarStudioScreen(
                userId: careSubject.id,
                profile: runtimeProfile,
                gamificationService: gamification,
              ),
            ),
          );
        }
      }

      if (!mounted) return;
      if (widget.createNewWard || widget.editExisting) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(
          context,
        ).pushAndRemoveUntil(mainAppRoute(), (route) => false);
      }
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
    final isWard = _data.ownership.isWard;

    if (widget.editExisting && !_initialDataReady) {
      return const Scaffold(
        backgroundColor: AppTheme.profileCanvas,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_step) {
      case 1:
        title = widget.editExisting
            ? 'Update this care space.'
            : widget.createNewWard
            ? 'A private space for them.'
            : 'Start with a private space.';
        explainer = widget.editExisting
            ? 'Review the details saved for this care space. The person and ownership stay the same.'
            : widget.createNewWard
            ? 'Create a separate local workspace for another person. Your own profile will not be changed.'
            : 'First, choose whose information you are setting up. Each person’s records stay in their own private workspace.';
        child = StepOwnership(
          initialData: _data,
          allowSelf: !widget.createNewWard,
          lockedSubjectType: widget.editExisting
              ? _data.ownership.subjectType
              : null,
          onSave: _saveOwnership,
          onValidityChanged: (valid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _stepValid != valid) {
                setState(() => _stepValid = valid);
              }
            });
          },
        );
        break;
      case 2:
        title = 'Your data, your body, your rules.';
        explainer = isWard
            ? 'You are creating a separate local profile for someone you care for. We explain what stays on this device and what you can export or delete.'
            : 'Health information is sensitive. We explain what stays on this device and what you can export or delete.';
        child = StepConsent(
          initialData: _data,
          onSave: (data) => _data = data,
          isCaregiverMode: isWard,
        );
        _stepValid = true;
        break;
      case 3:
        title = isWard ? 'Nice to meet them.' : 'Nice to meet you.';
        explainer = isWard
            ? 'Add only the essentials you know. Sex assigned at birth is optional and can be skipped.'
            : 'Add only the essentials you are comfortable sharing. Sex assigned at birth is optional and can be skipped.';
        child = StepBasics(
          initialData: _data,
          isCaregiverMode: isWard,
          onSave: (data) => _data = data,
          onValidityChanged: (valid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _stepValid != valid) {
                setState(() => _stepValid = valid);
              }
            });
          },
        );
        break;
      case 4:
        title = isWard ? 'Their curve details.' : 'Curve details.';
        explainer =
            'Only fill in what you know from a clinic visit or report. If you do not have it handy, skip it and add it later.';
        secondaryLabel = 'I don\'t have this info';
        onSecondaryTap = _nextStep;
        child = StepCurve(
          initialData: _data,
          onSave: (data) => _data = data,
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
        title = isWard ? 'Their care routine.' : 'Your care routine.';
        explainer =
            'A quick snapshot of brace and physiotherapy information. You can change it later; it does not replace a clinician’s plan.';
        secondaryLabel = 'Skip';
        onSecondaryTap = _nextStep;
        child = StepCare(
          initialData: _data,
          onSave: (data) => _data = data,
          onValidityChanged: (valid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _stepValid != valid) {
                setState(() => _stepValid = valid);
              }
            });
          },
        );
        break;
      case 6:
        title = isWard ? 'Pick their goals.' : 'Pick your goals.';
        explainer = isWard
            ? 'Choose what would be helpful to track together. These shape reminders and app activities, not a treatment plan.'
            : 'Choose what would be helpful to track. These shape reminders and app activities, not a treatment plan.';
        primaryLabel = _finishing
            ? 'Saving profile…'
            : widget.editExisting
            ? 'Save changes'
            : 'Finish setting up your profile';
        child = StepGoals(
          initialData: _data,
          onSave: (data) => _data = data,
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
      totalSteps: 6,
      title: title,
      explainer: explainer,
      primaryLabel: primaryLabel,
      primaryDisabled: !_stepValid || _finishing,
      onPrimaryTap: onPrimaryTap,
      secondaryLabel: secondaryLabel,
      onSecondaryTap: _finishing ? null : onSecondaryTap,
      onBack: _finishing ? null : _prevStep,
      onClose: () {
        if (widget.createNewWard || widget.editExisting) {
          Navigator.of(context).pop(false);
        } else {
          Navigator.of(
            context,
          ).pushAndRemoveUntil(localFirstWelcomeRoute(), (route) => false);
        }
      },
      child: child,
    );
  }
}
