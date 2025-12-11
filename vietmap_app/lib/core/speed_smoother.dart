class SpeedSmoother {
  final double alpha;
  double _filtered = 0;
  bool _initialized = false;

  SpeedSmoother({this.alpha = 0.25});

  double update(double rawKmh) {
    if (!_initialized) {
      _filtered = rawKmh;
      _initialized = true;
    } else {
      _filtered = _filtered + alpha * (rawKmh - _filtered);
    }
    return _filtered;
  }

  double get value => _filtered;
}

