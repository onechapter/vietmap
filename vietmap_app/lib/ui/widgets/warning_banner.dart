import 'package:flutter/material.dart';
import '../../features/warning/warning_model.dart';

class WarningBanner extends StatelessWidget {
  final Warning warning;
  final VoidCallback onDismiss;

  const WarningBanner({
    super.key,
    required this.warning,
    required this.onDismiss,
  });

  String _getWarningText() {
    switch (warning.type) {
      case 'camera':
        return 'Sắp đến camera phạt nguội';
      case 'railway':
        return 'Cảnh báo đường sắt phía trước';
      case 'danger':
        return 'Khu vực nguy hiểm';
      case 'speed':
        return 'Vượt quá tốc độ cho phép';
      default:
        return 'Cảnh báo';
    }
  }

  IconData _getIcon() {
    switch (warning.type) {
      case 'camera':
        return Icons.camera_alt;
      case 'railway':
        return Icons.train;
      case 'danger':
        return Icons.warning;
      case 'speed':
        return Icons.speed;
      default:
        return Icons.info;
    }
  }

  Color _getColor() {
    switch (warning.type) {
      case 'camera':
        return Colors.red;
      case 'railway':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      case 'speed':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getColor().withOpacity(0.9),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(_getIcon(), color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getWarningText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (warning.distance > 0)
                    Text(
                      'Khoảng cách: ${warning.distance.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

