class VehicleLocation {
  const VehicleLocation({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double speedKmh;
  final DateTime timestamp;
}
