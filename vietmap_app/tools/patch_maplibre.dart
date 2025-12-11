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
  final pubCache = Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']}'
          '${Platform.pathSeparator}.pub-cache';

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

