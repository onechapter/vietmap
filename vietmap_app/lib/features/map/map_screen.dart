import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' show cos, sin;

import '../../core/logger.dart';
import '../../core/grid_index.dart';
import '../../core/speed_smoother.dart';
import '../../data/cameras/camera_model.dart';
import '../../data/cameras/camera_repository.dart';
import '../../data/repositories/camera_repository.dart' as NewCameraRepo;
import '../../data/repositories/speed_limit_repository.dart';
import '../../data/repositories/danger_zone_repository.dart';
import '../../data/repositories/railway_repository.dart';
import '../../data/rules/rule_models.dart';
import '../../data/rules/rule_repository.dart';
import '../../ui/hud/speedometer.dart';
import '../../ui/hud/speed_limit_sign.dart';
import '../../ui/widgets/camera_bottom_sheet.dart';
import '../../ui/widgets/warning_banner.dart';
import '../debug/debug_screen.dart';
import '../debug/fake_location_service.dart';
import '../debug/route_simulator_service.dart';
import '../../features/warning/warning_model.dart';
import '../../config/map_layers_loader.dart';
import '../../core/location/location_controller.dart';
import 'map_service.dart';
import 'map_screen_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
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
  final MapService _mapService = MapService.instance;
  final MapLayersLoader _layersLoader = MapLayersLoader.instance;
  bool _hasVectorTiles = false;
  late final MapScreenController _controller;
  StreamSubscription? _warningStreamSub;
  Warning? _currentWarning;
  // ignore: unused_field
  StreamSubscription<Position?>? _fakeSub;
  bool _fakeEnabled = false;
  Marker? _fakeMarker;
  bool _autoFollowFake = true;
  bool _routeSimListenerSetup = false;

  @override
  void initState() {
    super.initState();
    _controller = MapScreenController();
    _initTts();
    _initMapService();
    _initController();
    _loadCameras();
    _loadRules();
    _initLocationTracking();
  }

  Future<void> _initController() async {
    await _controller.init();
    _warningStreamSub = _controller.warningStream.listen((warning) {
      if (mounted) {
        setState(() {
          _currentWarning = warning;
        });
      }
    });
    // Start warning engine when map is ready
    await _controller.startWarningEngine();
    
    // Đảm bảo repositories mới được load cho counter
    try {
      await NewCameraRepo.CameraRepository.instance.load();
      await SpeedLimitRepository.instance.load();
      await DangerZoneRepository.instance.load();
      await RailwayRepository.instance.load();
      appLog('[MapScreen] New repositories loaded for counter');
    } catch (e) {
      appLog('[MapScreen] Failed to load new repositories: $e');
    }

    // Lắng nghe vị trí giả lập
    _fakeSub = FakeLocationService.instance.stream.listen((pos) {
      if (!mounted) return;
      if (pos == null) {
        setState(() {
          _fakeEnabled = false;
          _fakeMarker = null;
        });
        return;
      }
      _applyPosition(pos, isFake: true);
    });
  }


  Future<void> _initMapService() async {
    try {
      await _mapService.init();
      await _layersLoader.load();
      if (mounted) {
        setState(() {
          _hasVectorTiles = _mapService.hasMbtiles();
        });
      }
      _log('MapService initialized: hasMbtiles=${_mapService.hasMbtiles()}');
      if (_mapService.hasMbtiles()) {
        _log('MBTiles available: ${_mapService.getMbtilesPath()}');
        _log('Tile URL template: ${_mapService.getTileUrlTemplate()}');
      }
    } catch (e) {
      _log('MapService init failed: $e');
    }
  }

  @override
  void dispose() {
    try {
      _positionSub?.cancel();
    } catch (_) {}
    try {
      _warningStreamSub?.cancel();
    } catch (_) {}
    try {
      _controller.dispose();
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

  void _applyPosition(Position pos, {required bool isFake}) {
    final next = LatLng(pos.latitude, pos.longitude);
    setState(() {
      // Nếu vừa chuyển sang fake, bật lại auto-follow để camera bám vị trí giả
      if (isFake && !_fakeEnabled) {
        _autoFollowFake = true;
      }
      _fakeEnabled = isFake;
      _currentLatLng = next;
      _currentSpeedKmh = (pos.speed * 3.6).clamp(0, 300);
      // Bypass EMA smoothing in simulation mode (TASK 2)
      _filteredSpeedKmh = isFake 
          ? _currentSpeedKmh  // Use raw speed in simulation
          : _smoother.update(_currentSpeedKmh);  // Use smoothed speed in real GPS
      _fakeMarker = isFake
          ? Marker(
              width: 38,
              height: 38,
              point: next,
              child: const Icon(Icons.place, color: Colors.deepPurple, size: 34),
            )
          : null;
    });
    _log('Tick pos=$next fake=$isFake speed_raw=${_currentSpeedKmh.toStringAsFixed(1)} speed_f=${_filteredSpeedKmh.toStringAsFixed(1)} bucket=${_bucketKey(next)}');
    _checkProximity();
    _checkRules();
    _updateCurrentSpeedLimit();
    if (isFake && _mapReady && _autoFollowFake) {
      // Không ép zoom lại, giữ mức zoom hiện tại để tránh cảm giác "nhảy"
      _moveTo(next);
    }
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
    try {
      _log('Init location tracking');
      
      // Start unified LocationController (will start real GPS if not in simulation mode)
      await LocationController.instance.startRealGps();
      
      // Listen to unified positionStream (converts LocationData to Position)
      _positionSub = LocationController.instance.positionStream.listen(
        (Position pos) {
          if (!mounted) return;
          final isFromSimulator = LocationController.instance.isSimulationMode;
          _log('Location update: ${pos.latitude}, ${pos.longitude}, speed=${(pos.speed * 3.6).toStringAsFixed(1)} km/h (sim: $isFromSimulator)');
          _applyPosition(pos, isFake: isFromSimulator);
        },
        onError: (e) {
          _log('Location stream error: $e');
        },
      );

      // Get initial position (TASK 0: Auto follow camera)
      final current = LocationController.instance.currentPosition;
      if (current != null) {
        final initialLatLng = LatLng(current.latitude, current.longitude);
        setState(() {
          _currentLatLng = initialLatLng;
          _loading = false;
        });
        _log('Got initial position: $initialLatLng');
        // Auto follow camera on startup (TASK 0)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _moveTo(initialLatLng, zoom: 16.0);
          }
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Không lấy được vị trí: $e';
        _loading = false;
      });
      _log('Location init failed: $e');
    }
  }

  void _moveTo(LatLng target, {double? zoom}) {
    if (!_mapReady) return;
    try {
      final z = zoom ?? _mapController.camera.zoom;
      _mapController.move(target, z);
    } catch (_) {
      // Nếu map chưa render kịp, bỏ qua.
    }
  }

  List<CameraModel> _queryCamerasInRadius(double lat, double lng, {required double radiusKm}) {
    if (_cameras.isEmpty) return [];
    final radiusM = radiusKm * 1000;
    return _cameras.where((cam) {
      final d = _distance(LatLng(cam.lat, cam.lng), LatLng(lat, lng));
      return d <= radiusM;
    }).toList();
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
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 500);
      }
      _log('TTS disabled, vibrated instead');
      return;
    }
    try {
      await _tts.speak('Sắp đến camera phạt nguội phía trước');
    } catch (_) {
      _ttsEnabled = false;
      if (await Vibration.hasVibrator()) {
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

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Setup route simulator listener (chỉ một lần)
    if (!_routeSimListenerSetup) {
      _routeSimListenerSetup = true;
      ref.listen<LatLng?>(routeSimulatorProvider, (prev, next) {
        if (!mounted) return;
        if (next != null && prev == null) {
          // Simulator vừa bắt đầu
          _moveTo(next, zoom: 16.0);
          _autoFollowFake = true;
          appLog('MapScreen: Auto-zoomed to simulator start position');
        }
      });
    }
    
    // StreamBuilder để hiển thị vị trí mượt mà từ LocationController
    return StreamBuilder<LocationData>(
      stream: LocationController.instance.stream,
      builder: (context, snapshot) {
        LatLng? displayLocation;
        if (snapshot.hasData) {
          final loc = snapshot.data!;
          displayLocation = LatLng(loc.lat, loc.lng);
          
          // Auto-follow camera when location updates (TASK 0)
          // In simulation mode: follow if auto-follow enabled
          // In real GPS mode: follow on first location or if auto-follow enabled
          final shouldFollow = LocationController.instance.isSimulationMode 
              ? _autoFollowFake 
              : true;  // Always follow in real GPS mode (TASK 0)
          
          if (shouldFollow && _mapReady && displayLocation != null) {
            final locToFollow = displayLocation;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Don't force zoom, just move camera smoothly
                _moveTo(locToFollow);
              }
            });
          }
        } else {
          displayLocation = _currentLatLng;
        }
        
        return _buildMapContent(displayLocation);
      },
    );
  }

  Widget _buildMapContent(LatLng? displayLocation) {
    
    final markers = <Marker>[];
    if (displayLocation != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: displayLocation,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
        ),
      );
    }
    if (_cameras.isNotEmpty && displayLocation != null) {
      // Query cameras trong bán kính lớn hơn (5x5 cells thay vì 3x3)
      final visible = _queryCamerasInRadius(displayLocation.latitude, displayLocation.longitude, radiusKm: 5.0);
      _log('Cameras visible: ${visible.length} / ${_cameras.length}');
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
              child: Image.asset('assets/icons/camera.png', width: 32, height: 32, errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.camera_alt, color: Colors.red, size: 32);
              }),
            ),
          ),
        ),
      );
    }

    final polygons = <Polygon>[];
    final dangerStyle = _layersLoader.getStyle('danger_zone');
    final dangerColor = dangerStyle != null
        ? _parseColor(dangerStyle.color)
        : Colors.red;
    final dangerOpacity = dangerStyle?.opacity ?? 0.6;
    final dangerStrokeColor = (dangerStyle?.strokeColor != null)
        ? _parseColor(dangerStyle!.strokeColor!)
        : Colors.red;
    final dangerStrokeWidth = dangerStyle?.strokeWidth ?? 1.0;

    for (final rule in _dangerGrid.queryNeighborhood(
      _currentLatLng?.latitude ?? 0,
      _currentLatLng?.longitude ?? 0,
    )) {
      if (rule.polygon.isNotEmpty) {
        polygons.add(
          Polygon(
            points: rule.polygon,
            color: dangerColor.withValues(alpha: dangerOpacity),
            borderStrokeWidth: dangerStrokeWidth,
            borderColor: dangerStrokeColor,
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
            color: dangerColor.withValues(alpha: dangerOpacity),
            borderStrokeWidth: dangerStrokeWidth,
            borderColor: dangerStrokeColor,
          ),
        );
      }
    }

    final railwayStyle = _layersLoader.getStyle('railway');
    final railwayColor = railwayStyle != null
        ? _parseColor(railwayStyle.color)
        : Colors.blue;
    final railwayMarkers = _railwayGrid
        .queryNeighborhood(_currentLatLng?.latitude ?? 0, _currentLatLng?.longitude ?? 0)
        .map(
          (r) => Marker(
            width: 36,
            height: 36,
            point: r.point,
            child: Column(
              children: [
                Icon(Icons.warning_amber, color: railwayColor, size: 28),
                const Icon(Icons.horizontal_rule, size: 12, color: Colors.black54),
              ],
            ),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_hasVectorTiles ? 'Bản đồ Vector Tiles' : 'Bản đồ OSM'),
        actions: [
          if (_hasVectorTiles)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.layers, color: Colors.green),
            ),
        ],
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
                        onPositionChanged: (pos, hasGesture) {
                          if (hasGesture && _autoFollowFake) {
                            setState(() {
                              _autoFollowFake = false; // Người dùng kéo map -> dừng auto-follow fake
                            });
                          }
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
                        if (_fakeMarker != null) MarkerLayer(markers: [_fakeMarker!]),
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
                              : StreamBuilder<LocationData>(
                                  stream: LocationController.instance.stream,
                                  builder: (context, snapshot) {
                                    // Query nearby features theo location hiện tại
                                    int camCount = 0;
                                    int speedCount = 0;
                                    int dangerCount = 0;
                                    int railCount = 0;
                                    
                                    if (snapshot.hasData) {
                                      final loc = snapshot.data!;
                                      final lat = loc.lat;
                                      final lng = loc.lng;
                                      
                                      // Query nearby features với radius phù hợp (500m)
                                      // Repositories đã được load trong _initController()
                                      try {
                                        camCount = NewCameraRepo.CameraRepository.instance.queryNearby(lat, lng, 500).length;
                                        speedCount = SpeedLimitRepository.instance.queryNearby(lat, lng, 500).length;
                                        dangerCount = DangerZoneRepository.instance.queryNearby(lat, lng, 500).length;
                                        railCount = RailwayRepository.instance.queryNearby(lat, lng, 500).length;
                                        
                                        // Log để debug nếu tất cả = 0
                                        if (camCount == 0 && speedCount == 0 && dangerCount == 0 && railCount == 0) {
                                          // Log repository counts để debug (không dùng await trong builder)
                                          final camRepoCount = NewCameraRepo.CameraRepository.instance.count;
                                          final speedRepoCount = SpeedLimitRepository.instance.count;
                                          final dangerRepoCount = DangerZoneRepository.instance.count;
                                          final railRepoCount = RailwayRepository.instance.count;
                                          
                                          appLog('[MapScreen] Counter: All zeros at lat=$lat, lng=$lng');
                                          appLog('[MapScreen] Repository counts: cam=$camRepoCount, speed=$speedRepoCount, danger=$dangerRepoCount, rail=$railRepoCount');
                                          
                                          // Nếu repositories chưa load, trigger load (async, không block UI)
                                          if (camRepoCount == 0 || speedRepoCount == 0 || dangerRepoCount == 0 || railRepoCount == 0) {
                                            // Load repositories async (không await trong builder)
                                            NewCameraRepo.CameraRepository.instance.load();
                                            SpeedLimitRepository.instance.load();
                                            DangerZoneRepository.instance.load();
                                            RailwayRepository.instance.load();
                                          }
                                        }
                                      } catch (e) {
                                        appLog('[MapScreen] Counter query error: $e');
                                      }
                                    }
                                    
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Text(
                                          'cam:$camCount speed:$speedCount danger:$dangerCount rail:$railCount',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    );
                                  },
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
                    if (_currentWarning != null)
                      Positioned(
                        top: _cameraError != null ? 80 : 12,
                        left: 12,
                        right: 12,
                        child: WarningBanner(
                          warning: _currentWarning!,
                          onDismiss: () {
                            setState(() {
                              _currentWarning = null;
                            });
                            _controller.dismissWarning();
                          },
                        ),
                      ),
                  ],
                ),
      floatingActionButton: _currentLatLng == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'hud-btn',
                  onPressed: () {
                    setState(() {
                      _hudMode = !_hudMode;
                    });
                    _moveTo(_currentLatLng!);
                  },
                  child: Icon(_hudMode ? Icons.screen_rotation : Icons.my_location),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'debug-btn',
                  child: const Icon(Icons.bug_report),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DebugScreen()),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

