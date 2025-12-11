import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../engine/engine_config.dart';
import '../../core/logger.dart';

/// Optimized location service with throttling
class LocationService {
  StreamController<Position>? _controller;
  StreamSubscription<Position>? _subscription;
  DateTime? _lastEmit;
  Timer? _adaptiveTimer;

  /// Get location stream with adaptive frequency
  Stream<Position> getLocationStream() {
    _controller ??= StreamController<Position>.broadcast();

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    final rawStream = Geolocator.getPositionStream(locationSettings: locationSettings);

    _subscription = rawStream.listen(
      (position) {
        _handlePosition(position);
      },
      onError: (e) {
        appLog('LocationService: Stream error: $e');
      },
    );

    return _controller!.stream;
  }

  void _handlePosition(Position position) {
    final now = DateTime.now();

    // Throttle: minimum 250ms between emits
    if (_lastEmit != null) {
      final diff = now.difference(_lastEmit!).inMilliseconds;
      if (diff < EngineConfig.minLocationIntervalMs) {
        return; // Skip this update
      }
    }

    // Adaptive frequency based on speed
    if (EngineConfig.enableAdaptiveFrequency) {
      final speedKmh = (position.speed * 3.6).clamp(0.0, 300.0);
      final interval = EngineConfig.intervalForSpeed(speedKmh);

      // Cancel previous timer
      _adaptiveTimer?.cancel();

      // Schedule next emit based on speed
      _adaptiveTimer = Timer(Duration(milliseconds: (interval * 1000).round()), () {
        _emitPosition(position);
      });
    } else {
      _emitPosition(position);
    }
  }

  void _emitPosition(Position position) {
    _lastEmit = DateTime.now();
    _controller?.add(position);
  }

  void dispose() {
    _adaptiveTimer?.cancel();
    _subscription?.cancel();
    _controller?.close();
    _controller = null;
    _subscription = null;
  }
}

