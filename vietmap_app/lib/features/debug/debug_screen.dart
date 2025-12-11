import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/repositories/danger_zone_repository.dart';
import '../../data/repositories/railway_repository.dart';
import '../../data/repositories/camera_repository.dart';
import '../../data/repositories/speed_limit_repository.dart';
import '../../features/warning/warning_manager.dart';
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
          _buildRepositoryInfo(),
          const Divider(),
          _buildLiveOverlayToggle(),
          const Divider(),
          _buildQueryTester(),
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

  Widget _buildCooldownViewer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xem cooldown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                // Show cooldown info (would need to query DB)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dữ liệu cooldown trong CSDL')),
                );
              },
              child: const Text('Xem cooldown'),
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

