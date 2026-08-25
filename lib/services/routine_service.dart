import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/routine.dart';
import 'session_service.dart';

class RoutineService {
  RoutineService._();

  static const _routineKeyPrefix = 'spineup_active_routine_';

  static const catalog = <RoutineExercise>[
    RoutineExercise(
      id: 'cat_cow',
      name: 'Cat-Cow Mobilization',
      description: 'Alternating spinal flexion and extension on all fours.',
      durationSeconds: 45,
      icon: Icons.self_improvement_rounded,
      category: 'Mobility',
      equipment: 'No equipment',
      effort: 'Gentle',
      safetyLabel:
          'Move within a comfortable range and stop if you feel pain or become unwell.',
      videoContentId: 'curated-nhs-scoliosis-pilates',
      steps: [
        ExerciseStep(
          stepText:
              'Start on all fours with hands under shoulders and knees beneath hips.',
          durationSeconds: 10,
          cueTags: ['Positioning', 'Neutral spine'],
        ),
        ExerciseStep(
          stepText:
              'Inhale as you arch your back gently, dropping your stomach toward the floor.',
          durationSeconds: 15,
          cueTags: ['Deep inhale', 'Gentle arch'],
        ),
        ExerciseStep(
          stepText:
              'Exhale as you draw your belly button in and round your spine toward the ceiling.',
          durationSeconds: 15,
          cueTags: ['Slow exhale', 'Core activation'],
        ),
        ExerciseStep(
          stepText:
              'Move slowly between both positions for the final few seconds.',
          durationSeconds: 15,
          cueTags: ['Fluid motion', 'Repeat x3'],
        ),
      ],
    ),
    RoutineExercise(
      id: 'side_plank',
      name: 'Side-Plank Core Hold',
      description:
          'Lateral core stabilization with a focus on steady breathing.',
      durationSeconds: 60,
      icon: Icons.fitness_center_rounded,
      category: 'Strength and balance',
      equipment: 'Mat or soft surface',
      effort: 'Moderate',
      safetyLabel:
          'Choose a version that feels manageable. Stop if you feel pain or become unwell.',
      videoContentId: 'curated-youtube-scoliosis-movement',
      steps: [
        ExerciseStep(
          stepText:
              'Lie on your side with your elbow beneath your shoulder and legs straight.',
          durationSeconds: 10,
          cueTags: ['Alignment'],
        ),
        ExerciseStep(
          stepText:
              'Engage gently and lift your hips only as far as feels comfortable.',
          durationSeconds: 25,
          cueTags: ['Core hold', 'Hips level'],
        ),
        ExerciseStep(
          stepText: 'Switch sides and hold steady while breathing deeply.',
          durationSeconds: 25,
          cueTags: ['Switch side', 'Deep breathing'],
        ),
      ],
    ),
    RoutineExercise(
      id: 'hamstring_wall',
      name: 'Hamstring Wall Stretch',
      description: 'A supported leg stretch using a wall or doorway.',
      durationSeconds: 45,
      icon: Icons.airline_seat_flat_angled_rounded,
      category: 'Flexibility',
      equipment: 'Wall or doorway',
      effort: 'Gentle',
      safetyLabel:
          'Keep the stretch gentle and stop if you feel pain or become unwell.',
      videoContentId: 'curated-nhs-scoliosis-pilates',
      steps: [
        ExerciseStep(
          stepText: 'Lie on your back near a doorway or wall corner.',
          durationSeconds: 10,
          cueTags: ['Flat back'],
        ),
        ExerciseStep(
          stepText:
              'Rest one leg vertically against the wall while keeping the other comfortable.',
          durationSeconds: 20,
          cueTags: ['Leg vertical', 'Hold 20 sec'],
        ),
        ExerciseStep(
          stepText: 'Switch sides and breathe slowly.',
          durationSeconds: 20,
          cueTags: ['Switch leg', 'Relax shoulders'],
        ),
      ],
    ),
    RoutineExercise(
      id: 'thoracic_extension',
      name: 'Thoracic Extension',
      description:
          'A supported upper-back movement using a chair or foam roller.',
      durationSeconds: 60,
      icon: Icons.accessibility_new_rounded,
      category: 'Mobility',
      equipment: 'Chair or foam roller',
      effort: 'Gentle',
      safetyLabel:
          'Use a stable surface and keep the movement comfortable. Stop if you feel pain.',
      videoContentId: 'curated-youtube-scoliosis-movement',
      steps: [
        ExerciseStep(
          stepText:
              'Sit upright in a firm chair or place a foam roller under your mid-back.',
          durationSeconds: 10,
          cueTags: ['Seated upright'],
        ),
        ExerciseStep(
          stepText: 'Support your head gently with your hands if needed.',
          durationSeconds: 15,
          cueTags: ['Neck support'],
        ),
        ExerciseStep(
          stepText:
              'Lean back over the chair or roller only within a comfortable range.',
          durationSeconds: 35,
          cueTags: ['Open chest', 'Breathe deeply'],
        ),
      ],
    ),
    RoutineExercise(
      id: 'bird_dog',
      name: 'Bird-Dog Core Balance',
      description:
          'Opposite arm and leg extension for balance and body awareness.',
      durationSeconds: 45,
      icon: Icons.sports_gymnastics_rounded,
      category: 'Strength and balance',
      equipment: 'No equipment',
      effort: 'Gentle',
      safetyLabel:
          'Move slowly and keep a stable support underneath you. Stop if you feel pain.',
      videoContentId: 'curated-youtube-scoliosis-movement',
      steps: [
        ExerciseStep(
          stepText:
              'Begin on hands and knees with a comfortable neutral position.',
          durationSeconds: 10,
          cueTags: ['Quadruped'],
        ),
        ExerciseStep(
          stepText:
              'Reach one arm forward and the opposite leg back if comfortable.',
          durationSeconds: 20,
          cueTags: ['Opposite reach', 'Hold 3 sec'],
        ),
        ExerciseStep(
          stepText: 'Return to the start and alternate sides.',
          durationSeconds: 15,
          cueTags: ['Alternate sides', 'Keep hips steady'],
        ),
      ],
    ),
    RoutineExercise(
      id: 'pelvic_tilt',
      name: 'Pelvic Tilt and Bridge',
      description: 'A supported floor movement for gentle body awareness.',
      durationSeconds: 60,
      icon: Icons.unfold_more_rounded,
      category: 'Strength and balance',
      equipment: 'Mat or soft surface',
      effort: 'Gentle',
      safetyLabel:
          'Use a comfortable range and stop if you feel pain or become unwell.',
      videoContentId: 'curated-youtube-scoliosis-movement',
      steps: [
        ExerciseStep(
          stepText: 'Lie on your back with knees bent and feet supported.',
          durationSeconds: 10,
          cueTags: ['Supported position'],
        ),
        ExerciseStep(
          stepText:
              'Gently notice your lower back and engage only as much as feels comfortable.',
          durationSeconds: 20,
          cueTags: ['Slow movement', 'Breathe'],
        ),
        ExerciseStep(
          stepText:
              'Lift your hips only if that feels comfortable, then lower slowly.',
          durationSeconds: 30,
          cueTags: ['Supported bridge', 'Hold 5 sec'],
        ),
      ],
    ),
    RoutineExercise(
      id: 'childs_pose',
      name: 'Child’s Pose and Side Reach',
      description: 'A gentle supported position with optional side reach.',
      durationSeconds: 45,
      icon: Icons.nightlight_round,
      category: 'Flexibility',
      equipment: 'Mat or soft surface',
      effort: 'Gentle',
      safetyLabel:
          'Use cushions or skip the movement if the position is uncomfortable.',
      videoContentId: 'curated-nhs-scoliosis-pilates',
      steps: [
        ExerciseStep(
          stepText:
              'Kneel or choose a supported seated position that feels comfortable.',
          durationSeconds: 10,
          cueTags: ['Support yourself'],
        ),
        ExerciseStep(
          stepText:
              'Fold forward only as far as feels comfortable, or stay upright.',
          durationSeconds: 20,
          cueTags: ['Reach forward'],
        ),
        ExerciseStep(
          stepText:
              'Walk your hands slightly to one side if that feels comfortable.',
          durationSeconds: 15,
          cueTags: ['Optional side reach', 'Breathe'],
        ),
      ],
    ),
    RoutineExercise(
      id: 'wall_angels',
      name: 'Wall Angels',
      description:
          'A supported wall movement for posture awareness and mobility.',
      durationSeconds: 60,
      icon: Icons.auto_awesome_rounded,
      category: 'Posture awareness',
      equipment: 'Wall',
      effort: 'Gentle',
      safetyLabel:
          'Keep the movement small and comfortable. Stop if you feel pain or become unwell.',
      videoContentId: 'curated-youtube-scoliosis-movement',
      steps: [
        ExerciseStep(
          stepText: 'Stand near a smooth wall with a stable stance.',
          durationSeconds: 10,
          cueTags: ['Posture reset'],
        ),
        ExerciseStep(
          stepText: 'Raise your arms only as far as feels comfortable.',
          durationSeconds: 25,
          cueTags: ['Easy range', 'Breathe'],
        ),
        ExerciseStep(
          stepText:
              'Slide your arms slowly while keeping your shoulders relaxed.',
          durationSeconds: 25,
          cueTags: ['Slow slide', 'Repeat 5x'],
        ),
      ],
    ),
  ];

  static const templates = <RoutineTemplate>[
    RoutineTemplate(
      id: 'gentle_reset',
      name: 'Gentle movement reset',
      description: 'A short selection of low-intensity movements to explore.',
      exerciseIds: ['cat_cow', 'hamstring_wall', 'wall_angels'],
      referenceVideoId: 'curated-nhs-scoliosis-pilates',
    ),
    RoutineTemplate(
      id: 'posture_break',
      name: 'Short posture break',
      description: 'A brief mix of mobility and posture-awareness movements.',
      exerciseIds: ['cat_cow', 'thoracic_extension', 'wall_angels'],
      referenceVideoId: 'curated-youtube-scoliosis-movement',
    ),
    RoutineTemplate(
      id: 'balance_basics',
      name: 'Core and balance basics',
      description: 'A balanced starter set with supported movement options.',
      exerciseIds: ['bird_dog', 'pelvic_tilt', 'side_plank'],
      referenceVideoId: 'curated-youtube-scoliosis-movement',
    ),
  ];

  static final _byId = {for (final exercise in catalog) exercise.id: exercise};

  static RoutineExercise? findExercise(String id) => _byId[id];

  static List<RoutineExercise> exercisesForIds(Iterable<String> ids) {
    return ids.map(findExercise).whereType<RoutineExercise>().toList();
  }

  static String _scopedKey() =>
      '$_routineKeyPrefix${SessionService.currentUserId}_${SessionService.currentCareSubjectId}';

  static Future<CareSubjectRoutine> loadActiveRoutine() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scopedKey());
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final ids = (json['exerciseIds'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .where(_byId.containsKey)
            .toList();
        if (ids.isNotEmpty) {
          return CareSubjectRoutine(
            name: json['name'] as String? ?? 'My Routine',
            exerciseIds: ids,
          );
        }
      } catch (_) {
        // Recreate a safe starter routine below when old local data is malformed.
      }
    }
    final starter = templates.first;
    final routine = CareSubjectRoutine(
      name: starter.name,
      exerciseIds: starter.exerciseIds,
    );
    await saveActiveRoutine(routine);
    return routine;
  }

  static Future<void> saveActiveRoutine(CareSubjectRoutine routine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scopedKey(),
      jsonEncode({'name': routine.name, 'exerciseIds': routine.exerciseIds}),
    );
  }
}
