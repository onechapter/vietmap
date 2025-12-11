import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../logger.dart';

/// Unified location controller - single source of truth for all location updates
/// Supports both real GPS and fake/simulated locations
class LocationController {
  static LocationController? _instance;
  final _streamController = StreamController<Position>.broadcast();
  StreamSubscription<Position>? _realGpsSubscription;
  bool _simulationMode = false;
  Position? _lastPosition;

  LocationController._();

  static LocationController get instance {
    _instance ??= LocationController._();
    return _instance!;
  }

  /// Stream of location updates (unified for real GPS and fake/simulated)
  Stream<Position> get stream => _streamController.stream;

  /// Current location
  Position? get currentLocation => _lastPosition;

  /// Check if simulation mode is active
  bool get isSimulationMode => _simulationMode;

  /// Start real GPS tracking
  Future<void> startRealGps() async {
    if (_simulationMode) {
      appLog('LocationController: Real GPS disabled (simulation mode active)');
      return;
    }

    if (_realGpsSubscription != null) {
      appLog('LocationController: Real GPS already started');
      return;
    }

    try {
      appLog('LocationController: Starting real GPS...');
      
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        appLog('LocationController: Location service disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        appLog('LocationController: Permission denied');
        return;
      }

      final locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _realGpsSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen(
        (position) {
          if (!_simulationMode) {
            _emitPosition(position);
          }
        },
        onError: (e) {
          appLog('LocationController: GPS stream error: $e');
        },
      );

      appLog('LocationController: Real GPS started');
    } catch (e) {
      appLog('LocationController: Start GPS failed: $e');
    }
  }

  /// Stop real GPS tracking
  void stopRealGps() {
    _realGpsSubscription?.cancel();
    _realGpsSubscription = null;
    appLog('LocationController: Real GPS stopped');
  }

  /// Enable simulation mode (disables real GPS)
  void enableSimulationMode() {
    _simulationMode = true;
    stopRealGps();
    appLog('LocationController: Simulation mode enabled (real GPS disabled)');
  }

  /// Disable simulation mode (enables real GPS)
  void disableSimulationMode() {
    _simulationMode = false;
    appLog('LocationController: Simulation mode disabled');
    startRealGps();
  }

  /// Update location from fake/simulated source
  void updateLocation({
    required double latitude,
    required double longitude,
    double speed = 0.0,
    double accuracy = 5.0,
  }) {
    final position = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: 0,
      heading: 0,
      speed: speed,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    appLog('FAKE LOC → $latitude, $longitude, speed=${speed.toStringAsFixed(1)} km/h');
    _emitPosition(position);
  }

  /// Emit position to stream
  void _emitPosition(Position position) {
    _lastPosition = position;
    _streamController.add(position);
  }

  /// Dispose controller
  void dispose() {
    stopRealGps();
    _streamController.close();
    appLog('LocationController: Disposed');
  }
}

