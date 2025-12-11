import '../logger.dart';

/// Detector for CPU spikes
class SpikeDetector {
  static SpikeDetector? _instance;
  final List<double> _cpuReadings = [];
  static const double spikeThreshold = 70.0; // 70% CPU
  static const int spikeDurationSeconds = 3;
  static const int maxReadings = 30; // Keep last 30 readings (10s * 3 = 30s at 10s interval)

  SpikeDetector._();

  static SpikeDetector get instance {
    _instance ??= SpikeDetector._();
    return _instance!;
  }

  /// Check for CPU spike
  void checkSpike(double cpuUsage) {
    _cpuReadings.add(cpuUsage);
    if (_cpuReadings.length > maxReadings) {
      _cpuReadings.removeAt(0);
    }

    // Check if last N readings are all above threshold
    if (_cpuReadings.length >= spikeDurationSeconds) {
      final recentReadings = _cpuReadings.sublist(_cpuReadings.length - spikeDurationSeconds);
      final allAboveThreshold = recentReadings.every((r) => r > spikeThreshold);

      if (allAboveThreshold) {
        _reportSpike(recentReadings);
        // Clear readings after reporting
        _cpuReadings.clear();
      }
    }
  }

  /// Report CPU spike
  void _reportSpike(List<double> readings) {
    final avgCpu = readings.reduce((a, b) => a + b) / readings.length;
    appLog('SpikeDetector: CPU spike detected - ${avgCpu.toStringAsFixed(1)}% for ${spikeDurationSeconds}s');
    
    // Could trigger performance dump or alert here
  }

  /// Get current CPU average
  double getCurrentAverage() {
    if (_cpuReadings.isEmpty) return 0.0;
    return _cpuReadings.reduce((a, b) => a + b) / _cpuReadings.length;
  }
}

