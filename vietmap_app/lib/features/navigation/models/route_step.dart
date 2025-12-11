import 'package:latlong2/latlong.dart';

/// Maneuver types from VietMap API
enum ManeuverType {
  start,
  end,
  turnLeft,
  turnRight,
  turnSharpLeft,
  turnSharpRight,
  turnSlightLeft,
  turnSlightRight,
  straight,
  rampLeft,
  rampRight,
  merge,
  forkLeft,
  forkRight,
  ferry,
  ferryTrain,
  roundaboutLeft,
  roundaboutRight,
  uturnLeft,
  uturnRight,
  arrive,
  arriveLeft,
  arriveRight,
  depart,
  departLeft,
  departRight,
  none,
  notification,
  exitLeft,
  exitRight,
  keepLeft,
  keepRight,
  continue_,
  nameChange,
  newName,
  offRamp,
}

/// Route step model
class RouteStep {
  final int index;
  final ManeuverType maneuver;
  final String instruction;
  final String? name;
  final double distance; // meters
  final double duration; // seconds
  final List<LatLng> geometry;
  final String? ref;
  final String? mode;

  RouteStep({
    required this.index,
    required this.maneuver,
    required this.instruction,
    this.name,
    required this.distance,
    required this.duration,
    required this.geometry,
    this.ref,
    this.mode,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json, int index) {
    return RouteStep(
      index: index,
      maneuver: _parseManeuver(json['maneuver'] as String?),
      instruction: json['instruction'] as String? ?? '',
      name: json['name'] as String?,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      geometry: _parseGeometry(json['geometry']),
      ref: json['ref'] as String?,
      mode: json['mode'] as String?,
    );
  }

  static ManeuverType _parseManeuver(String? maneuver) {
    if (maneuver == null) return ManeuverType.none;

    switch (maneuver.toLowerCase()) {
      case 'start':
        return ManeuverType.start;
      case 'end':
      case 'arrive':
        return ManeuverType.end;
      case 'turn-left':
        return ManeuverType.turnLeft;
      case 'turn-right':
        return ManeuverType.turnRight;
      case 'sharp-left':
        return ManeuverType.turnSharpLeft;
      case 'sharp-right':
        return ManeuverType.turnSharpRight;
      case 'slight-left':
        return ManeuverType.turnSlightLeft;
      case 'slight-right':
        return ManeuverType.turnSlightRight;
      case 'straight':
        return ManeuverType.straight;
      case 'ramp-left':
        return ManeuverType.rampLeft;
      case 'ramp-right':
        return ManeuverType.rampRight;
      case 'merge':
        return ManeuverType.merge;
      case 'fork-left':
        return ManeuverType.forkLeft;
      case 'fork-right':
        return ManeuverType.forkRight;
      case 'ferry':
        return ManeuverType.ferry;
      case 'ferry-train':
        return ManeuverType.ferryTrain;
      case 'roundabout-left':
        return ManeuverType.roundaboutLeft;
      case 'roundabout-right':
        return ManeuverType.roundaboutRight;
      case 'uturn-left':
        return ManeuverType.uturnLeft;
      case 'uturn-right':
        return ManeuverType.uturnRight;
      case 'arrive-left':
        return ManeuverType.arriveLeft;
      case 'arrive-right':
        return ManeuverType.arriveRight;
      case 'depart':
        return ManeuverType.depart;
      case 'depart-left':
        return ManeuverType.departLeft;
      case 'depart-right':
        return ManeuverType.departRight;
      case 'exit-left':
        return ManeuverType.exitLeft;
      case 'exit-right':
        return ManeuverType.exitRight;
      case 'keep-left':
        return ManeuverType.keepLeft;
      case 'keep-right':
        return ManeuverType.keepRight;
      case 'continue':
        return ManeuverType.continue_;
      case 'name-change':
        return ManeuverType.nameChange;
      case 'new-name':
        return ManeuverType.newName;
      case 'off-ramp':
        return ManeuverType.offRamp;
      default:
        return ManeuverType.none;
    }
  }

  static List<LatLng> _parseGeometry(dynamic geometry) {
    if (geometry is String) {
      // Polyline encoded string
      return decodePolyline(geometry);
    } else if (geometry is List) {
      // Array of coordinates
      return geometry.map((e) {
        if (e is List && e.length >= 2) {
          return LatLng((e[1] as num).toDouble(), (e[0] as num).toDouble());
        }
        return LatLng(0, 0);
      }).toList();
    }
    return [];
  }

  /// Decode polyline string to LatLng list (public for RouteModel)
  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

