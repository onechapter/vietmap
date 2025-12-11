import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final routeSimulatorProvider =
    StateNotifierProvider<RouteSimulatorService, LatLng?>(
  (ref) => RouteSimulatorService(),
);

class RouteSimulatorService extends StateNotifier<LatLng?> {
  RouteSimulatorService() : super(null);

  Timer? _timer;
  LatLng? _current;
  LatLng? _target;
  double _speed = 40; // km/h
  final Distance _distance = const Distance();

  bool running = false;

  void start({
    required LatLng start,
    required LatLng end,
    required double speedKmH,
  }) {
    stop();

    _current = start;
    _target = end;
    _speed = speedKmH;
    state = start;

    running = true;

    // Tick mỗi giây
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_current == null || _target == null) return;

    final meterPerSecond = (_speed * 1000) / 3600;
    final distanceToTarget = _distance(_current!, _target!);

    if (distanceToTarget < meterPerSecond) {
      state = _target;
      stop();
      return;
    }

    final bearing = _distance.bearing(_current!, _target!);
    final newPoint = _distance.offset(_current!, meterPerSecond, bearing);

    _current = newPoint;
    state = newPoint;
  }

  void stop() {
    running = false;
    _timer?.cancel();
    _timer = null;
    state = null;
  }
}

