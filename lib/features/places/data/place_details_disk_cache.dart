import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists Google-backed Place Details payloads (from the `places` Edge
/// `details` path) so [getPlaceDetails] avoids repeat billable calls across
/// sessions for the same `placeId|language` key.
class PlaceDetailsDiskCache {
  PlaceDetailsDiskCache._();

  static const String _prefsKey = 'wm_place_details_cache_v1';
  static const int _maxEntries = 80;
  static const Duration _ttl = Duration(days: 21);

  static final Map<String, _Entry> _cache = {};
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
          final now = DateTime.now();
          for (final e in decoded.entries) {
            final k = e.key;
            final v = e.value;
            if (k is! String || v is! Map) continue;
            final atStr = v['at'] as String?;
            final data = v['data'];
            if (atStr == null || data is! Map) continue;
            final at = DateTime.tryParse(atStr);
            if (at == null || now.difference(at) > _ttl) continue;
            _cache[k] = _Entry(
              savedAt: at,
              data: Map<String, dynamic>.from(
                data.map((key, val) => MapEntry(key.toString(), val)),
              ),
            );
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
      final serial = <String, dynamic>{};
      for (final e in _cache.entries) {
        serial[e.key] = {
          'at': e.value.savedAt.toIso8601String(),
          'data': e.value.data,
        };
      }
      await prefs.setString(_prefsKey, jsonEncode(serial));
    } catch (_) {}
  }

  /// Returns null if missing or expired.
  static Map<String, dynamic>? get(String cacheKey) {
    final e = _cache[cacheKey];
    if (e == null) return null;
    if (DateTime.now().difference(e.savedAt) > _ttl) {
      _cache.remove(cacheKey);
      return null;
    }
    return Map<String, dynamic>.from(e.data);
  }

  static void put(String cacheKey, Map<String, dynamic> details) {
    if (details.isEmpty) return;
    while (_cache.length >= _maxEntries && !_cache.containsKey(cacheKey)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = _Entry(
      savedAt: DateTime.now(),
      data: Map<String, dynamic>.from(details),
    );
    _schedulePersist();
    if (kDebugMode) {
      debugPrint('💾 place_details disk cache put $cacheKey (${_cache.length} entries)');
    }
  }
}

class _Entry {
  _Entry({required this.savedAt, required this.data});

  final DateTime savedAt;
  final Map<String, dynamic> data;
}
