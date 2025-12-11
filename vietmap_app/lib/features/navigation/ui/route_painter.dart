import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Custom painter for route line (can be used for advanced styling)
class RoutePainter extends CustomPainter {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;

  RoutePainter({
    required this.points,
    this.color = Colors.blue,
    this.strokeWidth = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Note: This is a placeholder painter
    // Actual route rendering is handled by FlutterMap PolylineLayer
    // This painter can be used for custom route styling if needed
    // Coordinate transformation would be handled by map library
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

