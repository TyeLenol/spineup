import 'event.dart';

class Milestone {
  final String id;
  final String label;
  final String iconFamily;
  final int tier;
  final int? requiredXp;
  final EventType? requiredEventType;
  final int? requiredEventCount;
  final int? requiredStreakDays;

  const Milestone({
    required this.id,
    required this.label,
    required this.iconFamily,
    required this.tier,
    this.requiredXp,
    this.requiredEventType,
    this.requiredEventCount,
    this.requiredStreakDays,
  });

  String get assetPath => 'assets/images/badges/${iconFamily}_tier$tier.svg';
}

const allMilestones = [
  Milestone(
    id: 'streak_tier1',
    label: '7-Day Streak',
    iconFamily: 'streak',
    tier: 1,
    requiredStreakDays: 7,
  ),
  Milestone(
    id: 'streak_tier2',
    label: '30-Day Streak',
    iconFamily: 'streak',
    tier: 2,
    requiredStreakDays: 30,
  ),
  Milestone(
    id: 'stretch_tier1',
    label: 'First Stretch',
    iconFamily: 'stretch',
    tier: 1,
    requiredEventType: EventType.stretchCompleted,
    requiredEventCount: 1,
  ),
  Milestone(
    id: 'stretch_tier2',
    label: '5 Stretches',
    iconFamily: 'stretch',
    tier: 2,
    requiredEventType: EventType.stretchCompleted,
    requiredEventCount: 5,
  ),
  Milestone(
    id: 'angle_tier1',
    label: 'First Cobb Angle',
    iconFamily: 'angle',
    tier: 1,
    requiredEventType: EventType.angleLogged,
    requiredEventCount: 1,
  ),
  Milestone(
    id: 'angle_tier2',
    label: '3 Cobb Angles',
    iconFamily: 'angle',
    tier: 2,
    requiredEventType: EventType.angleLogged,
    requiredEventCount: 3,
  ),
  Milestone(
    id: 'appointment_tier1',
    label: 'First Appointment',
    iconFamily: 'appointment',
    tier: 1,
    requiredEventType: EventType.appointmentAttended,
    requiredEventCount: 1,
  ),
  Milestone(
    id: 'appointment_tier2',
    label: '3 Appointments',
    iconFamily: 'appointment',
    tier: 2,
    requiredEventType: EventType.appointmentAttended,
    requiredEventCount: 3,
  ),
  Milestone(
    id: 'milestone_tier1',
    label: '500 XP',
    iconFamily: 'milestone',
    tier: 1,
    requiredXp: 500,
  ),
  Milestone(
    id: 'milestone_tier2',
    label: '1000 XP',
    iconFamily: 'milestone',
    tier: 2,
    requiredXp: 1000,
  ),
];
