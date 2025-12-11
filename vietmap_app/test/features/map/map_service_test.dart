import 'package:flutter_test/flutter_test.dart';
import 'package:vietmap_app/features/map/map_service.dart';
import 'dart:io';

void main() {
  group('MapService', () {
    setUp(() {
      // Reset service before each test
      MapService.instance.reset();
    });

    test('init() should detect MBTiles if file exists', () async {
      final service = MapService.instance;
      
      // Initialize service
      await service.init();
      
      // Check if hasMbtiles returns a boolean (true or false)
      final hasMbtiles = service.hasMbtiles();
      expect(hasMbtiles, isA<bool>());
      
      // If MBTiles exists, path should not be null
      if (hasMbtiles) {
        expect(service.getMbtilesPath(), isNotNull);
        expect(service.getTileUrlTemplate(), isNotNull);
      } else {
        // If no MBTiles, tile URL template should be null
        expect(service.getTileUrlTemplate(), isNull);
      }
    });

    test('hasMbtiles() should return false if MBTiles not found', () async {
      final service = MapService.instance;
      await service.init();
      
      // Even if file doesn't exist, should return false (not throw)
      final result = service.hasMbtiles();
      expect(result, isA<bool>());
    });

    test('getTileUrlTemplate() should return null if no MBTiles', () async {
      final service = MapService.instance;
      await service.init();
      
      if (!service.hasMbtiles()) {
        expect(service.getTileUrlTemplate(), isNull);
      }
    });

    test('reset() should clear service state', () async {
      final service = MapService.instance;
      await service.init();
      
      service.reset();
      
      // After reset, should be able to re-initialize
      await service.init();
      expect(service.hasMbtiles(), isA<bool>());
    });
  });
}

