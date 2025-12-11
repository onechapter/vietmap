import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' show cos, sin;

import '../../core/logger.dart';
import '../../core/retry.dart';
import '../../core/grid_index.dart';
import '../../core/speed_smoother.dart';
import '../../data/cameras/camera_model.dart';
import '../../data/cameras/camera_repository.dart';
import '../../data/rules/rule_models.dart';
import '../../data/rules/rule_repository.dart';
import '../../ui/hud/speedometer.dart';
import '../../ui/hud/speed_limit_sign.dart';
import '../../ui/widgets/camera_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;
  late final FlutterTts _tts;
  final Distance _distance = const Distance();
  LatLng? _currentLatLng;
  String? _error;
  bool _loading = true;
  List<CameraModel> _cameras = [];
  String? _cameraError;
  final Set<String> _cameraAlerted = {};
  final Map<String, DateTime> _cameraAlertTimestamps = {};
  bool _mapReady = false;
  bool _ttsEnabled = true;
  List<SpeedRule> _speedRules = [];
  List<DangerRule> _dangerRules = [];
  List<RailwayRule> _railwayRules = [];
  double _currentSpeedKmh = 0;
  double _filteredSpeedKmh = 0;
  int? _currentSpeedLimit;
  bool _hudMode = false;
  final SpeedSmoother _smoother = SpeedSmoother(alpha: 0.25);
  final GridIndex<CameraModel> _cameraGrid = GridIndex(cellSize: 0.01);
  final GridIndex<SpeedRule> _speedGrid = GridIndex(cellSize: 0.01);
  final GridIndex<DangerRule> _dangerGrid = GridIndex(cellSize: 0.01);
  final GridIndex<RailwayRule> _railwayGrid = GridIndex(cellSize: 0.01);
  final Map<String, DateTime> _speedCooldown = {};
  final Map<String, DateTime> _dangerCooldown = {};
  final Map<String, DateTime> _railCooldown = {};

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadCameras();
    _loadRules();
    _initLocationTracking();
  }

  @override
  void dispose() {
    try {
      _positionSub?.cancel();
    } catch (_) {}
    try {
      _mapController.dispose();
    } catch (_) {}
    try {
      _tts.stop();
    } catch (_) {}
    super.dispose();
  }

  void _log(String message) {
    appLog('[MapScreen] $message');
  }

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await _tts.setLanguage('vi-VN');
      await _tts.setSpeechRate(0.9);
      await _tts.setVolume(1.0);
      _log('TTS initialized');
    } catch (e) {
      _log('TTS init failed: $e');
      _ttsEnabled = false;
    }
  }

  Future<void> _initLocationTracking() async {
    final backoff = ExponentialBackoff(maxAttempts: 5);
    try {
      _log('Init location tracking');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Vui lòng bật dịch vụ vị trí (GPS).';
          _loading = false;
        });
        _log('Location service disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Ứng dụng cần quyền truy cập vị trí.';
          _loading = false;
        });
        _log('Permission denied');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Quyền vị trí bị từ chối vĩnh viễn. Hãy bật trong cài đặt.';
          _loading = false;
        });
        _log('Permission denied forever');
        return;
      }

      final current = await backoff.run(() => Geolocator.getCurrentPosition());
      final initialLatLng = LatLng(current.latitude, current.longitude);
      setState(() {
        _currentLatLng = initialLatLng;
        _loading = false;
      });
      _log('Got initial position: $initialLatLng');
      _moveTo(initialLatLng);

      final locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen(
        (Position pos) {
          final next = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _currentLatLng = next;
            _currentSpeedKmh = (pos.speed * 3.6).clamp(0, 300);
            _filteredSpeedKmh = _smoother.update(_currentSpeedKmh);
          });
          _log('Tick pos=$next speed_raw=${_currentSpeedKmh.toStringAsFixed(1)} speed_f=${_filteredSpeedKmh.toStringAsFixed(1)} bucket=${_bucketKey(next)}');
          _checkProximity();
          _checkRules();
          _updateCurrentSpeedLimit();
        },
        onError: (e) async {
          _log('Position stream error: $e');
          await Future.delayed(const Duration(seconds: 1));
          _positionSub?.cancel();
          await _initLocationTracking();
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Không lấy được vị trí: $e';
        _loading = false;
      });
      _log('Location init failed: $e');
    }
  }

  void _moveTo(LatLng target) {
    if (!_mapReady) return;
    try {
      final zoom = _mapController.camera.zoom;
      _mapController.move(target, zoom);
    } catch (_) {
      // Nếu map chưa render kịp, bỏ qua.
    }
  }

  Future<void> _checkProximity() async {
    if (_currentLatLng == null || _cameras.isEmpty) return;
    final candidates = _cameraGrid.queryNeighborhood(_currentLatLng!.latitude, _currentLatLng!.longitude);
    for (final cam in candidates) {
      final d = _distance(LatLng(cam.lat, cam.lng), _currentLatLng!);
      if (d < 150) {
        if (!_cameraAlerted.contains(cam.id)) {
          final last = _cameraAlertTimestamps[cam.id];
          final now = DateTime.now();
          if (last == null || now.difference(last) > const Duration(seconds: 40)) {
            _cameraAlerted.add(cam.id);
            _cameraAlertTimestamps[cam.id] = now;
            await _speakWarning();
            _log('Alerted camera ${cam.id} at ${d.toStringAsFixed(1)}m');
          }
        }
      } else if (d > 300) {
        _cameraAlerted.remove(cam.id);
      }
    }
  }

  Future<void> _speakWarning() async {
    if (!_ttsEnabled) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }
      _log('TTS disabled, vibrated instead');
      return;
    }
    try {
      await _tts.speak('Sắp đến camera phạt nguội phía trước');
    } catch (_) {
      _ttsEnabled = false;
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }
      _log('TTS speak failed, disabled & vibrated');
    }
  }

  Future<void> _loadCameras() async {
    try {
      final repo = CameraRepository();
      final data = await repo.load();
      if (!mounted) return;
      setState(() {
        _cameras = data;
        _cameraGridBuckets(data);
      });
      _log('Loaded ${data.length} cameras');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Không tải được danh sách camera: $e';
      });
      _log('Load cameras failed: $e');
    }
  }

  Future<void> _loadRules() async {
    final repo = RuleRepository();
    try {
      final speeds = await repo.loadSpeedRules();
      final dangers = await repo.loadDangerRules();
      final rails = await repo.loadRailwayRules();
      if (!mounted) return;
      setState(() {
        _speedRules = speeds;
        _dangerRules = dangers;
        _railwayRules = rails;
        _speedGridBuckets(speeds);
        _dangerGridBuckets(dangers);
        _railwayGridBuckets(rails);
      });
      _log('Rules loaded: speed=${speeds.length}, danger=${dangers.length}, rail=${rails.length}');
    } catch (e) {
      _log('Load rules failed: $e');
    }
  }

  Future<void> _checkRules() async {
    if (_currentLatLng == null) return;
    final pos = _currentLatLng!;
    for (final rule in _speedGrid.queryNeighborhood(pos.latitude, pos.longitude)) {
      final d = _distance(rule.point, _currentLatLng!);
      if (d <= rule.radiusM) {
        if (_filteredSpeedKmh > rule.speedLimit + 5) {
          final key = 'speed_${rule.id}';
          final now = DateTime.now();
          final last = _speedCooldown[key];
          if (last == null || now.difference(last) > const Duration(seconds: 40)) {
            _speedCooldown[key] = now;
            _log('Over speed at ${rule.name}: ${_filteredSpeedKmh.toStringAsFixed(1)} > ${rule.speedLimit}');
            await _speakWarning();
          } else {
            _log('Speed cooldown skip ${rule.id}');
          }
        }
      }
    }
    for (final rule in _dangerGrid.queryNeighborhood(pos.latitude, pos.longitude)) {
      final inside = _isInDanger(rule, pos);
      if (inside) {
        final key = 'danger_${rule.id}';
        final now = DateTime.now();
        final last = _dangerCooldown[key];
        if (last == null || now.difference(last) > const Duration(seconds: 60)) {
          _dangerCooldown[key] = now;
          _log('Danger zone: ${rule.type} - ${rule.name}');
          await _speakWarning();
        } else {
          _log('Danger cooldown skip ${rule.id}');
        }
      }
    }
    for (final rule in _railwayGrid.queryNeighborhood(pos.latitude, pos.longitude)) {
      final d = _distance(rule.point, _currentLatLng!);
      if (d <= 300) {
        final key = 'rail_${rule.id}';
        final now = DateTime.now();
        final last = _railCooldown[key];
        if (last == null || now.difference(last) > const Duration(seconds: 60)) {
          _railCooldown[key] = now;
          _log('Railway ahead: ${rule.name}');
          await _speakWarning();
        } else {
          _log('Rail cooldown skip ${rule.id}');
        }
      }
    }
  }

  void _updateCurrentSpeedLimit() {
    int? best;
    double bestDist = double.infinity;
    final pos = _currentLatLng;
    if (pos == null) return;

    for (final cam in _cameraGrid.queryNeighborhood(pos.latitude, pos.longitude)) {
      if (cam.speedLimit == null) continue;
      final d = _distance(LatLng(cam.lat, cam.lng), pos);
      if (d < bestDist) {
        bestDist = d;
        best = cam.speedLimit;
      }
    }

    for (final rule in _speedGrid.queryNeighborhood(pos.latitude, pos.longitude)) {
      final d = _distance(rule.point, pos);
      if (d <= rule.radiusM && d < bestDist) {
        bestDist = d;
        best = rule.speedLimit.toInt();
      }
    }

    if (best != _currentSpeedLimit) {
      setState(() {
        _currentSpeedLimit = best;
      });
    }
  }

  String _bucketKey(LatLng pos) {
    final gx = (pos.latitude / 0.01).floor();
    final gy = (pos.longitude / 0.01).floor();
    return '$gx:$gy';
  }

  void _cameraGridBuckets(List<CameraModel> cams) {
    for (final c in cams) {
      _cameraGrid.add(c.lat, c.lng, c);
    }
    _log('Camera grid buckets=${_cameraGrid.bucketCount()}');
  }

  void _speedGridBuckets(List<SpeedRule> rules) {
    for (final r in rules) {
      _speedGrid.add(r.point.latitude, r.point.longitude, r);
    }
    _log('Speed grid buckets=${_speedGrid.bucketCount()}');
  }

  void _dangerGridBuckets(List<DangerRule> rules) {
    for (final r in rules) {
      final lat = r.polygon.isNotEmpty ? r.polygon.first.latitude : r.point.latitude;
      final lng = r.polygon.isNotEmpty ? r.polygon.first.longitude : r.point.longitude;
      _dangerGrid.add(lat, lng, r);
    }
    _log('Danger grid buckets=${_dangerGrid.bucketCount()}');
  }

  void _railwayGridBuckets(List<RailwayRule> rules) {
    for (final r in rules) {
      _railwayGrid.add(r.point.latitude, r.point.longitude, r);
    }
    _log('Rail grid buckets=${_railwayGrid.bucketCount()}');
  }

  bool _isInDanger(DangerRule rule, LatLng pos) {
    if (rule.polygon.isNotEmpty) {
      return _pointInPolygon(pos.latitude, pos.longitude, rule.polygon);
    }
    if (rule.radiusM > 0) {
      final d = _distance(rule.point, pos);
      return d <= rule.radiusM;
    }
    return false;
  }

  bool _pointInPolygon(double lat, double lng, List<LatLng> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].latitude;
      final yi = poly[i].longitude;
      final xj = poly[j].latitude;
      final yj = poly[j].longitude;
      final intersect = ((yi > lng) != (yj > lng)) &&
          (lat < (xj - xi) * (lng - yi) / ((yj - yi) == 0 ? 1e-9 : (yj - yi)) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    if (_currentLatLng != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: _currentLatLng!,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
        ),
      );
    }
    if (_cameras.isNotEmpty && _currentLatLng != null) {
      final visible = _cameraGrid.queryNeighborhood(_currentLatLng!.latitude, _currentLatLng!.longitude);
      markers.addAll(
        visible.map(
          (cam) => Marker(
            width: 40,
            height: 40,
            point: LatLng(cam.lat, cam.lng),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => CameraBottomSheet(camera: cam),
                );
              },
              child: Image.asset('assets/icons/camera.png', width: 32, height: 32),
            ),
          ),
        ),
      );
    }

    final polygons = <Polygon>[];
    for (final rule in _dangerGrid.queryNeighborhood(
      _currentLatLng?.latitude ?? 0,
      _currentLatLng?.longitude ?? 0,
    )) {
      if (rule.polygon.isNotEmpty) {
        polygons.add(
          Polygon(
            points: rule.polygon,
            color: Colors.red.withOpacity(0.15),
            borderStrokeWidth: 2,
            borderColor: Colors.red,
          ),
        );
      } else if (rule.radiusM > 0 && _currentLatLng != null) {
        final center = rule.point;
        final circle = List.generate(
          40,
          (i) {
            final ang = 2 * 3.14159 * i / 40;
            final dx = (rule.radiusM / 111320) * cos(ang);
            final dy = (rule.radiusM / 111320) * sin(ang);
            return LatLng(center.latitude + dx, center.longitude + dy);
          },
        );
        polygons.add(
          Polygon(
            points: circle,
            color: Colors.red.withOpacity(0.15),
            borderStrokeWidth: 2,
            borderColor: Colors.red,
          ),
        );
      }
    }

    final railwayMarkers = _railwayGrid
        .queryNeighborhood(_currentLatLng?.latitude ?? 0, _currentLatLng?.longitude ?? 0)
        .map(
          (r) => Marker(
            width: 36,
            height: 36,
            point: r.point,
            child: Column(
              children: const [
                Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                Icon(Icons.horizontal_rule, size: 12, color: Colors.black54),
              ],
            ),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ OSM'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Stack(
                  children: [
                    if (_hudMode)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: Icon(Icons.screen_rotation_alt, color: Colors.orange),
                      ),
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLatLng ?? const LatLng(10.762622, 106.660172),
                        initialZoom: 15,
                        onMapReady: () {
                      _mapReady = true;
                      if (_currentLatLng != null) {
                        _moveTo(_currentLatLng!);
                      }
                      _log('Map ready');
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.vietmap_app',
                          errorTileCallback: (tile, error, stackTrace) {
                            _log('Tile error: $error');
                          },
                        ),
                        if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
                        MarkerLayer(markers: markers),
                        if (railwayMarkers.isNotEmpty) MarkerLayer(markers: railwayMarkers),
                      ],
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _hudMode
                              ? const SizedBox.shrink()
                              : Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      'cam:${_cameras.length} speed:${_speedRules.length} danger:${_dangerRules.length} rail:${_railwayRules.length}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SpeedLimitSign(
                                speedLimit: _currentSpeedLimit,
                                isOver: _currentSpeedLimit != null && _filteredSpeedKmh > (_currentSpeedLimit! + 5),
                              ),
                              const SizedBox(width: 12),
                              Speedometer(speedKmh: _filteredSpeedKmh),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_cameraError != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Card(
                          color: Colors.red.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _cameraError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: _currentLatLng == null
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _hudMode = !_hudMode;
                });
                _moveTo(_currentLatLng!);
              },
              child: Icon(_hudMode ? Icons.screen_rotation : Icons.my_location),
            ),
    );
  }
}

