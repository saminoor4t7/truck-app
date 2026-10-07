import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, 'truck_app.db'),
      version: 2,
      onCreate: (db, version) async {
        await _createOperationalTables(db);
        await _createTelemetryTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createTelemetryTable(db);
      },
    );
    _database = database;
    return database;
  }

  Future<void> _createOperationalTables(DatabaseExecutor db) async {
    await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            customer_name TEXT NOT NULL,
            status TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE manifests (
            id TEXT PRIMARY KEY,
            route_code TEXT NOT NULL,
            total_stops INTEGER NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE action_logs (
            id TEXT PRIMARY KEY,
            entity_type TEXT NOT NULL,
            method TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            payload TEXT NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TEXT NOT NULL
          )
        ''');
  }

  Future<void> _createTelemetryTable(DatabaseExecutor db) async {
    await db.execute('''
          CREATE TABLE telemetry_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            speed_kmh REAL NOT NULL,
            recorded_at TEXT NOT NULL
          )
        ''');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
