import 'base_repository.dart';

class SpeedLimitItem {
  final String id;
  final double lat;
  final double lng;
  final int speedLimit;

  SpeedLimitItem({
    required this.id,
    required this.lat,
    required this.lng,
    required this.speedLimit,
  });
}

class SpeedLimitRepository extends BaseRepository<SpeedLimitItem> {
  static SpeedLimitRepository? _instance;

  SpeedLimitRepository._() : super('data_sources/final/speed_limit.min.json');

  static SpeedLimitRepository get instance {
    _instance ??= SpeedLimitRepository._();
    return _instance!;
  }

  @override
  SpeedLimitItem parseItem(Map<String, dynamic> json) {
    final lat = (json['lat'] as num).toDouble();
    final lng = (json['lng'] as num).toDouble();
    final speedLimit = (json['speedLimit'] as num?)?.toInt() ?? 
                       (json['speed_limit'] as num?)?.toInt() ?? 0;
    final id = '${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}';
    return SpeedLimitItem(id: id, lat: lat, lng: lng, speedLimit: speedLimit);
  }

  @override
  String getId(SpeedLimitItem item) => item.id;

  @override
  (double lat, double lng) getLocation(SpeedLimitItem item) => (item.lat, item.lng);
}

