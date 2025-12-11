import 'dart:convert';
import 'dart:io';

void main() {
  print('=== Generate Tile Metadata ===\n');

  // Read summary for counts
  final summaryFile = File('data_sources/final/all_data_summary.json');
  Map<String, dynamic> summary = {};
  if (summaryFile.existsSync()) {
    summary = jsonDecode(summaryFile.readAsStringSync()) as Map<String, dynamic>;
  }

  // Check if vietmap.mbtiles exists to get actual zoom levels
  final mbtilesFile = File('vietmap.mbtiles');
  int minZoom = 5;
  int maxZoom = 18;

  if (mbtilesFile.existsSync()) {
    // Try to read metadata from mbtiles (if sqlite3 available)
    // For now, use defaults
    print('  ℹ️  Using default zoom levels: $minZoom-$maxZoom');
  }

  final metadata = {
    'version': 1,
    'minzoom': minZoom,
    'maxzoom': maxZoom,
    'attribution': 'OSM, Custom Pipeline',
    'layers': [
      'danger_zone',
      'railway',
      'cameras',
      'speed_limit',
    ],
    'generated_at': DateTime.now().toIso8601String().split('T')[0],
    'bbox': summary['bbox'] ?? [104.5, 8.8, 107.5, 11.8],
    'counts': summary['counts'] ?? {
      'danger_zone': 0,
      'railway': 0,
      'cameras': 0,
      'speed_limit': 0,
    },
    'mbtiles_file': 'vietmap.mbtiles',
    'pipeline_version': '3.0.0',
  };

  // Save metadata
  final output = File('data_sources/final/tile_metadata.json');
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(metadata),
  );

  print('✅ Tile metadata generated:');
  print('  Version: ${metadata['version']}');
  print('  Zoom: ${metadata['minzoom']}-${metadata['maxzoom']}');
  print('  Layers: ${metadata['layers'].length}');
  print('  Generated at: ${metadata['generated_at']}');
  print('  ✅ Saved: tile_metadata.json');
}

