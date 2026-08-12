import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spineup/data/database_helper.dart';
import 'package:spineup/models/event.dart';
import 'package:spineup/services/gamification_service.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

/// Creates an in-memory DatabaseHelper backed by sqflite_common_ffi.
Future<DatabaseHelper> makeDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE events (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            type TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            payload TEXT NOT NULL,
            xp_value INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE user_profiles (
            user_id TEXT PRIMARY KEY,
            preset_id TEXT NOT NULL,
            custom_photo_path TEXT
          )
        ''');
      },
    ),
  );
  return DatabaseHelper(database: db);
}

Future<GamificationService> makeService() async {
  final db = await makeDb();
  return GamificationService(db: db);
}

const _uid = 'test_user';

// ── Tests ───────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    final db = await makeDb();
    await (await db.database).delete('events');
  });

  group('GamificationService.baseXpFor', () {
    test('returns correct base XP per category', () {
      expect(GamificationService.baseXpFor(EventType.stretchCompleted), kXpStretch);
      expect(GamificationService.baseXpFor(EventType.journalEntry), kXpJournal);
      expect(GamificationService.baseXpFor(EventType.angleLogged), kXpAngle);
      expect(GamificationService.baseXpFor(EventType.appointmentAttended), kXpAppointment);
    });

    test('stretch XP is flat (30) for all exercises', () {
      // All stretch events use the same base; no per-exercise variation.
      expect(GamificationService.baseXpFor(EventType.stretchCompleted), 30);
    });
  });

  group('GamificationService.isFirstEventToday', () {
    test('returns true when no events today', () async {
      final gs = await makeService();
      final result = await gs.isFirstEventToday(_uid);
      expect(result, isTrue);
    });

    test('returns false after one event logged today', () async {
      final gs = await makeService();
      await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.stretchCompleted,
        payload: {'exercise_id': 'cat_cow'},
      );
      final result = await gs.isFirstEventToday(_uid);
      expect(result, isFalse);
    });
  });

  group('GamificationService.logEvent — daily first-log bonus', () {
    test('awards +5 bonus on first event of the day', () async {
      final gs = await makeService();
      final result = await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.stretchCompleted,
        payload: {'exercise_id': 'cat_cow'},
      );
      expect(result.dailyBonusAwarded, isTrue);
      expect(result.xpAwarded, equals(kXpStretch + kXpDailyBonus));
    });

    test('does NOT award bonus on second event of the same day', () async {
      final gs = await makeService();
      await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.stretchCompleted,
        payload: {'exercise_id': 'cat_cow'},
      );
      final result2 = await gs.logEvent(
        eventId: 'e2',
        userId: _uid,
        type: EventType.journalEntry,
        payload: {'pain_level': 2},
      );
      expect(result2.dailyBonusAwarded, isFalse);
      expect(result2.xpAwarded, equals(kXpJournal)); // no bonus
    });
  });

  group('GamificationService.logEvent — XP values', () {
    test('stretch_completed awards kXpStretch base', () async {
      final gs = await makeService();
      final r = await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.stretchCompleted,
        payload: {'exercise_id': 'cat_cow'},
      );
      // First event today so bonus included; subtract bonus to check base
      expect(r.xpAwarded - (r.dailyBonusAwarded ? kXpDailyBonus : 0),
          equals(kXpStretch));
    });

    test('angle_logged awards kXpAngle (+50 XP)', () async {
      final gs = await makeService();
      // log something else first to consume daily bonus
      await gs.logEvent(
        eventId: 'e0',
        userId: _uid,
        type: EventType.stretchCompleted,
        payload: {},
      );
      final r = await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.angleLogged,
        payload: {'degrees': 28.5, 'method': 'manual'},
      );
      expect(r.xpAwarded, equals(kXpAngle));
      expect(r.dailyBonusAwarded, isFalse);
    });

    test('appointment_attended awards kXpAppointment (+40 XP)', () async {
      final gs = await makeService();
      await gs.logEvent(eventId: 'e0', userId: _uid,
          type: EventType.stretchCompleted, payload: {});
      final r = await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.appointmentAttended,
        payload: {'notes': 'stable'},
      );
      expect(r.xpAwarded, equals(kXpAppointment));
    });
  });

  group('GamificationService.getSnapshot — level & XP', () {
    test('starts at level 1 with 0 XP', () async {
      final gs = await makeService();
      final snap = await gs.getSnapshot(_uid);
      expect(snap.totalXp, 0);
      expect(snap.currentLevel, 1);
      expect(snap.levelProgress, 0.0);
    });

    test('computes level correctly at cumulative boundaries', () async {
      final gs = await makeService();
      // Level 1: 0
      // Level 2: 100
      // Level 3: 225
      
      // Log 2 angle events (50 each) -> 100 total (Wait, +5 daily bonus on first = 105 total).
      // So 105 total -> Level 2, 5 XP in level
      await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.angleLogged,
        payload: {'degrees': 28.0},
      ); // 50 + 5 = 55
      await gs.logEvent(
        eventId: 'e2',
        userId: _uid,
        type: EventType.appointmentAttended,
        payload: {},
      ); // 40
      await gs.logEvent(
        eventId: 'e3',
        userId: _uid,
        type: EventType.stretchCompleted,
        payload: {},
      ); // 30 -> 125 total
      
      var snap = await gs.getSnapshot(_uid);
      expect(snap.totalXp, 125);
      expect(snap.currentLevel, 2);
      expect(snap.xpInLevel, 25); // 125 - 100 = 25

      // Log 100 XP more -> 225 total (Level 3 boundary)
      await gs.logEvent(eventId: 'e4', userId: _uid, type: EventType.appointmentAttended, payload: {}); // 40
      await gs.logEvent(eventId: 'e5', userId: _uid, type: EventType.stretchCompleted, payload: {}); // 30
      await gs.logEvent(eventId: 'e6', userId: _uid, type: EventType.stretchCompleted, payload: {}); // 30 -> 100 XP -> 225 total
      
      snap = await gs.getSnapshot(_uid);
      expect(snap.totalXp, 225);
      expect(snap.currentLevel, 3);
      expect(snap.xpInLevel, 0);
      expect(snap.currentTitle, 'Newcomer'); // Level 3 < 5
    });

    test('levelProgress is between 0.0 and 1.0', () async {
      final gs = await makeService();
      await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.stretchCompleted,
        payload: {},
      );
      final snap = await gs.getSnapshot(_uid);
      expect(snap.levelProgress, greaterThanOrEqualTo(0.0));
      expect(snap.levelProgress, lessThan(1.0));
    });
  });

  group('GamificationService.getSnapshot — streak', () {
    test('streak is 0 with no events', () async {
      final gs = await makeService();
      final snap = await gs.getSnapshot(_uid);
      expect(snap.streakDays, 0);
    });

    test('streak is 1 after logging today', () async {
      final gs = await makeService();
      await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.stretchCompleted,
        payload: {},
      );
      final snap = await gs.getSnapshot(_uid);
      expect(snap.streakDays, 1);
    });
  });

  group('GamificationService — milestones', () {
    test('stretch_tier1 milestone unlocks after 1 stretch', () async {
      final gs = await makeService();
      await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.stretchCompleted,
        payload: {},
      );
      final snap = await gs.getSnapshot(_uid);
      expect(
        snap.unlockedMilestones.any((m) => m.id == 'stretch_tier1'),
        isTrue,
      );
    });

    test('angle_tier1 milestone unlocks after 1 angle log', () async {
      final gs = await makeService();
      await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.angleLogged,
        payload: {'degrees': 28.0, 'method': 'manual'},
      );
      final snap = await gs.getSnapshot(_uid);
      expect(
        snap.unlockedMilestones.any((m) => m.id == 'angle_tier1'),
        isTrue,
      );
    });

    test('subsequent Cobb angle log on same day awards 0 XP', () async {
      final gs = await makeService();
      final res1 = await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.angleLogged,
        payload: {'degrees': 28.0, 'method': 'manual'},
      );
      expect(res1.xpAwarded, greaterThan(0));

      final res2 = await gs.logEvent(
        eventId: 'e2',
        userId: _uid,
        type: EventType.angleLogged,
        payload: {'degrees': 29.0, 'method': 'manual'},
      );
      expect(res2.xpAwarded, equals(0));
    });

    test('appointment_tier1 milestone unlocks after 1 appointment', () async {
      final gs = await makeService();
      await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.appointmentAttended,
        payload: {'notes': 'check-up'},
      );
      final snap = await gs.getSnapshot(_uid);
      expect(
        snap.unlockedMilestones.any((m) => m.id == 'appointment_tier1'),
        isTrue,
      );
    });
  });



  group('GamificationService.getCobbAngleHistory', () {
    test('returns empty list when no angle events', () async {
      final gs = await makeService();
      final history = await gs.getCobbAngleHistory(_uid);
      expect(history, isEmpty);
    });

    test('returns correct degrees from payload', () async {
      final gs = await makeService();
      await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.angleLogged,
        payload: {'degrees': 31.5, 'method': 'manual'},
      );
      final history = await gs.getCobbAngleHistory(_uid);
      expect(history.length, 1);
      expect(history.first.degrees, closeTo(31.5, 0.01));
    });

    test('returns angles in ascending date order', () async {
      final gs = await makeService();
      await gs.logEvent(
        eventId: 'e1',
        userId: _uid,
        type: EventType.angleLogged,
        payload: {'degrees': 32.0, 'method': 'manual'},
      );
      await Future.delayed(const Duration(milliseconds: 5));
      await gs.logEvent(
        eventId: 'e2',
        userId: _uid,
        type: EventType.angleLogged,
        payload: {'degrees': 30.0, 'method': 'traced'},
      );
      final history = await gs.getCobbAngleHistory(_uid);
      expect(history.length, 2);
      expect(history.first.degrees, 32.0);
      expect(history.last.degrees, 30.0);
    });
  });
}
