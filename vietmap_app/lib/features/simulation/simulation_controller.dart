import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../warning/warning_engine.dart';
import '../warning/warning_manager.dart';
import '../warning/warning_model.dart';
import 'navigation_simulator.dart';
import 'simulation_route_mock.dart';

class SimulationState {
  final LatLng? start;
  final LatLng? end;
  final LatLng? current;
  final bool isRunning;
  final bool isPaused;
  final bool follow;
  final bool loop;
  final double speedKmh;
  final double routeLengthM;
  final int segmentIndex;
  final double headingDeg;
  final Map<String, int> warningCounts;

  SimulationState({
    required this.start,
    required this.end,
    required this.current,
    required this.isRunning,
    required this.isPaused,
    required this.follow,
    required this.loop,
    required this.speedKmh,
    required this.routeLengthM,
    required this.segmentIndex,
    required this.headingDeg,
    required this.warningCounts,
  });

  SimulationState copyWith({
    LatLng? start,
    LatLng? end,
    LatLng? current,
    bool? isRunning,
    bool? isPaused,
    bool? follow,
    bool? loop,
    double? speedKmh,
    double? routeLengthM,
    int? segmentIndex,
    double? headingDeg,
    Map<String, int>? warningCounts,
  }) {
    return SimulationState(
      start: start ?? this.start,
      end: end ?? this.end,
      current: current ?? this.current,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      follow: follow ?? this.follow,
      loop: loop ?? this.loop,
      speedKmh: speedKmh ?? this.speedKmh,
      routeLengthM: routeLengthM ?? this.routeLengthM,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      headingDeg: headingDeg ?? this.headingDeg,
      warningCounts: warningCounts ?? this.warningCounts,
    );
  }
}

class SimulationController extends ChangeNotifier {
  LatLng? startPoint;
  LatLng? endPoint;
  List<LatLng> routePoints = [];
  LatLng? currentPosition;
  bool follow = true;
  bool loop = false;
  bool isRunning = false;
  bool isPaused = false;
  double speedKmh = 40;
  double routeLengthM = 0;
  int segmentIndex = 0;
  double headingDeg = 0;

  final ll.Distance _distance = const ll.Distance();
  NavigationSimulator? _sim;
  final StreamController<Position> _posStream =
      StreamController<Position>.broadcast();
  WarningEngine? _warningEngine;
  StreamSubscription<Warning>? _warningSub;
  bool _warningStarted = false;
  final Map<String, int> _warningCounts = {
    'speed': 0,
    'camera': 0,
    'danger': 0,
    'rail': 0,
  };

  SimulationState get state => SimulationState(
        start: startPoint,
        end: endPoint,
        current: currentPosition,
        isRunning: isRunning,
        isPaused: isPaused,
        follow: follow,
        loop: loop,
        speedKmh: speedKmh,
        routeLengthM: routeLengthM,
        segmentIndex: segmentIndex,
        headingDeg: headingDeg,
        warningCounts: Map<String, int>.from(_warningCounts),
      );

  void setPoint(LatLng point) {
    if (startPoint == null) {
      startPoint = point;
      endPoint = null;
      _resetRoute();
    } else if (endPoint == null) {
      endPoint = point;
    } else {
      startPoint = point;
      endPoint = null;
      _resetRoute();
    }
    notifyListeners();
  }

  void setSpeed(double v) {
    speedKmh = v.clamp(5, 120);
    _sim?.setSpeed(speedKmh);
    notifyListeners();
  }

  void toggleFollow(bool v) {
    follow = v;
    notifyListeners();
  }

  void toggleLoop(bool v) {
    loop = v;
    notifyListeners();
  }

  Future<void> start() async {
    if (isRunning) return;
    if (startPoint == null || endPoint == null) return;

    routePoints = await SimulationRouteMock.buildRoute(startPoint!, endPoint!);
    routeLengthM = _computeLength(routePoints);
    segmentIndex = 0;
    currentPosition = routePoints.isNotEmpty ? routePoints.first : null;

    await _ensureWarningEngine();

    _sim = NavigationSimulator(
      routePoints: routePoints,
      speedKmh: speedKmh,
    );
    _sim!.onPositionUpdate = _handleUpdate;
    _sim!.start(loop: loop);

    isRunning = true;
    isPaused = false;
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;
    _sim?.pause();
    isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (!isRunning) return;
    _sim?.resume();
    isPaused = false;
    notifyListeners();
  }

  void stop() {
    _sim?.stop();
    isRunning = false;
    isPaused = false;
    notifyListeners();
  }

  void clearRoute() {
    stop();
    startPoint = null;
    endPoint = null;
    _resetRoute();
    notifyListeners();
  }

  @override
  void dispose() {
    _sim?.stop();
    _posStream.close();
    _warningSub?.cancel();
    super.dispose();
  }

  // ---- internal helpers ----
  void _resetRoute() {
    routePoints = [];
    routeLengthM = 0;
    segmentIndex = 0;
    currentPosition = null;
  }

  Future<void> _ensureWarningEngine() async {
    if (_warningStarted) return;
    try {
      _warningEngine = WarningEngine();
      await _warningEngine!.start(_posStream.stream);
      _warningStarted = true;
      _warningSub = WarningManager.instance.stream.listen((w) {
        _warningCounts[w.type] = (_warningCounts[w.type] ?? 0) + 1;
        notifyListeners();
      });
    } catch (_) {
      // If warning engine cannot start, ignore silently.
    }
  }

  void _handleUpdate(SimPositionUpdate update) {
    currentPosition = update.position;
    segmentIndex = update.segmentIndex;
    headingDeg = update.headingDeg;

    _emitPositionToWarning(update);

    if (!isRunning) return;
    if (!loop &&
        update.segmentIndex >= routePoints.length - 1 &&
        !_sim!.isRunning) {
      stop();
    }
    notifyListeners();
  }

  void _emitPositionToWarning(SimPositionUpdate update) {
    try {
      _posStream.add(
        Position(
          latitude: update.position.latitude,
          longitude: update.position.longitude,
          timestamp: update.timestamp,
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 1,
          heading: update.headingDeg,
          headingAccuracy: 5,
          speed: update.speedKmh / 3.6,
          speedAccuracy: 1,
        ),
      );
    } catch (_) {
      // best-effort
    }
  }

  double _computeLength(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    double total = 0;
    for (var i = 1; i < pts.length; i++) {
      total += _distance.as(
        ll.LengthUnit.Meter,
        ll.LatLng(pts[i - 1].latitude, pts[i - 1].longitude),
        ll.LatLng(pts[i].latitude, pts[i].longitude),
      );
    }
    return total;
  }
}

