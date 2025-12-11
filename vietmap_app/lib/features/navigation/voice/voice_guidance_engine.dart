import 'dart:async';
import 'dart:collection';
import '../../../core/logger.dart';
import '../../../core/platform/android_service_bridge.dart';
import '../models/route_step.dart';
import 'navigation_tts_messages.dart';

/// Voice guidance engine for navigation
class VoiceGuidanceEngine {
  static VoiceGuidanceEngine? _instance;
  final AndroidServiceBridge _androidBridge = AndroidServiceBridge.instance;
  final NavigationTtsMessages _ttsMessages = NavigationTtsMessages();
  
  final Queue<String> _ttsQueue = Queue<String>();
  bool _isSpeaking = false;
  Timer? _announcementTimer;
  
  // Announcement distances (meters)
  static const double announce500m = 500;
  static const double announce200m = 200;
  static const double announce50m = 50;
  static const double announceOnManeuver = 0;

  VoiceGuidanceEngine._();

  static VoiceGuidanceEngine get instance {
    _instance ??= VoiceGuidanceEngine._();
    return _instance!;
  }

  /// Update current step and position
  void updateStep(RouteStep? currentStep, RouteStep? nextStep, double distanceToManeuver, double speedKmh) {
    if (currentStep == null) return;

    // Determine announcement timing based on speed
    final announceDistance = speedKmh >= 60 ? announce500m : announce200m;

    // Queue announcements based on distance
    if (distanceToManeuver <= announceOnManeuver && !_hasAnnounced('on_maneuver')) {
      _queueAnnouncement(_ttsMessages.getOnManeuverMessage(currentStep));
      _markAnnounced('on_maneuver');
    } else if (distanceToManeuver <= announce50m && !_hasAnnounced('50m')) {
      _queueAnnouncement(_ttsMessages.get50mMessage(currentStep));
      _markAnnounced('50m');
    } else if (distanceToManeuver <= announce200m && !_hasAnnounced('200m')) {
      _queueAnnouncement(_ttsMessages.get200mMessage(currentStep));
      _markAnnounced('200m');
    } else if (distanceToManeuver <= announceDistance && !_hasAnnounced('500m')) {
      _queueAnnouncement(_ttsMessages.get500mMessage(currentStep));
      _markAnnounced('500m');
    }

    _processQueue();
  }

  final Set<String> _announced = {};

  bool _hasAnnounced(String key) {
    return _announced.contains(key);
  }

  void _markAnnounced(String key) {
    _announced.add(key);
    // Clear after step changes
    Timer(const Duration(seconds: 2), () {
      _announced.remove(key);
    });
  }

  void _queueAnnouncement(String message) {
    if (message.isEmpty) return;
    _ttsQueue.add(message);
    appLog('VoiceGuidanceEngine: Queued: $message');
  }

  Future<void> _processQueue() async {
    if (_isSpeaking || _ttsQueue.isEmpty) return;

    _isSpeaking = true;
    final message = _ttsQueue.removeFirst();
    
    try {
      await _androidBridge.requestTTS(message);
      appLog('VoiceGuidanceEngine: Spoke: $message');
      
      // Wait before next announcement
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      appLog('VoiceGuidanceEngine: TTS error: $e');
    } finally {
      _isSpeaking = false;
      
      // Process next in queue
      if (_ttsQueue.isNotEmpty) {
        _processQueue();
      }
    }
  }

  void clear() {
    _ttsQueue.clear();
    _announced.clear();
    _announcementTimer?.cancel();
    appLog('VoiceGuidanceEngine: Cleared');
  }
}

