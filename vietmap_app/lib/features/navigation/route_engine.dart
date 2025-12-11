import 'package:latlong2/latlong.dart';
import '../../core/logger.dart';
import 'models/route_model.dart';
import 'route_api.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Route engine for managing navigation routes
class RouteEngine {
  static RouteEngine? _instance;
  final RouteApi _api = RouteApi();
  RouteModel? _currentRoute;
  SharedPreferences? _prefs;

  RouteEngine._();

  static RouteEngine get instance {
    _instance ??= RouteEngine._();
    return _instance!;
  }

  /// Request route from origin to destination
  Future<RouteModel?> requestRoute({
    required LatLng from,
    required LatLng to,
    String profile = 'driving',
    bool useCache = true,
  }) async {
    try {
      // Try cache first
      if (useCache) {
        final cached = await loadFromCache(from, to);
        if (cached != null) {
          appLog('RouteEngine: Using cached route');
          _currentRoute = cached;
          return cached;
        }
      }

      // Request from API
      final route = await _api.requestRoute(from: from, to: to, profile: profile);
      if (route != null) {
        _currentRoute = route;
        await _saveToCache(route, from, to);
      }

      return route;
    } catch (e) {
      appLog('RouteEngine: Error requesting route: $e');
      return null;
    }
  }

  /// Load route from cache
  Future<RouteModel?> loadFromCache(LatLng from, LatLng to) async {
    try {
      await _initPrefs();
      if (_prefs == null) return null;

      final cacheKey = _getCacheKey(from, to);
      final cachedJson = _prefs?.getString(cacheKey);
      if (cachedJson == null) return null;

      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      final route = RouteModel.fromJson(json, json['id'] as String);

      // Check if cache is still valid (less than 1 hour old)
      final cachedTime = json['cached_at'] as int?;
      if (cachedTime != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedTime;
        if (age > 3600000) { // 1 hour
          appLog('RouteEngine: Cache expired');
          return null;
        }
      }

      return route;
    } catch (e) {
      appLog('RouteEngine: Error loading cache: $e');
      return null;
    }
  }

  /// Save route to cache
  Future<void> _saveToCache(RouteModel route, LatLng from, LatLng to) async {
    try {
      await _initPrefs();
      if (_prefs == null) return;

      final cacheKey = _getCacheKey(from, to);
      final json = {
        'id': route.id,
        'distance': route.distance,
        'duration': route.duration,
        'name': route.name,
        'geometry': route.geometry.map((p) => [p.longitude, p.latitude]).toList(),
        'steps': route.steps.map((s) => {
          'index': s.index,
          'maneuver': s.maneuver.toString(),
          'instruction': s.instruction,
          'name': s.name,
          'distance': s.distance,
          'duration': s.duration,
          'geometry': s.geometry.map((p) => [p.longitude, p.latitude]).toList(),
        }).toList(),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      };

      await _prefs?.setString(cacheKey, jsonEncode(json));
      appLog('RouteEngine: Route cached');
    } catch (e) {
      appLog('RouteEngine: Error saving cache: $e');
    }
  }

  String _getCacheKey(LatLng from, LatLng to) {
    return 'route_${from.latitude.toStringAsFixed(4)}_${from.longitude.toStringAsFixed(4)}_'
           '${to.latitude.toStringAsFixed(4)}_${to.longitude.toStringAsFixed(4)}';
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get current route
  RouteModel? get currentRoute => _currentRoute;

  /// Clear current route
  void clearRoute() {
    _currentRoute = null;
    appLog('RouteEngine: Route cleared');
  }
}

