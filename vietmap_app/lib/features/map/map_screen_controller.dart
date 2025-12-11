import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../features/warning/warning_engine.dart';
import '../../features/warning/warning_manager.dart';
import '../../features/warning/warning_model.dart';
import '../../data/repositories/danger_zone_repository.dart';
import '../../data/repositories/railway_repository.dart';
import '../../data/repositories/camera_repository.dart';
import '../../data/repositories/speed_limit_repository.dart';
import '../../features/map/map_service.dart';
import '../../core/platform/android_service_bridge.dart';
import '../../core/logger.dart';

/// Controller for MapScreen to manage warning engine and state
class MapScreenController {
  final WarningEngine _warningEngine = WarningEngine();
  final WarningManager _warningManager = WarningManager.instance;
  final MapService _mapService = MapService.instance;
  final AndroidServiceBridge _androidBridge = AndroidServiceBridge.instance;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<Warning>? _warningSub;

  // State
  Warning? _currentWarning;
  bool _hasMbtiles = false;
  bool _isEngineRunning = false;
  Position? _lastPosition;

  // Getters
  Warning? get currentWarning => _currentWarning;
  bool get hasMbtiles => _hasMbtiles;
  bool get isEngineRunning => _isEngineRunning;
  Position? get lastPosition => _lastPosition;

  // Streams
  final StreamController<Warning?> _warningController = StreamController<Warning?>.broadcast();
  Stream<Warning?> get warningStream => _warningController.stream;

  /// Initialize controller
  Future<void> init() async {
    try {
      appLog('MapScreenController: Initializing...');

      // Initialize map service
      await _mapService.init();
      _hasMbtiles = _mapService.hasMbtiles();

      // Initialize Android bridge
      await _androidBridge.initialize();
      _androidBridge.setWarningEngine(_warningEngine);

      // Load repositories
      await _loadRepositories();

      // Listen to warnings
      _warningSub = _warningManager.stream.listen(
        (warning) {
          _currentWarning = warning;
          _warningController.add(warning);
          _handleWarning(warning);
        },
      );

      appLog('MapScreenController: Initialized');
    } catch (e) {
      appLog('MapScreenController: Init failed: $e');
    }
  }

  Future<void> _loadRepositories() async {
    await DangerZoneRepository.instance.load();
    await RailwayRepository.instance.load();
    await CameraRepository.instance.load();
    await SpeedLimitRepository.instance.load();
  }

  /// Start warning engine with GPS stream
  Future<void> startWarningEngine() async {
    if (_isEngineRunning) return;

    try {
      appLog('MapScreenController: Starting warning engine...');

      // Get location stream
      final locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      final positionStream = Geolocator.getPositionStream(locationSettings: locationSettings);

      // Start engine
      await _warningEngine.start(positionStream);

      // Track positions
      _positionSub = positionStream.listen(
        (position) {
          _lastPosition = position;
        },
        onError: (e) {
          appLog('MapScreenController: Position stream error: $e');
        },
      );

      _isEngineRunning = true;
      appLog('MapScreenController: Warning engine started');
    } catch (e) {
      appLog('MapScreenController: Start engine failed: $e');
    }
  }

  /// Stop warning engine
  void stopWarningEngine() {
    if (!_isEngineRunning) return;

    _warningEngine.stop();
    _positionSub?.cancel();
    _positionSub = null;
    _isEngineRunning = false;
    appLog('MapScreenController: Warning engine stopped');
  }

  /// Handle warning - trigger TTS and vibration
  Future<void> _handleWarning(Warning warning) async {
    try {
      final text = _getWarningText(warning);
      
      // Request TTS via Android bridge (for background) or direct TTS
      await _androidBridge.requestTTS(text);
      
      appLog('MapScreenController: Warning handled: ${warning.type}');
    } catch (e) {
      appLog('MapScreenController: Handle warning failed: $e');
    }
  }

  String _getWarningText(Warning warning) {
    switch (warning.type) {
      case 'camera':
        return 'Sắp đến camera phạt nguội phía trước';
      case 'railway':
        return 'Cảnh báo đường sắt phía trước';
      case 'danger':
        return 'Khu vực nguy hiểm phía trước';
      case 'speed':
        return 'Vượt quá tốc độ cho phép';
      default:
        return 'Cảnh báo';
    }
  }

  /// Dismiss current warning
  void dismissWarning() {
    _currentWarning = null;
    _warningController.add(null);
  }

  /// Dispose controller
  void dispose() {
    stopWarningEngine();
    _warningSub?.cancel();
    _warningSub = null;
    _warningController.close();
    _androidBridge.dispose();
    appLog('MapScreenController: Disposed');
  }
}

