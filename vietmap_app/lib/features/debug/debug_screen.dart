import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/repositories/danger_zone_repository.dart';
import '../../data/repositories/railway_repository.dart';
import '../../data/repositories/camera_repository.dart';
import '../../data/repositories/speed_limit_repository.dart';
import '../../features/warning/warning_manager.dart';
import 'fake_location_service.dart';
import 'live_overlay_controller.dart';
import 'debug_upload_screen.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<Map<String, dynamic>> _warningHistory = [];
  final FakeLocationService _fakeLocation = FakeLocationService();
  final LiveOverlayController _overlayController = LiveOverlayController.instance;
  StreamSubscription? _warningSub;
  bool _isSimulating = false;
  bool _overlayEnabled = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
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
            const Text('Live Overlay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable Live Overlay'),
              subtitle: const Text('Show FPS and Dart VM metrics'),
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
            const Text('Repository Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    final latController = TextEditingController(text: '10.762622');
    final lngController = TextEditingController(text: '106.660172');
    final radiusController = TextEditingController(text: '500');
    List<String> results = [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Query Nearby Tester', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: radiusController,
              decoration: const InputDecoration(labelText: 'Radius (m)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final lat = double.tryParse(latController.text) ?? 0;
                final lng = double.tryParse(lngController.text) ?? 0;
                final radius = double.tryParse(radiusController.text) ?? 500;

                results.clear();
                results.add('Danger: ${DangerZoneRepository.instance.queryNearby(lat, lng, radius).length}');
                results.add('Railway: ${RailwayRepository.instance.queryNearby(lat, lng, radius).length}');
                results.add('Cameras: ${CameraRepository.instance.queryNearby(lat, lng, radius).length}');
                results.add('Speed: ${SpeedLimitRepository.instance.queryNearby(lat, lng, radius).length}');

                setState(() {});
              },
              child: const Text('Query'),
            ),
            if (results.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...results.map((r) => Text(r)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGpsSimulator() {
    final latController = TextEditingController(text: '10.762622');
    final lngController = TextEditingController(text: '106.660172');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GPS Simulator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final lat = double.tryParse(latController.text) ?? 0;
                final lng = double.tryParse(lngController.text) ?? 0;

                if (!_isSimulating) {
                  await _fakeLocation.startSimulating(lat, lng);
                  setState(() => _isSimulating = true);
                } else {
                  _fakeLocation.stopSimulating();
                  setState(() => _isSimulating = false);
                }
              },
              child: Text(_isSimulating ? 'Stop' : 'Start Simulating'),
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
            const Text('Warning History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_warningHistory.isEmpty)
              const Text('No warnings yet')
            else
              ..._warningHistory.take(20).map((w) => ListTile(
                    title: Text('${w['type']} - ${w['id']}'),
                    subtitle: Text('${w['distance']}m at ${w['time']}'),
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
            const Text('Cooldown Viewer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                // Show cooldown info (would need to query DB)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cooldown data in database')),
                );
              },
              child: const Text('View Cooldowns'),
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
              label: const Text('Upload Logs'),
            ),
          ],
        ),
      ),
    );
  }
}

