import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../core/logger.dart';
import 'camera_api_service.dart';
import 'camera_cache.dart';
import 'camera_model.dart';

class CameraRepository {
  final CameraCache _cache = CameraCache();
  final CameraApiService _api = CameraApiService(
    baseUrl: const String.fromEnvironment('CAMERA_API', defaultValue: 'http://localhost:8080'),
  );
  DateTime? _lastFetch;

  Future<List<CameraModel>> _loadLocal() async {
    final raw = await rootBundle.loadString('assets/cameras/sample.json');
    final data = jsonDecode(raw);
    if (data is List) {
      return data.map((e) => CameraModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<CameraModel>> load() async {
    await _cache.init();

    // Debounce 3 phút
    if (_lastFetch != null && DateTime.now().difference(_lastFetch!) < const Duration(minutes: 3)) {
      appLog('Camera fetch skipped (debounce)');
      final cached = await _cache.getAll();
      if (cached.isNotEmpty) return cached;
    }

    final local = await _loadLocal();

    try {
      final remote = await _api.fetchAll();
      _lastFetch = DateTime.now();
      if (remote.isNotEmpty) {
        await _cache.clear();
        await _cache.saveAll(remote);
        return remote;
      }
    } catch (e) {
      appLog('Camera API failed: $e');
    }

    final cached = await _cache.getAll();
    if (cached.isNotEmpty) {
      appLog('Using cached cameras ${cached.length}');
      return cached;
    }

    appLog('Using local assets cameras ${local.length}');
    return local;
  }
}

