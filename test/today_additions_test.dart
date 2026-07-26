import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spineup/data/database_helper.dart';
import 'package:spineup/models/event.dart';
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

  group("Today Screen Additions Tests", () {
    late DatabaseHelper db;
    late GamificationService gs;

    setUp(() async {
      db = await makeDb();
      gs = GamificationService(db: db);
    });

    test("1. getTodayEvents strictly queries calendar day events and resets at midnight", () async {
      final uid = 'user_today_${DateTime.now().microsecondsSinceEpoch}';
      final now = DateTime.now();

      // Log event today
      await gs.logEvent(
        eventId: 'evt_today_1',
        userId: uid,
        type: EventType.stretchCompleted,
        payload: {'exercise_name': 'Cat-Cow'},
      );

      // Log event yesterday manually into DB
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayEvt = Event(
        id: 'evt_yesterday_1',
        userId: uid,
        type: EventType.stretchCompleted,
        timestamp: yesterday,
        payload: {'exercise_name': 'Bird-Dog'},
        xpValue: 30,
      );
      await db.insertEvent(yesterdayEvt);

      final todayEvents = await gs.getTodayEvents(uid);
      expect(todayEvents.length, equals(1));
      expect(todayEvents.first.id, equals('evt_today_1'));

      final todayXp = todayEvents.fold(0, (sum, e) => sum + e.xpValue);
      expect(todayXp, equals(35)); // 30 base + 5 daily first-event bonus
    });

    test("2. Stat chips calculate correct stretches count today and soonest appointment", () async {
      final uid = 'user_chips_${DateTime.now().microsecondsSinceEpoch}';

      // Log 2 stretches today
      await gs.logEvent(
        eventId: 's1',
        userId: uid,
        type: EventType.stretchCompleted,
        payload: {'exercise_name': 'Cat-Cow'},
      );
      await gs.logEvent(
        eventId: 's2',
        userId: uid,
        type: EventType.stretchCompleted,
        payload: {'exercise_name': 'Side Plank'},
      );

      // Schedule 2 future appointments
      final apt1 = await gs.scheduleAppointment(
        userId: uid,
        title: 'Physical Therapy',
        scheduledDateTime: DateTime.now().add(const Duration(days: 2)),
      );
      await gs.scheduleAppointment(
        userId: uid,
        title: 'Orthopedist Visit',
        scheduledDateTime: DateTime.now().add(const Duration(days: 5)),
      );

      final todayEvents = await gs.getTodayEvents(uid);
      final stretchesCount = todayEvents.where((e) => e.type == EventType.stretchCompleted).length;
      expect(stretchesCount, equals(2));

      final appointments = await gs.getAppointments(uid);
      final scheduled = appointments.where((a) => a.isScheduled).toList();
      scheduled.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

      expect(scheduled.first.id, equals(apt1.id));
      expect(scheduled.first.title, equals('Physical Therapy'));
    });

    test("3. Same-day timeline matches calendar day without omitting or duplicating entries", () async {
      final uid = 'user_timeline_${DateTime.now().microsecondsSinceEpoch}';

      await gs.logEvent(
        eventId: 'e1',
        userId: uid,
        type: EventType.journalEntry,
        payload: {'pain_level': 2, 'mood': '😊'},
      );
      await gs.logEvent(
        eventId: 'e2',
        userId: uid,
        type: EventType.angleLogged,
        payload: {'degrees': 24.5},
      );

      final todayEvents = await gs.getTodayEvents(uid);
      final allEvents = await gs.getAllEvents(uid);

      expect(todayEvents.length, equals(2));
      expect(allEvents.length, equals(2));
      expect(todayEvents.map((e) => e.id).toSet(), equals(allEvents.map((e) => e.id).toSet()));
    });
  });
}
