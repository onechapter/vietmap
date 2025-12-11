import 'dart:async';
import 'warning_model.dart';
import '../../core/logger.dart';

/// Singleton manager for warning stream
class WarningManager {
  static WarningManager? _instance;
  final StreamController<Warning> _controller = StreamController<Warning>.broadcast();

  WarningManager._();

  static WarningManager get instance {
    _instance ??= WarningManager._();
    return _instance!;
  }

  /// Stream of warnings
  Stream<Warning> get stream => _controller.stream;

  /// Emit a warning
  void emit(Warning warning) {
    appLog('WarningManager: Emitting ${warning.type} warning: ${warning.id}');
    _controller.add(warning);
  }

  void dispose() {
    _controller.close();
  }
}

