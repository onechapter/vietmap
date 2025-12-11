import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../core/grid_index.dart';
import '../../core/logger.dart';
import '../../core/engine/engine_config.dart';

/// Base repository with spatial indexing and caching
abstract class BaseRepository<T> {
  final GridIndex<T> _gridIndex = GridIndex<T>(cellSize: 0.01);
  final Map<String, T> _itemsById = {};
  final String assetPath;
  bool _loaded = false;

  // Grid cache for performance
  final Map<String, List<T>> _gridCache = {};
  DateTime? _lastCacheRefresh;
  double? _lastCacheLat;
  double? _lastCacheLng;

  BaseRepository(this.assetPath);

  /// Parse item from JSON
  T parseItem(Map<String, dynamic> json);

  /// Get ID from item
  String getId(T item);

  /// Get lat/lng from item
  (double lat, double lng) getLocation(T item);

  /// Load data from asset file
  Future<void> load() async {
    if (_loaded) return;

    try {
      appLog('Loading $assetPath...');
      final String jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      _itemsById.clear();
      _gridIndex.clear();

      for (final json in jsonList) {
        final item = parseItem(json as Map<String, dynamic>);
        final id = getId(item);
        _itemsById[id] = item;

        final (lat, lng) = getLocation(item);
        _gridIndex.add(lat, lng, item);
      }

      _loaded = true;
      appLog('Loaded ${_itemsById.length} items from $assetPath');
    } catch (e) {
      appLog('Error loading $assetPath: $e');
      _loaded = true; // Mark as loaded to prevent infinite retries
    }
  }

  /// Query nearby items within radius (with caching)
  List<T> queryNearby(double lat, double lng, double radiusMeters) {
    if (!_loaded) return [];

    // Check grid cache
    if (EngineConfig.enableGridCache) {
      final cacheKey = _gridKey(lat, lng);
      final now = DateTime.now();

      // Check if cache is valid
      bool cacheValid = false;
      if (_lastCacheRefresh != null && _lastCacheLat != null && _lastCacheLng != null) {
        final timeDiff = now.difference(_lastCacheRefresh!);
        final distance = const Distance();
        final regionDiff = distance.as(
          LengthUnit.Meter,
          LatLng(_lastCacheLat!, _lastCacheLng!),
          LatLng(lat, lng),
        );

        if (timeDiff.inMinutes < EngineConfig.gridCacheRefreshMinutes &&
            regionDiff < EngineConfig.gridCacheRegionThresholdM) {
          cacheValid = true;
        }
      }

      if (cacheValid && _gridCache.containsKey(cacheKey)) {
        appLog('BaseRepository: Grid cache hit for $cacheKey');
        return _gridCache[cacheKey]!;
      }

      // Update cache
      _lastCacheRefresh = now;
      _lastCacheLat = lat;
      _lastCacheLng = lng;
    }

    // Query from grid index
    final candidates = _gridIndex.queryNeighborhood(lat, lng);
    final results = <T>[];
    final distance = const Distance();

    for (final item in candidates) {
      final (itemLat, itemLng) = getLocation(item);
      final dist = distance.as(
        LengthUnit.Meter,
        LatLng(lat, lng),
        LatLng(itemLat, itemLng),
      );

      if (dist <= radiusMeters) {
        results.add(item);
      }
    }

    // Cache results
    if (EngineConfig.enableGridCache) {
      final cacheKey = _gridKey(lat, lng);
      _gridCache[cacheKey] = results;
      appLog('BaseRepository: Grid cache updated for $cacheKey (${results.length} items)');
    }

    return results;
  }

  String _gridKey(double lat, double lng) {
    // Round to 0.01 degree (~1km) for cache key
    final gridLat = (lat * 100).floor();
    final gridLng = (lng * 100).floor();
    return '${gridLat}_${gridLng}';
  }

  /// Get item by ID
  T? getById(String id) {
    return _itemsById[id];
  }

  /// Reload data
  Future<void> reload() async {
    _loaded = false;
    await load();
  }

  /// Get all items
  List<T> getAll() {
    return _itemsById.values.toList();
  }

  /// Get count
  int get count => _itemsById.length;
}

