import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// In-memory cache + in-flight dedupe for Moody place card blurbs.
///
/// Persisted so legacy / fallback card lines survive process death.
class MoodyPlaceBlurbCache {
  MoodyPlaceBlurbCache._();

  static final Map<String, String> _cache = {};
  static final Map<String, Future<String>> _inflight = {};
  static const int _maxEntries = 80;

  static const String _prefsKey = 'wm_moody_place_blurb_cache_v1';
  static bool _hydrated = false;
  static Future<void>? _hydrateFuture;
  static Timer? _persistTimer;

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
    } finally {
      _hydrated = true;
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
    _schedulePersist();
  }

  static Future<String>? inflight(String key) => _inflight[key];

  static void setInflight(String key, Future<String> future) {
    _inflight[key] = future;
  }

  static void clearInflight(String key) {
    _inflight.remove(key);
  }

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
  }
}
