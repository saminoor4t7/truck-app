class TelemetryPoint {
  const TelemetryPoint({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.timestamp,
    this.heading = 0,
    this.accuracy = 0,
  });

  final double latitude;
  final double longitude;
  final double speedKmh;
  final DateTime timestamp;
  final double heading;
  final double accuracy;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'speedKmh': speedKmh,
        'timestamp': timestamp.toIso8601String(),
        'heading': heading,
        'accuracy': accuracy,
      };
}
