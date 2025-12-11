import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

/// ================================
/// Overpass Importer for Taxi App
/// ================================
/// Tải dữ liệu:
///   - Speed camera / surveillance
///   - Railway + level crossing
///   - Polygon nguy hiểm:
///         + school
///         + pedestrian
///         + construction
///         + industrial
///
/// Output:
///   data_sources/cameras/cameras.json
///   data_sources/railway/railway.json
///   data_sources/polygons/danger_zone.json
///
/// Bổ sung: tự chia bbox thành nhiều tile 0.5° để tránh timeout.
/// ================================

Future<void> main(List<String> args) async {
  print("=== OSM Importer Starting ===");

  if (args.length != 5 || args[0] != "--bbox") {
    print("Usage:");
    print("  dart tools/osm_importer.dart --bbox minLat minLng maxLat maxLng");
    exit(1);
  }

  final minLat = double.parse(args[1]);
  final minLng = double.parse(args[2]);
  final maxLat = double.parse(args[3]);
  final maxLng = double.parse(args[4]);

  final importer = OSMImporter(
    minLat: minLat,
    minLng: minLng,
    maxLat: maxLat,
    maxLng: maxLng,
  );

  await importer.run();
  print("=== DONE ===");
}

class OSMImporter {
  final double minLat, minLng, maxLat, maxLng;

  final dangerPolygons = <Map<String, dynamic>>[];
  final cameras = <Map<String, dynamic>>[];
  final railway = <Map<String, dynamic>>[];
  final waySpeeds = <Map<String, dynamic>>[];

  final overpassMirrors = const [
    "https://overpass-api.de/api/interpreter",
    "https://lz4.overpass-api.de/api/interpreter",
    "https://z.overpass-api.de/api/interpreter",
    "https://overpass.openstreetmap.fr/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
  ];

  OSMImporter({
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
  });

  /// =========================
  /// RUN
  /// =========================
  Future<void> run() async {
    _ensureFolder("data_sources/cameras");
    _ensureFolder("data_sources/railway");
    _ensureFolder("data_sources/polygons");

    print("Splitting BBOX into 0.5° tiles...");
    final tiles = _splitTiles(0.5);

    for (final t in tiles) {
      await _importTile(t);
    }

    await _saveAll();
  }

  /// =========================
  /// Import 1 tile
  /// =========================
  Future<void> _importTile(List<double> t) async {
    final a = t[0], b = t[1], c = t[2], d = t[3];
    print("Import tile: [$a,$b] → [$c,$d]");

    final query = """
[out:json][timeout:25];
(
  // Speed camera + surveillance
  node["man_made"="surveillance"]["surveillance:type"="speed"]($a,$b,$c,$d);
  node["camera:traffic"="signals"]($a,$b,$c,$d);

  // Railway
  node["railway"="level_crossing"]($a,$b,$c,$d);
  way["railway"="rail"]($a,$b,$c,$d);

  // Danger Polygons
  way["amenity"="school"]($a,$b,$c,$d);
  way["highway"="pedestrian"]($a,$b,$c,$d);
  way["highway"="construction"]($a,$b,$c,$d);
  way["landuse"="industrial"]($a,$b,$c,$d);

  // Way maxspeed
  way["highway"]["maxspeed"]($a,$b,$c,$d);
);
out body;
>;
out skel qt;
""";

    final json = await fetchFromMirrors(overpassMirrors, query);
    if (json == null) {
      print("  -> Skip tile after retries/mirrors");
      await _logError(t, "All mirrors failed or non-JSON");
      return;
    }
    _parseOverpass(json);
    print("  -> Tile OK");
  }

  /// =========================
  /// Parse raw Overpass JSON
  /// =========================
  void _parseOverpass(dynamic data) {
    if (data["elements"] == null) return;

    final nodes = <int, List<double>>{};
    for (final e in data["elements"]) {
      if (e["type"] == "node") {
        nodes[e["id"]] = [e["lat"], e["lon"]];

        // Level crossing
        if (e["tags"]?["railway"] == "level_crossing") {
          railway.add({
            "type": "crossing",
            "lat": e["lat"],
            "lng": e["lon"]
          });
        }

        // Speed camera
        if (e["tags"]?["surveillance:type"] == "speed" ||
            e["tags"]?["camera:traffic"] == "signals") {
          cameras.add({
            "id": e["id"].toString(),
            "lat": e["lat"],
            "lng": e["lon"],
            "type": "camera",
            "speedLimit": _extractSpeed(e["tags"])
          });
        }
      }
    }

    // Polygon + railway line (way)
    for (final e in data["elements"]) {
      if (e["type"] != "way") continue;
      final tags = e["tags"] ?? {};

      // Railway line
      if (tags["railway"] == "rail") {
        for (final nid in e["nodes"]) {
          if (nodes[nid] != null) {
            railway.add({
              "type": "rail",
              "lat": nodes[nid]![0],
              "lng": nodes[nid]![1]
            });
          }
        }
      }

      // Danger polygon
      if (_isDangerPolygon(tags)) {
        final poly = <List<double>>[];
        for (final nid in e["nodes"]) {
          if (nodes[nid] != null) {
            poly.add([nodes[nid]![0], nodes[nid]![1]]);
          }
        }

        if (poly.length > 3) {
          dangerPolygons.add({
            "type": tags["amenity"] ?? tags["highway"] ?? tags["landuse"],
            "polygon": poly
          });
        }
      }

      // Way maxspeed
      if (tags.containsKey("maxspeed") && tags["maxspeed"] != null) {
        final points = <List<double>>[];
        for (final nid in e["nodes"]) {
          final p = nodes[nid];
          if (p != null) points.add(p);
        }
        if (points.isNotEmpty) {
          final maxspeed = _parseMaxspeed(tags["maxspeed"].toString());
          if (maxspeed != null) {
            final centroid = _centroid(points);
            waySpeeds.add({
              "id": e["id"].toString(),
              "lat": centroid[0],
              "lng": centroid[1],
              "speedLimit": maxspeed,
              "source": "way_maxspeed",
            });
          }
        }
      }
    }
  }

  bool _isDangerPolygon(Map tags) {
    if (tags["amenity"] == "school") return true;
    if (tags["highway"] == "pedestrian") return true;
    if (tags["highway"] == "construction") return true;
    if (tags["landuse"] == "industrial") return true;
    return false;
  }

  int _extractSpeed(Map? tags) {
    if (tags == null) return 0;
    if (tags["maxspeed"] == null) return 0;
    final s = tags["maxspeed"].toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (s.isEmpty) return 0;
    return int.tryParse(s) ?? 0;
  }

  int? _parseMaxspeed(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('signals') || lower.contains('variable')) return null;
    final digits = RegExp(r'\\d+').allMatches(raw).map((m) => m.group(0)).whereType<String>().toList();
    if (digits.isEmpty) return null;
    return int.tryParse(digits.first);
  }

  List<double> _centroid(List<List<double>> pts) {
    double sx = 0, sy = 0;
    for (final p in pts) {
      sx += p[0];
      sy += p[1];
    }
    final n = pts.length.toDouble();
    return [sx / n, sy / n];
  }

  /// =========================
  /// Save output
  /// =========================
  Future<void> _saveAll() async {
    await File("data_sources/cameras/cameras.json")
        .writeAsString(const JsonEncoder.withIndent("  ").convert(cameras));

    await File("data_sources/railway/railway.json")
        .writeAsString(const JsonEncoder.withIndent("  ").convert(railway));

    await File("data_sources/polygons/danger_zone.json")
        .writeAsString(const JsonEncoder.withIndent("  ").convert(dangerPolygons));

    await File("data_sources/speed/way_speed.json")
        .writeAsString(const JsonEncoder.withIndent("  ").convert(waySpeeds));

    print("Saved:");
    print("  cameras:     ${cameras.length}");
    print("  railway:     ${railway.length}");
    print("  polygons:    ${dangerPolygons.length}");
    print("  way_speeds:  ${waySpeeds.length}");
  }

  /// =========================
  /// Utils
  /// =========================
  Future<void> _logError(List<double> tile, String msg) async {
    final file = File("data_sources/importer_errors.jsonl");
    await file.parent.create(recursive: true);
    final record = {
      "tile": tile,
      "error": msg,
      "time": DateTime.now().toIso8601String(),
    };
    await file.writeAsString(jsonEncode(record) + '\n', mode: FileMode.append);
  }

  void _ensureFolder(String path) {
    Directory(path).createSync(recursive: true);
  }

  List<List<double>> _splitTiles(double step) {
    final tiles = <List<double>>[];

    for (double lat = minLat; lat < maxLat; lat += step) {
      for (double lng = minLng; lng < maxLng; lng += step) {
        final a = lat;
        final b = lng;
        final c = min(lat + step, maxLat);
        final d = min(lng + step, maxLng);
        tiles.add([a, b, c, d]);
      }
    }
    return tiles;
  }
}

/// =========================
/// Helper: content-type check
/// =========================
bool isJsonContentType(String? contentType) {
  if (contentType == null) return false;
  final lower = contentType.toLowerCase();
  return lower.contains("application/json");
}

bool isOverpassErrorHtml(String body) {
  final lower = body.toLowerCase();
  return lower.contains("rate limit") ||
      lower.contains("too many requests") ||
      lower.contains("timeout") ||
      lower.contains("timed out") ||
      lower.contains("runtime error") ||
      lower.contains("out of memory") ||
      (lower.contains("query") && lower.contains("error"));
}

enum OverpassResponseType { json, retryableErrorHtml, fatalHtml }

OverpassResponseType detectOverpassResponse(http.Response res) {
  final ct = res.headers["content-type"];
  if (isJsonContentType(ct)) return OverpassResponseType.json;
  final body = res.body;
  if (isOverpassErrorHtml(body)) return OverpassResponseType.retryableErrorHtml;
  return OverpassResponseType.fatalHtml;
}

Future<Map<String, dynamic>?> fetchOverpassJson(String url, String query) async {
  const delays = [Duration(seconds: 2), Duration(seconds: 5), Duration(seconds: 10)];
  for (var attempt = 1; attempt <= 3; attempt++) {
    try {
      print("  -> Request attempt $attempt @ $url");
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"data": query},
      );

      final type = detectOverpassResponse(res);
      switch (type) {
        case OverpassResponseType.json:
          return jsonDecode(res.body) as Map<String, dynamic>;
        case OverpassResponseType.retryableErrorHtml:
          if (attempt < 3) {
            await Future.delayed(delays[attempt - 1]);
            continue;
          }
          return null;
        case OverpassResponseType.fatalHtml:
          return null;
      }
    } catch (_) {
      if (attempt < 3) {
        await Future.delayed(delays[attempt - 1]);
        continue;
      }
      return null;
    }
  }
  return null;
}

Future<Map<String, dynamic>?> fetchFromMirrors(List<String> mirrors, String query) async {
  for (final m in mirrors) {
    final json = await fetchOverpassJson(m, query);
    if (json != null) return json;
  }
  return null;
}

