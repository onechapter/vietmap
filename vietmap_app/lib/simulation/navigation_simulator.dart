import 'dart:async';

import 'package:latlong2/latlong.dart' as ll;

/// Simple navigation simulator that walks along a list of route points
/// at a constant speed, emitting position updates for each point.
class NavigationSimulator {
  final List<ll.LatLng> routePoints;
  final double speedKmh;

  Function(ll.LatLng pos)? onPositionUpdate;
  bool _running = false;

  NavigationSimulator({
    required this.routePoints,
    required this.speedKmh,
  });

  Future<void> start() async {
    if (routePoints.isEmpty) return;
    _running = true;
    final speedMps = speedKmh / 3.6;

    for (int i = 0; i < routePoints.length; i++) {
      if (!_running) break;

      onPositionUpdate?.call(routePoints[i]);

      if (i == 0) {
        await Future.delayed(const Duration(milliseconds: 20));
        continue;
      }

      final dist = _distance(routePoints[i - 1], routePoints[i]);
      final sec = dist / speedMps;

      await Future.delayed(Duration(milliseconds: (sec * 1000).round()));
    }

    _running = false;
  }

  void stop() => _running = false;

  double _distance(ll.LatLng a, ll.LatLng b) {
    const d = ll.Distance();
    return d(a, b);
  }
}

