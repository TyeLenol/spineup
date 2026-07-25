import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:spineup/models/event.dart';
import 'package:spineup/data/database_helper.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for running sqflite in unit tests on desktop/Linux VM
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late Database db;
  const uuid = Uuid();
  final testUserId = uuid.v4();
  final otherUserId = uuid.v4();

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
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
          await db.execute(
            'CREATE INDEX idx_events_user_type ON events(user_id, type)',
          );
          await db.execute(
            'CREATE INDEX idx_events_user_timestamp ON events(user_id, timestamp)',
          );
        },
      ),
    );
    dbHelper = DatabaseHelper(database: db);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('Event Model Tests', () {
    test('Event serialization to and from DB map', () {
      final now = DateTime.now();
      final event = Event(
        id: uuid.v4(),
        userId: testUserId,
        type: EventType.stretchCompleted,
        timestamp: now,
        payload: {'exercise_name': 'Hamstring Stretch', 'duration_sec': 60},
        xpValue: 25,
      );

      final dbMap = event.toDbMap();
      expect(dbMap['id'], event.id);
      expect(dbMap['user_id'], event.userId);
      expect(dbMap['type'], 'stretch_completed');
      expect(dbMap['xp_value'], 25);

      final restored = Event.fromDbMap(dbMap);
      expect(restored.id, event.id);
      expect(restored.userId, event.userId);
      expect(restored.type, EventType.stretchCompleted);
      expect(restored.payload['exercise_name'], 'Hamstring Stretch');
      expect(restored.xpValue, 25);
    });

    test('Event JSON serialization', () {
      final now = DateTime.now();
      final event = Event(
        id: uuid.v4(),
        userId: testUserId,
        type: EventType.angleLogged,
        timestamp: now,
        payload: {'angle_value': 45.5, 'side': 'left'},
        xpValue: 10,
      );

      final json = event.toJson();
      expect(json['type'], 'angle_logged');

      final restored = Event.fromJson(json);
      expect(restored.id, event.id);
      expect(restored.type, EventType.angleLogged);
      expect(restored.payload['angle_value'], 45.5);
    });
  });

  group('DatabaseHelper CRUD Tests', () {
    test('insertEvent and getEventsByUser', () async {
      final event1 = Event(
        id: uuid.v4(),
        userId: testUserId,
        type: EventType.stretchCompleted,
        timestamp: DateTime.parse('2026-07-25T10:00:00Z'),
        payload: {'exercise_name': 'Lumbar Flexion'},
        xpValue: 20,
      );

      final event2 = Event(
        id: uuid.v4(),
        userId: otherUserId,
        type: EventType.journalEntry,
        timestamp: DateTime.parse('2026-07-25T11:00:00Z'),
        payload: {'note': 'Feeling good today'},
        xpValue: 15,
      );

      await dbHelper.insertEvent(event1);
      await dbHelper.insertEvent(event2);

      final user1Events = await dbHelper.getEventsByUser(testUserId);
      expect(user1Events.length, 1);
      expect(user1Events.first.id, event1.id);
      expect(user1Events.first.type, EventType.stretchCompleted);

      final user2Events = await dbHelper.getEventsByUser(otherUserId);
      expect(user2Events.length, 1);
      expect(user2Events.first.id, event2.id);
    });

    test('getEventsByUserAndType filters correctly', () async {
      final stretchEvent1 = Event(
        id: uuid.v4(),
        userId: testUserId,
        type: EventType.stretchCompleted,
        timestamp: DateTime.parse('2026-07-25T08:00:00Z'),
        payload: {'exercise_name': 'Child Pose'},
        xpValue: 10,
      );

      final stretchEvent2 = Event(
        id: uuid.v4(),
        userId: testUserId,
        type: EventType.stretchCompleted,
        timestamp: DateTime.parse('2026-07-25T09:00:00Z'),
        payload: {'exercise_name': 'Cat Cow'},
        xpValue: 10,
      );

      final appointmentEvent = Event(
        id: uuid.v4(),
        userId: testUserId,
        type: EventType.appointmentAttended,
        timestamp: DateTime.parse('2026-07-25T10:00:00Z'),
        payload: {'doctor': 'Dr. Smith'},
        xpValue: 50,
      );

      await dbHelper.insertEvent(stretchEvent1);
      await dbHelper.insertEvent(stretchEvent2);
      await dbHelper.insertEvent(appointmentEvent);

      final stretches = await dbHelper.getEventsByUserAndType(
        testUserId,
        EventType.stretchCompleted,
      );
      expect(stretches.length, 2);
      expect(stretches.map((e) => e.id), containsAll([stretchEvent1.id, stretchEvent2.id]));

      final appointments = await dbHelper.getEventsByUserAndType(
        testUserId,
        EventType.appointmentAttended,
      );
      expect(appointments.length, 1);
      expect(appointments.first.id, appointmentEvent.id);
    });

    test('getEventsByDateRange filters within range', () async {
      final eventBefore = Event(
        id: uuid.v4(),
        userId: testUserId,
        type: EventType.journalEntry,
        timestamp: DateTime.parse('2026-07-01T00:00:00Z'),
        payload: {'note': 'Start of month'},
        xpValue: 5,
      );

      final eventInRange1 = Event(
        id: uuid.v4(),
        userId: testUserId,
        type: EventType.angleLogged,
        timestamp: DateTime.parse('2026-07-15T12:00:00Z'),
        payload: {'angle_value': 30},
        xpValue: 15,
      );

      final eventInRange2 = Event(
        id: uuid.v4(),
        userId: testUserId,
        type: EventType.stretchCompleted,
        timestamp: DateTime.parse('2026-07-20T12:00:00Z'),
        payload: {'exercise_name': 'Bridge'},
        xpValue: 20,
      );

      final eventAfter = Event(
        id: uuid.v4(),
        userId: testUserId,
        type: EventType.journalEntry,
        timestamp: DateTime.parse('2026-08-01T00:00:00Z'),
        payload: {'note': 'Next month'},
        xpValue: 5,
      );

      await dbHelper.insertEvent(eventBefore);
      await dbHelper.insertEvent(eventInRange1);
      await dbHelper.insertEvent(eventInRange2);
      await dbHelper.insertEvent(eventAfter);

      final results = await dbHelper.getEventsByDateRange(
        testUserId,
        DateTime.parse('2026-07-10T00:00:00Z'),
        DateTime.parse('2026-07-25T23:59:59Z'),
      );

      expect(results.length, 2);
      expect(results.map((e) => e.id), containsAll([eventInRange1.id, eventInRange2.id]));
    });
  });
}
