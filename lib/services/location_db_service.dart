import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location_log.dart';

class LocationDbService {
  static Database? _database;
  static const String _dbName = 'road_safety_telemetry.db';
  static const String _tableName = 'location_logs';

  // Singleton Instance Pattern
  static final LocationDbService instance = LocationDbService._init();
  LocationDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed REAL NOT NULL,
        heading REAL NOT NULL,
        altitude REAL NOT NULL,
        accuracy REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // Insert a new location telemetry log
  Future<int> insertLocation(LocationLog log) async {
    final db = await instance.database;
    return await db.insert(_tableName, log.toMap());
  }

  // Fetch all stored location logs ordered by timestamp descending
  Future<List<LocationLog>> getAllLogs() async {
    final db = await instance.database;
    final maps = await db.query(_tableName, orderBy: 'timestamp DESC');

    return maps.map((map) => LocationLog.fromMap(map)).toList();
  }

  // Delete logs older than a certain duration (e.g. 7 days) to save space
  Future<int> purgeOldLogs(Duration maxAge) async {
    final db = await instance.database;
    final cutoff = DateTime.now().subtract(maxAge).toIso8601String();
    return await db.delete(
      _tableName,
      where: 'timestamp < ?',
      whereArgs: [cutoff],
    );
  }

  // Clear all logs
  Future<int> clearAllLogs() async {
    final db = await instance.database;
    return await db.delete(_tableName);
  }
}
