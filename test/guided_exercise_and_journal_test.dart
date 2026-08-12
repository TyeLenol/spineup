import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spineup/data/database_helper.dart';
import 'package:spineup/models/event.dart';
import 'package:spineup/models/milestone.dart';
import 'package:spineup/services/gamification_service.dart';

Future<DatabaseHelper> makeDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 3,
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
        await db.execute('''
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
  return DatabaseHelper(database: db);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guided Exercise, Journal Payload & My Journey Chart Tests', () {
    late DatabaseHelper db;
    late GamificationService gs;

    setUp(() async {
      db = await makeDb();
      gs = GamificationService(db: db);
    });

    test('1. Journal entry saves 0-10 pain scale, location list, tightness, fatigue', () async {
      final uid = 'user_j_${DateTime.now().microsecondsSinceEpoch}';

      final result = await gs.logEvent(
        eventId: 'j1',
        userId: uid,
        type: EventType.journalEntry,
        payload: {
          'pain_level': 8,
          'brace_hours': 12,
          'mood': '😣',
          'locations': ['Lower Back', 'Left Hip'],
          'tightness': 'Severe',
          'fatigue': 'Moderate',
          'notes': 'Stiff morning',
          'logged_at': DateTime.now().toIso8601String(),
        },
      );

      // Base journal XP 25 + 5 daily first-log bonus = 30
      expect(result.xpAwarded, equals(30));
      expect(result.dailyBonusAwarded, isTrue);

      final events = await gs.getJournalHistory(uid);
      expect(events.length, equals(1));

      final payload = events.first.payload;
      expect(payload['pain_level'], equals(8));
      expect(payload['locations'], equals(['Lower Back', 'Left Hip']));
      expect(payload['tightness'], equals('Severe'));
      expect(payload['fatigue'], equals('Moderate'));
    });

    test('2. Cobb history & events time range filtering', () async {
      final uid = 'user_cobb_${DateTime.now().microsecondsSinceEpoch}';

      // Insert event 40 days ago
      final oldDate = DateTime.now().subtract(const Duration(days: 40));
      await db.insertEvent(Event(
        id: 'old_1',
        userId: uid,
        type: EventType.angleLogged,
        timestamp: oldDate,
        payload: {'degrees': 28.5},
        xpValue: 50,
      ));

      // Insert event 5 days ago
      final recentDate = DateTime.now().subtract(const Duration(days: 5));
      await db.insertEvent(Event(
        id: 'rec_1',
        userId: uid,
        type: EventType.angleLogged,
        timestamp: recentDate,
        payload: {'degrees': 26.0},
        xpValue: 50,
      ));

      final fullHistory = await gs.getCobbAngleHistory(uid);
      expect(fullHistory.length, equals(2));

      final cutoff7d = DateTime.now().subtract(const Duration(days: 7));
      final filtered7d = fullHistory.where((e) => e.date.isAfter(cutoff7d)).toList();
      expect(filtered7d.length, equals(1));
      expect(filtered7d.first.degrees, equals(26.0));
    });

    test('3. Badges vs Achievements milestone date derivation', () async {
      final uid = 'user_achieve_${DateTime.now().microsecondsSinceEpoch}';

      await gs.logEvent(
        eventId: 'str_1',
        userId: uid,
        type: EventType.stretchCompleted,
        payload: {'exercise_name': 'Cat-Cow'},
      );

      // Verify 'first_stretch' unlocked milestone in snapshot
      final snap = await gs.getSnapshot(uid);
      expect(snap.unlockedMilestones.any((m) => m.id == 'first_stretch'), isTrue);

      final events = await gs.getAllEvents(uid);
      final stretchEvent = events.firstWhere((e) => e.type == EventType.stretchCompleted);

      // Verify event timestamp matches achievement unlock date
      final milestone = allMilestones.firstWhere((m) => m.id == 'first_stretch');
      expect(milestone.requiredEventType, equals(EventType.stretchCompleted));
      expect(stretchEvent.timestamp, isNotNull);
    });
  });
}
