import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/logger.dart';
import '../models/route_model.dart';
import '../route_engine.dart';
import 'widgets/maneuver_banner.dart';
import 'widgets/navigation_bottom_bar.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng destination;
  final LatLng? origin;

  const NavigationScreen({
    super.key,
    required this.destination,
    this.origin,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  final RouteEngine _routeEngine = RouteEngine.instance;
  RouteModel? _route;
  LatLng? _currentPosition;
  int _currentStepIndex = 0;
  bool _loading = true;
  String? _error;
  bool _autoFollow = true;
  bool _isNightMode = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
    _initLocationTracking();
    _checkNightMode();
  }

  Future<void> _loadRoute() async {
    setState(() => _loading = true);

    try {
      final origin = widget.origin ?? _currentPosition;
      if (origin == null) {
        setState(() {
          _error = 'Chưa có vị trí hiện tại';
          _loading = false;
        });
        return;
      }

      final route = await _routeEngine.requestRoute(
        from: origin,
        to: widget.destination,
      );

      if (route != null) {
        setState(() {
          _route = route;
          _loading = false;
        });
        _centerOnRoute();
      } else {
        setState(() {
          _error = 'Không tìm thấy đường đi';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi: $e';
        _loading = false;
      });
      appLog('NavigationScreen: Error loading route: $e');
    }
  }

  Future<void> _initLocationTracking() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });

          if (_route != null) {
            _updateCurrentStep();
            if (_autoFollow) {
              _mapController.move(_currentPosition!, _mapController.camera.zoom);
            }
          }
        }
      });
    } catch (e) {
      appLog('NavigationScreen: Error tracking location: $e');
    }
  }

  void _updateCurrentStep() {
    if (_route == null || _currentPosition == null) return;

    final newIndex = _route!.getCurrentStepIndex(_currentPosition!);
    if (newIndex != _currentStepIndex) {
      setState(() {
        _currentStepIndex = newIndex;
      });
    }
  }

  void _centerOnRoute() {
    if (_route == null || _route!.geometry.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(_route!.geometry);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _checkNightMode() {
    final hour = DateTime.now().hour;
    setState(() {
      _isNightMode = hour < 6 || hour >= 18;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isNightMode ? Colors.black87 : Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _route == null
                  ? const Center(child: Text('Không có route'))
                  : Stack(
                      children: [
                        // Map
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentPosition ?? widget.destination,
                            initialZoom: 15,
                            minZoom: 10,
                            maxZoom: 20,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.vietmap_app',
                            ),
                            // Route line
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _route!.geometry,
                                  strokeWidth: 5,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                            // Current position marker
                            if (_currentPosition != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _currentPosition!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        // Maneuver banner
                        if (_currentStepIndex < _route!.steps.length)
                          Positioned(
                            top: 50,
                            left: 12,
                            right: 12,
                            child: ManeuverBanner(
                              step: _route!.steps[_currentStepIndex],
                            ),
                          ),
                        // Bottom bar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: NavigationBottomBar(
                            route: _route!,
                            currentPosition: _currentPosition,
                            onAutoFollowToggle: (value) {
                              setState(() => _autoFollow = value);
                            },
                            autoFollow: _autoFollow,
                          ),
                        ),
                      ],
                    ),
    );
  }
}

