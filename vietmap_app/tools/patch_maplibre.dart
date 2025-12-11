import 'dart:io';

/// Patch maplibre_gl 0.16.0 to add Android namespace for AGP 8+
/// and remove deprecated package attribute in AndroidManifest.xml
///
/// Usage:
///   dart run tools/patch_maplibre.dart
///
/// The script looks up the package in PUB_CACHE (or default ~/.pub-cache),
/// edits android/build.gradle to insert:
///
/// android {
///     namespace "com.maplibre.flutter"
/// }
///
/// The patch is idempotent (will not duplicate if already present).
Future<void> main() async {
  // Resolve pub cache path (supports Linux/macOS default ~/.pub-cache,
  // Windows default %LOCALAPPDATA%/Pub/Cache, or PUB_CACHE override)
  String? pubCache = Platform.environment['PUB_CACHE'];
  if (pubCache == null || pubCache.isEmpty) {
    // Windows: %LOCALAPPDATA%\Pub\Cache
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      final winPath =
          '$localAppData${Platform.pathSeparator}Pub${Platform.pathSeparator}Cache';
      if (Directory(winPath).existsSync()) {
        pubCache = winPath;
      }
    }
  }
  if (pubCache == null || pubCache.isEmpty) {
    // Fallback: ~/.pub-cache
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    pubCache = '$home${Platform.pathSeparator}.pub-cache';
  }

  final packageDir = Directory(
      '$pubCache${Platform.pathSeparator}hosted${Platform.pathSeparator}pub.dev${Platform.pathSeparator}maplibre_gl-0.16.0');

  if (!packageDir.existsSync()) {
    stderr.writeln(
        'maplibre_gl-0.16.0 not found in pub cache at: ${packageDir.path}');
    exit(1);
  }

  final buildGradle =
      File('${packageDir.path}${Platform.pathSeparator}android${Platform.pathSeparator}build.gradle');
  final manifest = File(
      '${packageDir.path}${Platform.pathSeparator}android${Platform.pathSeparator}src${Platform.pathSeparator}main${Platform.pathSeparator}AndroidManifest.xml');

  if (!buildGradle.existsSync()) {
    stderr.writeln('build.gradle not found: ${buildGradle.path}');
    exit(1);
  }

  final content = buildGradle.readAsStringSync();
  if (content.contains('namespace "com.maplibre.flutter"')) {
    stdout.writeln('maplibre_gl already patched (namespace).');
  } else {
    const needle = "apply plugin: 'com.android.library'";
    final insert = '''
$needle

android {
    namespace "com.maplibre.flutter"
}
''';

    if (!content.contains(needle)) {
      stderr.writeln('Unexpected build.gradle format, needle not found.');
      exit(1);
    }

    final patched = content.replaceFirst(needle, insert);
    buildGradle.writeAsStringSync(patched);
    stdout.writeln('Patched maplibre_gl namespace at ${buildGradle.path}');
  }

  // Patch AndroidManifest: remove package attribute if present
  if (manifest.existsSync()) {
    final manifestContent = manifest.readAsStringSync();
    if (manifestContent.contains('package="com.mapbox.mapboxgl"')) {
      final updated = manifestContent.replaceAll('package="com.mapbox.mapboxgl"', '');
      manifest.writeAsStringSync(updated);
      stdout.writeln('Removed package attribute from AndroidManifest.xml');
    } else {
      stdout.writeln('AndroidManifest already clean (no package attribute).');
    }
  } else {
    stderr.writeln('AndroidManifest.xml not found: ${manifest.path}');
  }
}

