import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;

class PointSelector extends StatelessWidget {
  final ll.LatLng? start;
  final ll.LatLng? end;
  final VoidCallback onReset;

  const PointSelector({
    super.key,
    required this.start,
    required this.end,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Start: '),
            Expanded(
              child: Text(
                start != null
                    ? '${start!.latitude.toStringAsFixed(5)}, ${start!.longitude.toStringAsFixed(5)}'
                    : 'Chưa chọn',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text('End:   '),
            Expanded(
              child: Text(
                end != null
                    ? '${end!.latitude.toStringAsFixed(5)}, ${end!.longitude.toStringAsFixed(5)}'
                    : 'Chưa chọn',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onReset,
            child: const Text('Reset điểm'),
          ),
        ),
      ],
    );
  }
}

