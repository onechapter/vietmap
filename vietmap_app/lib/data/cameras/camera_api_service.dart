import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/logger.dart';
import '../../core/retry.dart';
import 'camera_model.dart';

class CameraApiService {
  final String baseUrl;
  final ExponentialBackoff _backoff = ExponentialBackoff(maxAttempts: 3, baseDelay: const Duration(milliseconds: 500));

  CameraApiService({required this.baseUrl});

  Future<List<CameraModel>> fetchAll() async {
    final uri = Uri.parse('$baseUrl/cameras');
    return _backoff.run(() async {
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) {
        appLog('Camera API error ${resp.statusCode}');
        throw Exception('API ${resp.statusCode}');
      }
      final data = jsonDecode(resp.body);
      if (data is List) {
        final cams = data.map((e) => CameraModel.fromJson(e as Map<String, dynamic>)).toList();
        appLog('Camera API success: ${cams.length} items');
        return cams;
      }
      appLog('Camera API empty payload');
      return [];
    });
  }
}

