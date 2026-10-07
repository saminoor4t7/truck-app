import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger();

  void log(String message) {
    debugPrint(message);
  }
}
