import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'warning_engine.dart';

/// Provider cho WarningEngine singleton
final warningEngineProvider = Provider<WarningEngine>((ref) {
  return WarningEngine();
});

