import 'package:latlong2/latlong.dart';
import 'route_step.dart';

/// Route model from VietMap API
class RouteModel {
  final String id;
  final List<LatLng> geometry;
  final List<RouteStep> steps;
  final double distance; // meters
  final double duration; // seconds
  final String? name;
  final Map<String, dynamic>? metadata;

  RouteModel({
    required this.id,
    required this.geometry,
    required this.steps,
    required this.distance,
    required this.duration,
    this.name,
    this.metadata,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json, String id) {
    final legs = json['legs'] as List? ?? [];
    final steps = <RouteStep>[];
    final allGeometry = <LatLng>[];

    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i] as Map<String, dynamic>;
      final legSteps = leg['steps'] as List? ?? [];
      
      for (var j = 0; j < legSteps.length; j++) {
        final stepJson = legSteps[j] as Map<String, dynamic>;
        final step = RouteStep.fromJson(stepJson, steps.length);
        steps.add(step);
        allGeometry.addAll(step.geometry);
      }
    }

    // If no steps, try to decode main geometry
    if (allGeometry.isEmpty && json['geometry'] != null) {
      if (json['geometry'] is String) {
        allGeometry.addAll(RouteStep.decodePolyline(json['geometry'] as String));
      } else if (json['geometry'] is List) {
        final coords = json['geometry'] as List;
        allGeometry.addAll(coords.map((e) {
          if (e is List && e.length >= 2) {
            return LatLng((e[1] as num).toDouble(), (e[0] as num).toDouble());
          }
          return LatLng(0, 0);
        }).toList());
      }
    }

    return RouteModel(
      id: id,
      geometry: allGeometry,
      steps: steps,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Get current step index based on position
  int getCurrentStepIndex(LatLng position) {
    if (steps.isEmpty) return 0;

    double minDistance = double.infinity;
    int closestStepIndex = 0;

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      for (final point in step.geometry) {
        final distance = const Distance().as(
          LengthUnit.Meter,
          position,
          point,
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestStepIndex = i;
        }
      }
    }

    return closestStepIndex;
  }

  /// Get remaining distance from position
  double getRemainingDistance(LatLng position) {
    final currentStepIndex = getCurrentStepIndex(position);
    double remaining = 0.0;

    for (var i = currentStepIndex; i < steps.length; i++) {
      remaining += steps[i].distance;
    }

    return remaining;
  }

  /// Get remaining duration from position
  double getRemainingDuration(LatLng position) {
    final currentStepIndex = getCurrentStepIndex(position);
    double remaining = 0.0;

    for (var i = currentStepIndex; i < steps.length; i++) {
      remaining += steps[i].duration;
    }

    return remaining;
  }
}

