class Warning {
  final String id;
  final String type; // camera|danger|railway|speed
  final double distance; // meters
  final double lat;
  final double lng;
  final DateTime timestamp;

  Warning({
    required this.id,
    required this.type,
    required this.distance,
    required this.lat,
    required this.lng,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'distance': distance,
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Warning.fromJson(Map<String, dynamic> json) => Warning(
        id: json['id'] as String,
        type: json['type'] as String,
        distance: (json['distance'] as num).toDouble(),
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

