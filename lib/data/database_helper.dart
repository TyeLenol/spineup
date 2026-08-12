import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/event.dart';
import '../models/appointment.dart';

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

    return await openDatabase(
      path,
      version: 4,
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
      await db.execute('ALTER TABLE user_profiles ADD COLUMN brace_status TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN age_range TEXT');
    }
  }

  /// Wipes all user data completely across all tables.
  Future<void> clearAllUserData() async {
    final db = await database;
    await db.delete(tableName);
    await db.delete('user_profiles');
    await db.delete('appointments');
  }

  /// Insert a new event into the database.
  Future<int> insertEvent(Event event) async {
    final db = await database;
    return await db.insert(
      tableName,
      event.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch events filtered by user ID and event type.
  Future<List<Event>> getEventsByUserAndType(
    String userId,
    EventType type,
  ) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'user_id = ? AND type = ?',
      whereArgs: [userId, type.value],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => Event.fromDbMap(map)).toList();
  }

  /// Fetch events filtered by user ID and timestamp range [start, end].
  Future<List<Event>> getEventsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => Event.fromDbMap(map)).toList();
  }

  /// Fetch all events for a given user ID.
  Future<List<Event>> getEventsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => Event.fromDbMap(map)).toList();
  }

  /// Close the database connection.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  // ── User Profile ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
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
    return await db.insert(
      'appointments',
      appointment.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final db = await database;
    return await db.update(
      'appointments',
      appointment.toDbMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> deleteAppointment(String appointmentId) async {
    final db = await database;
    return await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  Future<List<Appointment>> getAppointmentsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'appointments',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((m) => Appointment.fromDbMap(m)).toList();
  }

  Future<Appointment?> getAppointmentById(String id) async {
    final db = await database;
    final maps = await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Appointment.fromDbMap(maps.first);
    }
    return null;
  }
}
