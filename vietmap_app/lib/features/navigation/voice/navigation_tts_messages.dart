import '../models/route_step.dart';

/// TTS messages for navigation
class NavigationTtsMessages {
  /// Get message for 500m before maneuver
  String get500mMessage(RouteStep step) {
    return _getMessage(step, distance: 500);
  }

  /// Get message for 200m before maneuver
  String get200mMessage(RouteStep step) {
    return _getMessage(step, distance: 200);
  }

  /// Get message for 50m before maneuver
  String get50mMessage(RouteStep step) {
    return _getMessage(step, distance: 50);
  }

  /// Get message for on-maneuver
  String getOnManeuverMessage(RouteStep step) {
    return step.instruction.isNotEmpty ? step.instruction : _getDefaultMessage(step);
  }

  String _getMessage(RouteStep step, {required int distance}) {
    final distanceText = distance >= 1000 
        ? '${(distance / 1000).toStringAsFixed(1)} cây số'
        : '$distance mét';
    
    return 'Sau $distanceText, ${step.instruction.isNotEmpty ? step.instruction : _getDefaultMessage(step)}';
  }

  String _getDefaultMessage(RouteStep step) {
    switch (step.maneuver) {
      case ManeuverType.turnLeft:
        return 'rẽ trái';
      case ManeuverType.turnRight:
        return 'rẽ phải';
      case ManeuverType.turnSharpLeft:
        return 'rẽ trái gấp';
      case ManeuverType.turnSharpRight:
        return 'rẽ phải gấp';
      case ManeuverType.turnSlightLeft:
        return 'rẽ trái nhẹ';
      case ManeuverType.turnSlightRight:
        return 'rẽ phải nhẹ';
      case ManeuverType.straight:
        return 'đi thẳng';
      case ManeuverType.uturnLeft:
      case ManeuverType.uturnRight:
        return 'quay đầu';
      case ManeuverType.rampLeft:
        return 'vào đường nhánh bên trái';
      case ManeuverType.rampRight:
        return 'vào đường nhánh bên phải';
      case ManeuverType.merge:
        return 'nhập làn';
      case ManeuverType.forkLeft:
        return 'rẽ trái tại ngã ba';
      case ManeuverType.forkRight:
        return 'rẽ phải tại ngã ba';
      case ManeuverType.roundaboutLeft:
      case ManeuverType.roundaboutRight:
        return 'vào vòng xoay';
      case ManeuverType.arrive:
      case ManeuverType.arriveLeft:
      case ManeuverType.arriveRight:
        return 'đã đến đích';
      case ManeuverType.keepLeft:
        return 'giữ bên trái';
      case ManeuverType.keepRight:
        return 'giữ bên phải';
      default:
        return 'theo chỉ dẫn';
    }
  }
}

