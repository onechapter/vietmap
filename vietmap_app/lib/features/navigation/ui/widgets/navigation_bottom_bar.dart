import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/route_model.dart';

class NavigationBottomBar extends StatelessWidget {
  final RouteModel route;
  final LatLng? currentPosition;
  final bool autoFollow;
  final ValueChanged<bool> onAutoFollowToggle;

  const NavigationBottomBar({
    super.key,
    required this.route,
    this.currentPosition,
    required this.autoFollow,
    required this.onAutoFollowToggle,
  });

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final remainingDistance = currentPosition != null
        ? route.getRemainingDistance(currentPosition!)
        : route.distance;
    final remainingDuration = currentPosition != null
        ? route.getRemainingDuration(currentPosition!)
        : route.duration;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ETA and Distance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'Thời gian',
                    value: _formatDuration(remainingDuration),
                  ),
                  _buildInfoItem(
                    icon: Icons.straighten,
                    label: 'Khoảng cách',
                    value: _formatDistance(remainingDistance),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Auto-follow toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tự động theo dõi'),
                  const SizedBox(width: 8),
                  Switch(
                    value: autoFollow,
                    onChanged: onAutoFollowToggle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

