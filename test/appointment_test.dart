import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spineup/data/database_helper.dart';
import 'package:spineup/models/appointment.dart';
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

  group('Unified Appointment System Tests', () {
    late DatabaseHelper db;
    late GamificationService gs;

    setUp(() async {
      db = await makeDb();
      gs = GamificationService(db: db);
    });

    test('1. Schedule appointment creates DB row without awarding XP or events', () async {
      final uid = 'uid_1_${DateTime.now().microsecondsSinceEpoch}';
      final futureTime = DateTime.now().add(const Duration(days: 2));
      final apt = await gs.scheduleAppointment(
        userId: uid,
        title: 'Orthopedist Follow-up',
        scheduledDateTime: futureTime,
        notes: 'Bring X-ray scan',
      );

      expect(apt.title, equals('Orthopedist Follow-up'));
      expect(apt.status, equals(AppointmentStatus.scheduled));
      expect(apt.isScheduled, isTrue);

      // Verify DB row exists
      final appointments = await gs.getAppointments(uid);
      expect(appointments.length, equals(1));
      expect(appointments.first.id, equals(apt.id));

      // Verify ZERO XP and ZERO events written to events table
      final events = await db.getEventsByUser(uid);
      expect(events.isEmpty, isTrue);

      final snap = await gs.getSnapshot(uid);
      expect(snap.totalXp, equals(0));
    });

    test('2. Update scheduled appointment fields', () async {
      final uid = 'uid_2_${DateTime.now().microsecondsSinceEpoch}';
      final futureTime = DateTime.now().add(const Duration(days: 3));
      final apt = await gs.scheduleAppointment(
        userId: uid,
        title: 'Initial Checkup',
        scheduledDateTime: futureTime,
      );

      final updatedTime = futureTime.add(const Duration(hours: 4));
      final updatedApt = apt.copyWith(
        title: 'Spine Specialist Checkup',
        scheduledDateTime: updatedTime,
        notes: 'Updated notes',
      );

      await gs.updateAppointment(updatedApt);

      final fetched = await db.getAppointmentById(apt.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Spine Specialist Checkup'));
      expect(fetched.notes, equals('Updated notes'));
    });

    test('3. Delete scheduled appointment removes DB row', () async {
      final uid = 'uid_3_${DateTime.now().microsecondsSinceEpoch}';
      final apt = await gs.scheduleAppointment(
        userId: uid,
        title: 'Therapy Session',
        scheduledDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      var appointments = await gs.getAppointments(uid);
      expect(appointments.length, equals(1));

      await gs.deleteAppointment(apt.id);

      appointments = await gs.getAppointments(uid);
      expect(appointments.isEmpty, isTrue);
    });

    test('4. Cannot complete appointment before scheduled time', () async {
      final uid = 'uid_4_${DateTime.now().microsecondsSinceEpoch}';
      final futureTime = DateTime.now().add(const Duration(hours: 5));
      final apt = await gs.scheduleAppointment(
        userId: uid,
        title: 'Future Visit',
        scheduledDateTime: futureTime,
      );

      expect(
        () async => await gs.completeAppointment(appointmentId: apt.id, userId: uid),
        throwsA(isA<StateError>()),
      );
    });

    test('5. Completing past/arrived appointment awards +40 XP, writes event & links event ID', () async {
      final uid = 'uid_5_${DateTime.now().microsecondsSinceEpoch}';
      final pastTime = DateTime.now().subtract(const Duration(minutes: 10));
      final apt = await gs.scheduleAppointment(
        userId: uid,
        title: 'Physical Therapy Session',
        scheduledDateTime: pastTime,
        notes: 'Core exercises',
      );

      final result = await gs.completeAppointment(
        appointmentId: apt.id,
        userId: uid,
      );

      // Verify +40 XP base (+5 bonus if first action today)
      expect(result.xpAwarded, equals(45));

      // Verify updated appointment state
      final fetched = await db.getAppointmentById(apt.id);
      expect(fetched, isNotNull);
      expect(fetched!.isCompleted, isTrue);
      expect(fetched.completedEventId, isNotNull);

      // Verify appointment_attended event written to SQLite events table
      final events = await db.getEventsByUserAndType(uid, EventType.appointmentAttended);
      expect(events.length, equals(1));
      expect(events.first.id, equals(fetched.completedEventId));
      expect(events.first.payload['appointment_id'], equals(apt.id));

      // Verify snapshot XP
      final snap = await gs.getSnapshot(uid);
      expect(snap.totalXp, equals(45));
    });
  });
}
