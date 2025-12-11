import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/logger.dart';

/// Live overlay controller for displaying real-time metrics
class LiveOverlayController {
  static LiveOverlayController? _instance;
  OverlayEntry? _overlayEntry;
  bool _isEnabled = false;
  Timer? _updateTimer;
  final ValueNotifier<Map<String, String>> _metrics = ValueNotifier({});

  LiveOverlayController._();

  static LiveOverlayController get instance {
    _instance ??= LiveOverlayController._();
    return _instance!;
  }

  /// Enable live overlay
  void enable(BuildContext context) {
    if (_isEnabled) return;

    _isEnabled = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);

    // Update metrics every 250ms
    _updateTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _updateMetrics();
    });

    appLog('LiveOverlayController: Enabled');
  }

  /// Disable live overlay
  void disable() {
    if (!_isEnabled) return;

    _isEnabled = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _updateTimer?.cancel();
    _updateTimer = null;

    appLog('LiveOverlayController: Disabled');
  }

  bool get isEnabled => _isEnabled;

  DateTime? _lastFrameTime;
  int _frameCount = 0;
  double _fps = 0;

  /// Update metrics
  void _updateMetrics() {
    final metrics = <String, String>{};

    // FPS calculation
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      _frameCount++;
      final elapsed = now.difference(_lastFrameTime!).inMilliseconds;
      if (elapsed >= 1000) {
        _fps = (_frameCount * 1000) / elapsed;
        _frameCount = 0;
        _lastFrameTime = now;
      }
    } else {
      _lastFrameTime = now;
    }
    metrics['FPS'] = _fps.toStringAsFixed(1);

    // Dart VM metrics
    final vm = _getVmMetrics();
    metrics.addAll(vm);

    _metrics.value = metrics;
  }

  Map<String, String> _getVmMetrics() {
    final metrics = <String, String>{};

    // Memory usage (approximate)
    // Note: Actual memory metrics require VM service connection
    metrics['Memory'] = 'N/A';

    return metrics;
  }

  /// Create overlay entry
  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        right: 12,
        child: Material(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ValueListenableBuilder<Map<String, String>>(
              valueListenable: _metrics,
              builder: (context, metrics, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Live Metrics',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...metrics.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void dispose() {
    disable();
  }
}
