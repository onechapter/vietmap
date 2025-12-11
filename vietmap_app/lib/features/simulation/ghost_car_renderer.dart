import 'package:maplibre_gl/maplibre_gl.dart';

class GhostCarRenderer {
  final MapLibreMapController map;
  Line? _routeLine;
  Symbol? _carSymbol;

  GhostCarRenderer(this.map);

  Future<void> drawRoute(List<LatLng> points) async {
    await _clearRoute();
    if (points.isEmpty) return;
    _routeLine = await map.addLine(
      LineOptions(
        geometry: points,
        lineColor: '#FF5722',
        lineWidth: 4.0,
      ),
    );
  }

  Future<void> updateCar(
    LatLng pos, {
    double heading = 0,
    bool follow = true,
  }) async {
    if (_carSymbol == null) {
      _carSymbol = await map.addSymbol(
        SymbolOptions(
          geometry: pos,
          iconImage: 'marker-15', // fallback built-in icon
          iconSize: 1.3,
          iconRotate: heading,
        ),
      );
    } else {
      await map.updateSymbol(
        _carSymbol!,
        SymbolOptions(
          geometry: pos,
          iconRotate: heading,
        ),
      );
    }
    if (follow) {
      try {
        await map.animateCamera(CameraUpdate.newLatLng(pos));
      } catch (_) {}
    }
  }

  Future<void> clearAll() async {
    await _clearRoute();
    if (_carSymbol != null) {
      try {
        await map.removeSymbol(_carSymbol!);
      } catch (_) {}
      _carSymbol = null;
    }
  }

  Future<void> _clearRoute() async {
    if (_routeLine != null) {
      try {
        await map.removeLine(_routeLine!);
      } catch (_) {}
      _routeLine = null;
    }
  }
}

