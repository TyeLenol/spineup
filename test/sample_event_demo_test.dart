// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:spineup/models/event.dart';
import 'package:spineup/data/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Demo: Insert sample stretch_completed event and read it back', () async {
    print('\n==================== EVENT LOCAL DATA LAYER DEMO ====================');

    final db = await databaseFactory.openDatabase(
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

    final dbHelper = DatabaseHelper(database: db);
    const uuid = Uuid();

    final userId = uuid.v4();
    final sampleEvent = Event(
      id: uuid.v4(),
      userId: userId,
      type: EventType.stretchCompleted,
      timestamp: DateTime.now(),
      payload: {
        'exercise_name': 'Hamstring Stretch',
        'duration_seconds': 45,
        'pain_level': 2,
      },
      xpValue: 30,
    );

    print('\n[1] Sample Event to Insert:');
    print('  - ID: ${sampleEvent.id}');
    print('  - User ID: ${sampleEvent.userId}');
    print('  - Type: ${sampleEvent.type.value}');
    print('  - Timestamp: ${sampleEvent.timestamp}');
    print('  - Payload: ${sampleEvent.payload}');
    print('  - XP Value: ${sampleEvent.xpValue}');

    // Insert into local DB
    await dbHelper.insertEvent(sampleEvent);
    print('\n[2] Event inserted into SQLite database successfully.');

    // Read back by user and type
    final fetchedEvents = await dbHelper.getEventsByUserAndType(
      userId,
      EventType.stretchCompleted,
    );

    print('\n[3] Fetched Events from Database (User: $userId, Type: stretch_completed):');
    for (final event in fetchedEvents) {
      print('  -> $event');
    }

    print('======================================================================\n');

    expect(fetchedEvents.length, equals(1));
    expect(fetchedEvents.first.id, equals(sampleEvent.id));
    expect(fetchedEvents.first.type, equals(EventType.stretchCompleted));
    expect(fetchedEvents.first.payload['exercise_name'], equals('Hamstring Stretch'));

    await dbHelper.close();
  });
}
