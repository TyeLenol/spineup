import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:spineup/data/database_helper.dart';
import 'package:spineup/models/event.dart';
import 'package:spineup/models/profile_data.dart';
import 'package:spineup/services/gamification_service.dart';
import 'package:spineup/services/profile_mapper.dart';

void main() {
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
    await dbHelper.insertEvent(Event(
      id: uuid.v4(),
      userId: userId,
      type: EventType.journalEntry,
      timestamp: DateTime.now(),
      payload: {'notes': 'private'},
      xpValue: 25,
    ));
    await dbHelper.insertEvent(Event(
      id: uuid.v4(),
      userId: otherUserId,
      type: EventType.journalEntry,
      timestamp: DateTime.now(),
      payload: {'notes': 'keep'},
      xpValue: 25,
    ));

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
      await db.query('user_profiles', where: 'user_id = ?', whereArgs: [userId]),
      isEmpty,
    );
    expect(
      await db.query('user_profiles', where: 'user_id = ?', whereArgs: [otherUserId]),
      hasLength(1),
    );
  });

  test('updating a journal entry preserves its event and XP identity', () async {
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
  });

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
}

extension on DatabaseHelper {
  Future<List<Event>> getJournalEvents(String userId) {
    return getEventsByUserAndType(userId, EventType.journalEntry);
  }
}
