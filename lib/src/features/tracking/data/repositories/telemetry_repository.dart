import 'package:sqflite/sqflite.dart';

import '../../../../core/offline/local_database.dart';
import '../models/telemetry_point.dart';

class TelemetryRepository {
  TelemetryRepository({LocalDatabase? localDatabase})
      : _localDatabase = localDatabase ?? LocalDatabase.instance;

  final LocalDatabase _localDatabase;

  Future<void> record(TelemetryPoint point) async {
    final db = await _localDatabase.database;
    await db.insert('telemetry_points', {
      'latitude': point.latitude,
      'longitude': point.longitude,
      'speed_kmh': point.speedKmh,
      'recorded_at': point.timestamp.toUtc().toIso8601String(),
    });
    await db.rawDelete('''
      DELETE FROM telemetry_points
      WHERE id NOT IN (
        SELECT id FROM telemetry_points ORDER BY recorded_at DESC LIMIT 5000
      )
    ''');
  }

  Future<List<Map<String, Object?>>> recent({int limit = 50}) async {
    if (limit < 1 || limit > 5000) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 5000');
    }
    final db = await _localDatabase.database;
    return db.query(
      'telemetry_points',
      orderBy: 'recorded_at DESC',
      limit: limit,
    );
  }

  Future<int> get count async {
    final db = await _localDatabase.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM telemetry_points'),
        ) ??
        0;
  }
}
