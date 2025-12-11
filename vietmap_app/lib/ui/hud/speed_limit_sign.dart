import 'package:flutter/material.dart';

class SpeedLimitSign extends StatefulWidget {
  final int? speedLimit;
  final bool isOver;

  const SpeedLimitSign({
    super.key,
    required this.speedLimit,
    required this.isOver,
  });

  @override
  State<SpeedLimitSign> createState() => _SpeedLimitSignState();
}

class _SpeedLimitSignState extends State<SpeedLimitSign> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800), lowerBound: 0.3, upperBound: 1.0)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.red, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        widget.speedLimit?.toString() ?? '--',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );

    if (!widget.isOver) return content;

    return FadeTransition(
      opacity: _controller,
      child: content,
    );
  }
}

