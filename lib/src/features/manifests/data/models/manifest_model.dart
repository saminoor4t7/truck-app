class ManifestModel {
  const ManifestModel({
    required this.id,
    required this.routeCode,
    required this.totalStops,
    required this.synced,
  });

  final String id;
  final String routeCode;
  final int totalStops;
  final bool synced;

  factory ManifestModel.fromJson(Map<String, dynamic> json) {
    return ManifestModel(
      id: json['id'] as String,
      routeCode: json['routeCode'] as String,
      totalStops: (json['totalStops'] as num).toInt(),
      synced: (json['synced'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeCode': routeCode,
        'totalStops': totalStops,
        'synced': synced,
      };
}
