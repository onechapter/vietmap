import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_model.dart';
import '../../../core/logger.dart';

/// Cache for offline route storage
class OfflineRouteCache {
  static OfflineRouteCache? _instance;
  static const int maxCachedRoutes = 5;
  static const String cacheKey = 'offline_routes';

  OfflineRouteCache._();

  static OfflineRouteCache get instance {
    _instance ??= OfflineRouteCache._();
    return _instance!;
  }

  /// Save route to cache
  Future<void> saveRoute(RouteModel route, LatLng from, LatLng to) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRoutes = await getCachedRoutes();

      // Remove oldest if at max capacity
      if (cachedRoutes.length >= maxCachedRoutes) {
        cachedRoutes.removeAt(0);
      }

      // Add new route
      final routeData = {
        'id': route.id,
        'from_lat': from.latitude,
        'from_lng': from.longitude,
        'to_lat': to.latitude,
        'to_lng': to.longitude,
        'distance': route.distance,
        'duration': route.duration,
        'geometry': route.geometry.map((p) => [p.latitude, p.longitude]).toList(),
        'steps': route.steps.map((s) => {
          'index': s.index,
          'maneuver': s.maneuver.toString(),
          'instruction': s.instruction,
          'name': s.name,
          'distance': s.distance,
          'duration': s.duration,
          'geometry': s.geometry.map((p) => [p.latitude, p.longitude]).toList(),
        }).toList(),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      };

      cachedRoutes.add(routeData);

      // Save to preferences
      await prefs.setString(cacheKey, jsonEncode(cachedRoutes));
      appLog('OfflineRouteCache: Saved route ${route.id}');
    } catch (e) {
      appLog('OfflineRouteCache: Error saving route: $e');
    }
  }

  /// Get cached routes
  Future<List<Map<String, dynamic>>> getCachedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) return [];

      final cached = jsonDecode(cachedJson) as List;
      return cached.cast<Map<String, dynamic>>();
    } catch (e) {
      appLog('OfflineRouteCache: Error getting cached routes: $e');
      return [];
    }
  }

  /// Find cached route matching from/to
  Future<RouteModel?> findCachedRoute(LatLng from, LatLng to, {double toleranceM = 100.0}) async {
    try {
      final cachedRoutes = await getCachedRoutes();
      final distance = const Distance();

      for (final routeData in cachedRoutes) {
        final fromLat = routeData['from_lat'] as num?;
        final fromLng = routeData['from_lng'] as num?;
        final toLat = routeData['to_lat'] as num?;
        final toLng = routeData['to_lng'] as num?;

        if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
          continue;
        }

        final cachedFrom = LatLng(fromLat.toDouble(), fromLng.toDouble());
        final cachedTo = LatLng(toLat.toDouble(), toLng.toDouble());

        final fromDist = distance.as(LengthUnit.Meter, from, cachedFrom);
        final toDist = distance.as(LengthUnit.Meter, to, cachedTo);

        if (fromDist <= toleranceM && toDist <= toleranceM) {
          // Reconstruct route from cache
          return _reconstructRoute(routeData);
        }
      }

      return null;
    } catch (e) {
      appLog('OfflineRouteCache: Error finding cached route: $e');
      return null;
    }
  }

  /// Reconstruct RouteModel from cached data
  RouteModel _reconstructRoute(Map<String, dynamic> data) {
    final geometry = (data['geometry'] as List).map((e) {
      final coords = e as List;
      return LatLng((coords[0] as num).toDouble(), (coords[1] as num).toDouble());
    }).toList();

    return RouteModel(
      id: data['id'] as String,
      geometry: geometry,
      steps: [], // Would need to reconstruct properly from cached steps
      distance: (data['distance'] as num).toDouble(),
      duration: (data['duration'] as num).toDouble(),
    );
  }

  /// Clear all cached routes
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      appLog('OfflineRouteCache: Cache cleared');
    } catch (e) {
      appLog('OfflineRouteCache: Error clearing cache: $e');
    }
  }
}

