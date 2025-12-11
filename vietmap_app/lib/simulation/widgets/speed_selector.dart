import 'package:flutter/material.dart';

class SpeedSelector extends StatelessWidget {
  final double speedKmh;
  final ValueChanged<double> onChanged;

  const SpeedSelector({
    super.key,
    required this.speedKmh,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Speed: ${speedKmh.round()} km/h'),
        Expanded(
          child: Slider(
            min: 5,
            max: 120,
            value: speedKmh.clamp(5, 120),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

