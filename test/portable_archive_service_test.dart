import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spineup/data/database_helper.dart';
import 'package:spineup/models/appointment.dart';
import 'package:spineup/models/care_subject.dart';
import 'package:spineup/models/event.dart';
import 'package:spineup/models/profile_data.dart';
import 'package:spineup/services/portable_archive_service.dart';
import 'package:spineup/services/profile_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DatabaseHelper dbHelper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 5,
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
          await database.execute('''
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
        },
      ),
    );
    dbHelper = DatabaseHelper(database: db);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test(
    'exports a protected archive with preview counts and rejects wrong passphrases',
    () async {
      final service = PortableArchiveService(database: dbHelper);
      await _seedSubject(dbHelper, ownerId: 'owner-a', subjectId: 'owner-a');

      final archive = await service.exportOwner(
        ownerUserId: 'owner-a',
        passphrase: 'a long, private passphrase',
      );
      expect(archive, isA<Uint8List>());

      final preview = await service.inspect(
        archiveBytes: archive,
        passphrase: 'a long, private passphrase',
      );
      expect(preview.subjects, hasLength(1));
      expect(preview.subjects.single.displayName, 'Alex');
      expect(preview.eventCount, 1);
      expect(preview.appointmentCount, 1);

      expect(
        () => service.inspect(
          archiveBytes: archive,
          passphrase: 'the wrong passphrase',
        ),
        throwsA(isA<PortableArchiveException>()),
      );
    },
  );

  test('imports as separate subjects with remapped IDs', () async {
    final exportService = PortableArchiveService(database: dbHelper);
    await _seedSubject(dbHelper, ownerId: 'owner-a', subjectId: 'owner-a');
    final archive = await exportService.exportOwner(
      ownerUserId: 'owner-a',
      passphrase: 'a long, private passphrase',
    );

    final targetDb = await _openDatabase();
    final targetHelper = DatabaseHelper(database: targetDb);
    addTearDown(targetHelper.close);
    final importService = PortableArchiveService(database: targetHelper);

    final result = await importService.importArchive(
      ownerUserId: 'owner-b',
      archiveBytes: archive,
      passphrase: 'a long, private passphrase',
      mode: ArchiveImportMode.separateSubjects,
    );

    expect(result.importedSubjectIds, hasLength(1));
    expect(result.importedSubjectIds.single, isNot('owner-a'));
    expect(result.importedEventCount, 1);
    expect(result.importedAppointmentCount, 1);
    expect(
      await targetHelper.getCareSubject(
        ownerUserId: 'owner-b',
        careSubjectId: result.importedSubjectIds.single,
      ),
      isNotNull,
    );
    expect(
      await targetHelper.getEventsByUser(result.importedSubjectIds.single),
      hasLength(1),
    );
  });

  test(
    'refuses separate import that would silently create a second self profile',
    () async {
      final exportService = PortableArchiveService(database: dbHelper);
      await _seedSubject(dbHelper, ownerId: 'owner-a', subjectId: 'owner-a');
      final archive = await exportService.exportOwner(
        ownerUserId: 'owner-a',
        passphrase: 'a long, private passphrase',
      );

      final targetDb = await _openDatabase();
      final targetHelper = DatabaseHelper(database: targetDb);
      addTearDown(targetHelper.close);
      await _seedSubject(
        targetHelper,
        ownerId: 'owner-b',
        subjectId: 'owner-b',
      );
      final importService = PortableArchiveService(database: targetHelper);

      expect(
        () => importService.importArchive(
          ownerUserId: 'owner-b',
          archiveBytes: archive,
          passphrase: 'a long, private passphrase',
          mode: ArchiveImportMode.separateSubjects,
        ),
        throwsA(isA<PortableArchiveException>()),
      );
    },
  );
}

Future<Database> _openDatabase() {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 5,
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
        await database.execute('''
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
      },
    ),
  );
}

Future<void> _seedSubject(
  DatabaseHelper helper, {
  required String ownerId,
  required String subjectId,
}) async {
  final now = DateTime.now();
  await helper.upsertCareSubject(
    CareSubject(
      id: subjectId,
      ownerUserId: ownerId,
      type: subjectId == ownerId ? CareSubjectType.self : CareSubjectType.ward,
      displayName: 'Alex',
      relationship: subjectId == ownerId ? null : 'Child',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await ProfileStore.saveProfile(
    userId: ownerId,
    careSubjectId: subjectId,
    data: const ProfileData(),
  );
  await helper.updateUserProfile(
    userId: subjectId,
    presetId: 'sage',
    name: 'Alex',
  );
  await helper.insertEvent(
    Event(
      id: 'event-$subjectId',
      userId: subjectId,
      type: EventType.journalEntry,
      timestamp: now,
      payload: const {'note': 'Private'},
      xpValue: 0,
    ),
  );
  await helper.insertAppointment(
    Appointment(
      id: 'appointment-$subjectId',
      userId: subjectId,
      title: 'Clinic visit',
      scheduledDateTime: now.add(const Duration(days: 1)),
    ),
  );
}
