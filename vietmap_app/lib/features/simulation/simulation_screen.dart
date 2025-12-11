import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'ghost_car_renderer.dart';
import 'simulation_controller.dart';
import 'widgets/simulation_panel.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  late final SimulationController _controller;
  GhostCarRenderer? _renderer;

  @override
  void initState() {
    super.initState();
    _controller = SimulationController();
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    final state = _controller.state;
    if (_renderer != null) {
      _renderer!.drawRoute(_controller.routePoints);
      if (state.current != null) {
        _renderer!.updateCar(
          state.current!,
          heading: state.headingDeg,
          follow: state.follow,
        );
      }
    }
    setState(() {});
  }

  void _onMapCreated(MapLibreMapController controller) {
    _renderer = GhostCarRenderer(controller);
  }

  void _onMapTap(Point<double> _, LatLng point) {
    _controller.setPoint(point);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return Scaffold(
      appBar: AppBar(title: const Text('Chế độ mô phỏng')),
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.77, 106.69),
              zoom: 13.5,
            ),
            styleString: 'https://demotiles.maplibre.org/style.json',
            onMapCreated: _onMapCreated,
            onMapClick: _onMapTap,
          ),
          Positioned(
            left: 12,
            top: 12,
            child: SimulationPanel(
              state: state,
              onStart: _controller.start,
              onPause: state.isPaused ? _controller.resume : _controller.pause,
              onStop: _controller.stop,
              onClear: _controller.clearRoute,
              onSpeedChanged: _controller.setSpeed,
              onFollowChanged: _controller.toggleFollow,
              onLoopChanged: _controller.toggleLoop,
            ),
          ),
        ],
      ),
    );
  }
}

