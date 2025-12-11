import 'dart:convert';
import 'dart:io';

void main() {
  print('=== Convert to GeoJSON ===\n');

  // Convert Danger Zone
  print('1. Converting danger_zone.json...');
  convertDangerZoneToGeoJSON();

  // Convert Railway
  print('\n2. Converting railway.json...');
  convertRailwayToGeoJSON();

  // Convert Cameras
  print('\n3. Converting cameras.json...');
  convertCamerasToGeoJSON();

  // Convert Speed Limit
  print('\n4. Converting speed_limit.json...');
  convertSpeedLimitToGeoJSON();

  print('\n=== Complete ===');
}

void convertDangerZoneToGeoJSON() {
  final file = File('data_sources/final/danger_zone.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  final features = <Map<String, dynamic>>[];

  for (var item in data) {
    final map = item as Map<String, dynamic>;
    final polygon = map['polygon'] as List?;
    final type = map['type'] as String?;

    if (polygon == null || polygon.isEmpty || type == null) continue;

    // Convert polygon to GeoJSON format [lng, lat]
    final coordinates = <List<double>>[];
    for (var point in polygon) {
      if (point is List && point.length >= 2) {
        coordinates.add([
          (point[1] as num).toDouble(), // lng
          (point[0] as num).toDouble(), // lat
        ]);
      }
    }

    if (coordinates.length < 3) continue;

    // Close polygon (first point = last point)
    if (coordinates.first[0] != coordinates.last[0] ||
        coordinates.first[1] != coordinates.last[1]) {
      coordinates.add(coordinates.first);
    }

    features.add({
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [coordinates],
      },
      'properties': {
        'type': type,
      },
    });
  }

  final geojson = {
    'type': 'FeatureCollection',
    'features': features,
  };

  final output = File('data_sources/final/danger_zone.geojson');
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(geojson),
  );

  print('  ✅ Converted: ${features.length} features');
  print('  ✅ Saved: danger_zone.geojson');
}

void convertRailwayToGeoJSON() {
  final file = File('data_sources/final/railway.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  final features = <Map<String, dynamic>>[];

  for (var item in data) {
    final map = item as Map<String, dynamic>;
    final lat = map['lat'];
    final lng = map['lng'];
    final type = map['type'] as String?;
    final isCrossing = map['is_crossing'] as bool? ?? false;

    if (lat == null || lng == null || type == null) continue;

    features.add({
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [
          (lng as num).toDouble(),
          (lat as num).toDouble(),
        ],
      },
      'properties': {
        'type': type,
        'is_crossing': isCrossing,
      },
    });
  }

  final geojson = {
    'type': 'FeatureCollection',
    'features': features,
  };

  final output = File('data_sources/final/railway.geojson');
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(geojson),
  );

  print('  ✅ Converted: ${features.length} features');
  print('  ✅ Saved: railway.geojson');
}

void convertCamerasToGeoJSON() {
  final file = File('data_sources/final/cameras.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  final features = <Map<String, dynamic>>[];

  for (var item in data) {
    final map = item as Map<String, dynamic>;
    final lat = map['lat'];
    final lng = map['lng'];
    final type = map['type'] as String? ?? 'camera';
    final speedLimit = map['speedLimit'];

    if (lat == null || lng == null) continue;

    features.add({
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [
          (lng as num).toDouble(),
          (lat as num).toDouble(),
        ],
      },
      'properties': {
        'type': type,
        if (speedLimit != null) 'speedLimit': speedLimit,
      },
    });
  }

  final geojson = {
    'type': 'FeatureCollection',
    'features': features,
  };

  final output = File('data_sources/final/cameras.geojson');
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(geojson),
  );

  print('  ✅ Converted: ${features.length} features');
  print('  ✅ Saved: cameras.geojson');
}

void convertSpeedLimitToGeoJSON() {
  final file = File('data_sources/final/speed_limit.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  final features = <Map<String, dynamic>>[];

  for (var item in data) {
    final map = item as Map<String, dynamic>;
    final lat = map['lat'];
    final lng = map['lng'];
    final speedLimit = map['speedLimit'];

    if (lat == null || lng == null || speedLimit == null) continue;

    features.add({
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [
          (lng as num).toDouble(),
          (lat as num).toDouble(),
        ],
      },
      'properties': {
        'speedLimit': speedLimit,
      },
    });
  }

  final geojson = {
    'type': 'FeatureCollection',
    'features': features,
  };

  final output = File('data_sources/final/speed_limit.geojson');
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(geojson),
  );

  print('  ✅ Converted: ${features.length} features');
  print('  ✅ Saved: speed_limit.geojson');
}

