import 'logger.dart';  // TASK DEBUG-08: Import logger for cell key logging

class GridIndex<T> {
  final double cellSize;
  final Map<String, List<T>> _buckets = {};

  GridIndex({this.cellSize = 0.01});

  String _key(double lat, double lng) {
    final gx = (lat / cellSize).floor();
    final gy = (lng / cellSize).floor();
    return '$gx:$gy';
  }

  void add(double lat, double lng, T item) {
    final key = _key(lat, lng);
    _buckets.putIfAbsent(key, () => []).add(item);
  }

  // TASK DEBUG-08: Track last cell to verify changes
  String? _lastCellKey;

  Iterable<T> queryNeighborhood(double lat, double lng) sync* {
    final gx = (lat / cellSize).floor();
    final gy = (lng / cellSize).floor();
    final currentCellKey = '$gx:$gy';
    
    // TASK DEBUG-08: Log cell key and verify cell changed
    if (_lastCellKey != currentCellKey) {
      appLog('[GridIndex] ✅ Cell CHANGED: $currentCellKey (was $_lastCellKey), lat=$lat, lng=$lng');
      _lastCellKey = currentCellKey;
    } else {
      appLog('[GridIndex] Cell unchanged: $currentCellKey');
    }
    
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final key = '${gx + dx}:${gy + dy}';
        final bucket = _buckets[key];
        if (bucket != null) {
          for (final item in bucket) {
            yield item;
          }
        }
      }
    }
  }

  int bucketCount() => _buckets.length;

  void clear() {
    _buckets.clear();
  }
}

