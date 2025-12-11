import 'package:flutter/material.dart';
import '../../models/route_step.dart';

class ManeuverBanner extends StatelessWidget {
  final RouteStep step;

  const ManeuverBanner({
    super.key,
    required this.step,
  });

  IconData _getManeuverIcon() {
    switch (step.maneuver) {
      case ManeuverType.turnLeft:
      case ManeuverType.turnSharpLeft:
        return Icons.turn_left;
      case ManeuverType.turnRight:
      case ManeuverType.turnSharpRight:
        return Icons.turn_right;
      case ManeuverType.turnSlightLeft:
        return Icons.subdirectory_arrow_left;
      case ManeuverType.turnSlightRight:
        return Icons.subdirectory_arrow_right;
      case ManeuverType.straight:
        return Icons.straight;
      case ManeuverType.uturnLeft:
      case ManeuverType.uturnRight:
        return Icons.u_turn_left;
      case ManeuverType.rampLeft:
      case ManeuverType.rampRight:
        return Icons.merge;
      case ManeuverType.merge:
        return Icons.merge_type;
      case ManeuverType.forkLeft:
      case ManeuverType.forkRight:
        return Icons.fork_left;
      case ManeuverType.roundaboutLeft:
      case ManeuverType.roundaboutRight:
        return Icons.roundabout_left;
      case ManeuverType.arrive:
      case ManeuverType.arriveLeft:
      case ManeuverType.arriveRight:
        return Icons.location_on;
      case ManeuverType.depart:
      case ManeuverType.departLeft:
      case ManeuverType.departRight:
        return Icons.navigation;
      case ManeuverType.keepLeft:
        return Icons.keyboard_arrow_left;
      case ManeuverType.keepRight:
        return Icons.keyboard_arrow_right;
      default:
        return Icons.navigation;
    }
  }

  Color _getManeuverColor() {
    switch (step.maneuver) {
      case ManeuverType.arrive:
      case ManeuverType.arriveLeft:
      case ManeuverType.arriveRight:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getManeuverColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getManeuverIcon(),
                color: _getManeuverColor(),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step.instruction,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (step.name != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.name!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Còn ${(step.distance / 1000).toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

