import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/logger.dart';
import '../../core/retry.dart';
import 'models/route_model.dart';

/// VietMap Routing API service
class RouteApi {
  static const String baseUrl = 'https://routing.vietmap.vn';
  static const String apiKey = ''; // TODO: Add API key if required

  /// Request route from origin to destination
  Future<RouteModel?> requestRoute({
    required LatLng from,
    required LatLng to,
    String profile = 'driving',
  }) async {
    try {
      appLog('RouteApi: Requesting route from $from to $to');

      final url = Uri.parse(
        '$baseUrl/route/v1/$profile/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=polyline&steps=true',
      );

      final backoff = ExponentialBackoff(maxAttempts: 3);
      final response = await backoff.run(() async {
        final res = await http.get(url).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          return res;
        }
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      });

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;

      if (routes == null || routes.isEmpty) {
        appLog('RouteApi: No routes found');
        return null;
      }

      final routeData = routes[0] as Map<String, dynamic>;
      final routeId = 'route_${DateTime.now().millisecondsSinceEpoch}';
      final route = RouteModel.fromJson(routeData, routeId);

      appLog('RouteApi: Route found - ${route.distance.toStringAsFixed(0)}m, ${route.steps.length} steps');
      return route;
    } catch (e) {
      appLog('RouteApi: Error requesting route: $e');
      return null;
    }
  }
}

