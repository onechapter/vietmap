import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../simulation_controller.dart';

class SimulationPanel extends StatelessWidget {
  final SimulationState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final VoidCallback onClear;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<bool> onFollowChanged;
  final ValueChanged<bool> onLoopChanged;

  const SimulationPanel({
    super.key,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onStop,
    required this.onClear,
    required this.onSpeedChanged,
    required this.onFollowChanged,
    required this.onLoopChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pointsSection(),
            const SizedBox(height: 8),
            _buttonsSection(),
            const SizedBox(height: 8),
            _speedSlider(),
            const SizedBox(height: 8),
            _toggles(),
            const SizedBox(height: 8),
            _hud(context),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear),
                label: const Text('Clear route'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pointRow('Start', state.start),
        _pointRow('End', state.end),
      ],
    );
  }

  Widget _pointRow(String title, LatLng? p) {
    final text = p == null
        ? 'Chưa chọn'
        : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    return Row(
      children: [
        Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(text)),
      ],
    );
  }

  Widget _buttonsSection() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: state.isRunning ? null : onStart,
            child: const Text('Start'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ElevatedButton(
            onPressed: state.isRunning ? onPause : null,
            child: Text(state.isPaused ? 'Resume' : 'Pause'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ElevatedButton(
            onPressed: state.isRunning ? onStop : null,
            child: const Text('Stop'),
          ),
        ),
      ],
    );
  }

  Widget _speedSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Speed: ${state.speedKmh.toStringAsFixed(0)} km/h'),
        Slider(
          min: 5,
          max: 120,
          value: state.speedKmh.clamp(5, 120),
          onChanged: onSpeedChanged,
        ),
      ],
    );
  }

  Widget _toggles() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Follow camera'),
          value: state.follow,
          onChanged: onFollowChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Loop route'),
          value: state.loop,
          onChanged: onLoopChanged,
        ),
      ],
    );
  }

  Widget _hud(BuildContext context) {
    final w = state.warningCounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HUD',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text('Segment: ${state.segmentIndex} / ${state.routeLengthM.toStringAsFixed(0)} m'),
        Text(
          state.current == null
              ? 'Pos: -'
              : 'Pos: ${state.current!.latitude.toStringAsFixed(5)}, ${state.current!.longitude.toStringAsFixed(5)}',
        ),
        Text('Speed: ${state.speedKmh.toStringAsFixed(1)} km/h'),
        Text(
          'Warnings → speed:${w['speed'] ?? 0} cam:${w['camera'] ?? 0} '
          'danger:${w['danger'] ?? 0} rail:${w['rail'] ?? 0}',
        ),
      ],
    );
  }
}

