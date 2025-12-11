import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../core/logger.dart';

/// Clean old log files
class LogCleaner {
  static const int retentionDays = 7;

  /// Clean logs older than retentionDays
  static Future<void> cleanOldLogs() async {
    try {
      appLog('LogCleaner: Starting cleanup...');

      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDir.path, 'logs'));

      if (!logDir.existsSync()) {
        appLog('LogCleaner: Log directory does not exist');
        return;
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      int deletedCount = 0;
      int totalSize = 0;

      final files = logDir.listSync();
      for (final entity in files) {
        if (entity is File) {
          final stat = entity.statSync();
          final modified = stat.modified;

          if (modified.isBefore(cutoffDate)) {
            final size = stat.size;
            totalSize += size;
            entity.deleteSync();
            deletedCount++;
            appLog('LogCleaner: Deleted ${entity.path} (${(size / 1024).toStringAsFixed(2)} KB)');
          }
        }
      }

      appLog('LogCleaner: Cleanup complete - deleted $deletedCount files (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB)');
    } catch (e) {
      appLog('LogCleaner: Error during cleanup: $e');
    }
  }

  /// Get log directory size
  static Future<int> getLogDirectorySize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDir.path, 'logs'));

      if (!logDir.existsSync()) {
        return 0;
      }

      int totalSize = 0;
      final files = logDir.listSync(recursive: true);
      for (final entity in files) {
        if (entity is File) {
          totalSize += entity.lengthSync();
        }
      }

      return totalSize;
    } catch (e) {
      appLog('LogCleaner: Error getting directory size: $e');
      return 0;
    }
  }
}
