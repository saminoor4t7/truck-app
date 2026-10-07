import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initializeDatabaseFactory() {
  if (defaultTargetPlatform != TargetPlatform.windows &&
      defaultTargetPlatform != TargetPlatform.linux &&
      defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
