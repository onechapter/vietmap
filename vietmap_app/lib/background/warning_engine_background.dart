import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../features/warning/warning_engine.dart';
import '../core/logger.dart';

/// Background warning engine that receives location from Android service
class BackgroundWarningEngine {
  static BackgroundWarningEngine? _instance;
  final EventChannel _locationChannel = const EventChannel('com.vietmap/location_stream');
  final MethodChannel _methodChannel = const MethodChannel('com.vietmap/foreground_location');
  StreamSubscription? _locationSubscription;
  WarningEngine? _engine;

  BackgroundWarningEngine._();

  static BackgroundWarningEngine get instance {
    _instance ??= BackgroundWarningEngine._();
    return _instance!;
  }

  /// Start listening to location stream from Android service
  Future<void> start() async {
    if (_engine != null) return;

    try {
      appLog('BackgroundWarningEngine: Starting...');
      _engine = WarningEngine();

      // Listen to location events from Android service
      _locationSubscription = _locationChannel.receiveBroadcastStream().listen(
        (dynamic data) {
          _handleLocationData(data);
        },
        onError: (error) {
          appLog('BackgroundWarningEngine: Location stream error: $error');
        },
      );

      // Start warning engine with a stream controller
      final controller = StreamController<Position>();
      await _engine!.start(controller.stream);

      appLog('BackgroundWarningEngine: Started');
    } catch (e) {
      appLog('BackgroundWarningEngine: Start failed: $e');
    }
  }

  void _handleLocationData(dynamic data) {
    try {
      if (data is Map) {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;

        if (lat != null && lng != null) {
          appLog('BackgroundWarningEngine: Received location: $lat, $lng, speed: $speed');
          
          // TODO: Create Position and forward to engine stream
          // This requires refactoring WarningEngine to accept Position directly
          // or creating a stream controller
          // final accuracy = (data['accuracy'] as num?)?.toDouble() ?? 0.0;
          // final timestamp = data['timestamp'] as int?;
          // final position = Position(
          //   latitude: lat,
          //   longitude: lng,
          //   timestamp: timestamp != null
          //       ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          //       : DateTime.now(),
          //   accuracy: accuracy,
          //   altitude: 0,
          //   heading: 0,
          //   speed: speed,
          //   speedAccuracy: 0,
          //   altitudeAccuracy: 0,
          //   headingAccuracy: 0,
          // );
        }
      }
    } catch (e) {
      appLog('BackgroundWarningEngine: Error handling location: $e');
    }
  }

  /// Request TTS from Android service
  Future<void> requestTTS(String text) async {
    try {
      await _methodChannel.invokeMethod('requestTTS', {'text': text});
      appLog('BackgroundWarningEngine: TTS requested: $text');
    } catch (e) {
      appLog('BackgroundWarningEngine: TTS request failed: $e');
    }
  }

  void stop() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _engine?.stop();
    _engine = null;
    appLog('BackgroundWarningEngine: Stopped');
  }
}

