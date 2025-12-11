import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/logger.dart';

/// Detector for offline/online status
class OfflineDetector {
  static OfflineDetector? _instance;
  final Connectivity _connectivity = Connectivity();
  bool _isOffline = false;
  StreamController<bool>? _statusController;

  OfflineDetector._();

  static OfflineDetector get instance {
    _instance ??= OfflineDetector._();
    return _instance!;
  }

  /// Initialize offline detection
  Future<void> initialize() async {
    _statusController = StreamController<bool>.broadcast();

    // Check initial status
    await _checkConnectivity();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _isOffline = result == ConnectivityResult.none;
      _statusController?.add(_isOffline);
      appLog('OfflineDetector: Status changed - offline: $_isOffline');
    });

    appLog('OfflineDetector: Initialized');
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOffline = result == ConnectivityResult.none;
      _statusController?.add(_isOffline);
    } catch (e) {
      appLog('OfflineDetector: Error checking connectivity: $e');
      _isOffline = true; // Assume offline on error
    }
  }

  /// Get current offline status
  bool get isOffline => _isOffline;

  /// Stream of offline status changes
  Stream<bool> get statusStream => _statusController?.stream ?? const Stream.empty();

  void dispose() {
    _statusController?.close();
    _statusController = null;
  }
}

