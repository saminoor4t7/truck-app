import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../data/models/telemetry_point.dart';

class LocationTracker {
  StreamSubscription<Position>? _subscription;

  bool get isTracking => _subscription != null;

  Future<void> startTracking({
    required FutureOr<void> Function(TelemetryPoint point) onPosition,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    if (isTracking) return;
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission is not granted.');
    }
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always) {
      throw StateError(
        'Allow location access all the time in system settings to track in the background.',
      );
    }
    final settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            intervalDuration: const Duration(seconds: 5),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Truck tracking active',
              notificationText: 'Your vehicle location is being recorded.',
              notificationChannelName: 'Vehicle tracking',
              enableWakeLock: true,
              setOngoing: true,
            ),
          )
        : AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 10,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: true,
            allowBackgroundLocationUpdates: true,
          );
    final initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    await onPosition(_toTelemetryPoint(initialPosition));

    _subscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (position) async {
            await onPosition(_toTelemetryPoint(position));
          },
          onError: (Object error, StackTrace stackTrace) {
            if (onError != null) {
              onError(error, stackTrace);
            } else {
              Zone.current.handleUncaughtError(error, stackTrace);
            }
          },
        );
  }

  TelemetryPoint _toTelemetryPoint(Position position) => TelemetryPoint(
    latitude: position.latitude,
    longitude: position.longitude,
    speedKmh: position.speed * 3.6,
    timestamp: position.timestamp,
    heading: position.heading,
    accuracy: position.accuracy,
  );

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
