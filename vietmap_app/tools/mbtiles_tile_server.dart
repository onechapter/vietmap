import 'dart:io';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

/// Simple MBTiles tile server
/// Serves tiles from MBTiles file via HTTP on localhost:8081
/// 
/// Usage:
///   dart run tools/mbtiles_tile_server.dart path/to/vietmap.mbtiles
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run tools/mbtiles_tile_server.dart <mbtiles_path>');
    exit(1);
  }

  final mbtilesPath = args[0];
  final file = File(mbtilesPath);

  if (!await file.exists()) {
    print('Error: MBTiles file not found: $mbtilesPath');
    exit(1);
  }

  // Initialize sqflite for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('Starting MBTiles tile server...');
  print('MBTiles: $mbtilesPath');
  print('Server: http://127.0.0.1:8081/tiles/{z}/{x}/{y}.pbf');

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8081);
  print('Server running on http://127.0.0.1:8081');

  await for (final request in server) {
    try {
      if (request.method == 'GET' && request.uri.path.startsWith('/tiles/')) {
        // Parse tile coordinates from URL: /tiles/{z}/{x}/{y}.pbf
        final parts = request.uri.path.split('/');
        if (parts.length == 5 && parts[4].endsWith('.pbf')) {
          final z = int.tryParse(parts[2]);
          final x = int.tryParse(parts[3]);
          final y = int.tryParse(parts[4].replaceAll('.pbf', ''));

          if (z != null && x != null && y != null) {
            final tileData = await _getTile(mbtilesPath, z, x, y);
            if (tileData != null) {
              request.response
                ..statusCode = 200
                ..headers.set('Content-Type', 'application/x-protobuf')
                ..headers.set('Content-Encoding', 'gzip')
                ..headers.set('Access-Control-Allow-Origin', '*')
                ..add(tileData);
              await request.response.close();
              continue;
            }
          }
        }
      }

      // 404 for invalid requests
      request.response
        ..statusCode = 404
        ..write('Not found');
      await request.response.close();
    } catch (e) {
      print('Error handling request: $e');
      request.response
        ..statusCode = 500
        ..write('Internal server error');
      await request.response.close();
    }
  }
}

/// Get tile data from MBTiles database
Future<Uint8List?> _getTile(String mbtilesPath, int z, int x, int y) async {
  try {
    // Convert Y coordinate (MBTiles uses TMS, not XYZ)
    final tmsY = (1 << z) - 1 - y;

    final db = await databaseFactoryFfi.openDatabase(mbtilesPath);
    final result = await db.rawQuery(
      'SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?',
      [z, x, tmsY],
    );
    await db.close();

    if (result.isNotEmpty && result[0]['tile_data'] != null) {
      return result[0]['tile_data'] as Uint8List;
    }

    return null;
  } catch (e) {
    print('Error reading tile ($z/$x/$y): $e');
    return null;
  }
}

