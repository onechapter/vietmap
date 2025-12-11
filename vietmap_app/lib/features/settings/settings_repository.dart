import 'package:shared_preferences/shared_preferences.dart';
import '../../core/logger.dart';

class SettingsRepository {
  static SettingsRepository? _instance;
  SharedPreferences? _prefs;

  SettingsRepository._();

  static SettingsRepository get instance {
    _instance ??= SettingsRepository._();
    return _instance!;
  }

  Future<void> init() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      appLog('SettingsRepository: Initialized');
    } catch (e) {
      appLog('SettingsRepository: Init failed: $e');
    }
  }

  // Warning enabled per type
  Future<bool> isWarningEnabled(String type) async {
    await init();
    return _prefs?.getBool('warning_$type') ?? true;
  }

  Future<void> setWarningEnabled(String type, bool enabled) async {
    await init();
    await _prefs?.setBool('warning_$type', enabled);
    appLog('SettingsRepository: Set warning_$type = $enabled');
  }

  // Radius overrides
  Future<double> getRadius(String type) async {
    await init();
    final key = 'radius_$type';
    if (_prefs?.containsKey(key) ?? false) {
      return _prefs!.getDouble(key) ?? _getDefaultRadius(type);
    }
    return _getDefaultRadius(type);
  }

  Future<void> setRadius(String type, double radius) async {
    await init();
    await _prefs?.setDouble('radius_$type', radius);
    appLog('SettingsRepository: Set radius_$type = $radius');
  }

  double _getDefaultRadius(String type) {
    switch (type) {
      case 'camera':
        return 150.0;
      case 'railway':
        return 300.0;
      case 'danger':
        return 50.0;
      case 'speed':
        return 100.0;
      default:
        return 100.0;
    }
  }

  // TTS enabled
  Future<bool> isTtsEnabled() async {
    await init();
    return _prefs?.getBool('tts_enabled') ?? true;
  }

  Future<void> setTtsEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool('tts_enabled', enabled);
  }

  // Auto start warning engine
  Future<bool> isAutoStartEnabled() async {
    await init();
    return _prefs?.getBool('auto_start_warning_engine') ?? true;
  }

  Future<void> setAutoStartEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool('auto_start_warning_engine', enabled);
  }

  // Voice type
  Future<String> getVoiceType() async {
    await init();
    return _prefs?.getString('voice_type') ?? 'system';
  }

  Future<void> setVoiceType(String type) async {
    await init();
    await _prefs?.setString('voice_type', type);
  }
}

