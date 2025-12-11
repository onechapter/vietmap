import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'rule_models.dart';

class RuleRepository {
  Future<List<SpeedRule>> loadSpeedRules() async {
    final raw = await rootBundle.loadString('assets/local_rules/speed_limit.json');
    final data = jsonDecode(raw) as List;
    return data.map((e) => SpeedRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DangerRule>> loadDangerRules() async {
    final raw = await rootBundle.loadString('assets/local_rules/danger_zone.json');
    final data = jsonDecode(raw) as List;
    return data.map((e) => DangerRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RailwayRule>> loadRailwayRules() async {
    final raw = await rootBundle.loadString('assets/local_rules/railway.json');
    final data = jsonDecode(raw) as List;
    return data.map((e) => RailwayRule.fromJson(e as Map<String, dynamic>)).toList();
  }
}

