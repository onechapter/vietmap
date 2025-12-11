import 'dart:convert';
import 'dart:io';

void main() {
  print('=== Fix Schema & Generate Minified Files ===\n');

  // Fix and minify Danger Zone
  print('1. Processing danger_zone.json...');
  fixAndMinifyDangerZone();

  // Fix and minify Railway
  print('\n2. Processing railway.json...');
  fixAndMinifyRailway();

  // Minify Cameras
  print('\n3. Processing cameras.json...');
  minifyCameras();

  // Minify Speed Limit
  print('\n4. Processing speed_limit.json...');
  minifySpeedLimit();

  print('\n=== Complete ===');
}

void fixAndMinifyDangerZone() {
  final file = File('data_sources/final/danger_zone.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  final minified = <Map<String, dynamic>>[];

  for (var item in data) {
    final map = item as Map<String, dynamic>;
    final polygon = map['polygon'] as List?;
    final type = map['type'] as String?;

    if (polygon == null || polygon.isEmpty || type == null) continue;

    // Calculate centroid for lat/lng
    double sumLat = 0, sumLng = 0;
    int count = 0;
    for (var point in polygon) {
      if (point is List && point.length >= 2) {
        sumLat += (point[0] as num).toDouble();
        sumLng += (point[1] as num).toDouble();
        count++;
      }
    }

    if (count == 0) continue;

    final lat = sumLat / count;
    final lng = sumLng / count;

    // Minified format: only essential fields
    minified.add({
      'lat': lat,
      'lng': lng,
      'type': type,
    });
  }

  // Save minified
  final minFile = File('data_sources/final/danger_zone.min.json');
  minFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(minified),
  );

  print('  ✅ Original: ${data.length} items');
  print('  ✅ Minified: ${minified.length} items');
  print('  ✅ Saved: danger_zone.min.json');
  print('  📊 Size reduction: ${_calculateSizeReduction(file, minFile)}%');
}

void fixAndMinifyRailway() {
  final file = File('data_sources/final/railway.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  final minified = <Map<String, dynamic>>[];

  for (var item in data) {
    final map = item as Map<String, dynamic>;
    final lat = map['lat'];
    final lng = map['lng'];
    final type = map['type'] as String?;

    if (lat == null || lng == null || type == null) continue;

    // Determine is_crossing and railway_type from type
    final isCrossing = type.contains('crossing');
    final railwayType = _normalizeRailwayType(type);

    // Minified format
    minified.add({
      'lat': lat,
      'lng': lng,
      'type': railwayType,
      'is_crossing': isCrossing,
    });
  }

  // Save minified
  final minFile = File('data_sources/final/railway.min.json');
  minFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(minified),
  );

  // Also update original with fixed schema
  final fixedFile = File('data_sources/final/railway.json');
  fixedFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(minified),
  );

  print('  ✅ Original: ${data.length} items');
  print('  ✅ Fixed & Minified: ${minified.length} items');
  print('  ✅ Saved: railway.min.json & railway.json (fixed)');
  print('  📊 Size reduction: ${_calculateSizeReduction(file, minFile)}%');
}

String _normalizeRailwayType(String type) {
  if (type.contains('crossing') || type.contains('level_crossing')) {
    return 'level_crossing';
  } else if (type.contains('station')) {
    return 'station';
  } else if (type.contains('rail')) {
    return 'rail';
  }
  return 'railway_crossing'; // default
}

void minifyCameras() {
  final file = File('data_sources/final/cameras.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  final minified = <Map<String, dynamic>>[];

  for (var item in data) {
    final map = item as Map<String, dynamic>;
    minified.add({
      'lat': map['lat'],
      'lng': map['lng'],
      'type': map['type'] ?? 'camera',
      if (map['speedLimit'] != null) 'speedLimit': map['speedLimit'],
    });
  }

  final minFile = File('data_sources/final/cameras.min.json');
  minFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(minified),
  );

  print('  ✅ Items: ${minified.length}');
  print('  ✅ Saved: cameras.min.json');
}

void minifySpeedLimit() {
  final file = File('data_sources/final/speed_limit.json');
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as List;
  final minified = <Map<String, dynamic>>[];

  for (var item in data) {
    final map = item as Map<String, dynamic>;
    minified.add({
      'lat': map['lat'],
      'lng': map['lng'],
      'speedLimit': map['speedLimit'],
    });
  }

  final minFile = File('data_sources/final/speed_limit.min.json');
  minFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(minified),
  );

  print('  ✅ Items: ${minified.length}');
  print('  ✅ Saved: speed_limit.min.json');
}

String _calculateSizeReduction(File original, File minified) {
  final origSize = original.lengthSync();
  final minSize = minified.lengthSync();
  if (origSize == 0) return '0';
  final reduction = ((origSize - minSize) / origSize * 100).toStringAsFixed(1);
  return reduction;
}

