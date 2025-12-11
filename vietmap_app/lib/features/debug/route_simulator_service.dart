import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/logger.dart';
import '../../features/navigation/route_engine.dart';

final routeSimulatorProvider =
    StateNotifierProvider<RouteSimulatorService, LatLng?>(
  (ref) => RouteSimulatorService(),
);

class RouteSimulatorService extends StateNotifier<LatLng?> {
  RouteSimulatorService() : super(null);

  Timer? _timer;
  List<LatLng>? _routePoints;
  int _currentPointIndex = 0;
  double _speed = 40; // km/h
  final Distance _distance = const Distance();

  bool running = false;
  String? _error;

  Future<void> start({
    required LatLng start,
    required LatLng end,
    required double speedKmH,
  }) async {
    stop();

    _speed = speedKmH;
    _error = null;

    // Lấy route thực tế từ RouteEngine
    appLog('RouteSimulator: Requesting route from ${start.latitude},${start.longitude} to ${end.latitude},${end.longitude}');
    final route = await RouteEngine.instance.requestRoute(
      from: start,
      to: end,
      useCache: true,
    );

    if (route == null || route.geometry.isEmpty) {
      _error = 'Không thể lấy route từ API';
      appLog('RouteSimulator: Failed to get route');
      return;
    }

    _routePoints = route.geometry;
    _currentPointIndex = 0;
    state = _routePoints!.first;
    running = true;

    appLog('RouteSimulator: Route loaded with ${_routePoints!.length} points, distance: ${route.distance.toStringAsFixed(0)}m');

    // Tick mỗi giây
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_routePoints == null || _routePoints!.isEmpty) return;
    if (_currentPointIndex >= _routePoints!.length - 1) {
      // Đã đến điểm cuối
      state = _routePoints!.last;
      stop();
      appLog('RouteSimulator: Reached destination');
      return;
    }

    final meterPerSecond = (_speed * 1000) / 3600;
    var remainingDistance = meterPerSecond;

    // Di chuyển theo route points
    while (remainingDistance > 0 && _currentPointIndex < _routePoints!.length - 1) {
      final currentPoint = _routePoints![_currentPointIndex];
      final nextPoint = _routePoints![_currentPointIndex + 1];
      final segmentDistance = _distance.as(LengthUnit.Meter, currentPoint, nextPoint);

      if (segmentDistance <= remainingDistance) {
        // Đã đi hết segment này, chuyển sang điểm tiếp theo
        _currentPointIndex++;
        remainingDistance -= segmentDistance;
        state = nextPoint;
      } else {
        // Đi một phần segment này
        final bearing = _distance.bearing(currentPoint, nextPoint);
        final newPoint = _distance.offset(currentPoint, remainingDistance, bearing);
        state = newPoint;
        remainingDistance = 0;
      }
    }
  }

  void stop() {
    running = false;
    _timer?.cancel();
    _timer = null;
    _routePoints = null;
    _currentPointIndex = 0;
    state = null;
    _error = null;
  }

  String? get error => _error;
  int get routePointCount => _routePoints?.length ?? 0;
  int get currentPointIndex => _currentPointIndex;
}

