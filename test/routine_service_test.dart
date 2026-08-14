import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spineup/models/care_subject.dart';
import 'package:spineup/models/routine.dart';
import 'package:spineup/services/routine_service.dart';
import 'package:spineup/services/session_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionService.startMockSession();
  });

  test('catalog exposes starter movements and templates', () {
    expect(RoutineService.catalog, isNotEmpty);
    expect(RoutineService.templates, isNotEmpty);
    expect(
      RoutineService.exercisesForIds(
        RoutineService.templates.first.exerciseIds,
      ),
      isNotEmpty,
    );
  });

  test('active routine persists for the active care subject', () async {
    final saved = const CareSubjectRoutine(
      name: 'Evening movement break',
      exerciseIds: ['cat_cow', 'wall_angels'],
    );
    await RoutineService.saveActiveRoutine(saved);

    final loaded = await RoutineService.loadActiveRoutine();
    expect(loaded.name, saved.name);
    expect(loaded.exerciseIds, saved.exerciseIds);

    final now = DateTime(2026, 8, 14);
    SessionService.setActiveCareSubject(
      CareSubject(
        id: 'ward-001',
        ownerUserId: SessionService.currentUserId,
        type: CareSubjectType.ward,
        displayName: 'Ward',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final wardRoutine = await RoutineService.loadActiveRoutine();
    expect(wardRoutine.name, RoutineService.templates.first.name);
    expect(wardRoutine.exerciseIds, RoutineService.templates.first.exerciseIds);
  });
}
