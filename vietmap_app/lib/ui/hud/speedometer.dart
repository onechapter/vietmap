import 'dart:math';

import 'package:flutter/material.dart';

class Speedometer extends StatefulWidget {
  final double speedKmh;

  const Speedometer({super.key, required this.speedKmh});

  @override
  State<Speedometer> createState() => _SpeedometerState();
}

class _SpeedometerState extends State<Speedometer> with SingleTickerProviderStateMixin {
  late double _displayed;

  @override
  void initState() {
    super.initState();
    _displayed = widget.speedKmh;
  }

  @override
  void didUpdateWidget(covariant Speedometer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.speedKmh - _displayed).abs() > 0.5) {
      setState(() {
        _displayed = widget.speedKmh;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 80,
      child: CustomPaint(
        painter: _SpeedPainter(_displayed),
      ),
    );
  }
}

class _SpeedPainter extends CustomPainter {
  final double speed;

  _SpeedPainter(this.speed);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.9);
    final radius = size.width * 0.45;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = pi;
    final sweepAngle = pi;

    final bg = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..shader = const SweepGradient(
        colors: [Colors.green, Colors.yellow, Colors.red],
        stops: [0.0, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, bg);

    final clamped = speed.clamp(0, 160);
    final progress = clamped / 160;
    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, fg);

    final textPainter = TextPainter(
      text: TextSpan(
        text: speed.toStringAsFixed(0),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - 36),
    );

    final unitPainter = TextPainter(
      text: const TextSpan(
        text: 'km/h',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    unitPainter.paint(
      canvas,
      Offset(center.dx - unitPainter.width / 2, center.dy - 14),
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedPainter oldDelegate) {
    return (oldDelegate.speed - speed).abs() > 0.1;
  }
}

