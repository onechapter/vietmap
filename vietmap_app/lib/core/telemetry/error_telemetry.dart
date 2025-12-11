import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../logger.dart';

/// Error telemetry system
class ErrorTelemetry {
  static ErrorTelemetry? _instance;
  static const String telemetryDir = 'telemetry';
  static const int maxLogSize = 800; // bytes

  ErrorTelemetry._();

  static ErrorTelemetry get instance {
    _instance ??= ErrorTelemetry._();
    return _instance!;
  }

  /// Initialize error telemetry
  void initialize() {
    // Catch Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _logFlutterError(details);
      FlutterError.presentError(details);
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logAsyncError(error, stack);
      return true;
    };

    appLog('ErrorTelemetry: Initialized');
  }

  /// Log Flutter error
  Future<void> _logFlutterError(FlutterErrorDetails details) async {
    try {
      final errorData = {
        'type': 'flutter_error',
        'timestamp': DateTime.now().toIso8601String(),
        'exception': details.exception.toString(),
        'library': details.library ?? 'unknown',
        'context': details.context?.toString(),
        'stack': details.stack?.toString(),
        'information': details.informationCollector?.call().map((e) => e.toString()).toList(),
      };

      await _writeLog(errorData);
    } catch (e) {
      appLog('ErrorTelemetry: Failed to log Flutter error: $e');
    }
  }

  /// Log async error
  Future<void> _logAsyncError(Object error, StackTrace stack) async {
    try {
      final errorData = {
        'type': 'async_error',
        'timestamp': DateTime.now().toIso8601String(),
        'error': error.toString(),
        'stack': stack.toString(),
      };

      await _writeLog(errorData);
    } catch (e) {
      appLog('ErrorTelemetry: Failed to log async error: $e');
    }
  }

  /// Log navigation error
  Future<void> logNavigationError({
    required String errorType,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    try {
      final errorData = {
        'type': 'navigation_error',
        'error_type': errorType, // 'route_api_failure', 'reroute_loop', 'tts_failure'
        'timestamp': DateTime.now().toIso8601String(),
        'message': message,
        if (context != null) 'context': context,
      };

      await _writeLog(errorData);
    } catch (e) {
      appLog('ErrorTelemetry: Failed to log navigation error: $e');
    }
  }

  /// Log warning engine diagnostics
  Future<void> logWarningEngineDiagnostics({
    required String event,
    Map<String, dynamic>? data,
  }) async {
    try {
      final errorData = {
        'type': 'warning_engine_diagnostics',
        'timestamp': DateTime.now().toIso8601String(),
        'event': event,
        if (data != null) 'data': data,
      };

      await _writeLog(errorData);
    } catch (e) {
      appLog('ErrorTelemetry: Failed to log warning engine diagnostics: $e');
    }
  }

  /// Log native crash
  Future<void> logNativeCrash({
    required String crashType,
    required String message,
    String? stackTrace,
  }) async {
    try {
      final errorData = {
        'type': 'native_crash',
        'crash_type': crashType,
        'timestamp': DateTime.now().toIso8601String(),
        'message': message,
        if (stackTrace != null) 'stack_trace': stackTrace,
      };

      await _writeLog(errorData);
    } catch (e) {
      appLog('ErrorTelemetry: Failed to log native crash: $e');
    }
  }

  /// Write log to file
  Future<void> _writeLog(Map<String, dynamic> data) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDir.path, 'logs', telemetryDir));
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }

      var json = jsonEncode(data);
      if (json.length > maxLogSize) {
        // Truncate if too large
        json = json.substring(0, maxLogSize);
        appLog('ErrorTelemetry: Log truncated from ${jsonEncode(data).length} to $maxLogSize bytes');
      }

      final fileName = 'error_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(path.join(logDir.path, fileName));
      await file.writeAsString(json.length > maxLogSize ? json.substring(0, maxLogSize) : json);

      appLog('ErrorTelemetry: Logged to $fileName');
    } catch (e) {
      appLog('ErrorTelemetry: Failed to write log: $e');
    }
  }

  /// Get all telemetry logs
  Future<List<File>> getLogFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDir.path, 'logs', telemetryDir));
      if (!logDir.existsSync()) {
        return [];
      }

      return logDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // Newest first
    } catch (e) {
      appLog('ErrorTelemetry: Failed to get log files: $e');
      return [];
    }
  }
}

