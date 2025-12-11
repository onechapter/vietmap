import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/logger.dart';

/// Layer style configuration
class LayerStyle {
  final String color;
  final double opacity;
  final String type;
  final String? strokeColor;
  final double? strokeWidth;
  final double? width;
  final String? icon;
  final double? iconSize;

  LayerStyle({
    required this.color,
    required this.opacity,
    required this.type,
    this.strokeColor,
    this.strokeWidth,
    this.width,
    this.icon,
    this.iconSize,
  });

  factory LayerStyle.fromJson(Map<String, dynamic> json) {
    return LayerStyle(
      color: json['color'] as String,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      type: json['type'] as String,
      strokeColor: json['stroke_color'] as String?,
      strokeWidth: (json['stroke_width'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      icon: json['icon'] as String?,
      iconSize: (json['icon_size'] as num?)?.toDouble(),
    );
  }
}

/// Map layers configuration loader
class MapLayersLoader {
  static MapLayersLoader? _instance;
  Map<String, LayerStyle>? _styles;

  MapLayersLoader._();

  static MapLayersLoader get instance {
    _instance ??= MapLayersLoader._();
    return _instance!;
  }

  /// Load map layers configuration from assets
  Future<void> load() async {
    if (_styles != null) return;

    try {
      appLog('Loading map_layers.json...');
      final String jsonString =
          await rootBundle.loadString('config/map_layers.json');
      final Map<String, dynamic> json = jsonDecode(jsonString);

      _styles = {};
      json.forEach((key, value) {
        _styles![key] = LayerStyle.fromJson(value as Map<String, dynamic>);
      });

      appLog('Loaded ${_styles!.length} layer styles');
    } catch (e) {
      appLog('Error loading map_layers.json: $e');
      _styles = {};
    }
  }

  /// Get style for a layer
  LayerStyle? getStyle(String layerName) {
    return _styles?[layerName];
  }

  /// Get all layer names
  List<String> getLayerNames() {
    return _styles?.keys.toList() ?? [];
  }

  /// Check if layer exists
  bool hasLayer(String layerName) {
    return _styles?.containsKey(layerName) ?? false;
  }
}

