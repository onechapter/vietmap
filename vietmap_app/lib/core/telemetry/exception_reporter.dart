import 'dart:async';
import 'package:flutter/material.dart';
import 'error_telemetry.dart';
import '../logger.dart';

/// Exception reporter for handling crashes gracefully
class ExceptionReporter {
  static ExceptionReporter? _instance;
  final ErrorTelemetry _telemetry = ErrorTelemetry.instance;
  bool _isHandlingError = false;

  ExceptionReporter._();

  static ExceptionReporter get instance {
    _instance ??= ExceptionReporter._();
    return _instance!;
  }

  /// Setup error widget builder
  void setupErrorWidget() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _handleError(details);
      return Material(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Đã xảy ra lỗi'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Restart navigation screen
                  // This would need to be handled by app-level navigation
                },
                child: const Text('Khởi động lại'),
              ),
            ],
          ),
        ),
      );
    };
  }

  /// Handle error and attempt recovery
  Future<void> _handleError(FlutterErrorDetails details) async {
    if (_isHandlingError) return;
    _isHandlingError = true;

    try {
      appLog('ExceptionReporter: Handling error: ${details.exception}');
      
      // Log to telemetry (using public method via error_telemetry)
      // Note: ErrorTelemetry already handles Flutter errors via FlutterError.onError

      // Attempt recovery based on error type
      if (details.exception.toString().contains('Navigation')) {
        // Navigation error - could restart navigation screen
        appLog('ExceptionReporter: Navigation error detected, attempting recovery');
      }
    } catch (e) {
      appLog('ExceptionReporter: Error in error handler: $e');
    } finally {
      _isHandlingError = false;
    }
  }

  /// Report navigation failure
  Future<void> reportNavigationFailure({
    required String failureType,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    await _telemetry.logNavigationError(
      errorType: failureType,
      message: message,
      context: context,
    );
  }
}

