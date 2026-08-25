import '../core/brand_icon_shape.dart';

/// Holds fetched icon payloads in memory, keyed by candidate id.
///
/// Bounded by bytes rather than by count, because the two payload kinds differ by orders of
/// magnitude: a vector path is a few hundred bytes and a 512 pixel PNG is tens of kilobytes.
class IconCache {
  IconCache({int byteBudget = defaultByteBudget})
      : byteBudget = byteBudget < 0 ? 0 : byteBudget;

  static const int defaultByteBudget = 8 * 1024 * 1024;

  final int byteBudget;
  final Map<String, _Entry> _entries = {};
  int _bytes = 0;
  int _counter = 0;

  int get byteCount => _bytes;

  /// The cached payload, marking it as recently used.
  BrandIconShape? shape(String id) {
    final entry = _entries[id];
    if (entry == null) return null;
    entry.lastUsed = ++_counter;
    return entry.shape;
  }

  /// Stores a payload, evicting older ones if it no longer fits.
  ///
  /// A payload larger than the whole budget is dropped rather than stored.
  void insert(BrandIconShape shape, String id) {
    final cost = costOf(shape);
    remove(id);
    if (cost > byteBudget) return;
    _entries[id] = _Entry(shape, cost, ++_counter);
    _bytes += cost;
    _evict();
  }

  void remove(String id) {
    final entry = _entries.remove(id);
    if (entry != null) _bytes -= entry.cost;
  }

  void removeAll() {
    _entries.clear();
    _bytes = 0;
  }

  void _evict() {
    if (_bytes <= byteBudget) return;
    final byAge = _entries.entries.toList()
      ..sort((a, b) => a.value.lastUsed.compareTo(b.value.lastUsed));
    for (final entry in byAge) {
      remove(entry.key);
      if (_bytes <= byteBudget) return;
    }
  }

  static int costOf(BrandIconShape shape) => switch (shape) {
        RasterShape(:final data) => data.length,
        VectorShape(:final path) => path.length + 64,
        LayeredVectorShape(:final layers) =>
          layers.fold(64, (total, layer) => total + layer.path.length + 16),
      };
}

class _Entry {
  _Entry(this.shape, this.cost, this.lastUsed);
  final BrandIconShape shape;
  final int cost;
  int lastUsed;
}
