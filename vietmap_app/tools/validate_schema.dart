import 'dart:convert';
import 'dart:io';

void main() {
  print('=== Schema Validation ===\n');

  // Validate Danger Zone
  print('1. Validating danger_zone.json...');
  validateDangerZone();

  // Validate Railway
  print('\n2. Validating railway.json...');
  validateRailway();

  // Validate Cameras
  print('\n3. Validating cameras.json...');
  validateCameras();

  // Validate Speed Limit
  print('\n4. Validating speed_limit.json...');
  validateSpeedLimit();

  print('\n=== Validation Complete ===');
}

void validateDangerZone() {
  final file = File('data_sources/final/danger_zone.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  print('  Total items: ${data.length}');

  int errors = 0;
  int missingType = 0;
  int missingPolygon = 0;
  int invalidPolygon = 0;

  for (var i = 0; i < data.length; i++) {
    final item = data[i] as Map<String, dynamic>;

    if (!item.containsKey('type') || item['type'] == null) {
      missingType++;
      errors++;
    }

    if (!item.containsKey('polygon') || item['polygon'] == null) {
      missingPolygon++;
      errors++;
    } else {
      final polygon = item['polygon'] as List;
      if (polygon.isEmpty || polygon.length < 3) {
        invalidPolygon++;
        errors++;
      }
    }
  }

  print('  ✅ Valid items: ${data.length - errors}');
  if (errors > 0) {
    print('  ❌ Errors:');
    if (missingType > 0) print('    - Missing type: $missingType');
    if (missingPolygon > 0) print('    - Missing polygon: $missingPolygon');
    if (invalidPolygon > 0) print('    - Invalid polygon (<3 points): $invalidPolygon');
  }
}

void validateRailway() {
  final file = File('data_sources/final/railway.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  print('  Total items: ${data.length}');

  int errors = 0;
  int missingLat = 0;
  int missingLng = 0;
  int missingType = 0;
  int invalidCoords = 0;
  int missingIsCrossing = 0;
  int missingRailwayType = 0;

  for (var i = 0; i < data.length; i++) {
    final item = data[i] as Map<String, dynamic>;

    if (!item.containsKey('lat') || item['lat'] == null) {
      missingLat++;
      errors++;
    } else {
      final lat = item['lat'];
      if (lat is! num || lat.isNaN || lat < -90 || lat > 90) {
        invalidCoords++;
        errors++;
      }
    }

    if (!item.containsKey('lng') || item['lng'] == null) {
      missingLng++;
      errors++;
    } else {
      final lng = item['lng'];
      if (lng is! num || lng.isNaN || lng < -180 || lng > 180) {
        invalidCoords++;
        errors++;
      }
    }

    if (!item.containsKey('type') || item['type'] == null) {
      missingType++;
      errors++;
    }

    if (!item.containsKey('is_crossing')) {
      missingIsCrossing++;
    }

    if (!item.containsKey('railway_type')) {
      missingRailwayType++;
    }
  }

  print('  ✅ Valid items: ${data.length - errors}');
  if (errors > 0 || missingIsCrossing > 0 || missingRailwayType > 0) {
    print('  ⚠️  Issues:');
    if (missingLat > 0) print('    - Missing lat: $missingLat');
    if (missingLng > 0) print('    - Missing lng: $missingLng');
    if (missingType > 0) print('    - Missing type: $missingType');
    if (invalidCoords > 0) print('    - Invalid coordinates: $invalidCoords');
    if (missingIsCrossing > 0) print('    - Missing is_crossing: $missingIsCrossing');
    if (missingRailwayType > 0) print('    - Missing railway_type: $missingRailwayType');
  }
}

void validateCameras() {
  final file = File('data_sources/final/cameras.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  print('  Total items: ${data.length}');

  if (data.isEmpty) {
    print('  ⚠️  Empty file - may need to re-run importer');
  }
}

void validateSpeedLimit() {
  final file = File('data_sources/final/speed_limit.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  print('  Total items: ${data.length}');

  if (data.isEmpty) {
    print('  ⚠️  Empty file - may need to re-run importer');
  }
}

