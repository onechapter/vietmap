import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../core/logger.dart';

/// Field logger for structured logging with throttling and rotation
class FieldLogger {
  static FieldLogger? _instance;
  File? _logFile;
  final List<String> _buffer = [];
  Timer? _flushTimer;
  DateTime? _lastWrite;
  static const Duration _throttleInterval = Duration(milliseconds: 500);
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int _maxFiles = 5;

  FieldLogger._();

  static FieldLogger get instance {
    _instance ??= FieldLogger._();
    return _instance!;
  }

  /// Initialize logger
  Future<void> init() async {
    try {
      final logDir = await _getLogDirectory();
      _logFile = File(path.join(logDir.path, 'field_${_getDateString()}.log'));
      await _logFile!.create(recursive: true);

      // Start flush timer
      _flushTimer = Timer.periodic(_throttleInterval, (_) => _flush());

      // Clean old logs
      await _cleanOldLogs();

      appLog('FieldLogger: Initialized at ${_logFile!.path}');
    } catch (e) {
      appLog('FieldLogger: Init failed: $e');
    }
  }

  /// Log structured data
  void log(String level, String category, Map<String, dynamic> fields) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = {
      'timestamp': timestamp,
      'level': level,
      'category': category,
      ...fields,
    };

    _buffer.add(_formatLogEntry(entry));

    // Auto-flush if buffer is large
    if (_buffer.length > 100) {
      _flush();
    }
  }

  String _formatLogEntry(Map<String, dynamic> entry) {
    final buffer = StringBuffer();
    entry.forEach((key, value) {
      if (buffer.isNotEmpty) buffer.write(' | ');
      buffer.write('$key=$value');
    });
    return buffer.toString();
  }

  /// Flush buffer to file
  Future<void> _flush() async {
    if (_buffer.isEmpty || _logFile == null) return;

    final now = DateTime.now();
    if (_lastWrite != null && now.difference(_lastWrite!) < _throttleInterval) {
      return; // Throttle
    }

    try {
      // Check file size and rotate if needed
      if (await _logFile!.length() > _maxFileSize) {
        await _rotateLog();
      }

      final content = _buffer.join('\n') + '\n';
      await _logFile!.writeAsString(content, mode: FileMode.append);
      _buffer.clear();
      _lastWrite = now;
    } catch (e) {
      appLog('FieldLogger: Flush failed: $e');
    }
  }

  /// Rotate log file
  Future<void> _rotateLog() async {
    if (_logFile == null) return;

    try {
      final logDir = _logFile!.parent;
      final newName = 'field_${_getDateString()}_${DateTime.now().millisecondsSinceEpoch}.log';
      final newFile = File(path.join(logDir.path, newName));
      await _logFile!.copy(newFile.path);
      await _logFile!.writeAsString(''); // Clear current file

      appLog('FieldLogger: Rotated to $newName');
    } catch (e) {
      appLog('FieldLogger: Rotate failed: $e');
    }
  }

  /// Clean logs older than 7 days
  Future<void> _cleanOldLogs() async {
    try {
      final logDir = await _getLogDirectory();
      final files = logDir.listSync()
          .whereType<File>()
          .where((f) => f.path.contains('field_'))
          .toList();

      final cutoff = DateTime.now().subtract(const Duration(days: 7));

      for (final file in files) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoff)) {
          await file.delete();
          appLog('FieldLogger: Deleted old log ${file.path}');
        }
      }

      // Keep only latest N files
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      if (files.length > _maxFiles) {
        for (final file in files.skip(_maxFiles)) {
          await file.delete();
          appLog('FieldLogger: Deleted excess log ${file.path}');
        }
      }
    } catch (e) {
      appLog('FieldLogger: Clean failed: $e');
    }
  }

  Future<Directory> _getLogDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final logDir = Directory(path.join(appDir.path, 'logs'));
    await logDir.create(recursive: true);
    return logDir;
  }

  String _getDateString() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  /// Get all log files
  Future<List<File>> getLogFiles() async {
    try {
      final logDir = await _getLogDirectory();
      return logDir.listSync()
          .whereType<File>()
          .where((f) => f.path.contains('field_'))
          .toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    } catch (e) {
      appLog('FieldLogger: Get log files failed: $e');
      return [];
    }
  }

  /// Force flush
  Future<void> flush() => _flush();

  void dispose() {
    _flushTimer?.cancel();
    _flush();
  }
}

