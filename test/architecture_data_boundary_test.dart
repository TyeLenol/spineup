import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:spineup/data/database_helper.dart';
import 'package:spineup/models/appointment.dart';
import 'package:spineup/models/care_subject.dart';
import 'package:spineup/models/event.dart';
import 'package:spineup/models/profile_data.dart';
import 'package:spineup/services/gamification_service.dart';
import 'package:spineup/services/profile_mapper.dart';
import 'package:spineup/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DatabaseHelper dbHelper;
  const uuid = Uuid();
  const userId = 'user-a';
  const otherUserId = 'user-b';

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE events (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              type TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              payload TEXT NOT NULL,
              xp_value INTEGER NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE user_profiles (
              user_id TEXT PRIMARY KEY,
              preset_id TEXT NOT NULL,
              custom_photo_path TEXT,
              name TEXT,
              diagnosis TEXT,
              brace_status TEXT,
              age_range TEXT
            )
          ''');
          await database.execute('''
            CREATE TABLE appointments (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              title TEXT NOT NULL,
              scheduled_datetime TEXT NOT NULL,
              notes TEXT,
              status TEXT NOT NULL,
              completed_event_id TEXT
            )
          ''');
        },
      ),
    );
    dbHelper = DatabaseHelper(database: db);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('clearUserData deletes only the active user records', () async {
    await dbHelper.insertEvent(
      Event(
        id: uuid.v4(),
        userId: userId,
        type: EventType.journalEntry,
        timestamp: DateTime.now(),
        payload: {'notes': 'private'},
        xpValue: 25,
      ),
    );
    await dbHelper.insertEvent(
      Event(
        id: uuid.v4(),
        userId: otherUserId,
        type: EventType.journalEntry,
        timestamp: DateTime.now(),
        payload: {'notes': 'keep'},
        xpValue: 25,
      ),
    );

    await db.insert('user_profiles', {
      'user_id': userId,
      'preset_id': 'preset_sun',
    });
    await db.insert('user_profiles', {
      'user_id': otherUserId,
      'preset_id': 'preset_leaf',
    });

    await dbHelper.clearUserData(userId);

    expect(await dbHelper.getEventsByUser(userId), isEmpty);
    expect(await dbHelper.getEventsByUser(otherUserId), hasLength(1));
    expect(
      await db.query(
        'user_profiles',
        where: 'user_id = ?',
        whereArgs: [userId],
      ),
      isEmpty,
    );
    expect(
      await db.query(
        'user_profiles',
        where: 'user_id = ?',
        whereArgs: [otherUserId],
      ),
      hasLength(1),
    );
  });

  test(
    'updating a journal entry preserves its event and XP identity',
    () async {
      final service = GamificationService(db: dbHelper);
      final result = await service.logEvent(
        eventId: uuid.v4(),
        userId: userId,
        type: EventType.journalEntry,
        payload: {'notes': 'original'},
      );
      expect(result.xpAwarded, greaterThan(0));

      final initialEvents = await dbHelper.getJournalEvents(userId);
      expect(initialEvents, hasLength(1));
      final original = initialEvents.single;

      await service.updateJournalEntry(
        eventId: original.id,
        userId: userId,
        payload: {'notes': 'updated'},
      );

      final updatedEvents = await dbHelper.getJournalEvents(userId);
      expect(updatedEvents, hasLength(1));
      expect(updatedEvents.single.id, original.id);
      expect(updatedEvents.single.xpValue, original.xpValue);
      expect(updatedEvents.single.payload['notes'], 'updated');
    },
  );

  test('profile completion is recorded without awarding starter XP', () async {
    final service = GamificationService(db: dbHelper);
    final result = await service.logEvent(
      eventId: uuid.v4(),
      userId: userId,
      type: EventType.profileCompleted,
      includeDailyBonus: false,
      payload: {
        'goals': ['reducePain'],
      },
    );

    expect(result.xpAwarded, 0);
    expect(result.dailyBonusAwarded, isFalse);
    expect((await service.getSnapshot(userId)).totalXp, 0);
    expect((await service.getSnapshot(userId)).currentLevel, 1);
  });

  test(
    'completing an appointment twice is rejected without a second event',
    () async {
      final service = GamificationService(db: dbHelper);
      final appointment = Appointment(
        id: uuid.v4(),
        userId: userId,
        title: 'Spine clinic',
        scheduledDateTime: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      await dbHelper.insertAppointment(appointment);

      await service.completeAppointment(
        appointmentId: appointment.id,
        userId: userId,
      );
      expect(
        await dbHelper.getEventsByUserAndType(
          userId,
          EventType.appointmentAttended,
        ),
        hasLength(1),
      );

      await expectLater(
        service.completeAppointment(
          appointmentId: appointment.id,
          userId: userId,
        ),
        throwsStateError,
      );
      expect(
        await dbHelper.getEventsByUserAndType(
          userId,
          EventType.appointmentAttended,
        ),
        hasLength(1),
      );
    },
  );

  test('profile mapper produces one runtime summary from onboarding data', () {
    const data = ProfileData(
      basics: ProfileBasics(displayName: 'Morgan', dob: '2010-01-01'),
      curve: ProfileCurve(curveType: CurveType.doubleS),
      brace: ProfileBrace(wears: false),
    );

    final runtime = ProfileMapper.toRuntimeProfile(data);

    expect(runtime.name, 'Morgan');
    expect(runtime.diagnosis, 'Double Major');
    expect(runtime.braceStatus, 'No');
    expect(runtime.ageRange, '13-17');
  });

  test(
    'care subjects remain owner-bound and delete only their own records',
    () async {
      await db.execute('''
      CREATE TABLE care_subjects (
        id TEXT PRIMARY KEY,
        owner_user_id TEXT NOT NULL,
        subject_type TEXT NOT NULL,
        display_name TEXT NOT NULL,
        relationship TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

      final now = DateTime(2026, 8, 12);
      final firstSubject = CareSubject(
        id: 'subject-one',
        ownerUserId: userId,
        type: CareSubjectType.ward,
        displayName: 'Ama',
        relationship: 'Parent',
        createdAt: now,
        updatedAt: now,
      );
      final secondSubject = CareSubject(
        id: 'subject-two',
        ownerUserId: userId,
        type: CareSubjectType.ward,
        displayName: 'Kojo',
        relationship: 'Parent',
        createdAt: now,
        updatedAt: now,
      );
      final otherOwnerSubject = CareSubject(
        id: 'subject-other-owner',
        ownerUserId: otherUserId,
        type: CareSubjectType.self,
        displayName: 'Other user',
        createdAt: now,
        updatedAt: now,
      );

      await dbHelper.upsertCareSubject(firstSubject);
      await dbHelper.upsertCareSubject(secondSubject);
      await dbHelper.upsertCareSubject(otherOwnerSubject);
      await dbHelper.insertEvent(
        Event(
          id: uuid.v4(),
          userId: firstSubject.id,
          type: EventType.journalEntry,
          timestamp: now,
          payload: const {'notes': 'first subject'},
          xpValue: 25,
        ),
      );
      await dbHelper.insertEvent(
        Event(
          id: uuid.v4(),
          userId: secondSubject.id,
          type: EventType.journalEntry,
          timestamp: now,
          payload: const {'notes': 'second subject'},
          xpValue: 25,
        ),
      );
      await dbHelper.insertEvent(
        Event(
          id: uuid.v4(),
          userId: otherOwnerSubject.id,
          type: EventType.journalEntry,
          timestamp: now,
          payload: const {'notes': 'other owner'},
          xpValue: 25,
        ),
      );

      expect(await dbHelper.getCareSubjects(userId), hasLength(2));
      expect(
        await dbHelper.getCareSubject(
          ownerUserId: otherUserId,
          careSubjectId: firstSubject.id,
        ),
        isNull,
      );

      await dbHelper.clearCareSubjectData(
        ownerUserId: userId,
        careSubjectId: firstSubject.id,
      );

      expect(await dbHelper.getEventsByUser(firstSubject.id), isEmpty);
      expect(await dbHelper.getEventsByUser(secondSubject.id), hasLength(1));
      expect(
        await dbHelper.getEventsByUser(otherOwnerSubject.id),
        hasLength(1),
      );
      expect(await dbHelper.getCareSubjects(userId), hasLength(1));
    },
  );

  test('session tracks the active subject and rejects another owner', () {
    SessionService.start(userId: userId);
    final activeSubject = CareSubject(
      id: 'subject-active',
      ownerUserId: userId,
      type: CareSubjectType.ward,
      displayName: 'Ama',
      relationship: 'Parent',
      createdAt: DateTime(2026, 8, 12),
      updatedAt: DateTime(2026, 8, 12),
    );
    final otherOwnerSubject = activeSubject.copyWith(
      id: 'subject-foreign',
      ownerUserId: otherUserId,
    );

    SessionService.setActiveCareSubject(activeSubject);
    expect(SessionService.currentCareSubjectId, activeSubject.id);
    expect(
      () => SessionService.setActiveCareSubject(otherOwnerSubject),
      throwsStateError,
    );

    SessionService.startMockSession();
  });

  test(
    'session restores a persisted subject only from the current owner',
    () async {
      final self = CareSubject(
        id: userId,
        ownerUserId: userId,
        type: CareSubjectType.self,
        displayName: 'Me',
        createdAt: DateTime(2026, 8, 12),
        updatedAt: DateTime(2026, 8, 12),
      );
      final ward = CareSubject(
        id: 'subject-ward',
        ownerUserId: userId,
        type: CareSubjectType.ward,
        displayName: 'Kojo',
        relationship: 'Parent',
        createdAt: DateTime(2026, 8, 12),
        updatedAt: DateTime(2026, 8, 12),
      );

      SharedPreferences.setMockInitialValues({
        'spineup_active_care_subject_$userId': ward.id,
      });
      SessionService.start(userId: userId);
      await SessionService.restoreActiveCareSubject(subjects: [self, ward]);
      expect(SessionService.currentCareSubjectId, ward.id);

      SharedPreferences.setMockInitialValues({
        'spineup_active_care_subject_$userId': 'missing-or-foreign-subject',
      });
      SessionService.start(userId: userId);
      await SessionService.restoreActiveCareSubject(subjects: [self, ward]);
      expect(SessionService.currentCareSubjectId, self.id);

      SessionService.startMockSession();
    },
  );

  test(
    'profile mapper preserves ward ownership in its care-subject record',
    () {
      const data = ProfileData(
        ownership: ProfileOwnership(
          subjectType: CareSubjectType.ward,
          relationship: 'Guardian',
        ),
        basics: ProfileBasics(displayName: 'Esi'),
      );
      final timestamp = DateTime(2026, 8, 12);

      final subject = ProfileMapper.toCareSubject(
        id: 'ward-esi',
        ownerUserId: userId,
        data: data,
        now: timestamp,
      );

      expect(subject.id, 'ward-esi');
      expect(subject.ownerUserId, userId);
      expect(subject.type, CareSubjectType.ward);
      expect(subject.relationship, 'Guardian');
      expect(subject.displayName, 'Esi');
      expect(subject.profileData, same(data));
    },
  );
}

extension on DatabaseHelper {
  Future<List<Event>> getJournalEvents(String userId) {
    return getEventsByUserAndType(userId, EventType.journalEntry);
  }
}
