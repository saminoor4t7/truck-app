import 'dart:async';
import 'dart:math' as math;

import '../entities/geofence.dart';

class MarkerInterpolator {
  const MarkerInterpolator();

  GeoPoint interpolate(GeoPoint from, GeoPoint to, double ratio) {
    final t = ratio.clamp(0.0, 1.0);
    final fromLat = _radians(from.latitude);
    final fromLng = _radians(from.longitude);
    final toLat = _radians(to.latitude);
    final toLng = _radians(to.longitude);
    final x1 = math.cos(fromLat) * math.cos(fromLng);
    final y1 = math.cos(fromLat) * math.sin(fromLng);
    final z1 = math.sin(fromLat);
    final x2 = math.cos(toLat) * math.cos(toLng);
    final y2 = math.cos(toLat) * math.sin(toLng);
    final z2 = math.sin(toLat);
    final omega = math.acos((x1 * x2 + y1 * y2 + z1 * z2).clamp(-1.0, 1.0));
    if (omega < 1e-9) return to;
    final sinOmega = math.sin(omega);
    final a = math.sin((1 - t) * omega) / sinOmega;
    final b = math.sin(t * omega) / sinOmega;
    final x = a * x1 + b * x2;
    final y = a * y1 + b * y2;
    final z = a * z1 + b * z2;
    return GeoPoint(
      latitude: _degrees(math.atan2(z, math.sqrt(x * x + y * y))),
      longitude: _degrees(math.atan2(y, x)),
    );
  }

  double distanceInMeters(GeoPoint from, GeoPoint to) {
    const earthRadius = 6371000.0;
    final lat1 = _radians(from.latitude);
    final lat2 = _radians(to.latitude);
    final deltaLat = lat2 - lat1;
    final deltaLng = _radians(to.longitude - from.longitude);
    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(deltaLng / 2), 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
  double _degrees(double radians) => radians * 180 / math.pi;
}

class MarkerAnimationController {
  MarkerAnimationController({
    MarkerInterpolator interpolator = const MarkerInterpolator(),
    this.duration = const Duration(milliseconds: 900),
    this.frameInterval = const Duration(milliseconds: 16),
  }) : _interpolator = interpolator;

  final MarkerInterpolator _interpolator;
  final Duration duration;
  final Duration frameInterval;
  final _positions = StreamController<GeoPoint>.broadcast();
  Timer? _timer;
  bool _disposed = false;

  Stream<GeoPoint> get positions => _positions.stream;

  void animate(GeoPoint from, GeoPoint to) {
    if (_disposed) throw StateError('MarkerAnimationController is disposed.');
    _timer?.cancel();
    final started = DateTime.now();
    _timer = Timer.periodic(frameInterval, (timer) {
      final elapsed = DateTime.now().difference(started).inMicroseconds;
      final ratio = duration.inMicroseconds == 0
          ? 1.0
          : elapsed / duration.inMicroseconds;
      final clamped = ratio.clamp(0.0, 1.0);
      _positions.add(_interpolator.interpolate(from, to, clamped));
      if (clamped >= 1) {
        timer.cancel();
        _timer = null;
      }
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    await _positions.close();
  }
}
