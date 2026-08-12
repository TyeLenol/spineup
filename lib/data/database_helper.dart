import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/appointment.dart';
import '../models/care_subject.dart';
import '../models/event.dart';

class DatabaseHelper {
  static const String tableName = 'events';
  static DatabaseHelper? _instance;
  Database? _db;

  DatabaseHelper._internal({Database? database}) : _db = database;

  factory DatabaseHelper({Database? database}) {
    if (database != null) {
      return DatabaseHelper._internal(database: database);
    }
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'spineup.db');

    return openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        payload TEXT NOT NULL,
        xp_value INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_events_user_type ON $tableName(user_id, type)',
    );
    await db.execute(
      'CREATE INDEX idx_events_user_timestamp ON $tableName(user_id, timestamp)',
    );
    await db.execute('''
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
    await db.execute(
      'CREATE INDEX idx_appointments_user_status ON appointments(user_id, status)',
    );
    await _createCareSubjectsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE user_profiles (
          user_id TEXT PRIMARY KEY,
          preset_id TEXT NOT NULL,
          custom_photo_path TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
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
      await db.execute(
        'CREATE INDEX idx_appointments_user_status ON appointments(user_id, status)',
      );
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE user_profiles ADD COLUMN name TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN diagnosis TEXT');
      await db.execute(
        'ALTER TABLE user_profiles ADD COLUMN brace_status TEXT',
      );
      await db.execute('ALTER TABLE user_profiles ADD COLUMN age_range TEXT');
    }
    if (oldVersion < 5) {
      await _createCareSubjectsTable(db);
      await _seedLegacySelfCareSubjects(db);
    }
  }

  Future<void> _createCareSubjectsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS care_subjects (
        id TEXT PRIMARY KEY,
        owner_user_id TEXT NOT NULL,
        subject_type TEXT NOT NULL,
        display_name TEXT NOT NULL,
        relationship TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_care_subjects_owner ON care_subjects(owner_user_id)',
    );
  }

  /// Preserves existing single-user local data by registering the historic
  /// owner ID as that owner's self care subject. Events, appointments, and
  /// runtime profiles already use this identifier, so no health records move
  /// or merge during the v4 → v5 migration.
  Future<void> _seedLegacySelfCareSubjects(Database db) async {
    final profileRows = await db.query('user_profiles');
    final namesByOwner = <String, String>{};
    for (final row in profileRows) {
      final ownerId = row['user_id'] as String?;
      if (ownerId != null && ownerId.isNotEmpty) {
        namesByOwner[ownerId] = row['name'] as String? ?? 'You';
      }
    }

    final ownerIds = <String>{...namesByOwner.keys};
    for (final table in <String>[tableName, 'appointments']) {
      final rows = await db.query(table, columns: const ['user_id']);
      for (final row in rows) {
        final ownerId = row['user_id'] as String?;
        if (ownerId != null && ownerId.isNotEmpty) {
          ownerIds.add(ownerId);
        }
      }
    }

    final now = DateTime.now().toIso8601String();
    for (final ownerId in ownerIds) {
      await db.insert('care_subjects', {
        'id': ownerId,
        'owner_user_id': ownerId,
        'subject_type': CareSubjectType.self.name,
        'display_name': namesByOwner[ownerId] ?? 'You',
        'relationship': null,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ── Care subjects ───────────────────────────────────────────────────────────

  Future<void> upsertCareSubject(CareSubject subject) async {
    final db = await database;
    await db.insert(
      'care_subjects',
      subject.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CareSubject>> getCareSubjects(String ownerUserId) async {
    final db = await database;
    final maps = await db.query(
      'care_subjects',
      where: 'owner_user_id = ?',
      whereArgs: [ownerUserId],
      orderBy: 'created_at ASC',
    );
    return maps.map(CareSubject.fromDbMap).toList();
  }

  Future<CareSubject?> getCareSubject({
    required String ownerUserId,
    required String careSubjectId,
  }) async {
    final db = await database;
    final maps = await db.query(
      'care_subjects',
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [careSubjectId, ownerUserId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CareSubject.fromDbMap(maps.first);
  }

  /// Deletes health records for one care subject after confirming that it
  /// belongs to [ownerUserId]. Account-wide deletion remains separate.
  Future<void> clearCareSubjectData({
    required String ownerUserId,
    required String careSubjectId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final subjectRows = await txn.query(
        'care_subjects',
        where: 'id = ? AND owner_user_id = ?',
        whereArgs: [careSubjectId, ownerUserId],
        limit: 1,
      );
      if (subjectRows.isEmpty) {
        throw StateError('Care subject does not belong to the active owner.');
      }

      await _deleteRecordsForSubject(txn, careSubjectId);
      await txn.delete(
        'care_subjects',
        where: 'id = ? AND owner_user_id = ?',
        whereArgs: [careSubjectId, ownerUserId],
      );
    });
  }

  /// Wipes all local data belonging to [ownerUserId], including every linked
  /// care subject. The transaction keeps account deletion consistent if a
  /// database write fails partway through.
  Future<void> clearUserData(String ownerUserId) async {
    final db = await database;
    await db.transaction((txn) async {
      final careSubjectIds = <String>{ownerUserId};
      final hasCareSubjectsTable = await _tableExists(txn, 'care_subjects');
      if (hasCareSubjectsTable) {
        final subjectRows = await txn.query(
          'care_subjects',
          columns: const ['id'],
          where: 'owner_user_id = ?',
          whereArgs: [ownerUserId],
        );
        for (final row in subjectRows) {
          final subjectId = row['id'] as String?;
          if (subjectId != null && subjectId.isNotEmpty) {
            careSubjectIds.add(subjectId);
          }
        }
      }

      for (final subjectId in careSubjectIds) {
        await _deleteRecordsForSubject(txn, subjectId);
      }
      if (hasCareSubjectsTable) {
        await txn.delete(
          'care_subjects',
          where: 'owner_user_id = ?',
          whereArgs: [ownerUserId],
        );
      }
    });
  }

  Future<bool> _tableExists(DatabaseExecutor db, String tableName) async {
    final rows = await db.query(
      'sqlite_master',
      columns: const ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', tableName],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _deleteRecordsForSubject(
    DatabaseExecutor db,
    String careSubjectId,
  ) async {
    await db.delete(
      tableName,
      where: 'user_id = ?',
      whereArgs: [careSubjectId],
    );
    await db.delete(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [careSubjectId],
    );
    await db.delete(
      'appointments',
      where: 'user_id = ?',
      whereArgs: [careSubjectId],
    );
  }

  // ── Events ──────────────────────────────────────────────────────────────────

  Future<int> insertEvent(Event event) async {
    final db = await database;
    return db.insert(
      tableName,
      event.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetches one event while enforcing active care-subject ownership.
  Future<Event?> getEventById(String eventId, String careSubjectId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'id = ? AND user_id = ?',
      whereArgs: [eventId, careSubjectId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Event.fromDbMap(maps.first);
  }

  /// Updates an event owned by its active care subject.
  Future<int> updateEvent(Event event) async {
    final db = await database;
    return db.update(
      tableName,
      event.toDbMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [event.id, event.userId],
    );
  }

  Future<List<Event>> getEventsByUserAndType(
    String careSubjectId,
    EventType type,
  ) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'user_id = ? AND type = ?',
      whereArgs: [careSubjectId, type.value],
      orderBy: 'timestamp DESC',
    );
    return maps.map(Event.fromDbMap).toList();
  }

  Future<List<Event>> getEventsByDateRange(
    String careSubjectId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        careSubjectId,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'timestamp DESC',
    );
    return maps.map(Event.fromDbMap).toList();
  }

  Future<List<Event>> getEventsByUser(String careSubjectId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [careSubjectId],
      orderBy: 'timestamp DESC',
    );
    return maps.map(Event.fromDbMap).toList();
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  // ── Runtime profile ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile(String careSubjectId) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [careSubjectId],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> updateUserProfile({
    required String userId,
    required String presetId,
    String? customPhotoPath,
    String? name,
    String? diagnosis,
    String? braceStatus,
    String? ageRange,
  }) async {
    final db = await database;
    final map = <String, dynamic>{
      'user_id': userId,
      'preset_id': presetId,
      'custom_photo_path': customPhotoPath,
    };
    if (name != null) map['name'] = name;
    if (diagnosis != null) map['diagnosis'] = diagnosis;
    if (braceStatus != null) map['brace_status'] = braceStatus;
    if (ageRange != null) map['age_range'] = ageRange;

    await db.insert(
      'user_profiles',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Appointments ────────────────────────────────────────────────────────────

  Future<int> insertAppointment(Appointment appointment) async {
    final db = await database;
    return db.insert(
      'appointments',
      appointment.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final db = await database;
    return db.update(
      'appointments',
      appointment.toDbMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> deleteAppointment(String appointmentId) async {
    final db = await database;
    return db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  Future<List<Appointment>> getAppointmentsByUser(String careSubjectId) async {
    final db = await database;
    final maps = await db.query(
      'appointments',
      where: 'user_id = ?',
      whereArgs: [careSubjectId],
    );
    return maps.map(Appointment.fromDbMap).toList();
  }

  Future<Appointment?> getAppointmentById(String id) async {
    final db = await database;
    final maps = await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Appointment.fromDbMap(maps.first);
    return null;
  }
}
