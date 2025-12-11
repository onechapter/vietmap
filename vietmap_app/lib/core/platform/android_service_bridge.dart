import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/warning/warning_engine.dart';
import '../../core/logger.dart';

/// Bridge to Android foreground location service
class AndroidServiceBridge {
  static const MethodChannel _methodChannel = MethodChannel('com.vietmap/foreground_location');
  static const EventChannel _locationChannel = EventChannel('com.vietmap/location_stream');
  
  static AndroidServiceBridge? _instance;
  StreamSubscription<dynamic>? _locationSubscription;
  WarningEngine? _warningEngine;

  AndroidServiceBridge._();

  static AndroidServiceBridge get instance {
    _instance ??= AndroidServiceBridge._();
    return _instance!;
  }

  /// Initialize bridge and connect to Android service
  Future<void> initialize() async {
    try {
      appLog('AndroidServiceBridge: Initializing...');
      
      // Listen to location events from Android service
      _locationSubscription = _locationChannel.receiveBroadcastStream().listen(
        (dynamic data) {
          _handleLocationEvent(data);
        },
        onError: (error) {
          appLog('AndroidServiceBridge: Location stream error: $error');
        },
      );

      appLog('AndroidServiceBridge: Initialized');
    } catch (e) {
      appLog('AndroidServiceBridge: Init failed: $e');
    }
  }

  /// Handle location event from Android service
  void _handleLocationEvent(dynamic data) {
    try {
      if (data is Map) {
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;
        final timestamp = data['timestamp'] as int?;

        if (lat != null && lng != null) {
          final position = Position(
            latitude: lat,
            longitude: lng,
            timestamp: timestamp != null
                ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                : DateTime.now(),
            accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
            altitude: (data['altitude'] as num?)?.toDouble() ?? 0.0,
            heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
            speed: speed,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );

          // Forward to warning engine if initialized
          if (_warningEngine != null) {
            // WarningEngine will process this via its own stream
            // This is a placeholder - actual implementation depends on architecture
            appLog('AndroidServiceBridge: Received location: $lat, $lng, speed: ${position.speed}');
          }
        }
      }
    } catch (e) {
      appLog('AndroidServiceBridge: Error handling location: $e');
    }
  }

  /// Set warning engine to receive location updates
  void setWarningEngine(WarningEngine engine) {
    _warningEngine = engine;
    appLog('AndroidServiceBridge: WarningEngine set');
  }

  /// Request TTS from Android service
  Future<void> requestTTS(String text) async {
    try {
      await _methodChannel.invokeMethod('requestTTS', {'text': text});
      appLog('AndroidServiceBridge: TTS requested: $text');
    } catch (e) {
      appLog('AndroidServiceBridge: TTS request failed: $e');
    }
  }

  /// Dispose bridge
  void dispose() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _warningEngine = null;
    appLog('AndroidServiceBridge: Disposed');
  }
}

