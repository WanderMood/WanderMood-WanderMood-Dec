/// In-memory cache + in-flight dedupe for Moody place card blurbs.
class MoodyPlaceBlurbCache {
  MoodyPlaceBlurbCache._();

  static final Map<String, String> _cache = {};
  static final Map<String, Future<String>> _inflight = {};
  static const int _maxEntries = 80;

  /// [variant] separates card vs detail blurbs (same facts, different generation).
  static String cacheKey(
    String placeId,
    String languageCode,
    int factsHash, {
    String variant = 'card',
  }) =>
      '$placeId|$languageCode|$factsHash|$variant';

  static String? get(String key) {
    final v = _cache[key];
    if (v == null || v.trim().isEmpty) return null;
    return v;
  }

  static void put(String key, String value) {
    if (value.trim().isEmpty) return;
    if (_cache.length >= _maxEntries && !_cache.containsKey(key)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  static Future<String>? inflight(String key) => _inflight[key];

  static void setInflight(String key, Future<String> future) {
    _inflight[key] = future;
  }

  static void clearInflight(String key) {
    _inflight.remove(key);
  }
}
