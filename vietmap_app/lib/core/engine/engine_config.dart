/// Configuration for WarningEngine performance
class EngineConfig {
  /// Adaptive frequency based on speed
  /// Returns interval in seconds
  static double intervalForSpeed(double speedKmh) {
    if (speedKmh < 5) return 1.5; // Slow/stopped
    if (speedKmh < 40) return 0.8; // Normal speed
    return 0.35; // High speed (60-80 km/h)
  }

  /// Minimum interval between location updates (ms)
  static const int minLocationIntervalMs = 250;

  /// Grid cache refresh interval (minutes)
  static const int gridCacheRefreshMinutes = 15;

  /// Grid cache region change threshold (meters)
  static const double gridCacheRegionThresholdM = 2000;

  /// Maximum pool size for object pooling
  static const int maxPoolSize = 50;

  /// Enable adaptive frequency
  static const bool enableAdaptiveFrequency = true;

  /// Enable object pooling
  static const bool enableObjectPooling = true;

  /// Enable grid caching
  static const bool enableGridCache = true;
}

