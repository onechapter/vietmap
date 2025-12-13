import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/repositories/danger_zone_repository.dart';
import '../../data/repositories/railway_repository.dart';
import '../../data/repositories/camera_repository.dart';
import '../../data/repositories/speed_limit_repository.dart';
import '../../features/warning/warning_manager.dart';
import '../../core/location/location_controller.dart';
import '../../data/cooldown_db.dart';
import '../../core/logger.dart';
import 'fake_location_service.dart';
import 'live_overlay_controller.dart';
import 'debug_upload_screen.dart';
import 'route_simulator_service.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  final List<Map<String, dynamic>> _warningHistory = [];
  final FakeLocationService _fakeLocation = FakeLocationService.instance;
  final LiveOverlayController _overlayController = LiveOverlayController.instance;
  StreamSubscription? _warningSub;
  bool _isSimulating = false;
  bool _overlayEnabled = false;
  // Controllers giữ giá trị nhập để không bị reset sau setState
  final TextEditingController _queryLatController =
      TextEditingController(text: '10.762622');
  final TextEditingController _queryLngController =
      TextEditingController(text: '106.660172');
  final TextEditingController _queryRadiusController =
      TextEditingController(text: '500');
  final List<String> _queryResults = [];

  final TextEditingController _simLatController =
      TextEditingController(text: '10.762622');
  final TextEditingController _simLngController =
      TextEditingController(text: '106.660172');
  bool _fakeToggle = false;
  // Route simulator
  final TextEditingController _simStartLat = TextEditingController(text: '11.502031');
  final TextEditingController _simStartLng = TextEditingController(text: '106.614439');
  final TextEditingController _simEndLat = TextEditingController(text: '11.481693');
  final TextEditingController _simEndLng = TextEditingController(text: '106.614505');
  double _simSpeed = 40;
  bool _routeLoading = false;
  String? _routeError;

  @override
  void initState() {
    super.initState();
    _loadRepositoryInfo();
    _listenToWarnings();
  }

  void _listenToWarnings() {
    _warningSub = WarningManager.instance.stream.listen((warning) {
      setState(() {
        _warningHistory.insert(0, {
          'type': warning.type,
          'id': warning.id,
          'distance': warning.distance.toStringAsFixed(1),
          'time': warning.timestamp.toString().substring(11, 19),
        });
        if (_warningHistory.length > 50) {
          _warningHistory.removeLast();
        }
      });
    });
  }

  Future<void> _loadRepositoryInfo() async {
    await DangerZoneRepository.instance.load();
    await RailwayRepository.instance.load();
    await CameraRepository.instance.load();
    await SpeedLimitRepository.instance.load();
    setState(() {});
  }

  @override
  void dispose() {
    _warningSub?.cancel();
    _queryLatController.dispose();
    _queryLngController.dispose();
    _queryRadiusController.dispose();
    _simLatController.dispose();
    _simLngController.dispose();
    _simStartLat.dispose();
    _simStartLng.dispose();
    _simEndLat.dispose();
    _simEndLng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công cụ debug'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrentLocationInfo(),  // TASK 4 & 7: Current location + speed
          const Divider(),
          _buildRepositoryInfo(),
          const Divider(),
          _buildLiveOverlayToggle(),
          const Divider(),
          _buildQueryTester(),
          const Divider(),
          _buildNearbyFeaturesViewer(),  // TASK 4: Nearby features with distance
          const Divider(),
          _buildGpsSimulator(),
          const Divider(),
          _buildWarningHistory(),
          const Divider(),
          _buildCooldownViewer(),
          const Divider(),
          _buildRouteSimulator(context),
        ],
      ),
    );
  }

  Widget _buildLiveOverlayToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lớp phủ trực tiếp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Bật lớp phủ'),
              subtitle: const Text('Hiển thị FPS và chỉ số Dart VM'),
              value: _overlayEnabled,
              onChanged: (value) {
                setState(() {
                  _overlayEnabled = value;
                });
                if (value) {
                  _overlayController.enable(context);
                } else {
                  _overlayController.disable();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepositoryInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin dữ liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Danger Zones: ${DangerZoneRepository.instance.count}'),
            Text('Railway: ${RailwayRepository.instance.count}'),
            Text('Cameras: ${CameraRepository.instance.count}'),
            Text('Speed Limits: ${SpeedLimitRepository.instance.count}'),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryTester() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kiểm thử truy vấn lân cận', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _queryLatController,
              decoration: const InputDecoration(labelText: 'Vĩ độ'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _queryLngController,
              decoration: const InputDecoration(labelText: 'Kinh độ'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _queryRadiusController,
              decoration: const InputDecoration(labelText: 'Bán kính (m)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final lat = double.tryParse(_queryLatController.text) ?? 0;
                final lng = double.tryParse(_queryLngController.text) ?? 0;
                final radius = double.tryParse(_queryRadiusController.text) ?? 500;

                _queryResults
                  ..clear()
                  ..add('Nguy hiểm: ${DangerZoneRepository.instance.queryNearby(lat, lng, radius).length}')
                  ..add('Đường sắt: ${RailwayRepository.instance.queryNearby(lat, lng, radius).length}')
                  ..add('Camera: ${CameraRepository.instance.queryNearby(lat, lng, radius).length}')
                  ..add('Tốc độ: ${SpeedLimitRepository.instance.queryNearby(lat, lng, radius).length}');

                setState(() {});
              },
              child: const Text('Truy vấn'),
            ),
            if (_queryResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._queryResults.map((r) => Text(r)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGpsSimulator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Giả lập vị trí'),
              subtitle: const Text('Dùng vị trí cố định 11.488688, 106.614503'),
              value: _fakeToggle,
              onChanged: (v) {
                setState(() => _fakeToggle = v);
                if (v) {
                  FakeLocationService.instance.enableFake();
                } else {
                  FakeLocationService.instance.disableFake();
                }
              },
            ),
            const Text('Mô phỏng GPS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _simLatController,
              decoration: const InputDecoration(labelText: 'Vĩ độ'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _simLngController,
              decoration: const InputDecoration(labelText: 'Kinh độ'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final lat = double.tryParse(_simLatController.text) ?? 0;
                final lng = double.tryParse(_simLngController.text) ?? 0;

                if (!_isSimulating) {
                  await _fakeLocation.startSimulating(lat, lng);
                  setState(() => _isSimulating = true);
                } else {
                  _fakeLocation.stopSimulating();
                  setState(() => _isSimulating = false);
                }
              },
              child: Text(_isSimulating ? 'Dừng' : 'Bắt đầu mô phỏng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSimulator(BuildContext context) {
    final sim = ref.watch(routeSimulatorProvider.notifier);
    final running = ref.watch(routeSimulatorProvider) != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mô phỏng lộ trình', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Điểm đầu'),
            TextField(
              controller: _simStartLat,
              decoration: const InputDecoration(labelText: 'Vĩ độ đầu'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _simStartLng,
              decoration: const InputDecoration(labelText: 'Kinh độ đầu'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const Text('Điểm cuối'),
            TextField(
              controller: _simEndLat,
              decoration: const InputDecoration(labelText: 'Vĩ độ cuối'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _simEndLng,
              decoration: const InputDecoration(labelText: 'Kinh độ cuối'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Text('Tốc độ: ${_simSpeed.toStringAsFixed(0)} km/h'),
            Slider(
              value: _simSpeed,
              min: 20,
              max: 120,
              divisions: 10,
              label: '${_simSpeed.toStringAsFixed(0)} km/h',
              onChanged: (v) => setState(() => _simSpeed = v),
            ),
            const SizedBox(height: 12),
            if (_routeLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Đang lấy route từ API...'),
                  ],
                ),
              )
            else if (_routeError != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _routeError!.contains('mock') ? Colors.orange.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _routeError!.contains('mock') ? Icons.warning_amber : Icons.error,
                        color: _routeError!.contains('mock') ? Colors.orange : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _routeError!,
                          style: TextStyle(
                            color: _routeError!.contains('mock') ? Colors.orange.shade900 : Colors.red.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _routeLoading || running ? null : () async {
                      setState(() {
                        _routeLoading = true;
                        _routeError = null;
                      });
                      try {
                        final start = LatLng(
                          double.tryParse(_simStartLat.text) ?? 0,
                          double.tryParse(_simStartLng.text) ?? 0,
                        );
                        final end = LatLng(
                          double.tryParse(_simEndLat.text) ?? 0,
                          double.tryParse(_simEndLng.text) ?? 0,
                        );
                        await sim.start(start: start, end: end, speedKmH: _simSpeed);
                        if (sim.error != null) {
                          setState(() {
                            _routeError = sim.error;
                            _routeLoading = false;
                          });
                        } else {
                          setState(() {
                            _routeLoading = false;
                            _routeError = null;
                          });
                        }
                      } catch (e) {
                        setState(() {
                          _routeError = 'Lỗi: $e';
                          _routeLoading = false;
                        });
                      }
                    },
                    child: const Text('Bắt đầu mô phỏng'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: running ? () => sim.stop() : null,
                    child: const Text('Dừng'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (running)
              Text(
                'Đang mô phỏng: điểm ${sim.currentPointIndex + 1}/${sim.routePointCount}',
                style: const TextStyle(color: Colors.green),
              )
            else
              const Text(
                'Đã dừng',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lịch sử cảnh báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_warningHistory.isEmpty)
              const Text('Chưa có cảnh báo')
            else
              ..._warningHistory.take(20).map((w) => ListTile(
                    title: Text('${w['type']} - ${w['id']}'),
                    subtitle: Text('${w['distance']}m lúc ${w['time']}'),
                    dense: true,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationInfo() {
    return StreamBuilder<LocationData>(
      stream: LocationController.instance.stream,
      builder: (context, snapshot) {
        final loc = snapshot.data;
        final isSim = LocationController.instance.isSimulationMode;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TASK DEBUG-04: Hiển thị source location rõ ràng
                Row(
                  children: [
                    const Text('📍 Vị trí hiện tại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Chip(
                      label: Text(isSim ? 'SIMULATION' : 'REAL GPS'),
                      backgroundColor: isSim ? Colors.orange : Colors.green,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (loc != null) ...[
                  // TASK DEBUG-04: Hiển thị location chi tiết
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSim ? Colors.orange.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSim ? Colors.orange : Colors.green,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lat: ${loc.lat.toStringAsFixed(6)}', 
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                        Text('Lng: ${loc.lng.toStringAsFixed(6)}', 
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                        const SizedBox(height: 8),
                        // TASK DEBUG-04: Speed raw/smooth
                        Text('Tốc độ: ${loc.speed.toStringAsFixed(1)} km/h', 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Source: ${isSim ? "SIMULATED" : "REAL GPS"}', 
                          style: TextStyle(
                            color: isSim ? Colors.orange.shade900 : Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          )),
                      ],
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('⏳ Chưa có vị trí', style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNearbyFeaturesViewer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TASK DEBUG-04: Hiển thị rõ đây là features theo location đang dùng
            Row(
              children: [
                const Text('🔍 Features xung quanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                StreamBuilder<LocationData>(
                  stream: LocationController.instance.stream,
                  builder: (context, snapshot) {
                    final isSim = LocationController.instance.isSimulationMode;
                    return Chip(
                      label: Text(isSim ? 'SIM' : 'REAL'),
                      backgroundColor: isSim ? Colors.orange : Colors.green,
                      labelStyle: const TextStyle(fontSize: 10, color: Colors.white),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<LocationData>(
              stream: LocationController.instance.stream,
              builder: (context, snapshot) {
                final loc = snapshot.data;
                final isSim = LocationController.instance.isSimulationMode;
                
                if (loc == null) {
                  return const Text('⏳ Chưa có vị trí');
                }

                final lat = loc.lat;
                final lng = loc.lng;
                final radius = 500.0;
                final distance = const Distance();
                
                // TASK DEBUG-04: Log rõ location source đang dùng để query
                appLog('[DebugScreen] Querying nearby features: source=${isSim ? "SIM" : "REAL"}, lat=$lat, lng=$lng');

                // Query nearby features
                final cameras = CameraRepository.instance.queryNearby(lat, lng, radius);
                final railways = RailwayRepository.instance.queryNearby(lat, lng, radius);
                final dangers = DangerZoneRepository.instance.queryNearby(lat, lng, radius);
                final speedLimits = SpeedLimitRepository.instance.queryNearby(lat, lng, radius);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bán kính: ${radius.toStringAsFixed(0)}m', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (cameras.isNotEmpty) ...[
                      const Text('📷 Camera:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...cameras.take(5).map((cam) {
                        final dist = distance.as(LengthUnit.Meter, LatLng(lat, lng), LatLng(cam.lat, cam.lng));
                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text('  ${cam.id}: ${dist.toStringAsFixed(1)}m'),
                        );
                      }),
                      if (cameras.length > 5) Text('  ... và ${cameras.length - 5} camera khác'),
                    ],
                    if (railways.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      const Text('🚂 Đường sắt:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...railways.take(5).map((rail) {
                        final dist = distance.as(LengthUnit.Meter, LatLng(lat, lng), LatLng(rail.lat, rail.lng));
                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text('  ${rail.id}: ${dist.toStringAsFixed(1)}m'),
                        );
                      }),
                    ],
                    if (dangers.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      const Text('⚠️ Nguy hiểm:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...dangers.take(5).map((danger) {
                        final dist = distance.as(LengthUnit.Meter, LatLng(lat, lng), LatLng(danger.lat, danger.lng));
                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text('  ${danger.id}: ${dist.toStringAsFixed(1)}m'),
                        );
                      }),
                    ],
                    if (speedLimits.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      const Text('🚦 Giới hạn tốc độ:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...speedLimits.take(5).map((limit) {
                        final dist = distance.as(LengthUnit.Meter, LatLng(lat, lng), LatLng(limit.lat, limit.lng));
                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text('  ${limit.id}: ${limit.speedLimit} km/h (${dist.toStringAsFixed(1)}m)'),
                        );
                      }),
                    ],
                    if (cameras.isEmpty && railways.isEmpty && dangers.isEmpty && speedLimits.isEmpty)
                      const Text('Không có features trong bán kính', style: TextStyle(color: Colors.grey)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCooldownViewer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xem cooldown (TASK 7)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                // TASK 7: Show cooldown info from DB
                try {
                  final db = CooldownDb.instance;
                  await db.init();
                  
                  // Query all cooldowns (simplified - would need proper DB query method)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cooldown data trong SQLite DB. Xem log để chi tiết.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  appLog('DebugScreen: Cooldown viewer - check logs for details');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text('Xem cooldown'),
            ),
            const SizedBox(height: 8),
            Text('Simulation mode: ${LocationController.instance.isSimulationMode ? "ON (cooldown reset)" : "OFF (cooldown persistent)"}',
              style: TextStyle(
                color: LocationController.instance.isSimulationMode ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DebugUploadScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.upload),
              label: const Text('Tải lên log'),
            ),
          ],
        ),
      ),
    );
  }
}

