import 'package:wandermood/features/places/data/place_card_ui_description.dart';

/// In-memory cache for unified Explore card UI (rich sections or plain blurb).
class MoodyPlaceCardUiCache {
  MoodyPlaceCardUiCache._();

  static final Map<String, String> _cache = {};
  static final Map<String, Future<PlaceCardUiDescription>> _inflight = {};
  static const int _maxEntries = 80;

  static String cacheKey(String placeId, String languageCode, int factsHash) =>
      '$placeId|$languageCode|$factsHash|card_ui_v1';

  static PlaceCardUiDescription? get(String key) {
    final raw = _cache[key];
    return PlaceCardUiDescription.fromCacheString(raw);
  }

  static void put(String key, PlaceCardUiDescription value) {
    final s = value.toCacheString();
    if (s.trim().isEmpty) return;
    if (_cache.length >= _maxEntries && !_cache.containsKey(key)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = s;
  }

  static Future<PlaceCardUiDescription>? inflight(String key) =>
      _inflight[key];

  static void setInflight(
    String key,
    Future<PlaceCardUiDescription> future,
  ) {
    _inflight[key] = future;
  }

  static void clearInflight(String key) {
    _inflight.remove(key);
  }
}
