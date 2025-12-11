import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../../../core/logger.dart';
import '../models/route_model.dart';

/// Detector for off-route situations
class RerouteDetector {
  static const double offRouteThresholdM = 30.0; // 30 meters
  static const double headingToleranceDeg = 45.0; // 45 degrees

  /// Check if position is off-route
  bool isOffRoute({
    required LatLng position,
    required RouteModel route,
    double? heading, // degrees, 0-360
  }) {
    if (route.geometry.isEmpty) return false;

    // Find closest point on route
    final closestDistance = _getDistanceToRoute(position, route.geometry);

    if (closestDistance > offRouteThresholdM) {
      // Check if heading is correct (might be on parallel road)
      if (heading != null) {
        final routeHeading = _getRouteHeadingAt(position, route);
        if (routeHeading != null) {
          final headingDiff = (heading - routeHeading).abs();
          final normalizedDiff = headingDiff > 180 ? 360 - headingDiff : headingDiff;
          
          // If heading is correct, might be on parallel road - don't reroute
          if (normalizedDiff < headingToleranceDeg) {
            appLog('RerouteDetector: Off route but heading correct, ignoring');
            return false;
          }
        }
      }

      appLog('RerouteDetector: Off route detected - ${closestDistance.toStringAsFixed(1)}m');
      return true;
    }

    return false;
  }

  /// Get distance from position to route
  double _getDistanceToRoute(LatLng position, List<LatLng> routeGeometry) {
    if (routeGeometry.isEmpty) return double.infinity;

    double minDistance = double.infinity;
    final distance = const Distance();

    for (var i = 0; i < routeGeometry.length - 1; i++) {
      final segmentStart = routeGeometry[i];
      final segmentEnd = routeGeometry[i + 1];
      
      // Distance to line segment (simplified - using midpoint)
      final midPoint = LatLng(
        (segmentStart.latitude + segmentEnd.latitude) / 2,
        (segmentStart.longitude + segmentEnd.longitude) / 2,
      );
      final dist = distance.as(LengthUnit.Meter, position, midPoint);
      
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance;
  }

  /// Get route heading at position (simplified)
  double? _getRouteHeadingAt(LatLng position, RouteModel route) {
    if (route.geometry.length < 2) return null;

    final currentStepIndex = route.getCurrentStepIndex(position);
    if (currentStepIndex >= route.steps.length) return null;

    final step = route.steps[currentStepIndex];
    if (step.geometry.length < 2) return null;

    // Calculate heading from first two points of current step
    final p1 = step.geometry[0];
    final p2 = step.geometry.length > 1 ? step.geometry[1] : step.geometry[0];
    
    // Simplified heading calculation
    final latDiff = p2.latitude - p1.latitude;
    final lngDiff = p2.longitude - p1.longitude;
    
    if (lngDiff == 0) return latDiff > 0 ? 0.0 : 180.0;
    
    final heading = (lngDiff > 0 ? 90.0 : 270.0) - 
                    math.atan(latDiff / lngDiff) * 180 / math.pi;
    
    return heading < 0 ? heading + 360 : heading;
  }
}

