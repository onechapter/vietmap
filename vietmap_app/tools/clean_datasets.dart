import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  await Directory('data_sources/final').create(recursive: true);

  await _cleanDanger();
  await _cleanRailway();
  await _mergeSpeed();
  await _writeFinals();
  await _report();
}

// Globals to merge finals
List<Map<String, dynamic>> finalCameras = [];
List<Map<String, dynamic>> finalRailway = [];
List<Map<String, dynamic>> finalDanger = [];
List<Map<String, dynamic>> finalSpeed = [];

Future<void> _cleanDanger() async {
  final file = File('data_sources/polygons/danger_zone.json');
  if (!await file.exists()) return;
  final data = jsonDecode(await file.readAsString()) as List;

  const whitelistTags = {
    'landuse': {'residential', 'industrial'},
    'highway': {'junction'},
    'natural': {'cliff', 'peak'},
    'amenity': {'school', 'kindergarten'},
  };

  List<Map<String, dynamic>> out = [];
  for (final e in data) {
    if (e is! Map) continue;
    final type = e['type']?.toString();
    final polygon = e['polygon'];
    if (polygon is! List || polygon.length < 3) continue;
    if (type == null) continue;

    bool ok = false;
    for (final key in whitelistTags.keys) {
      if (type == key) continue;
    }
    // Type already stored in e['type'] from importer; we map against values
    if (type == 'residential' || type == 'industrial') ok = true;
    if (type == 'junction') ok = true;
    if (type == 'cliff' || type == 'peak') ok = true;
    if (type == 'school' || type == 'kindergarten') ok = true;
    if (!ok) continue;

    out.add({
      "type": type,
      "polygon": polygon,
    });
  }

  // Dedupe polygons by hash of rounded points
  final dedup = <String, Map<String, dynamic>>{};
  for (final e in out) {
    final poly = (e['polygon'] as List)
        .map((p) => '${(p[0] as num).toStringAsFixed(6)},${(p[1] as num).toStringAsFixed(6)}')
        .join('|');
    final key = '${e['type']}:$poly';
    dedup[key] = e;
  }

  finalDanger = dedup.values.toList()
    ..sort((a, b) {
      final pa = (a['polygon'] as List).first as List;
      final pb = (b['polygon'] as List).first as List;
      final la = (pa[0] as num).compareTo(pb[0] as num);
      if (la != 0) return la;
      return (pa[1] as num).compareTo(pb[1] as num);
    });
}

Future<void> _cleanRailway() async {
  final file = File('data_sources/railway/railway.json');
  if (!await file.exists()) return;
  final data = jsonDecode(await file.readAsString()) as List;

  final out = <Map<String, dynamic>>[];
  for (final e in data) {
    if (e is! Map) continue;
    final lat = e['lat'];
    final lng = e['lng'];
    final type = e['type']?.toString() ?? '';
    if (lat == null || lng == null) continue;
    final allowed = {
      'crossing',
      'level_crossing',
      'tram_crossing',
      'railway_crossing',
    };
    if (!allowed.contains(type)) continue;
    out.add({
      "id": e['id']?.toString() ?? '',
      "lat": (lat as num).toDouble(),
      "lng": (lng as num).toDouble(),
      "type": "railway_crossing",
    });
  }

  // Dedupe by rounded lat/lng
  final dedup = <String, Map<String, dynamic>>{};
  for (final e in out) {
    final key = '${(e['lat'] as num).toStringAsFixed(6)}:${(e['lng'] as num).toStringAsFixed(6)}';
    dedup[key] = e;
  }

  finalRailway = dedup.values.toList()
    ..sort((a, b) {
      final la = (a['lat'] as num).compareTo(b['lat'] as num);
      if (la != 0) return la;
      return (a['lng'] as num).compareTo(b['lng'] as num);
    });
}

Future<void> _mergeSpeed() async {
  final speedFile = File('data_sources/final/speed_limit.json');
  if (!await speedFile.exists()) {
    finalSpeed = [];
    return;
  }
  final data = jsonDecode(await speedFile.readAsString());
  if (data is List) {
    finalSpeed = data.cast<Map<String, dynamic>>();
  } else {
    finalSpeed = [];
  }
}

Future<void> _writeFinals() async {
  // cameras: currently just pass-through raw cameras if exist
  final camFile = File('data_sources/cameras/cameras.json');
  if (await camFile.exists()) {
    final cams = jsonDecode(await camFile.readAsString());
    if (cams is List) {
      // dedupe by id
      final dedup = <String, Map<String, dynamic>>{};
      for (final e in cams) {
        if (e is! Map) continue;
        dedup[e['id']?.toString() ?? ''] = Map<String, dynamic>.from(e);
      }
      finalCameras = dedup.values.toList()
        ..sort((a, b) {
          final la = ((a['lat'] as num?) ?? 0).compareTo((b['lat'] as num?) ?? 0);
          if (la != 0) return la;
          return ((a['lng'] as num?) ?? 0).compareTo((b['lng'] as num?) ?? 0);
        });
    }
  }

  await File('data_sources/final/cameras.json').writeAsString(const JsonEncoder.withIndent('  ').convert(finalCameras));
  await File('data_sources/final/railway.json').writeAsString(const JsonEncoder.withIndent('  ').convert(finalRailway));
  await File('data_sources/final/danger_zone.json').writeAsString(const JsonEncoder.withIndent('  ').convert(finalDanger));
  await File('data_sources/final/speed_limit.json').writeAsString(const JsonEncoder.withIndent('  ').convert(finalSpeed));
}

Future<void> _report() async {
  Future<int> countItems(String path) async {
    final f = File(path);
    if (!await f.exists()) return 0;
    final data = jsonDecode(await f.readAsString());
    return data is List ? data.length : 0;
  }

  final cams = await countItems('data_sources/final/cameras.json');
  final rails = await countItems('data_sources/final/railway.json');
  final danger = await countItems('data_sources/final/danger_zone.json');
  final speeds = await countItems('data_sources/final/speed_limit.json');

  print('Final datasets: cameras=$cams railway=$rails danger=$danger speed=$speeds');
}

