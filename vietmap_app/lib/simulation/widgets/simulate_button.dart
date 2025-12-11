import 'package:flutter/material.dart';

class SimulateButton extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const SimulateButton({
    super.key,
    required this.isRunning,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isRunning ? onStop : onStart,
      icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
      label: Text(isRunning ? 'Stop' : 'Start Simulation'),
    );
  }
}

