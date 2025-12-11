import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../core/logger.dart';

/// Service to manage vector tiles (MBTiles) loading and access
class MapService {
  static MapService? _instance;
  bool _initialized = false;
  bool _hasMbtiles = false;
  String? _mbtilesPath;
  String? _tileUrlTemplate;

  MapService._();

  static MapService get instance {
    _instance ??= MapService._();
    return _instance!;
  }

  /// Initialize the map service
  /// Checks for MBTiles file and sets up tile URL template
  Future<void> init() async {
    if (_initialized) return;

    try {
      appLog('MapService: Initializing...');

      // Check for MBTiles in assets first
      _hasMbtiles = await _checkAssetMbtiles();

      if (!_hasMbtiles) {
        // Check in data_sources/final directory
        _hasMbtiles = await _checkLocalMbtiles();
      }

      if (_hasMbtiles && _mbtilesPath != null) {
        // For now, we'll use a local tile server approach
        // In production, you might want to use maplibre_gl directly
        _tileUrlTemplate = 'http://127.0.0.1:8081/tiles/{z}/{x}/{y}.pbf';
        appLog('MapService: MBTiles found at $_mbtilesPath');
      } else {
        appLog('MapService: MBTiles not found, will use JSON fallback');
        _tileUrlTemplate = null;
      }

      _initialized = true;
      appLog('MapService: Initialized (hasMbtiles: $_hasMbtiles)');
    } catch (e) {
      appLog('MapService: Error during init: $e');
      _hasMbtiles = false;
      _initialized = true;
    }
  }

  /// Check if MBTiles exists in assets
  Future<bool> _checkAssetMbtiles() async {
    try {
      // Try to load the asset
      await rootBundle.load('data_sources/final/vietmap.mbtiles');
      _mbtilesPath = 'asset://data_sources/final/vietmap.mbtiles';
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if MBTiles exists in local filesystem
  Future<bool> _checkLocalMbtiles() async {
    try {
      // Check in app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final mbtilesFile = File(path.join(
        appDir.path,
        'data_sources',
        'final',
        'vietmap.mbtiles',
      ));

      if (await mbtilesFile.exists()) {
        _mbtilesPath = mbtilesFile.path;
        return true;
      }

      // Check relative to app directory (for development)
      final devPath = path.join(
        Directory.current.path,
        'data_sources',
        'final',
        'vietmap.mbtiles',
      );
      final devFile = File(devPath);
      if (await devFile.exists()) {
        _mbtilesPath = devFile.path;
        return true;
      }

      return false;
    } catch (e) {
      appLog('MapService: Error checking local MBTiles: $e');
      return false;
    }
  }

  /// Get tile URL template for vector tiles
  /// Returns null if MBTiles not available (use JSON fallback)
  String? getTileUrlTemplate() {
    return _tileUrlTemplate;
  }

  /// Check if MBTiles is available
  bool hasMbtiles() {
    return _hasMbtiles;
  }

  /// Get MBTiles file path
  String? getMbtilesPath() {
    return _mbtilesPath;
  }

  /// Reset service (for testing)
  void reset() {
    _initialized = false;
    _hasMbtiles = false;
    _mbtilesPath = null;
    _tileUrlTemplate = null;
  }
}

