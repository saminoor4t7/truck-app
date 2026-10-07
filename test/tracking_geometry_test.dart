import 'package:flutter_test/flutter_test.dart';
import 'package:truck_app/src/features/tracking/domain/entities/geofence.dart';
import 'package:truck_app/src/features/tracking/domain/services/geofence_service.dart';
import 'package:truck_app/src/features/tracking/domain/services/marker_interpolator.dart';

void main() {
  group('GeofenceService', () {
    const service = GeofenceService();

    test('detects circular geofence membership using meters', () {
      const circle = Geofence(
        id: 'warehouse',
        center: GeoPoint(latitude: 51.5, longitude: -0.1),
        radiusMeters: 500,
        isActive: true,
      );

      expect(
        service.isInsideGeofence(
          const GeoPoint(latitude: 51.5005, longitude: -0.1),
          circle,
        ),
        isTrue,
      );
      expect(
        service.isInsideGeofence(
          const GeoPoint(latitude: 51.51, longitude: -0.1),
          circle,
        ),
        isFalse,
      );
    });

    test('detects polygon membership and emits transitions', () async {
      final polygon = PolygonGeofence(
        id: 'yard',
        vertices: const [
          GeoPoint(latitude: 0, longitude: 0),
          GeoPoint(latitude: 0, longitude: 1),
          GeoPoint(latitude: 1, longitude: 1),
          GeoPoint(latitude: 1, longitude: 0),
        ],
      );
      expect(service.isInsidePolygon(const GeoPoint(latitude: .5, longitude: .5), polygon), isTrue);
      expect(service.isInsidePolygon(const GeoPoint(latitude: 2, longitude: 2), polygon), isFalse);

      final monitor = GeofenceMonitor(
        circularGeofences: const [],
        polygonGeofences: [polygon],
      );
      final events = <GeofenceEvent>[];
      final subscription = monitor.events.listen(events.add);
      monitor.update(const GeoPoint(latitude: .5, longitude: .5));
      monitor.update(const GeoPoint(latitude: 2, longitude: 2));
      await Future<void>.delayed(Duration.zero);
      expect(events.map((event) => event.type), [
        GeofenceEventType.entered,
        GeofenceEventType.exited,
      ]);
      await subscription.cancel();
      await monitor.dispose();
    });
  });

  test('interpolates smoothly between GPS fixes', () {
    const interpolator = MarkerInterpolator();
    const start = GeoPoint(latitude: 0, longitude: 0);
    const end = GeoPoint(latitude: 0, longitude: 2);
    final middle = interpolator.interpolate(start, end, .5);

    expect(middle.latitude, closeTo(0, 1e-8));
    expect(middle.longitude, closeTo(1, 1e-8));
    expect(interpolator.distanceInMeters(start, end), closeTo(222390, 1000));
  });
}
