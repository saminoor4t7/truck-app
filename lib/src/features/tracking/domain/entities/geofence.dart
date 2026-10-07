class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class Geofence {
  const Geofence({
    required this.id,
    required this.center,
    required this.radiusMeters,
    required this.isActive,
  });

  final String id;
  final GeoPoint center;
  final double radiusMeters;
  final bool isActive;
}

class PolygonGeofence {
  PolygonGeofence({
    required this.id,
    required List<GeoPoint> vertices,
    this.isActive = true,
  }) : vertices = List.unmodifiable(vertices) {
    if (vertices.length < 3) {
      throw ArgumentError.value(vertices, 'vertices', 'A polygon needs at least 3 points');
    }
  }

  final String id;
  final List<GeoPoint> vertices;
  final bool isActive;
}

class GeofenceEvent {
  const GeofenceEvent({
    required this.geofenceId,
    required this.type,
    required this.timestamp,
  });

  final String geofenceId;
  final GeofenceEventType type;
  final DateTime timestamp;
}

enum GeofenceEventType { entered, exited }
