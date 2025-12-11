import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../features/navigation/models/route_model.dart';
import '../../features/navigation/route_engine.dart';
import 'navigation_simulator.dart';
import 'navigation_step_viewer.dart';

class NavigationDebugScreen extends StatefulWidget {
  const NavigationDebugScreen({super.key});

  @override
  State<NavigationDebugScreen> createState() => _NavigationDebugScreenState();
}

class _NavigationDebugScreenState extends State<NavigationDebugScreen> {
  final RouteEngine _routeEngine = RouteEngine.instance;
  RouteModel? _currentRoute;
  bool _isSimulating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug điều hướng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRoutePreview(),
          const Divider(),
          _buildSimulator(),
          const Divider(),
          if (_currentRoute != null) ...[
            _buildStepViewer(),
            const Divider(),
          ],
          _buildRerouteSimulator(),
        ],
      ),
    );
  }

  Widget _buildRoutePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xem trước lộ trình', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Điểm đi (vĩ,kinh)',
                hintText: '10.762622,106.660172',
              ),
              onSubmitted: (value) => _loadRoute(value, null),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Điểm đến (vĩ,kinh)',
                hintText: '10.771123,106.653789',
              ),
              onSubmitted: (value) => _loadRoute(null, value),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Default route for testing
                _loadRoute('10.762622,106.660172', '10.771123,106.653789');
              },
              child: const Text('Tải lộ trình mẫu'),
            ),
            if (_currentRoute != null) ...[
              const SizedBox(height: 16),
              Text('Đã tải: ${_currentRoute!.distance.toStringAsFixed(0)} m, ${_currentRoute!.steps.length} bước'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimulator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mô phỏng lộ trình', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_currentRoute == null)
              const Text('Hãy tải lộ trình trước')
            else ...[
              SwitchListTile(
                title: const Text('Bắt đầu mô phỏng'),
                value: _isSimulating,
                onChanged: (value) {
                  setState(() => _isSimulating = value);
                  if (value) {
                    _startSimulation();
                  } else {
                    _stopSimulation();
                  }
                },
              ),
              const SizedBox(height: 8),
              const Text('Tốc độ:'),
              Slider(
                value: 50.0,
                min: 10,
                max: 100,
                divisions: 9,
                label: '50 km/h',
                onChanged: (value) {
                  // Update simulation speed
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepViewer() {
    if (_currentRoute == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xem bước dẫn đường', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            NavigationStepViewer(route: _currentRoute!),
          ],
        ),
      ),
    );
  }

  Widget _buildRerouteSimulator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mô phỏng tính toán lại lộ trình', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Force off-route
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã kích hoạt lệch tuyến (giả lập)')),
                );
              },
              child: const Text('Giả lập lệch tuyến'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Manual reroute
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã kích hoạt tính lại lộ trình')),
                );
              },
              child: const Text('Tính lại lộ trình thủ công'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadRoute(String? fromStr, String? toStr) async {
    try {
      LatLng? from;
      LatLng? to;

      if (fromStr != null) {
        final parts = fromStr.split(',');
        if (parts.length == 2) {
          from = LatLng(double.parse(parts[0].trim()), double.parse(parts[1].trim()));
        }
      }

      if (toStr != null) {
        final parts = toStr.split(',');
        if (parts.length == 2) {
          to = LatLng(double.parse(parts[0].trim()), double.parse(parts[1].trim()));
        }
      }

      if (from == null || to == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toạ độ không hợp lệ')),
        );
        return;
      }

      final route = await _routeEngine.requestRoute(from: from, to: to);
      if (route != null) {
        setState(() => _currentRoute = route);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tải lộ trình thất bại')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _startSimulation() {
    // Start navigation simulator
    if (_currentRoute != null) {
      NavigationSimulator.instance.startSimulating(_currentRoute!);
    }
  }

  void _stopSimulation() {
    NavigationSimulator.instance.stopSimulating();
  }
}

