import 'package:flutter/material.dart';
import '../navigation/models/route_model.dart';
import '../navigation/models/route_step.dart';

class NavigationStepViewer extends StatefulWidget {
  final RouteModel route;
  final int? currentStepIndex;

  const NavigationStepViewer({
    super.key,
    required this.route,
    this.currentStepIndex,
  });

  @override
  State<NavigationStepViewer> createState() => _NavigationStepViewerState();
}

class _NavigationStepViewerState extends State<NavigationStepViewer> {
  int _selectedStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.route.steps.isEmpty) {
      return const Text('No steps available');
    }

    final currentIndex = widget.currentStepIndex ?? _selectedStepIndex;
    final currentStep = widget.route.steps[currentIndex];
    final nextSteps = widget.route.steps.skip(currentIndex + 1).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current step
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Step (${currentIndex + 1}/${widget.route.steps.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStepInfo(currentStep),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Next 3 steps
        const Text('Next 3 Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...nextSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildStepInfo(step),
                ),
              ),
            )),
        const SizedBox(height: 16),
        // All steps list
        ExpansionTile(
          title: const Text('All Steps'),
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.route.steps.length,
              itemBuilder: (context, index) {
                final step = widget.route.steps[index];
                final isCurrent = index == currentIndex;
                return ListTile(
                  selected: isCurrent,
                  title: Text('Step ${index + 1}: ${step.instruction}'),
                  subtitle: Text(
                    '${(step.distance / 1000).toStringAsFixed(2)} km • ${step.maneuver.toString().split('.').last}',
                  ),
                  onTap: () {
                    setState(() => _selectedStepIndex = index);
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepInfo(RouteStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.instruction,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (step.name != null) ...[
          const SizedBox(height: 4),
          Text('Road: ${step.name}'),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('${(step.distance / 1000).toStringAsFixed(2)} km'),
            const SizedBox(width: 16),
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('${(step.duration / 60).toStringAsFixed(1)} min'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Maneuver: ${step.maneuver.toString().split('.').last}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

