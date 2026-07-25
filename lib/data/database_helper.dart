import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
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
}
