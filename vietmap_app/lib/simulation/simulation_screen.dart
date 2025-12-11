import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

import 'simulation_controller.dart';
import 'widgets/point_selector.dart';
import 'widgets/speed_selector.dart';
import 'widgets/simulate_button.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  late final SimulationController controller;
  MapLibreMapController? _mapController;

  ll.LatLng? _simPosition;
  List<ll.LatLng> _routePoints = [];
  Line? _routeLine;

  @override
  void initState() {
    super.initState();
    controller = SimulationController();

    controller.onSimPosition = (p) {
      if (!mounted) return;
      setState(() => _simPosition = p);

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(p.latitude, p.longitude)),
      );

      // TODO: hook vào WarningEngine tại đây nếu cần
    };

    controller.onRouteReady = (pts) async {
      if (!mounted) return;
      setState(() => _routePoints = pts);
      await _drawRouteLine();
    };
  }

  @override
  void dispose() {
    controller.stop();
    super.dispose();
  }

  Future<void> _drawRouteLine() async {
    if (_mapController == null) return;

    await _clearRouteLine();

    if (_routePoints.isEmpty) return;

    try {
      _routeLine = await _mapController!.addLine(
        LineOptions(
          geometry:
              _routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          lineColor: '#FF5722',
          lineWidth: 4.0,
        ),
      );
    } catch (_) {}
  }

  Future<void> _clearRouteLine() async {
    if (_routeLine != null && _mapController != null) {
      try {
        await _mapController!.removeLine(_routeLine!);
      } catch (_) {}
    }
    _routeLine = null;
  }

  void _handleTap(LatLng point) {
    setState(() {
      final llPoint = ll.LatLng(point.latitude, point.longitude);
      if (controller.startPoint == null) {
        controller.startPoint = llPoint;
        _routePoints = [];
        _clearRouteLine();
      } else if (controller.endPoint == null) {
        controller.endPoint = llPoint;
      } else {
        // reset và chọn lại
        controller.startPoint = llPoint;
        controller.endPoint = null;
        _routePoints = [];
        _clearRouteLine();
      }
    });
  }

  Future<void> _startSim() async {
    if (controller.isRunning) return;
    setState(() => controller.isRunning = true);
    await controller.startSimulation();
    if (!mounted) return;
    setState(() => controller.isRunning = false);
  }

  void _stopSim() {
    controller.stop();
    setState(() => controller.isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulation Mode')),
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.77, 106.69),
              zoom: 14,
            ),
            styleString: 'https://demotiles.maplibre.org/style.json',
            onMapCreated: (c) => _mapController = c,
            onMapClick: (_, point) => _handleTap(point),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PointSelector(
                      start: controller.startPoint,
                      end: controller.endPoint,
                      onReset: () {
                        setState(() {
                          controller.startPoint = null;
                          controller.endPoint = null;
                          _routePoints = [];
                        });
                        _clearRouteLine();
                      },
                    ),
                    const SizedBox(height: 8),
                    SpeedSelector(
                      speedKmh: controller.speedKmh,
                      onChanged: (v) {
                        setState(() => controller.speedKmh = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    SimulateButton(
                      isRunning: controller.isRunning,
                      onStart: _startSim,
                      onStop: _stopSim,
                    ),
                    if (_simPosition != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'GPS: ${_simPosition!.latitude.toStringAsFixed(5)}, ${_simPosition!.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

