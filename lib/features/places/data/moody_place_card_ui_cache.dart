import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/places/data/place_card_ui_description.dart';

/// In-memory cache for unified Explore card UI (rich sections or plain blurb).
///
/// Also persisted to [SharedPreferences] so card copy survives app restarts and
/// cold starts without re-fetching Google details / edge blurbs.
class MoodyPlaceCardUiCache {
  MoodyPlaceCardUiCache._();

  static final Map<String, String> _cache = {};
  static final Map<String, Future<PlaceCardUiDescription>> _inflight = {};
  /// Room for facts-key + stable-key pairs per place.
  static const int _maxEntries = 120;

  static const String _prefsKey = 'wm_moody_place_card_ui_cache_v1';
  static bool _hydrated = false;
  static Future<void>? _hydrateFuture;
  static Timer? _persistTimer;
  static bool _revisionBumpMicrotaskPending = false;

  /// Bumped on every successful [put] / hydration. Card widgets listen to this
  /// so they pick up rich copy written by the Explore prewarm queue without
  /// needing a Riverpod invalidation round-trip.
  ///
  /// Notifications are **deferred** to a microtask so a [put] during layout
  /// (e.g. prewarm completing while a sliver is building children) does not
  /// trigger "setState/markNeedsBuild called during build" from
  /// [ListenableBuilder].
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void _scheduleRevisionBump() {
    if (_revisionBumpMicrotaskPending) return;
    _revisionBumpMicrotaskPending = true;
    scheduleMicrotask(() {
      _revisionBumpMicrotaskPending = false;
      revision.value++;
    });
  }

  /// True once [ensureHydrated] has completed at least once this session.
  static bool get isHydrated => _hydrated;

  /// Await once before reads so disk-backed entries are in [_cache].
  static Future<void> ensureHydrated() {
    if (_hydrated) return Future.value();
    _hydrateFuture ??= _loadFromDisk();
    return _hydrateFuture!;
  }

  static Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final e in decoded.entries) {
            final k = e.key;
            final v = e.value;
            if (k is String && v is String && v.isNotEmpty) {
              _cache[k] = v;
            }
          }
        }
      }
    } catch (_) {
      // Corrupt storage — ignore; in-memory / network paths still work.
    } finally {
      _hydrated = true;
      _scheduleRevisionBump();
    }
  }

  static void _schedulePersist() {
    if (!_hydrated) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 450), () {
      _persistTimer = null;
      unawaited(_persistToDisk());
    });
  }

  static Future<void> _persistToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_cache));
    } catch (_) {}
  }

  static String cacheKey(String placeId, String languageCode, int factsHash) =>
      '$placeId|$languageCode|$factsHash|card_ui_v1';

  /// Key without facts hash — copy for this place+language+style is stable enough to
  /// show instantly while [getPlaceDetails] + edge would otherwise take several seconds.
  static String stableCacheKey(
    String placeId,
    String languageCode,
    String communicationStyle,
  ) {
    final h = Object.hash(communicationStyle, 0);
    return '$placeId|$languageCode|${h}_card_ui_stable_v2';
  }

  /// Synchronous lookup against [stableCacheKey]. Returns null if [_hydrated]
  /// is still false or there is no cached entry yet — caller should fall back
  /// to the async provider in that case.
  static PlaceCardUiDescription? peekStable(
    String placeId,
    String languageCode,
    String communicationStyle,
  ) {
    if (!_hydrated) return null;
    return get(stableCacheKey(placeId, languageCode, communicationStyle));
  }

  static void putWithStableAlias(
    String uiKey,
    String stableKey,
    PlaceCardUiDescription value,
  ) {
    put(uiKey, value);
    put(stableKey, value);
  }

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
    _schedulePersist();
    _scheduleRevisionBump();
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

  /// Wipes memory + disk (e.g. sign out so the next user does not reuse copy).
  static Future<void> clearPersistent() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    _cache.clear();
    _inflight.clear();
    _hydrated = false;
    _hydrateFuture = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
    _scheduleRevisionBump();
  }
}
