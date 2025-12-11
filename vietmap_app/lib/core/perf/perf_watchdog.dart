import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import '../logger.dart';
import 'memory_sanitizer.dart';
import 'spike_detector.dart';

/// Performance watchdog monitoring CPU, memory, and frame timing
class PerfWatchdog {
  static PerfWatchdog? _instance;
  Timer? _monitoringTimer;
  final MemorySanitizer _memorySanitizer = MemorySanitizer.instance;
  final SpikeDetector _spikeDetector = SpikeDetector.instance;
  bool _isMonitoring = false;
  static const Duration monitoringInterval = Duration(seconds: 10);

  PerfWatchdog._();

  static PerfWatchdog get instance {
    _instance ??= PerfWatchdog._();
    return _instance!;
  }

  /// Start monitoring
  void start() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(monitoringInterval, (_) => _collectMetrics());
    appLog('PerfWatchdog: Started monitoring');
  }

  /// Stop monitoring
  void stop() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    appLog('PerfWatchdog: Stopped monitoring');
  }

  /// Collect performance metrics
  Future<void> _collectMetrics() async {
    try {
      final metrics = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'cpu_usage': await _getCpuUsage(),
        'memory_usage': await _getMemoryUsage(),
        'frame_timing': _getFrameTiming(),
      };

      // Check for spikes
      final cpuUsage = metrics['cpu_usage'] as double? ?? 0.0;
      _spikeDetector.checkSpike(cpuUsage);

      // Memory sanitization
      await _memorySanitizer.checkMemory();

      // Dump to log if enabled
      await _dumpMetrics(metrics);
    } catch (e) {
      appLog('PerfWatchdog: Error collecting metrics: $e');
    }
  }

  /// Get CPU usage (simplified - actual implementation would use platform channels)
  Future<double> _getCpuUsage() async {
    // Placeholder - would need native implementation
    return 0.0;
  }

  /// Get memory usage
  Future<double> _getMemoryUsage() async {
    try {
      // Use ProcessInfo for basic memory info
      // Note: This is simplified - actual memory tracking would need platform channels
      return 0.0;
    } catch (e) {
      appLog('PerfWatchdog: Error getting memory usage: $e');
      return 0.0;
    }
  }

  /// Get frame timing
  Map<String, dynamic> _getFrameTiming() {
    try {
      // Frame timing from SchedulerBinding
      // This is simplified - actual frame timing would need more detailed tracking
      return {
        'fps': 'N/A', // Would calculate from frame times
        'frame_time_ms': 'N/A',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Dump metrics to log file
  Future<void> _dumpMetrics(Map<String, dynamic> metrics) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final perfDir = Directory(path.join(appDir.path, 'logs', 'perf'));
      if (!perfDir.existsSync()) {
        perfDir.createSync(recursive: true);
      }

      final now = DateTime.now();
      final fileName = 'perf_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';

      final file = File(path.join(perfDir.path, fileName));
      final existing = file.existsSync() ? jsonDecode(await file.readAsString()) as Map<String, dynamic> : <String, dynamic>{};
      final entries = (existing['entries'] as List?) ?? <dynamic>[];
      entries.add(metrics);
      existing['entries'] = entries;

      await file.writeAsString(jsonEncode(existing));
    } catch (e) {
      appLog('PerfWatchdog: Error dumping metrics: $e');
    }
  }

  bool get isMonitoring => _isMonitoring;
}

