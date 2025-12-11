import 'package:flutter_test/flutter_test.dart';
import 'package:vietmap_app/data/repositories/danger_zone_repository.dart';
import 'package:vietmap_app/data/repositories/railway_repository.dart';
import 'package:vietmap_app/data/repositories/camera_repository.dart';
import 'package:vietmap_app/data/repositories/speed_limit_repository.dart';

void main() {
  group('Repository Tests', () {
    // Sample coordinates within bbox (10.762622, 106.660172 is Ho Chi Minh City)
    const testLat = 10.762622;
    const testLng = 106.660172;

    setUpAll(() async {
      // Load all repositories
      await DangerZoneRepository.instance.load();
      await RailwayRepository.instance.load();
      await CameraRepository.instance.load();
      await SpeedLimitRepository.instance.load();
    });

    test('DangerZoneRepository loads and queries nearby', () async {
      final repo = DangerZoneRepository.instance;
      
      expect(repo.count, greaterThan(0), reason: 'Should load danger zones');
      
      // Query within 500m
      final nearby = repo.queryNearby(testLat, testLng, 500);
      
      // Should return some results if data exists in that area
      expect(nearby, isA<List>());
      
      // Test getById
      if (nearby.isNotEmpty) {
        final item = nearby.first;
        final found = repo.getById(item.id);
        expect(found, isNotNull);
        expect(found!.id, equals(item.id));
      }
    });

    test('RailwayRepository loads and queries nearby', () async {
      final repo = RailwayRepository.instance;
      
      expect(repo.count, greaterThan(0), reason: 'Should load railway crossings');
      
      // Query within 500m
      final nearby = repo.queryNearby(testLat, testLng, 500);
      
      expect(nearby, isA<List>());
      
      // Test getById
      if (nearby.isNotEmpty) {
        final item = nearby.first;
        final found = repo.getById(item.id);
        expect(found, isNotNull);
        expect(found!.id, equals(item.id));
      }
    });

    test('CameraRepository loads and queries nearby', () async {
      final repo = CameraRepository.instance;
      
      // Cameras might be empty, so just check it doesn't crash
      final nearby = repo.queryNearby(testLat, testLng, 500);
      
      expect(nearby, isA<List>());
      
      // Test getById if items exist
      if (nearby.isNotEmpty) {
        final item = nearby.first;
        final found = repo.getById(item.id);
        expect(found, isNotNull);
        expect(found!.id, equals(item.id));
      }
    });

    test('SpeedLimitRepository loads and queries nearby', () async {
      final repo = SpeedLimitRepository.instance;
      
      // Speed limits might be empty, so just check it doesn't crash
      final nearby = repo.queryNearby(testLat, testLng, 500);
      
      expect(nearby, isA<List>());
      
      // Test getById if items exist
      if (nearby.isNotEmpty) {
        final item = nearby.first;
        final found = repo.getById(item.id);
        expect(found, isNotNull);
        expect(found!.id, equals(item.id));
      }
    });

    test('Repositories support reload', () async {
      final dangerRepo = DangerZoneRepository.instance;
      final initialCount = dangerRepo.count;
      
      await dangerRepo.reload();
      
      expect(dangerRepo.count, equals(initialCount));
    });

    test('Query with different radii returns different counts', () async {
      final repo = DangerZoneRepository.instance;
      
      final nearby100 = repo.queryNearby(testLat, testLng, 100);
      final nearby500 = repo.queryNearby(testLat, testLng, 500);
      
      // 500m radius should return >= 100m radius results
      expect(nearby500.length, greaterThanOrEqualTo(nearby100.length));
    });
  });
}

