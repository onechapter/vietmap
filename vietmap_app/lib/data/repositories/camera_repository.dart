import 'base_repository.dart';
import '../cameras/camera_model.dart';

class CameraRepository extends BaseRepository<CameraModel> {
  static CameraRepository? _instance;

  CameraRepository._() : super('data_sources/final/cameras.min.json');

  static CameraRepository get instance {
    _instance ??= CameraRepository._();
    return _instance!;
  }

  @override
  CameraModel parseItem(Map<String, dynamic> json) {
    return CameraModel.fromJson(json);
  }

  @override
  String getId(CameraModel item) => item.id;

  @override
  (double lat, double lng) getLocation(CameraModel item) => (item.lat, item.lng);
}

