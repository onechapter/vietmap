import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';
import '../logger.dart';

/// Location data model
class LocationData {
  final double lat;
  final double lng;
  final double speed; // km/h

  LocationData(this.lat, this.lng, this.speed);

  Position toPosition() {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      heading: 0,
      speed: speed / 3.6, // m/s
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}

/// Unified location controller - single source of truth for all location updates
/// Supports both real GPS and fake/simulated locations
/// Uses BehaviorSubject for smooth updates
class LocationController {
  static LocationController? _instance;
  final BehaviorSubject<LocationData> _stream = BehaviorSubject<LocationData>();
  StreamSubscription<Position>? _realGpsSubscription;
  bool _simulationMode = false;
  LocationData? _lastLocation;

  LocationController._();

  static LocationController get instance {
    _instance ??= LocationController._();
    return _instance!;
  }

  /// Stream of location updates (unified for real GPS and fake/simulated)
  Stream<LocationData> get stream => _stream.stream;

  /// Stream as Position (for backward compatibility)
  Stream<Position> get positionStream => _stream.stream.map((loc) => loc.toPosition());

  /// Current location
  LocationData? get currentLocation => _lastLocation;

  /// Current location as Position (for backward compatibility)
  Position? get currentPosition => _lastLocation?.toPosition();

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
          // TASK DEBUG-02: 100% override - Only emit if NOT in simulation mode
          if (!_simulationMode) {
            final loc = LocationData(
              position.latitude,
              position.longitude,
              position.speed * 3.6, // km/h
            );
            _emitLocation(loc);
          } else {
            // TASK DEBUG-02: Log when GPS tries to emit but simulation is active
            appLog('[LocationController] ⛔ GPS position IGNORED (simulation mode active): ${position.latitude}, ${position.longitude}');
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
    double speed = 0.0, // m/s
    double accuracy = 5.0,
  }) {
    // TASK DEBUG-02: Ensure simulation mode is active when updating simulated location
    if (!_simulationMode) {
      appLog('[LocationController] ⚠️ WARNING: updateLocation called but simulation mode is OFF. Enabling simulation mode...');
      enableSimulationMode();
    }
    
    final speedKmh = speed * 3.6; // Convert to km/h
    final loc = LocationData(latitude, longitude, speedKmh);
    
    appLog('[LocationController] [SIM] updateLocation: $latitude,$longitude | speed=$speedKmh km/h');
    _emitLocation(loc);
  }

  /// Emit location to stream
  void _emitLocation(LocationData location) {
    _lastLocation = location;
    // TASK DEBUG-02: Log source clearly (REAL/SIM)
    final source = _simulationMode ? 'SIM' : 'REAL';
    appLog('[LocationController] Emitting location: source=$source, lat=${location.lat.toStringAsFixed(6)}, lng=${location.lng.toStringAsFixed(6)}, speed=${location.speed.toStringAsFixed(1)} km/h');
    _stream.add(location);
  }

  /// Dispose controller
  void dispose() {
    stopRealGps();
    _stream.close();
    appLog('LocationController: Disposed');
  }
}

