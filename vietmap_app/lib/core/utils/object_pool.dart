/// Object pool for reusing objects to reduce GC pressure
class ObjectPool<T> {
  final List<T> _pool = [];
  final T Function() create;
  final int maxSize;

  ObjectPool(this.create, {this.maxSize = 50});

  /// Acquire an object from the pool
  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeLast();
    }
    return create();
  }

  /// Release an object back to the pool
  void release(T obj) {
    if (_pool.length < maxSize) {
      _pool.add(obj);
    }
  }

  /// Clear the pool
  void clear() {
    _pool.clear();
  }

  /// Get current pool size
  int get size => _pool.length;
}

