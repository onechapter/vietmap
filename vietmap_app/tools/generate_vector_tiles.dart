import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  print('=== Phase 3: Generate Vector Tiles ===\n');

  // Check if tippecanoe is available
  final tippecanoeAvailable = await _checkCommand('tippecanoe');
  final tileJoinAvailable = await _checkCommand('tile-join');

  if (!tippecanoeAvailable || !tileJoinAvailable) {
    print('❌ ERROR: tippecanoe or tile-join not found!');
    print('');
    print('Please install tippecanoe:');
    print('  Windows: choco install tippecanoe');
    print('  Or download from: https://github.com/felt/tippecanoe/releases');
    print('');
    print('Alternatively, run the PowerShell script:');
    print('  .\\tools\\generate_vector_tiles.ps1');
    exit(1);
  }

  // Create tiles directory
  final tilesDir = Directory('tiles');
  if (!tilesDir.existsSync()) {
    tilesDir.createSync(recursive: true);
  }

  // 1. Danger Zone
  print('1. Generating danger_zone.mbtiles...');
  final dangerZoneResult = await _runTippecanoe(
    output: 'tiles/danger_zone.mbtiles',
    layer: 'danger_zone',
    geojson: 'data_sources/final/danger_zone.geojson',
    options: [
      '--no-feature-limit',
      '--no-tile-size-limit',
      '--drop-densest-as-needed',
      '--extend-zooms-if-still-dropping',
      '--coalesce-smallest-as-needed',
      '--force',
    ],
  );

  if (dangerZoneResult.exitCode == 0) {
    print('  ✅ danger_zone.mbtiles created');
  } else {
    print('  ❌ Failed: ${dangerZoneResult.stderr}');
    exit(1);
  }
  print('');

  // 2. Railway
  print('2. Generating railway.mbtiles...');
  final railwayResult = await _runTippecanoe(
    output: 'tiles/railway.mbtiles',
    layer: 'railway',
    geojson: 'data_sources/final/railway.geojson',
    options: ['--force'],
  );

  if (railwayResult.exitCode == 0) {
    print('  ✅ railway.mbtiles created');
  } else {
    print('  ❌ Failed: ${railwayResult.stderr}');
    exit(1);
  }
  print('');

  // 3. Cameras
  print('3. Generating cameras.mbtiles...');
  final camerasResult = await _runTippecanoe(
    output: 'tiles/cameras.mbtiles',
    layer: 'cameras',
    geojson: 'data_sources/final/cameras.geojson',
    options: ['--force'],
  );

  if (camerasResult.exitCode == 0) {
    print('  ✅ cameras.mbtiles created');
  } else {
    print('  ❌ Failed: ${camerasResult.stderr}');
    exit(1);
  }
  print('');

  // 4. Speed Limit
  print('4. Generating speed_limit.mbtiles...');
  final speedLimitResult = await _runTippecanoe(
    output: 'tiles/speed_limit.mbtiles',
    layer: 'speed_limit',
    geojson: 'data_sources/final/speed_limit.geojson',
    options: ['--force'],
  );

  if (speedLimitResult.exitCode == 0) {
    print('  ✅ speed_limit.mbtiles created');
  } else {
    print('  ❌ Failed: ${speedLimitResult.stderr}');
    exit(1);
  }
  print('');

  // 5. Merge tiles
  print('5. Merging all tiles into vietmap.mbtiles...');
  final mergeResult = await Process.run(
    'tile-join',
    [
      '-o',
      'vietmap.mbtiles',
      'tiles/danger_zone.mbtiles',
      'tiles/railway.mbtiles',
      'tiles/cameras.mbtiles',
      'tiles/speed_limit.mbtiles',
      '--force',
    ],
    runInShell: true,
  );

  if (mergeResult.exitCode == 0) {
    print('  ✅ vietmap.mbtiles created');
  } else {
    print('  ❌ Failed: ${mergeResult.stderr}');
    exit(1);
  }
  print('');

  // Get file size
  final mbtilesFile = File('vietmap.mbtiles');
  if (mbtilesFile.existsSync()) {
    final sizeMB = (mbtilesFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
    print('✅ Complete!');
    print('  Output: vietmap.mbtiles (${sizeMB} MB)');
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

Future<ProcessResult> _runTippecanoe({
  required String output,
  required String layer,
  required String geojson,
  required List<String> options,
}) async {
  final args = [
    '-o',
    output,
    '--layer=$layer',
    ...options,
    geojson,
  ];

  return await Process.run(
    'tippecanoe',
    args,
    runInShell: true,
  );
}

