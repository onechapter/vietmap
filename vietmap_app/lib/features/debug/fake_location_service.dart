import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../core/logger.dart';
import '../../core/location/location_controller.dart';

/// Fake location service cho debug/simulator
class FakeLocationService {
  FakeLocationService._();
  static final FakeLocationService instance = FakeLocationService._();

  final StreamController<Position?> _controller = StreamController.broadcast();
  bool enabled = false;
  Position? _current;
  Timer? _timer;

  Stream<Position?> get stream => _controller.stream;
  Position? get current => _current;

  /// Bật giả lập tại vị trí mặc định (Có thể mở rộng nhận tham số)
  void enableFake({double lat = 11.488688, double lng = 106.614503}) {
    enabled = true;
    // Enable simulation mode (disables real GPS)
    LocationController.instance.enableSimulationMode();
    _emit(lat, lng);
    // Lặp lại mỗi 1s để giữ dòng vị trí ổn định
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _emit(lat, lng));
    appLog('FakeLocationService: Enabled at $lat, $lng');
  }

  void disableFake() {
    enabled = false;
    _timer?.cancel();
    _timer = null;
    _current = null;
    _controller.add(null);
    // Disable simulation mode (re-enable real GPS)
    LocationController.instance.disableSimulationMode();
    appLog('FakeLocationService: Disabled, real GPS re-enabled');
  }

  void _emit(double lat, double lng) {
    final position = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _current = position;
    _controller.add(position);
    
    // Emit vào unified LocationController
    LocationController.instance.updateLocation(
      latitude: lat,
      longitude: lng,
      speed: 0.0,
    );
  }

  /// API cũ: mô phỏng một vị trí tùy ý (sử dụng ngay lập tức, không bật flag)
  Future<void> startSimulating(double lat, double lng) async {
    enableFake(lat: lat, lng: lng);
  }

  void stopSimulating() {
    disableFake();
  }
}

