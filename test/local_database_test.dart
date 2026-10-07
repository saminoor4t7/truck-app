import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truck_app/src/core/offline/database_factory_initializer.dart';
import 'package:truck_app/src/core/offline/local_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'initializes the local database factory before opening SQLite',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        initializeDatabaseFactory();

        final database = await LocalDatabase.instance.database;
        final tables = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        );

        expect(
          tables.map((table) => table['name']),
          contains('telemetry_points'),
        );
        await LocalDatabase.instance.close();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
