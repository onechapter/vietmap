import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../features/warning/warning_engine.dart';
import '../../core/logger.dart';

/// Fake location service for testing warning engine
class FakeLocationService {
  StreamController<Position>? _controller;
  Timer? _timer;
  WarningEngine? _engine;

  /// Start simulating location at given coordinates
  Future<void> startSimulating(double lat, double lng) async {
    if (_controller != null) return;

    _controller = StreamController<Position>.broadcast();
    _engine = WarningEngine();
    await _engine!.start(_controller!.stream);

    // Emit position every 1 second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final position = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      _controller?.add(position);
      appLog('FakeLocationService: Emitted position $lat, $lng');
    });

    appLog('FakeLocationService: Started simulating at $lat, $lng');
  }

  /// Stop simulating
  void stopSimulating() {
    _timer?.cancel();
    _timer = null;
    _engine?.stop();
    _engine = null;
    _controller?.close();
    _controller = null;
    appLog('FakeLocationService: Stopped');
  }
}

