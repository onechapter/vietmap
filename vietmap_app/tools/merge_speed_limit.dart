import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() async {
  final camerasFile = File('data_sources/cameras/cameras.json');
  final waySpeedFile = File('data_sources/speed/way_speed.json');
  await Directory('data_sources/final').create(recursive: true);

  final cameras = await _readList(camerasFile);
  final waySpeeds = await _readList(waySpeedFile);

  final cameraSpeeds = cameras
      .where((e) => e['speedLimit'] != null && e['speedLimit'] is num)
      .map((e) => _SpeedPoint(
            id: e['id'].toString(),
            lat: (e['lat'] as num).toDouble(),
            lng: (e['lng'] as num).toDouble(),
            speed: (e['speedLimit'] as num).toInt(),
            source: 'camera',
          ))
      .toList();

  final wayPoints = waySpeeds
      .where((e) => e['speedLimit'] != null && e['speedLimit'] is num)
      .map((e) => _SpeedPoint(
            id: e['id'].toString(),
            lat: (e['lat'] as num).toDouble(),
            lng: (e['lng'] as num).toDouble(),
            speed: (e['speedLimit'] as num).toInt(),
            source: 'way',
          ))
      .toList();

  final result = <Map<String, dynamic>>[];

  // Index cameras for quick lookup
  for (final cam in cameraSpeeds) {
    result.add(cam.toJson());
  }

  for (final way in wayPoints) {
    final nearest = _findNearest(cameraSpeeds, way, 40); // within 40m
    if (nearest != null) continue; // camera has priority
    result.add(way.toJson());
  }

  // Dedupe by rounded lat/lng + speed
  final dedup = <String, Map<String, dynamic>>{};
  for (final r in result) {
    final key = '${r['speed']}:${r['lat'].toStringAsFixed(6)}:${r['lng'].toStringAsFixed(6)}';
    dedup[key] = r;
  }

  final sorted = dedup.values.toList()
    ..sort((a, b) {
      final la = (a['lat'] as num).compareTo(b['lat'] as num);
      if (la != 0) return la;
      final lo = (a['lng'] as num).compareTo(b['lng'] as num);
      if (lo != 0) return lo;
      return (a['speed'] as num).compareTo(b['speed'] as num);
    });

  await File('data_sources/final/speed_limit.json').writeAsString(const JsonEncoder.withIndent('  ').convert(sorted));
  print('Merged speed_limit: ${sorted.length} items');
}

Future<List<dynamic>> _readList(File f) async {
  if (!await f.exists()) return [];
  final txt = await f.readAsString();
  final data = jsonDecode(txt);
  return data is List ? data : [];
}

_SpeedPoint? _findNearest(List<_SpeedPoint> cams, _SpeedPoint target, double maxMeters) {
  _SpeedPoint? best;
  double bestD = double.infinity;
  for (final c in cams) {
    final d = _haversine(c.lat, c.lng, target.lat, target.lng);
    if (d < bestD) {
      bestD = d;
      best = c;
    }
  }
  if (bestD <= maxMeters) return best;
  return null;
}

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _deg2rad(double deg) => deg * pi / 180.0;

class _SpeedPoint {
  final String id;
  final double lat;
  final double lng;
  final int speed;
  final String source;

  _SpeedPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "lat": lat,
        "lng": lng,
        "speed": speed,
        "source": source,
      };
}

