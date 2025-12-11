import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/logger.dart';
import '../../core/speed_smoother.dart';
import '../../core/engine/engine_config.dart';
import '../../data/repositories/danger_zone_repository.dart';
import '../../data/repositories/railway_repository.dart';
import '../../data/repositories/camera_repository.dart';
import '../../data/repositories/speed_limit_repository.dart';
import '../../data/cooldown_db.dart';
import 'warning_model.dart';
import 'warning_manager.dart';

class WarningEngine {
  StreamSubscription<Position>? _positionSub;
  final SpeedSmoother _smoother = SpeedSmoother(alpha: 0.25);
  final Distance _distance = const Distance();
  final CooldownDb _cooldownDb = CooldownDb.instance;
  final WarningManager _warningManager = WarningManager.instance;
  bool _running = false;

  // Warm-up flag
  bool _warmedUp = false;

  // Radius configs
  static const double cameraRadiusM = 150;
  static const double railwayRadiusM = 300;
  static const double dangerZoneRadiusM = 50;
  static const double speedCheckRadiusM = 100;

  // Cooldowns
  static const Duration cameraCooldown = Duration(seconds: 40);
  static const Duration dangerCooldown = Duration(seconds: 60);
  static const Duration railwayCooldown = Duration(seconds: 60);
  static const Duration speedCooldown = Duration(seconds: 40);

  Future<void> start(Stream<Position> locationStream) async {
    if (_running) return;

    await _cooldownDb.init();
    await _loadRepositories();

    // Warm-up JIT engine
    if (!_warmedUp) {
      await _warmUp();
      _warmedUp = true;
    }

    _running = true;
    appLog('WarningEngine: Starting...');
    if (EngineConfig.enableAdaptiveFrequency) {
      appLog('WarningEngine: Adaptive frequency active');
    }

    _positionSub = locationStream.listen(
      (position) => _processLocation(position),
      onError: (e) {
        appLog('WarningEngine: Location stream error: $e');
      },
    );
  }

  void stop() {
    _running = false;
    _positionSub?.cancel();
    _positionSub = null;
    appLog('WarningEngine: Stopped');
  }

  /// Warm-up JIT engine with empty query
  Future<void> _warmUp() async {
    try {
      appLog('WarningEngine: Warming up JIT engine...');
      // Run empty queries to warm up
      await DangerZoneRepository.instance.queryNearby(0, 0, 1);
      await RailwayRepository.instance.queryNearby(0, 0, 1);
      await CameraRepository.instance.queryNearby(0, 0, 1);
      await SpeedLimitRepository.instance.queryNearby(0, 0, 1);
      appLog('WarningEngine: Warm-up complete');
    } catch (e) {
      appLog('WarningEngine: Warm-up failed: $e');
    }
  }

  Future<void> _loadRepositories() async {
    await DangerZoneRepository.instance.load();
    await RailwayRepository.instance.load();
    await CameraRepository.instance.load();
    await SpeedLimitRepository.instance.load();
  }

  Future<void> _processLocation(Position position) async {
    if (!_running) return;

    final lat = position.latitude;
    final lng = position.longitude;
    final speedMs = position.speed;
    final speedKmh = (speedMs * 3.6).clamp(0.0, 300.0);
    final filteredSpeed = _smoother.update(speedKmh);

    // Check cameras
    await _checkCameras(lat, lng);

    // Check railway
    await _checkRailway(lat, lng);

    // Check danger zones
    await _checkDangerZones(lat, lng);

    // Check speed limits
    await _checkSpeedLimits(lat, lng, filteredSpeed);
  }

  /// Evaluate location directly (for Route Simulator)
  Future<void> evaluate(LatLng location, {double speedKmh = 0.0}) async {
    if (!_running) return;

    appLog('Warning evaluated at $location');
    
    final lat = location.latitude;
    final lng = location.longitude;
    final filteredSpeed = speedKmh > 0 ? _smoother.update(speedKmh) : 0.0;

    // Check cameras
    await _checkCameras(lat, lng);

    // Check railway
    await _checkRailway(lat, lng);

    // Check danger zones
    await _checkDangerZones(lat, lng);

    // Check speed limits (only if speed > 0)
    if (filteredSpeed > 0) {
      await _checkSpeedLimits(lat, lng, filteredSpeed);
    }
  }

  Future<void> _checkCameras(double lat, double lng) async {
    final repo = CameraRepository.instance;
    final nearby = repo.queryNearby(lat, lng, cameraRadiusM);

    for (final camera in nearby) {
      final dist = _distance.as(
        LengthUnit.Meter,
        LatLng(lat, lng),
        LatLng(camera.lat, camera.lng),
      );

      if (dist <= cameraRadiusM) {
        final inCooldown = await _cooldownDb.isInCooldown(
          camera.id,
          'camera',
          cameraCooldown,
        );

        if (!inCooldown) {
          await _cooldownDb.setCooldown(camera.id, 'camera');
          final warning = Warning(
            id: camera.id,
            type: 'camera',
            distance: dist,
            lat: camera.lat,
            lng: camera.lng,
          );
          _warningManager.emit(warning);
          appLog('WarningEngine: Camera warning: ${camera.id} at ${dist.toStringAsFixed(1)}m');
        }
      }
    }
  }

  Future<void> _checkRailway(double lat, double lng) async {
    final repo = RailwayRepository.instance;
    final nearby = repo.queryNearby(lat, lng, railwayRadiusM);

    for (final railway in nearby) {
      final dist = _distance.as(
        LengthUnit.Meter,
        LatLng(lat, lng),
        LatLng(railway.lat, railway.lng),
      );

      if (dist <= railwayRadiusM) {
        final inCooldown = await _cooldownDb.isInCooldown(
          railway.id,
          'railway',
          railwayCooldown,
        );

        if (!inCooldown) {
          await _cooldownDb.setCooldown(railway.id, 'railway');
          final warning = Warning(
            id: railway.id,
            type: 'railway',
            distance: dist,
            lat: railway.lat,
            lng: railway.lng,
          );
          _warningManager.emit(warning);
          appLog('WarningEngine: Railway warning: ${railway.id} at ${dist.toStringAsFixed(1)}m');
        }
      }
    }
  }

  Future<void> _checkDangerZones(double lat, double lng) async {
    final repo = DangerZoneRepository.instance;
    final nearby = repo.queryNearby(lat, lng, dangerZoneRadiusM * 2); // Query wider area

    for (final zone in nearby) {
      final dist = _distance.as(
        LengthUnit.Meter,
        LatLng(lat, lng),
        LatLng(zone.lat, zone.lng),
      );

      // Check if inside polygon or within 50m of centroid
      if (dist <= dangerZoneRadiusM) {
        final inCooldown = await _cooldownDb.isInCooldown(
          zone.id,
          'danger',
          dangerCooldown,
        );

        if (!inCooldown) {
          await _cooldownDb.setCooldown(zone.id, 'danger');
          final warning = Warning(
            id: zone.id,
            type: 'danger',
            distance: dist,
            lat: zone.lat,
            lng: zone.lng,
          );
          _warningManager.emit(warning);
          appLog('WarningEngine: Danger zone warning: ${zone.id} at ${dist.toStringAsFixed(1)}m');
        }
      }
    }
  }

  Future<void> _checkSpeedLimits(double lat, double lng, double currentSpeedKmh) async {
    final repo = SpeedLimitRepository.instance;
    final nearby = repo.queryNearby(lat, lng, speedCheckRadiusM);

    for (final limit in nearby) {
      if (currentSpeedKmh > limit.speedLimit + 5) {
        final inCooldown = await _cooldownDb.isInCooldown(
          limit.id,
          'speed',
          speedCooldown,
        );

        if (!inCooldown) {
          await _cooldownDb.setCooldown(limit.id, 'speed');
          final warning = Warning(
            id: limit.id,
            type: 'speed',
            distance: 0,
            lat: limit.lat,
            lng: limit.lng,
          );
          _warningManager.emit(warning);
          appLog('WarningEngine: Speed warning: ${limit.id} - ${currentSpeedKmh.toStringAsFixed(1)} > ${limit.speedLimit}');
        }
      }
    }
  }
}

