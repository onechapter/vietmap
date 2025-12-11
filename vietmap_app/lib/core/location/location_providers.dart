import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../logger.dart';
import '../../features/debug/route_simulator_service.dart';

/// Provider cho vị trí từ Route Simulator
final routeSimulatorLocationProvider = routeSimulatorProvider;

/// Provider cho vị trí từ thiết bị GPS thật
final deviceLocationProvider = StreamProvider<LatLng>((ref) async* {
  try {
    appLog('LocationProvider: Starting device location stream');
    
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      appLog('LocationProvider: Location service disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      appLog('LocationProvider: Permission denied');
      return;
    }

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    await for (final position in Geolocator.getPositionStream(locationSettings: locationSettings)) {
      yield LatLng(position.latitude, position.longitude);
    }
  } catch (e) {
    appLog('LocationProvider: Error: $e');
  }
});

/// Provider cho vị trí hiện tại (ưu tiên Route Simulator, fallback GPS thật)
final currentLocationProvider = Provider<LatLng?>((ref) {
  // Ưu tiên Route Simulator
  final simLocation = ref.watch(routeSimulatorLocationProvider);
  if (simLocation != null) {
    appLog('LocationProvider: Using simulator location: $simLocation');
    return simLocation;
  }

  // Fallback GPS thật
  final deviceLocation = ref.watch(deviceLocationProvider);
  return deviceLocation.when(
    data: (location) {
      appLog('LocationProvider: Using device location: $location');
      return location;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

