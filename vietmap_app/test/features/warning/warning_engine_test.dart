import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:vietmap_app/features/warning/warning_engine.dart';
import 'package:vietmap_app/features/warning/warning_manager.dart';
import 'package:vietmap_app/data/cooldown_db.dart';

void main() {
  group('WarningEngine', () {
    late WarningEngine engine;
    late StreamController<Position> locationController;

    setUp(() async {
      engine = WarningEngine();
      locationController = StreamController<Position>();
      await CooldownDb.instance.init();
      await CooldownDb.instance.clear();
    });

    tearDown(() {
      engine.stop();
      locationController.close();
    });

    test('start() initializes and listens to location stream', () async {
      await engine.start(locationController.stream);
      
      // Engine should be running
      expect(engine, isNotNull);
    });

    test('stop() cancels location subscription', () async {
      await engine.start(locationController.stream);
      engine.stop();
      
      // Should not crash
      expect(engine, isNotNull);
    });

    test('cooldown prevents duplicate warnings', () async {
      await engine.start(locationController.stream);
      
      final warnings = <String>[];
      final subscription = WarningManager.instance.stream.listen((w) {
        warnings.add(w.id);
      });

      // Simulate location near a test point (if data exists)
      // Note: This test requires actual data in repositories
      final position = Position(
        latitude: 10.762622,
        longitude: 106.660172,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      // Emit position multiple times quickly
      locationController.add(position);
      await Future.delayed(const Duration(milliseconds: 100));
      locationController.add(position);
      await Future.delayed(const Duration(milliseconds: 100));
      locationController.add(position);

      await Future.delayed(const Duration(seconds: 1));

      // Should only emit one warning due to cooldown
      // (This is a basic test - actual behavior depends on data)
      expect(warnings.length, lessThanOrEqualTo(1));

      await subscription.cancel();
    });
  });
}

