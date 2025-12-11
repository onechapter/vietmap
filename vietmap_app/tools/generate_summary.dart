import 'dart:convert';
import 'dart:io';

void main() {
  print('=== Generate Global Summary ===\n');

  // Read report.json for counts
  final reportFile = File('data_sources/final/report.json');
  Map<String, dynamic> counts = {};
  if (reportFile.existsSync()) {
    counts = jsonDecode(reportFile.readAsStringSync()) as Map<String, dynamic>;
  }

  // Calculate bounding box from data
  final bbox = calculateBoundingBox();

  // Generate summary
  final summary = {
    'generated_at': DateTime.now().toIso8601String().split('T')[0],
    'bbox': bbox,
    'counts': {
      'danger_zone': counts['danger_zone'] ?? 0,
      'railway': counts['railway'] ?? 0,
      'cameras': counts['cameras'] ?? 0,
      'speed_limit': counts['speed_limit'] ?? 0,
    },
    'pipeline_version': '2.5.1',
    'files': {
      'json': [
        'cameras.json',
        'railway.json',
        'danger_zone.json',
      ],
      'minified': [
        'cameras.min.json',
        'railway.min.json',
        'danger_zone.min.json',
        'speed_limit.min.json',
      ],
      'geojson': [
        'cameras.geojson',
        'railway.geojson',
        'danger_zone.geojson',
        'speed_limit.geojson',
      ],
    },
  };

  // Save summary
  final output = File('data_sources/final/all_data_summary.json');
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
  );

  final countsMap = summary['counts'] as Map<String, dynamic>;
  print('✅ Summary generated:');
  print('  Generated at: ${summary['generated_at']}');
  print('  BBox: ${bbox[0]}, ${bbox[1]}, ${bbox[2]}, ${bbox[3]}');
  print('  Counts:');
  print('    - Danger Zone: ${countsMap['danger_zone']}');
  print('    - Railway: ${countsMap['railway']}');
  print('    - Cameras: ${countsMap['cameras']}');
  print('    - Speed Limit: ${countsMap['speed_limit']}');
  print('  ✅ Saved: all_data_summary.json');
}

List<double> calculateBoundingBox() {
  double minLat = 90, minLng = 180, maxLat = -90, maxLng = -180;

  // Check railway.json
  final railwayFile = File('data_sources/final/railway.json');
  if (railwayFile.existsSync()) {
    final data = jsonDecode(railwayFile.readAsStringSync()) as List;
    for (var item in data) {
      final map = item as Map<String, dynamic>;
      final lat = map['lat'] as num?;
      final lng = map['lng'] as num?;
      if (lat != null && lng != null) {
        minLat = minLat < lat ? minLat : lat.toDouble();
        maxLat = maxLat > lat ? maxLat : lat.toDouble();
        minLng = minLng < lng ? minLng : lng.toDouble();
        maxLng = maxLng > lng ? maxLng : lng.toDouble();
      }
    }
  }

  // Check danger_zone.json (use centroid)
  final dangerFile = File('data_sources/final/danger_zone.json');
  if (dangerFile.existsSync()) {
    final data = jsonDecode(dangerFile.readAsStringSync()) as List;
    for (var item in data) {
      final map = item as Map<String, dynamic>;
      final polygon = map['polygon'] as List?;
      if (polygon != null) {
        for (var point in polygon) {
          if (point is List && point.length >= 2) {
            final lat = (point[0] as num).toDouble();
            final lng = (point[1] as num).toDouble();
            minLat = minLat < lat ? minLat : lat;
            maxLat = maxLat > lat ? maxLat : lat;
            minLng = minLng < lng ? minLng : lng;
            maxLng = maxLng > lng ? maxLng : lng;
          }
        }
      }
    }
  }

  // If no data found, use default bbox from importer
  if (minLat == 90) {
    return [104.5, 8.8, 107.5, 11.8]; // [minLng, minLat, maxLng, maxLat]
  }

  return [minLng, minLat, maxLng, maxLat]; // [minLng, minLat, maxLng, maxLat]
}

