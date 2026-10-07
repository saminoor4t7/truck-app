import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'src/core/offline/database_factory_initializer.dart';
import 'src/core/workmanager/sync_worker.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDatabaseFactory();
  await Injection.configureDependencies();
  await SyncWorker.initialize();
  runApp(const App());
}
