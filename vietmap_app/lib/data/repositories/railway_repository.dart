import 'base_repository.dart';

class RailwayItem {
  final String id;
  final double lat;
  final double lng;
  final String type;
  final bool isCrossing;

  RailwayItem({
    required this.id,
    required this.lat,
    required this.lng,
    required this.type,
    required this.isCrossing,
  });
}

class RailwayRepository extends BaseRepository<RailwayItem> {
  static RailwayRepository? _instance;

  RailwayRepository._() : super('data_sources/final/railway.min.json');

  static RailwayRepository get instance {
    _instance ??= RailwayRepository._();
    return _instance!;
  }

  @override
  RailwayItem parseItem(Map<String, dynamic> json) {
    final lat = (json['lat'] as num).toDouble();
    final lng = (json['lng'] as num).toDouble();
    final type = json['type'] as String? ?? 'railway_crossing';
    final isCrossing = json['is_crossing'] as bool? ?? false;
    final id = '${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}';
    return RailwayItem(id: id, lat: lat, lng: lng, type: type, isCrossing: isCrossing);
  }

  @override
  String getId(RailwayItem item) => item.id;

  @override
  (double lat, double lng) getLocation(RailwayItem item) => (item.lat, item.lng);
}

