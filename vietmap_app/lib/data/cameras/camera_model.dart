class CameraModel {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String type;
  final int? speedLimit;

  const CameraModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
    this.speedLimit,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    int? parseSpeed() {
      final v = json['speedLimit'] ?? json['speed_limit'];
      if (v == null) return null;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        return parsed;
      }
      return null;
    }

    return CameraModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      type: json['type'] as String? ?? '',
      speedLimit: parseSpeed(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'type': type,
        'speedLimit': speedLimit,
      };
}

