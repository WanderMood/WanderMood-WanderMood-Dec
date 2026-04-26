import 'dart:math' show Random;
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/features/places/models/place.dart';

/// Result of reading an aggregate Explore row from `places_cache`.
class ExplorePlacesCacheHit {
  ExplorePlacesCacheHit({
    required this.places,
    required this.expiresAt,
  });

  final List<Place> places;
  final DateTime expiresAt;

  /// Moody's explore cache TTL is 7 days from upsert — approximate last refresh time.
  static const Duration _moodyExploreTtl = Duration(days: 7);

  /// When true, UI may refresh via Edge in the background (fire-and-forget).
  bool get shouldRefreshInBackground {
    final approxLastWrite = expiresAt.subtract(_moodyExploreTtl);
    return DateTime.now().difference(approxLastWrite) >= const Duration(hours: 6);
  }
}

/// Supabase `places_cache` helpers — cache-first for Explore (`get_explore`).
///
/// Cache keys must stay aligned with `supabase/functions/moody` (aggregate explore row).
class PlacesCacheUtils {
  PlacesCacheUtils._();

  static void _agentLogCache(
    String hypothesisId,
    String message, {
    Map<String, dynamic>? data,
    String runId = 'run1',
    String location = 'places_cache_utils.dart',
  }) {
    try {
      final entry = {
        'sessionId': '9a3a3b',
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data ?? <String, dynamic>{},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File('/Users/edviennemerencia/WanderMood-WanderMood-Dec/.cursor/debug-9a3a3b.log')
          .writeAsStringSync('${jsonEncode(entry)}\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  /// Same as aggregate explore cache prefix in `moody` (`explore_v9_…`).
  static const String exploreCacheSchemaVersion = 'v9';

  /// Section ids for `get_explore` (`section` param) + broad `discovery` aggregate.
  static const List<String> exploreV7SectionIds = [
    'discovery',
    'food',
    'trending',
    'solo',
    'different',
  ];

  /// Matches `fetchUserContext` in moody: `isLocalMode: currently_exploring === 'local'`.
  static Future<bool> readExploreIsLocalMode(SupabaseClient client) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final row = await client
          .from('profiles')
          .select('currently_exploring')
          .eq('id', userId)
          .maybeSingle();
      final v = (row?['currently_exploring'] as String?)?.toLowerCase().trim();
      return v == 'local';
    } catch (_) {
      return false;
    }
  }

  /// ISO 639-1 tag for cache keys — aligned with moody `googlePlacesLanguage` / `normalizeAppLang`.
  static String normalizeExploreLanguageCode(String? code) {
    final x = (code ?? 'en').toLowerCase().split(RegExp(r'[-_]')).first;
    if (x == 'nl' || x == 'es' || x == 'de' || x == 'fr') return x;
    return 'en';
  }

  /// In-app locale if set, else device — for moody `language_code` and localized `places_cache` keys.
  static String effectiveExploreLanguageTag({Locale? appLocale}) {
    final raw = appLocale?.languageCode ?? ui.PlatformDispatcher.instance.locale.languageCode;
    return normalizeExploreLanguageCode(raw);
  }

  /// Suffix for named-filter explore rows — must match moody `handleGetExplore`
  /// (`_nf_${sorted.join('_')}` appended to the base aggregate key).
  static String exploreNamedFiltersCacheSuffix(List<String>? namedFilters) {
    if (namedFilters == null || namedFilters.isEmpty) return '';
    final parts = namedFilters
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();
    if (parts.isEmpty) return '';
    return '_nf_${parts.join('_')}';
  }

  /// Canonical aggregate key — aligned with moody `handleGetExplore` (`index.ts`):
  /// English omits the `_en` suffix; other languages use `_nl`, `_es`, etc.
  static String exploreAggregateCacheKey(
    bool isLocalMode,
    String section,
    String location, {
    String? languageCode,
    List<String>? namedFilters,
  }) {
    final modeKey = isLocalMode ? 'local' : 'travel';
    final loc = location.toLowerCase().trim();
    final sec = section.toLowerCase().trim();
    final lang = normalizeExploreLanguageCode(languageCode);
    final nf = exploreNamedFiltersCacheSuffix(namedFilters);
    if (lang == 'en') {
      return 'explore_${exploreCacheSchemaVersion}_${modeKey}_${sec}_$loc$nf';
    }
    return 'explore_${exploreCacheSchemaVersion}_${modeKey}_${sec}_${loc}_$lang$nf';
  }

  /// v7 primary key (localized), server `all` slot for broad discovery, then legacy keys without language.
  static List<String> exploreAggregateCacheKeyCandidates(
    bool isLocalMode,
    String section,
    String location, {
    String? languageCode,
    List<String>? namedFilters,
  }) {
    final nf = exploreNamedFiltersCacheSuffix(namedFilters);
    if (nf.isNotEmpty) {
      // Moody stores one row per exact key including `_nf_…` — do not fall back to
      // non-filter keys or we would return the wrong feed.
      return [
        exploreAggregateCacheKey(
          isLocalMode,
          section,
          location,
          languageCode: languageCode,
          namedFilters: namedFilters,
        ),
      ];
    }
    final modeKey = isLocalMode ? 'local' : 'travel';
    final loc = location.toLowerCase().trim();
    final sec = section.toLowerCase().trim();
    final lang = normalizeExploreLanguageCode(languageCode);
    final v7 = exploreAggregateCacheKey(isLocalMode, section, location, languageCode: languageCode);
    final v7AllLang = lang == 'en'
        ? 'explore_${exploreCacheSchemaVersion}_${modeKey}_all_$loc'
        : 'explore_${exploreCacheSchemaVersion}_${modeKey}_all_${loc}_$lang';
    final v7NoLang = 'explore_${exploreCacheSchemaVersion}_${modeKey}_${sec}_$loc';
    final v7AllNoLang = 'explore_${exploreCacheSchemaVersion}_${modeKey}_all_$loc';
    final broadDiscovery =
        sec == 'discovery' || sec == 'all' || sec == 'discover' || sec.isEmpty;
    final primary = <String>[];
    void addKey(String k) {
      if (!primary.contains(k)) primary.add(k);
    }

    addKey(v7);
    if (broadDiscovery) addKey(v7AllLang);
    addKey(v7NoLang);
    if (broadDiscovery) addKey(v7AllNoLang);
    // Keep only same-schema candidates to avoid pulling stale legacy datasets.
    if (lang == 'en') {
      addKey('explore_${exploreCacheSchemaVersion}_${modeKey}_${sec}_${loc}_en');
    }
    return primary;
  }

  /// Canonical cache key for list-style Explore responses (Edge + `places_cache` aggregate row).
  static String standardExploreCacheKey(
    bool isLocalMode,
    String section,
    String city, {
    String? languageCode,
  }) =>
      exploreAggregateCacheKey(isLocalMode, section, city, languageCode: languageCode);

  /// Per-place row `cache_key` suffix (when used): `${aggregate}_${placeId}`.
  static String explorePerPlaceCacheKey(
    bool isLocalMode,
    String section,
    String location,
    String placeId, {
    String? languageCode,
  }) {
    final trimmed = placeId.trim();
    final raw = trimmed.startsWith('google_') ? trimmed.substring(7) : trimmed;
    return '${exploreAggregateCacheKey(isLocalMode, section, location, languageCode: languageCode)}_$raw';
  }

  static List<String> explorePerPlaceCacheKeyCandidates(
    bool isLocalMode,
    String section,
    String location,
    String placeId, {
    String? languageCode,
  }) {
    final trimmed = placeId.trim();
    final raw = trimmed.startsWith('google_') ? trimmed.substring(7) : trimmed;
    return exploreAggregateCacheKeyCandidates(isLocalMode, section, location, languageCode: languageCode)
        .map((k) => '${k}_$raw')
        .toList();
  }

  /// Raw JSON for a single cached explore card (when moody wrote a per-place row).
  ///
  /// When [section] is null, tries all [exploreV7SectionIds] in order.
  static Future<Map<String, dynamic>?> tryLoadExplorePlaceData(
    SupabaseClient client,
    String location,
    String placeId, {
    String? section,
    bool? isLocalMode,
    String? languageCode,
  }) async {
    final local = isLocalMode ?? await readExploreIsLocalMode(client);
    final secs = section != null && section.trim().isNotEmpty
        ? [section.toLowerCase().trim()]
        : exploreV7SectionIds;
    for (final sec in secs) {
      for (final key in explorePerPlaceCacheKeyCandidates(local, sec, location, placeId,
          languageCode: languageCode)) {
        final row = await _trySelectPlacesCacheRow(client, key);
        if (row != null) return row;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _trySelectPlacesCacheRow(
    SupabaseClient client,
    String cacheKey,
  ) async {
    try {
      final row = await client
          .from('places_cache')
          .select('data, expires_at')
          .eq('cache_key', cacheKey)
          .maybeSingle();
      if (row == null) return null;
      final expiresRaw = row['expires_at'];
      if (expiresRaw != null) {
        final expiresAt = DateTime.parse(expiresRaw as String);
        if (!expiresAt.isAfter(DateTime.now())) return null;
      }
      final raw = row['data'];
      if (raw is! Map) return null;
      return Map<String, dynamic>.from(raw);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('⚠️ places_cache per-place read: $e\n$st');
      }
      return null;
    }
  }

  static Future<String?> tryExplorePlacePhotoUrl(
    SupabaseClient client, {
    required String location,
    required String placeId,
    String? section,
    bool? isLocalMode,
    String? languageCode,
  }) async {
    final data = await tryLoadExplorePlaceData(
      client,
      location,
      placeId,
      section: section,
      isLocalMode: isLocalMode,
      languageCode: languageCode,
    );
    final u = data?['photo_url'] as String?;
    return (u != null && u.isNotEmpty) ? u : null;
  }

  /// One aggregate `places_cache` row for Explore — direct PostgREST read (no Edge Function).
  ///
  /// Moody's `cacheExplore` uses a 7-day [expiresAt]; we approximate last refresh as
  /// [expiresAt] − 7 days to decide [shouldRefreshInBackground] (6 hours).
  static Future<ExplorePlacesCacheHit?> getExploreCardsFromCache(
    SupabaseClient client,
    String cacheKey,
  ) async {
    try {
      final row = await client
          .from('places_cache')
          .select('data, expires_at')
          .eq('cache_key', cacheKey)
          .isFilter('place_id', null)
          .maybeSingle();

      if (row == null) {
        if (kDebugMode) {
          debugPrint('🔴 Cache MISS (no row) — $cacheKey');
        }
        return null;
      }

      final expiresRaw = row['expires_at'];
      if (expiresRaw == null) return null;
      final expiresAt = DateTime.parse(expiresRaw as String);
      if (!expiresAt.isAfter(DateTime.now())) {
        if (kDebugMode) {
          debugPrint('🔴 Cache MISS (expired) — $cacheKey');
        }
        return null;
      }

      final raw = row['data'];
      if (raw is! Map) {
        if (kDebugMode) {
          debugPrint('🔴 Cache MISS (bad data shape) — $cacheKey');
        }
        return null;
      }
      final data = Map<String, dynamic>.from(raw);
      final cards = data['cards'] as List<dynamic>?;
      if (cards == null || cards.isEmpty) {
        if (kDebugMode) {
          debugPrint('🔴 Cache MISS (no cards) — $cacheKey');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint(
          '🟢 Cache HIT — explore ($cacheKey, ${cards.length} cards)',
        );
      }

      final mapped = cards.map((c) {
        final m = c is Map<String, dynamic> ? c : Map<String, dynamic>.from(c as Map);
        return placeFromMoodyExploreCard(m);
      }).toList();
      mapped.shuffle(Random());
      return ExplorePlacesCacheHit(places: mapped, expiresAt: expiresAt);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('⚠️ places_cache explore read error ($cacheKey): $e\n$st');
      }
      return null;
    }
  }

  /// Loads Explore cards from `places_cache` when the aggregate row exists and is not expired.
  /// Does not filter by `user_id` (shared cache rows use NULL).
  ///
  /// [isLocalMode] must match moody `fetchUserContext` (`currently_exploring === 'local'`).
  /// When null, reads from `profiles` for the signed-in user (travel when unknown / guest).
  static Future<ExplorePlacesCacheHit?> tryLoadExplorePlacesHit(
    SupabaseClient client,
    String section,
    String location, {
    bool? isLocalMode,
    String? languageCode,
    List<String>? namedFilters,
  }) async {
    final local = isLocalMode ?? await readExploreIsLocalMode(client);
    final keys = exploreAggregateCacheKeyCandidates(
      local,
      section,
      location,
      languageCode: languageCode,
      namedFilters: namedFilters,
    );

    for (final cacheKey in keys) {
      final hit = await getExploreCardsFromCache(client, cacheKey);
      if (hit != null) return hit;
    }
    return null;
  }

  static Future<List<Place>?> tryLoadExplorePlaces(
    SupabaseClient client,
    String section,
    String location, {
    bool? isLocalMode,
    String? languageCode,
    List<String>? namedFilters,
  }) async {
    final hit = await tryLoadExplorePlacesHit(
      client,
      section,
      location,
      isLocalMode: isLocalMode,
      languageCode: languageCode,
      namedFilters: namedFilters,
    );
    return hit?.places;
  }

  /// Maps a Moody `get_explore` card to [Place] (same shape as Edge Function JSON).
  static Place placeFromMoodyExploreCard(Map<String, dynamic> card) {
    final locationData = card['location'] as Map<String, dynamic>? ?? {};
    bool looksLikeGooglePlaceRef(String id) {
      final t = id.trim();
      if (t.isEmpty) return false;
      return t.startsWith('google_') || t.startsWith('ChIJ') || t.startsWith('EhIJ');
    }

    String normalizePlaceId(String raw) {
      final t = raw.trim();
      if (t.isEmpty) return '';
      if (t.startsWith('google_')) return t;
      if (t.startsWith('ChIJ') || t.startsWith('EhIJ')) return 'google_$t';
      return t;
    }

    String pickPhoto(dynamic v) {
      final s = v?.toString().trim() ?? '';
      return s;
    }

    final photos = <String>[];
    void add(dynamic v) {
      final s = pickPhoto(v);
      if (s.isEmpty) return;
      if (!photos.contains(s)) photos.add(s);
    }

    add(card['photo_url']);
    add(card['image_url']);
    add(card['imageUrl']);
    add(card['photoUrl']);

    final cardPhotos = card['photos'];
    if (cardPhotos is List) {
      for (final p in cardPhotos) {
        if (p is String) {
          add(p);
        } else if (p is Map) {
          add(p['url'] ?? p['photo_url'] ?? p['photoUrl'] ?? p['uri'] ?? p['name']);
        }
      }
    }

    final address = card['address'] as String? ??
        card['vicinity'] as String? ??
        '';

    final types = (card['types'] as List<dynamic>?)?.cast<String>() ?? <String>[];

    final editorialRaw = ((card['editorial_summary'] ?? card['editorialSummary'])
            as String?)
        ?.trim();
    final editorialSummary =
        (editorialRaw != null && editorialRaw.isNotEmpty) ? editorialRaw : null;
    final description = (card['description'] ?? card['desc']) as String?;

    final primaryRaw = (card['primaryType'] as String?)?.trim() ??
        (card['primary_type'] as String?)?.trim();
    final socialRaw = (card['social_signal'] as String?)?.trim() ??
        (card['socialSignal'] as String?)?.trim();
    final bestRaw =
        (card['best_time'] as String?)?.trim() ?? (card['bestTime'] as String?)?.trim();

    final pl = card['price_level'] ?? card['priceLevel'];
    final priceLevelParsed = pl is num ? pl.toInt() : null;

    final openingRaw = card['opening_hours'] as Map<String, dynamic>?;
    PlaceOpeningHours? openingHours;
    if (openingRaw != null && openingRaw.isNotEmpty) {
      openingHours = PlaceOpeningHours(
        isOpen: openingRaw['open_now'] as bool? ?? false,
        currentStatus: null,
        weekdayText: (openingRaw['weekday_text'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
    }

    final rawId = (card['id'] as String?)?.trim() ?? '';
    final rawPlaceId = (card['place_id'] as String?)?.trim() ?? '';
    final resolvedId = looksLikeGooglePlaceRef(rawPlaceId)
        ? normalizePlaceId(rawPlaceId)
        : (looksLikeGooglePlaceRef(rawId) ? normalizePlaceId(rawId) : rawId);
    // #region agent log
    _agentLogCache(
      'H4',
      'mapped moody explore card to place',
      location: 'places_cache_utils.dart:placeFromMoodyExploreCard',
      data: {
        'rawId': rawId,
        'rawPlaceId': rawPlaceId,
        'resolvedId': resolvedId,
        'photoCount': photos.length,
        'firstPhoto': photos.isNotEmpty ? photos.first : '',
        'hasPhotosArray': card['photos'] is List,
      },
    );
    // #endregion

    return Place(
      id: resolvedId,
      name: card['name'] as String? ?? 'Unknown Place',
      address: address,
      rating: (card['rating'] as num?)?.toDouble() ?? 0.0,
      photos: photos.take(10).toList(),
      types: types,
      location: PlaceLocation(
        lat: (locationData['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (locationData['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      description: description,
      editorialSummary: editorialSummary,
      primaryType: (primaryRaw != null && primaryRaw.isNotEmpty) ? primaryRaw : null,
      socialSignal: (socialRaw != null && socialRaw.isNotEmpty) ? socialRaw : null,
      bestTime: (bestRaw != null && bestRaw.isNotEmpty) ? bestRaw : null,
      priceLevel: priceLevelParsed,
      isFree: ExplorePlaceCardCopy.inferIsFreeFromExploreCard(card),
      reviewCount: (card['user_ratings_total'] as num?)?.toInt() ?? 0,
      openingHours: openingHours,
    );
  }

  static const String _fallbackFreeTimeImage =
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80';

  /// Aligns with [ExplorePlaceCardCopy]: clean editorial or type blurb, no review boilerplate.
  static String _freeTimeCarouselDescriptionFromPlace(
    Place p,
    AppLocalizations l10n,
  ) {
    return ExplorePlaceCardCopy.cardDescription(p, l10n);
  }

  /// Maps cached [Place]s to [MyDayFreeTimeCarousel] activity maps (no network besides image URLs).
  static List<Map<String, dynamic>> toMyDayFreeTimeCarouselMaps(
    List<Place> places, {
    required AppLocalizations l10n,
    double? userLat,
    double? userLng,
    int maxItems = 5,
  }) {
    if (places.isEmpty) return [];
    final sorted = List<Place>.from(places);
    if (userLat != null && userLng != null) {
      double distKm(Place p) {
        if (p.location.lat == 0 && p.location.lng == 0) return 1e6;
        return DistanceService.calculateDistance(
          userLat,
          userLng,
          p.location.lat,
          p.location.lng,
        );
      }

      sorted.sort((a, b) => distKm(a).compareTo(distKm(b)));
    } else {
      sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return sorted.take(maxItems).map((p) {
      final hasCoords = p.location.lat != 0 && p.location.lng != 0;
      String distanceLabel = '';
      if (userLat != null && userLng != null && hasCoords) {
        final km = DistanceService.calculateDistance(
          userLat,
          userLng,
          p.location.lat,
          p.location.lng,
        );
        distanceLabel = DistanceService.formatDistance(km);
      }
      final imageUrl =
          p.photos.isNotEmpty ? p.photos.first : _fallbackFreeTimeImage;
      final desc = _freeTimeCarouselDescriptionFromPlace(p, l10n);
      return <String, dynamic>{
        'title': p.name,
        'description': desc,
        'place': p,
        'category': _freeTimeCategoryFromPlace(p),
        'distance': distanceLabel,
        'duration': _guessDurationMinutes(p),
        'imageUrl': imageUrl,
        'lat': p.location.lat,
        'lng': p.location.lng,
        'placeId': p.id,
        'rating': p.rating,
        'reviewCount': p.reviewCount,
        'priceLevel': p.priceLevel,
        'isFree': p.isFree,
      };
    }).toList();
  }

  static String _freeTimeCategoryFromPlace(Place p) {
    final types = p.types.map((t) => t.toLowerCase()).toList();
    if (types.any((t) =>
        ['restaurant', 'cafe', 'bakery', 'meal_takeaway', 'food'].contains(t))) {
      return 'food';
    }
    if (types.any((t) =>
        ['gym', 'stadium', 'park', 'natural_feature'].contains(t))) {
      return 'exercise';
    }
    if (types.any((t) => [
          'shopping_mall',
          'store',
          'clothing_store',
          'shoe_store',
        ].contains(t))) {
      return 'shopping';
    }
    if (types.any((t) => [
          'movie_theater',
          'night_club',
          'bowling_alley',
          'casino',
        ].contains(t))) {
      return 'entertainment';
    }
    if (types.any((t) => [
          'museum',
          'art_gallery',
          'tourist_attraction',
          'church',
          'place_of_worship',
        ].contains(t))) {
      return 'culture';
    }
    return 'culture';
  }

  static int _guessDurationMinutes(Place p) {
    final cat = _freeTimeCategoryFromPlace(p);
    switch (cat) {
      case 'food':
        return 90;
      case 'exercise':
        return 60;
      case 'shopping':
        return 45;
      case 'entertainment':
        return 120;
      default:
        return 60;
    }
  }
}
