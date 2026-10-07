import 'package:flutter/foundation.dart';

class LoggingInterceptor {
  const LoggingInterceptor();

  void intercept(String message) {
    // Add request/response logging here.
    debugPrint(message);
  }
}
