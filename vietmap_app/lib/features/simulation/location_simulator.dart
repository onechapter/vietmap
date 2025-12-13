import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../../core/location/location_controller.dart';
import '../../core/logger.dart';

/// Location Simulator - hoạt động mượt, không giật
/// Sử dụng tick 800ms để di chuyển mượt mà giữa các điểm route
class LocationSimulator {
  List<LatLng> _route = [];
  double _speedKmh = 40; // speed user sets
  int _index = 0;
  Timer? _timer;
  bool _running = false;
  final Distance _distance = const Distance();

  void setRoute(List<LatLng> route) {
    _route = route;
    _index = 0;
    appLog('LocationSimulator: Route set with ${route.length} points');
  }

  void setSpeed(double kmh) {
    _speedKmh = kmh;
    appLog('LocationSimulator: Speed set to ${kmh.toStringAsFixed(1)} km/h');
  }

  void start() {
    if (_route.isEmpty) {
      appLog('LocationSimulator: Cannot start - route is empty');
      return;
    }
    
    if (_running) {
      appLog('LocationSimulator: Already running');
      return;
    }

    _running = true;
    _index = 0;

    // Enable simulation mode (disables real GPS)
    LocationController.instance.enableSimulationMode();

    // Emit initial position
    LocationController.instance.updateLocation(
      latitude: _route[0].latitude,
      longitude: _route[0].longitude,
      speed: _speedKmh / 3.6, // m/s
    );

    _timer?.cancel();
    // Tick mỗi 800ms để mượt mà
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) => _tick());
    appLog('LocationSimulator: Started with ${_route.length} points, speed=${_speedKmh.toStringAsFixed(1)} km/h');
  }

  void stop() {
    if (!_running) return;
    
    _running = false;
    _timer?.cancel();
    _timer = null;
    
    // Disable simulation mode (re-enable real GPS)
    LocationController.instance.disableSimulationMode();
    appLog('LocationSimulator: Stopped, real GPS re-enabled');
  }

  bool get running => _running;

  void _tick() {
    if (!_running || _route.isEmpty) {
      appLog('[LocationSimulator] ⚠️ Tick skipped: running=$_running, route empty=${_route.isEmpty}');
      return;
    }

    if (_index >= _route.length - 1) {
      // Đã đến điểm cuối
      appLog('[LocationSimulator] ✅ Reached destination at index $_index/${_route.length}');
      LocationController.instance.updateLocation(
        latitude: _route[_index].latitude,
        longitude: _route[_index].longitude,
        speed: _speedKmh / 3.6, // m/s
      );
      stop();
      return;
    }

    final a = _route[_index];
    final b = _route[_index + 1];

    // Calculate distance between points
    final dist = _distance.as(LengthUnit.Meter, a, b);
    
    // Calculate move distance for 800ms tick
    final moveDist = (_speedKmh / 3.6) * 0.8; // 800ms = 0.8s

    if (moveDist >= dist) {
      // Đã đi hết segment này, chuyển sang điểm tiếp theo
      _index++;
      appLog('[LocationSimulator] ✅ Moved to point $_index/${_route.length} (jumped segment, dist=${dist.toStringAsFixed(1)}m)');
      LocationController.instance.updateLocation(
        latitude: b.latitude,
        longitude: b.longitude,
        speed: _speedKmh / 3.6, // m/s
      );
      return;
    }

    // Interpolate position between a and b
    final ratio = moveDist / dist;
    final newLat = a.latitude + (b.latitude - a.latitude) * ratio;
    final newLng = a.longitude + (b.longitude - a.longitude) * ratio;

    appLog('[LocationSimulator] ✅ Tick #$_index: pos=$newLat,$newLng speed=${_speedKmh.toStringAsFixed(1)} km/h (dist=${dist.toStringAsFixed(1)}m, move=${moveDist.toStringAsFixed(1)}m)');
    
    LocationController.instance.updateLocation(
      latitude: newLat,
      longitude: newLng,
      speed: _speedKmh / 3.6, // m/s
    );
  }
}

