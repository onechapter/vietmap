import 'dart:io';

void main() async {
  print('=== Phase 3 - Pre-flight Check ===\n');

  bool allGood = true;

  // 1. Check tippecanoe
  print('1. Checking tippecanoe...');
  final tippecanoeOk = await _checkCommand('tippecanoe');
  if (tippecanoeOk) {
    print('  ✅ tippecanoe is installed');
  } else {
    print('  ❌ tippecanoe NOT found');
    print('     Install: choco install tippecanoe');
    allGood = false;
  }

  // 2. Check tile-join
  print('\n2. Checking tile-join...');
  final tileJoinOk = await _checkCommand('tile-join');
  if (tileJoinOk) {
    print('  ✅ tile-join is installed');
  } else {
    print('  ❌ tile-join NOT found');
    print('     Should come with tippecanoe');
    allGood = false;
  }

  // 3. Check GeoJSON files
  print('\n3. Checking GeoJSON files...');
  final geojsonFiles = [
    'data_sources/final/danger_zone.geojson',
    'data_sources/final/railway.geojson',
    'data_sources/final/cameras.geojson',
    'data_sources/final/speed_limit.geojson',
  ];

  for (var file in geojsonFiles) {
    final f = File(file);
    if (f.existsSync()) {
      final sizeKB = (f.lengthSync() / 1024).toStringAsFixed(2);
      print('  ✅ ${f.path.split('/').last} (${sizeKB} KB)');
    } else {
      print('  ❌ ${f.path.split('/').last} NOT found');
      allGood = false;
    }
  }

  // 4. Check metadata
  print('\n4. Checking metadata...');
  final metadataFile = File('data_sources/final/tile_metadata.json');
  if (metadataFile.existsSync()) {
    print('  ✅ tile_metadata.json exists');
  } else {
    print('  ❌ tile_metadata.json NOT found');
    print('     Run: dart run tools/generate_tile_metadata.dart');
    allGood = false;
  }

  // 5. Check config
  print('\n5. Checking config...');
  final configFile = File('config/map_layers.json');
  if (configFile.existsSync()) {
    print('  ✅ map_layers.json exists');
  } else {
    print('  ❌ map_layers.json NOT found');
    allGood = false;
  }

  // Summary
  print('\n=== Summary ===');
  if (allGood) {
    print('✅ All checks passed! Ready to generate vector tiles.');
    print('\nRun: dart run tools/generate_vector_tiles.dart');
  } else {
    print('❌ Some checks failed. Please fix the issues above.');
    print('\nSee: tools/PHASE3_README.md for installation guide');
  }
}

Future<bool> _checkCommand(String command) async {
  try {
    final result = await Process.run(
      command,
      ['--version'],
      runInShell: true,
    );
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

