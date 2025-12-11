import 'package:flutter/services.dart';
import 'error_telemetry.dart';
import '../logger.dart';

/// Channel for receiving native crash reports
class NativeErrorChannel {
  static NativeErrorChannel? _instance;
  static const MethodChannel _channel = MethodChannel('com.vietmap.app/crash');
  final ErrorTelemetry _telemetry = ErrorTelemetry.instance;
  bool _isListening = false;

  NativeErrorChannel._();

  static NativeErrorChannel get instance {
    _instance ??= NativeErrorChannel._();
    return _instance!;
  }

  /// Start listening for native crashes
  void startListening() {
    if (_isListening) return;

    _channel.setMethodCallHandler(_handleNativeError);
    _isListening = true;
    appLog('NativeErrorChannel: Started listening');
  }

  /// Stop listening
  void stopListening() {
    _isListening = false;
    _channel.setMethodCallHandler(null);
    appLog('NativeErrorChannel: Stopped listening');
  }

  /// Handle native error
  Future<dynamic> _handleNativeError(MethodCall call) async {
    try {
      if (call.method == 'nativeCrash') {
        final crashType = call.arguments['crash_type'] as String? ?? 'unknown';
        final message = call.arguments['message'] as String? ?? 'No message';
        final stackTrace = call.arguments['stack_trace'] as String?;

        appLog('NativeErrorChannel: Received crash - $crashType: $message');

        await _telemetry.logNativeCrash(
          crashType: crashType,
          message: message,
          stackTrace: stackTrace,
        );
      }
    } catch (e) {
      appLog('NativeErrorChannel: Error handling native error: $e');
    }
  }
}

