import 'package:latlong2/latlong.dart';

class SpeedRule {
  final int id;
  final String name;
  final LatLng point;
  final double radiusM;
  final double speedLimit;

  SpeedRule({
    required this.id,
    required this.name,
    required this.point,
    required this.radiusM,
    required this.speedLimit,
  });

  factory SpeedRule.fromJson(Map<String, dynamic> json) => SpeedRule(
        id: json['id'] as int,
        name: json['name'] as String,
        point: LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble()),
        radiusM: (json['radius_m'] as num).toDouble(),
        speedLimit: (json['speed_limit'] as num).toDouble(),
      );
}

class DangerRule {
  final int id;
  final String name;
  final LatLng point;
  final double radiusM;
  final String type;
  final List<LatLng> polygon;

  DangerRule({
    required this.id,
    required this.name,
    required this.point,
    required this.radiusM,
    required this.type,
    required this.polygon,
  });

  factory DangerRule.fromJson(Map<String, dynamic> json) => DangerRule(
        id: json['id'] as int,
        name: json['name'] as String,
        point: LatLng(
          (json['lat'] as num?)?.toDouble() ?? 0,
          (json['lng'] as num?)?.toDouble() ?? 0,
        ),
        radiusM: (json['radius_m'] as num?)?.toDouble() ?? 0,
        type: json['type'] as String,
        polygon: (json['polygon'] as List?)
                ?.map((e) => LatLng((e[0] as num).toDouble(), (e[1] as num).toDouble()))
                .toList() ??
            [],
      );
}

class RailwayRule {
  final int id;
  final String name;
  final LatLng point;
  final double radiusM;

  RailwayRule({
    required this.id,
    required this.name,
    required this.point,
    required this.radiusM,
  });

  factory RailwayRule.fromJson(Map<String, dynamic> json) => RailwayRule(
        id: json['id'] as int,
        name: json['name'] as String,
        point: LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble()),
        radiusM: (json['radius_m'] as num).toDouble(),
      );
}

