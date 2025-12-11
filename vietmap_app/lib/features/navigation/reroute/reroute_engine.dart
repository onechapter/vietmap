import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../../../core/logger.dart';
import '../models/route_model.dart';
import '../route_engine.dart';
import 'reroute_detector.dart';

/// Engine for handling rerouting
class RerouteEngine {
  static RerouteEngine? _instance;
  final RouteEngine _routeEngine = RouteEngine.instance;
  final RerouteDetector _detector = RerouteDetector();
  
  DateTime? _lastRerouteTime;
  static const Duration rerouteCooldown = Duration(seconds: 15);
  bool _isRerouting = false;

  RerouteEngine._();

  static RerouteEngine get instance {
    _instance ??= RerouteEngine._();
    return _instance!;
  }

  /// Check if rerouting is needed and trigger if necessary
  Future<RouteModel?> checkAndReroute({
    required LatLng currentPosition,
    required RouteModel currentRoute,
    required LatLng destination,
    double? heading,
  }) async {
    // Check cooldown
    if (_lastRerouteTime != null) {
      final timeSinceLastReroute = DateTime.now().difference(_lastRerouteTime!);
      if (timeSinceLastReroute < rerouteCooldown) {
        appLog('RerouteEngine: In cooldown (${rerouteCooldown.inSeconds - timeSinceLastReroute.inSeconds}s remaining)');
        return null;
      }
    }

    // Check if off-route
    if (!_detector.isOffRoute(
      position: currentPosition,
      route: currentRoute,
      heading: heading,
    )) {
      return null;
    }

    // Trigger reroute
    if (_isRerouting) {
      appLog('RerouteEngine: Already rerouting, skipping');
      return null;
    }

    _isRerouting = true;
    appLog('RerouteEngine: Starting reroute...');

    try {
      final newRoute = await _routeEngine.requestRoute(
        from: currentPosition,
        to: destination,
        useCache: false, // Don't use cache for reroute
      );

      if (newRoute != null) {
        _lastRerouteTime = DateTime.now();
        appLog('RerouteEngine: Reroute successful - ${newRoute.distance.toStringAsFixed(0)}m');
      } else {
        appLog('RerouteEngine: Reroute failed - no route found');
      }

      return newRoute;
    } catch (e) {
      appLog('RerouteEngine: Reroute error: $e');
      return null;
    } finally {
      _isRerouting = false;
    }
  }

  /// Reset reroute cooldown (for testing)
  void resetCooldown() {
    _lastRerouteTime = null;
  }
}

