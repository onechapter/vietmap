import 'base_repository.dart';

class DangerZoneItem {
  final String id;
  final double lat;
  final double lng;
  final String type;

  DangerZoneItem({
    required this.id,
    required this.lat,
    required this.lng,
    required this.type,
  });
}

class DangerZoneRepository extends BaseRepository<DangerZoneItem> {
  static DangerZoneRepository? _instance;

  DangerZoneRepository._() : super('data_sources/final/danger_zone.min.json');

  static DangerZoneRepository get instance {
    _instance ??= DangerZoneRepository._();
    return _instance!;
  }

  @override
  DangerZoneItem parseItem(Map<String, dynamic> json) {
    final lat = (json['lat'] as num).toDouble();
    final lng = (json['lng'] as num).toDouble();
    final type = json['type'] as String? ?? 'unknown';
    final id = '${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}_$type';
    return DangerZoneItem(id: id, lat: lat, lng: lng, type: type);
  }

  @override
  String getId(DangerZoneItem item) => item.id;

  @override
  (double lat, double lng) getLocation(DangerZoneItem item) => (item.lat, item.lng);
}

