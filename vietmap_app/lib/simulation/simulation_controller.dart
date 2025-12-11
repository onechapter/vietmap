import 'package:latlong2/latlong.dart' as ll;

import 'navigation_simulator.dart';

class SimulationController {
  ll.LatLng? startPoint;
  ll.LatLng? endPoint;
  double speedKmh = 40;

  bool isRunning = false;

  Function(List<ll.LatLng> route)? onRouteReady;
  Function(ll.LatLng pos)? onSimPosition;

  NavigationSimulator? _simulator;

  Future<void> startSimulation() async {
    if (startPoint == null || endPoint == null) return;
    if (isRunning) return;

    // 1) Lấy route từ service (TODO: thay bằng OSRM/Maplibre server của bạn)
    final routePoints = await getRoute(startPoint!, endPoint!);
    if (routePoints.isEmpty) return;

    onRouteReady?.call(routePoints);

    // 2) Tạo simulator
    _simulator = NavigationSimulator(
      routePoints: routePoints,
      speedKmh: speedKmh,
    );

    _simulator!.onPositionUpdate = (p) {
      onSimPosition?.call(p);
    };

    isRunning = true;
    await _simulator!.start();
    isRunning = false;
  }

  void stop() {
    _simulator?.stop();
    isRunning = false;
  }

  Future<List<ll.LatLng>> getRoute(ll.LatLng start, ll.LatLng end) async {
    // TODO: CALL API OSRM / Mapbox / your routing service.
    // Tạm thời nội suy tuyến thẳng giữa start/end để mô phỏng mượt hơn.
    const segments = 20;
    final points = <ll.LatLng>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      points.add(ll.LatLng(lat, lng));
    }
    return points;
  }
}

