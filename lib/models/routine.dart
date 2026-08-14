import 'package:flutter/material.dart';

class ExerciseStep {
  final String stepText;
  final int? durationSeconds;
  final List<String> cueTags;

  const ExerciseStep({
    required this.stepText,
    this.durationSeconds,
    this.cueTags = const [],
  });
}

class RoutineExercise {
  final String id;
  final String name;
  final String description;
  final int durationSeconds;
  final IconData icon;
  final String category;
  final String equipment;
  final String effort;
  final String safetyLabel;
  final String? videoContentId;
  final List<ExerciseStep> steps;

  const RoutineExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.durationSeconds,
    required this.icon,
    required this.category,
    required this.equipment,
    required this.effort,
    required this.safetyLabel,
    this.videoContentId,
    required this.steps,
  });

  String get durationLabel {
    if (durationSeconds < 60) return '$durationSeconds sec';
    final minutes = durationSeconds ~/ 60;
    return '$minutes min';
  }
}

class RoutineTemplate {
  final String id;
  final String name;
  final String description;
  final List<String> exerciseIds;
  final String? referenceVideoId;

  const RoutineTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.exerciseIds,
    this.referenceVideoId,
  });
}

class CareSubjectRoutine {
  final String name;
  final List<String> exerciseIds;

  const CareSubjectRoutine({required this.name, required this.exerciseIds});

  CareSubjectRoutine copyWith({String? name, List<String>? exerciseIds}) {
    return CareSubjectRoutine(
      name: name ?? this.name,
      exerciseIds: exerciseIds ?? this.exerciseIds,
    );
  }
}
