import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/widgets/app_drawer.dart';
import '../background/location_tracker.dart';
import '../data/repositories/telemetry_repository.dart';
import '../domain/entities/geofence.dart';
import '../domain/services/geofence_service.dart';
import '../domain/services/marker_interpolator.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({
    super.key,
    this.circularGeofences = const [],
    this.polygonGeofences = const [],
  });

  final List<Geofence> circularGeofences;
  final List<PolygonGeofence> polygonGeofences;

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  final LocationTracker _tracker = LocationTracker();
  final TelemetryRepository _telemetry = TelemetryRepository();
  late GeofenceMonitor _geofenceMonitor;
  final MarkerAnimationController _markerController =
      MarkerAnimationController();
  final MapController _mapController = MapController();
  StreamSubscription<GeoPoint>? _markerSubscription;
  StreamSubscription<GeofenceEvent>? _geofenceSubscription;
  bool _mapReady = false;
  GeoPoint? _position;
  double? _speed;
  int _savedPoints = 0;
  bool _tracking = false;
  String? _error;
  final List<String> _geofenceMessages = [];

  @override
  void initState() {
    super.initState();
    _geofenceMonitor = GeofenceMonitor(
      circularGeofences: widget.circularGeofences,
      polygonGeofences: widget.polygonGeofences,
    );
    _markerSubscription = _markerController.positions.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
      _moveCamera(position);
    });
    _listenForGeofenceEvents();
    _loadPointCount();
  }

  void _listenForGeofenceEvents() {
    _geofenceSubscription = _geofenceMonitor.events.listen((event) {
      final message =
          '${event.geofenceId}: ${event.type.name} at ${event.timestamp.toLocal()}';
      if (!mounted) return;
      setState(() => _geofenceMessages.insert(0, message));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  void _moveCamera(GeoPoint position) {
    if (_mapReady) {
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
    }
  }

  Future<void> _loadPointCount() async {
    final count = await _telemetry.count;
    if (mounted) setState(() => _savedPoints = count);
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _tracking = true;
    });
    try {
      await _tracker.startTracking(
        onPosition: (point) async {
          final previous = _position;
          final current = GeoPoint(
            latitude: point.latitude,
            longitude: point.longitude,
          );
          if (previous == null) {
            if (mounted) {
              setState(() => _position = current);
              _moveCamera(current);
            }
          } else {
            _markerController.animate(previous, current);
          }
          _geofenceMonitor.update(current, timestamp: point.timestamp);
          if (mounted) {
            setState(() {
              _speed = point.speedKmh;
            });
          }
          try {
            await _telemetry.record(point);
            if (mounted) setState(() => _savedPoints++);
          } catch (error) {
            if (mounted) {
              setState(() => _error = 'Could not save GPS sample locally: $error');
            }
          }
        },
        onError: (error, stackTrace) {
          if (mounted) setState(() => _error = 'Location stream error: $error');
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _tracking = false;
          _error = 'Could not start tracking: $error';
        });
      }
    }
  }

  Future<void> _stop() async {
    await _tracker.stopTracking();
    if (mounted) setState(() => _tracking = false);
  }

  @override
  void dispose() {
    _tracker.stopTracking();
    _markerSubscription?.cancel();
    _geofenceSubscription?.cancel();
    _mapController.dispose();
    _markerController.dispose();
    _geofenceMonitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    return Scaffold(
      appBar: AppBar(
        leading: const AppDrawerMenuButton(),
        title: const Text('Vehicle tracking'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_tracking ? 'Tracking active' : 'Tracking stopped'),
                  const SizedBox(height: 8),
                  Text(
                    position == null
                        ? 'Waiting for GPS location'
                        : 'Latitude: ${position.latitude.toStringAsFixed(6)}\n'
                              'Longitude: ${position.longitude.toStringAsFixed(6)}\n'
                              'Speed: ${(_speed ?? 0).toStringAsFixed(1)} km/h',
                  ),
                  const SizedBox(height: 8),
                  Text('Locally saved GPS samples: $_savedPoints'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _tracking ? _stop : _start,
                    icon: Icon(_tracking ? Icons.stop : Icons.my_location),
                    label: Text(_tracking ? 'Stop tracking' : 'Start tracking'),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_error!),
                    if (_error!.contains('system settings'))
                      TextButton(
                        onPressed: Geolocator.openAppSettings,
                        child: const Text('Open location settings'),
                      ),
                  ],
                ),
              ),
            ),
          SizedBox(
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: position == null
                      ? const LatLng(0, 0)
                      : LatLng(position.latitude, position.longitude),
                  initialZoom: position == null ? 2 : 16,
                  onMapReady: () {
                    _mapReady = true;
                    if (position != null) _moveCamera(position);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.truck_app',
                    maxNativeZoom: 19,
                  ),
                  CircleLayer(
                    circles: [
                      for (final fence in widget.circularGeofences)
                        if (fence.isActive)
                          CircleMarker(
                            point: LatLng(
                              fence.center.latitude,
                              fence.center.longitude,
                            ),
                            radius: fence.radiusMeters,
                            useRadiusInMeter: true,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .15),
                            borderColor: Theme.of(context).colorScheme.primary,
                            borderStrokeWidth: 2,
                          ),
                    ],
                  ),
                  PolygonLayer(
                    polygons: [
                      for (final fence in widget.polygonGeofences)
                        if (fence.isActive)
                          Polygon(
                            points: fence.vertices
                                .map(
                                  (point) =>
                                      LatLng(point.latitude, point.longitude),
                                )
                                .toList(),
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiary.withValues(alpha: .15),
                            borderColor: Theme.of(context).colorScheme.tertiary,
                            borderStrokeWidth: 2,
                          ),
                    ],
                  ),
                  if (position != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(position.latitude, position.longitude),
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.local_shipping,
                            size: 38,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            '© OpenStreetMap contributors',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configured geofences: ${widget.circularGeofences.length} circular, '
            '${widget.polygonGeofences.length} polygonal',
          ),
          for (final message in _geofenceMessages.take(10))
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(message),
              dense: true,
            ),
        ],
      ),
    );
  }
}
