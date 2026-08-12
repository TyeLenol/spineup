import 'event.dart';

class Milestone {
  final String id;
  final String label;
  final String emoji;
  final int? requiredXp;
  final EventType? requiredEventType;
  final int? requiredEventCount;

  const Milestone({
    required this.id,
    required this.label,
    required this.emoji,
    this.requiredXp,
    this.requiredEventType,
    this.requiredEventCount,
  });
}

const allMilestones = [
  Milestone(
    id: 'first_stretch',
    label: 'First Stretch',
    emoji: '🧘',
    requiredEventType: EventType.stretchCompleted,
    requiredEventCount: 1,
  ),
  Milestone(
    id: 'five_stretches',
    label: '5 Stretches',
    emoji: '🔥',
    requiredEventType: EventType.stretchCompleted,
    requiredEventCount: 5,
  ),
  Milestone(
    id: 'first_cobb',
    label: 'First Cobb Angle',
    emoji: '📐',
    requiredEventType: EventType.angleLogged,
    requiredEventCount: 1,
  ),
  Milestone(
    id: 'first_appointment',
    label: 'First Appointment',
    emoji: '🩺',
    requiredEventType: EventType.appointmentAttended,
    requiredEventCount: 1,
  ),
  Milestone(
    id: 'xp_500',
    label: '500 XP',
    emoji: '⭐',
    requiredXp: 500,
  ),
];
