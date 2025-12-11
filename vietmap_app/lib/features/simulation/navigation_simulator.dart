import 'dart:async';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

class SimPositionUpdate {
  final LatLng position;
  final double speedKmh;
  final double headingDeg;
  final DateTime timestamp;
  final int segmentIndex;

  SimPositionUpdate({
    required this.position,
    required this.speedKmh,
    required this.headingDeg,
    required this.timestamp,
    required this.segmentIndex,
  });
}

/// Drives a ghost car along a polyline with pause/resume support.
class NavigationSimulator {
  final List<LatLng> routePoints;
  double speedKmh;
  double speedMultiplier;
  final Duration tick = const Duration(milliseconds: 200);

  void Function(SimPositionUpdate update)? onPositionUpdate;

  int _segment = 0;
  double _offsetOnSegmentM = 0;
  bool _running = false;
  bool _paused = false;
  Timer? _timer;
  final ll.Distance _distance = const ll.Distance();

  NavigationSimulator({
    required this.routePoints,
    required this.speedKmh,
    this.speedMultiplier = 1.0,
  });

  bool get isRunning => _running;
  bool get isPaused => _paused;
  int get segmentIndex => _segment;

  void start({bool loop = false}) {
    if (routePoints.length < 2) return;
    _running = true;
    _paused = false;
    _segment = 0;
    _offsetOnSegmentM = 0;
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) => _step(loop: loop));
  }

  void pause() {
    if (!_running) return;
    _paused = true;
  }

  void resume() {
    if (!_running) return;
    _paused = false;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _paused = false;
    _segment = 0;
    _offsetOnSegmentM = 0;
  }

  void setSpeed(double kmh) {
    speedKmh = kmh;
  }

  void setSpeedMultiplier(double m) {
    speedMultiplier = m;
  }

  void _step({required bool loop}) {
    if (!_running || _paused || routePoints.length < 2) return;

    final speedMps = (speedKmh / 3.6) * speedMultiplier;
    var remaining = speedMps * (tick.inMilliseconds / 1000.0);

    while (remaining > 0 && _segment < routePoints.length - 1) {
      final a = routePoints[_segment];
      final b = routePoints[_segment + 1];
      final segLen = _distance.as(
        ll.LengthUnit.Meter,
        ll.LatLng(a.latitude, a.longitude),
        ll.LatLng(b.latitude, b.longitude),
      );

      final distToTravel = segLen - _offsetOnSegmentM;
      if (distToTravel <= remaining) {
        // Move to next segment
        _segment++;
        _offsetOnSegmentM = 0;
        remaining -= distToTravel;
        if (_segment >= routePoints.length - 1) {
          // Reached end
          _emitUpdate(b);
          if (loop) {
            _segment = 0;
            _offsetOnSegmentM = 0;
          } else {
            stop();
          }
          return;
        }
      } else {
        _offsetOnSegmentM += remaining;
        remaining = 0;
      }
    }

    if (!_running) return;
    final pos = _interpolateCurrent();
    _emitUpdate(pos);
  }

  LatLng _interpolateCurrent() {
    final a = routePoints[_segment];
    final b = routePoints[_segment + 1];
    final segLen = _distance.as(
      ll.LengthUnit.Meter,
      ll.LatLng(a.latitude, a.longitude),
      ll.LatLng(b.latitude, b.longitude),
    );
    final t = segLen == 0 ? 0 : (_offsetOnSegmentM / segLen).clamp(0.0, 1.0);
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  void _emitUpdate(LatLng pos) {
    onPositionUpdate?.call(
      SimPositionUpdate(
        position: pos,
        speedKmh: speedKmh * speedMultiplier,
        headingDeg: _headingDeg(),
        timestamp: DateTime.now(),
        segmentIndex: _segment,
      ),
    );
  }

  double _headingDeg() {
    if (_segment >= routePoints.length - 1) return 0;
    final a = routePoints[_segment];
    final b = routePoints[_segment + 1];
    final y = math.sin(_degToRad(b.longitude - a.longitude)) *
        math.cos(_degToRad(b.latitude));
    final x = math.cos(_degToRad(a.latitude)) *
            math.sin(_degToRad(b.latitude)) -
        math.sin(_degToRad(a.latitude)) *
            math.cos(_degToRad(b.latitude)) *
            math.cos(_degToRad(b.longitude - a.longitude));
    final brng = math.atan2(y, x);
    return (_radToDeg(brng) + 360) % 360;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;
  double _radToDeg(double rad) => rad * 180.0 / math.pi;
}

