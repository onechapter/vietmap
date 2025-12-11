import 'dart:async';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../navigation/models/route_model.dart';
import '../../core/logger.dart';

/// Simulator for testing navigation along a route
class NavigationSimulator {
  static NavigationSimulator? _instance;
  Timer? _simulationTimer;
  RouteModel? _simulatingRoute;
  int _currentPointIndex = 0;
  double _simulationSpeed = 50.0; // km/h
  StreamController<Position>? _positionController;

  NavigationSimulator._();

  static NavigationSimulator get instance {
    _instance ??= NavigationSimulator._();
    return _instance!;
  }

  /// Start simulating navigation along route
  void startSimulating(RouteModel route, {double speedKmh = 50.0}) {
    if (_simulationTimer != null) {
      stopSimulating();
    }

    _simulatingRoute = route;
    _simulationSpeed = speedKmh;
    _currentPointIndex = 0;
    _positionController = StreamController<Position>.broadcast();

    appLog('NavigationSimulator: Starting simulation at ${speedKmh}km/h');

    // Calculate update interval based on speed
    // At 50 km/h = ~13.9 m/s, update every 1 second = ~13.9m per update
    final updateInterval = Duration(milliseconds: 1000);
    final metersPerUpdate = (_simulationSpeed / 3.6) * (updateInterval.inMilliseconds / 1000.0);

    _simulationTimer = Timer.periodic(updateInterval, (_) {
      if (_simulatingRoute == null || _currentPointIndex >= _simulatingRoute!.geometry.length - 1) {
        stopSimulating();
        return;
      }

      // Move along route
      final currentPoint = _simulatingRoute!.geometry[_currentPointIndex];
      final nextPoint = _simulatingRoute!.geometry[_currentPointIndex + 1];
      
      final distance = const Distance().as(LengthUnit.Meter, currentPoint, nextPoint);
      if (distance <= metersPerUpdate) {
        _currentPointIndex++;
      }

      if (_currentPointIndex < _simulatingRoute!.geometry.length) {
        final position = _simulatingRoute!.geometry[_currentPointIndex];
        _positionController?.add(Position(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0,
          altitudeAccuracy: 1.0,
          heading: _calculateHeading(position, _currentPointIndex),
          headingAccuracy: 5.0,
          speed: _simulationSpeed / 3.6, // m/s
          speedAccuracy: 1.0,
        ));
      }
    });
  }

  double _calculateHeading(LatLng current, int index) {
    if (_simulatingRoute == null || index >= _simulatingRoute!.geometry.length - 1) {
      return 0.0;
    }

    final next = _simulatingRoute!.geometry[index + 1];
    final latDiff = next.latitude - current.latitude;
    final lngDiff = next.longitude - current.longitude;

    if (lngDiff == 0) return latDiff > 0 ? 0.0 : 180.0;

    final heading = (lngDiff > 0 ? 90.0 : 270.0) - 
                    math.atan(latDiff / lngDiff) * 180 / math.pi;
    
    return heading < 0 ? heading + 360 : heading;
  }

  /// Stop simulation
  void stopSimulating() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _simulatingRoute = null;
    _currentPointIndex = 0;
    _positionController?.close();
    _positionController = null;
    appLog('NavigationSimulator: Stopped');
  }

  /// Get position stream
  Stream<Position>? get positionStream => _positionController?.stream;

  /// Update simulation speed
  void setSpeed(double speedKmh) {
    _simulationSpeed = speedKmh;
    if (_simulationTimer != null && _simulatingRoute != null) {
      // Restart with new speed
      final route = _simulatingRoute!;
      final index = _currentPointIndex;
      stopSimulating();
      _currentPointIndex = index;
      startSimulating(route, speedKmh: speedKmh);
    }
  }

  bool get isSimulating => _simulationTimer != null;
}

