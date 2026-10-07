import 'dart:async';
import 'dart:math' as math;

import '../entities/geofence.dart';

class GeofenceService {
  const GeofenceService();

  bool isInsideGeofence(GeoPoint point, Geofence geofence) {
    return geofence.isActive &&
        _haversine(point, geofence.center) <= geofence.radiusMeters;
  }

  bool isInsidePolygon(GeoPoint point, PolygonGeofence geofence) {
    if (!geofence.isActive) return false;
    var inside = false;
    final vertices = geofence.vertices;
    for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      final a = vertices[i];
      final b = vertices[j];
      final crosses = (a.latitude > point.latitude) !=
          (b.latitude > point.latitude);
      if (crosses) {
        final longitudeAtLatitude = (b.longitude - a.longitude) *
                (point.latitude - a.latitude) /
                (b.latitude - a.latitude) +
            a.longitude;
        if (point.longitude < longitudeAtLatitude) inside = !inside;
      }
    }
    return inside;
  }

  double _haversine(GeoPoint a, GeoPoint b) {
    const earthRadius = 6371000.0;
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);
    final deltaLat = lat2 - lat1;
    final deltaLng = _radians(b.longitude - a.longitude);
    final haversine = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(deltaLng / 2), 2);
    return earthRadius *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}

class GeofenceMonitor {
  GeofenceMonitor({
    required this.circularGeofences,
    required this.polygonGeofences,
    this.service = const GeofenceService(),
  });

  final List<Geofence> circularGeofences;
  final List<PolygonGeofence> polygonGeofences;
  final GeofenceService service;
  final Map<String, bool> _insideById = {};

  final StreamController<GeofenceEvent> _events =
      StreamController<GeofenceEvent>.broadcast();

  Stream<GeofenceEvent> get events => _events.stream;

  void update(GeoPoint currentPosition, {DateTime? timestamp}) {
    final occurredAt = timestamp ?? DateTime.now().toUtc();
    for (final geofence in circularGeofences) {
      _check(
        id: geofence.id,
        enabled: geofence.isActive,
        inside: service.isInsideGeofence(currentPosition, geofence),
        timestamp: occurredAt,
      );
    }
    for (final geofence in polygonGeofences) {
      _check(
        id: geofence.id,
        enabled: geofence.isActive,
        inside: service.isInsidePolygon(currentPosition, geofence),
        timestamp: occurredAt,
      );
    }
  }

  void _check({
    required String id,
    required bool enabled,
    required bool inside,
    required DateTime timestamp,
  }) {
    if (!enabled) {
      _insideById.remove(id);
      return;
    }
    final wasInside = _insideById[id];
    if ((wasInside == null && inside) ||
        (wasInside != null && wasInside != inside)) {
      _events.add(
        GeofenceEvent(
          geofenceId: id,
          type: inside ? GeofenceEventType.entered : GeofenceEventType.exited,
          timestamp: timestamp,
        ),
      );
    }
    _insideById[id] = inside;
  }

  Future<void> dispose() => _events.close();
}
