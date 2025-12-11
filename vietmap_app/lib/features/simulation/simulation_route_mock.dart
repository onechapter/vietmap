import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../navigation/route_engine.dart';
import '../navigation/models/route_model.dart';

/// Generates a mock or real route (if RouteEngine is available).
class SimulationRouteMock {
  static Future<List<LatLng>> buildRoute(
    LatLng start,
    LatLng end, {
    int segments = 200,
  }) async {
    // Try real routing if available
    try {
      final route = await RouteEngine.instance.requestRoute(
        from: ll.LatLng(start.latitude, start.longitude),
        to: ll.LatLng(end.latitude, end.longitude),
      );
      if (route != null && route.geometry.isNotEmpty) {
        return route.geometry
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
      }
    } catch (_) {
      // ignore and fall back
    }

    return interpolate(start, end, segments: segments);
  }

  /// Straight-line interpolation between two points.
  static List<LatLng> interpolate(
    LatLng start,
    LatLng end, {
    int segments = 200,
  }) {
    final pts = <LatLng>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      pts.add(
        LatLng(
          start.latitude + (end.latitude - start.latitude) * t,
          start.longitude + (end.longitude - start.longitude) * t,
        ),
      );
    }
    return pts;
  }
}

