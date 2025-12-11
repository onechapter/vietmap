import 'package:flutter/material.dart';

import '../../data/cameras/camera_model.dart';

class CameraBottomSheet extends StatelessWidget {
  final CameraModel camera;

  const CameraBottomSheet({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            camera.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Loại: ${camera.type}'),
          if (camera.speedLimit != null) Text('Giới hạn: ${camera.speedLimit} km/h'),
          Text('Vị trí: ${camera.lat.toStringAsFixed(6)}, ${camera.lng.toStringAsFixed(6)}'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }
}

