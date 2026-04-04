import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/features/places/models/place.dart';

/// Supabase `places_cache` helpers — cache-first for Explore (`get_explore`).
///
/// Cache keys must stay aligned with `supabase/functions/moody` (aggregate explore row).
class PlacesCacheUtils {
  PlacesCacheUtils._();

  /// Same as aggregate explore cache prefix in `moody` (`explore_v7_…`).
  static const String exploreCacheSchemaVersion = 'v7';

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

  /// Canonical aggregate key — moody v7: `explore_v7_{local|travel}_{section}_{city}`.
  static String exploreAggregateCacheKey(
    bool isLocalMode,
    String section,
    String location,
  ) {
    final modeKey = isLocalMode ? 'local' : 'travel';
    final loc = location.toLowerCase().trim();
    final sec = section.toLowerCase().trim();
    return 'explore_${exploreCacheSchemaVersion}_${modeKey}_${sec}_$loc';
  }

  /// v7 primary key, then v6 mood-based rows, then older keys (pre–sections Explore).
  static List<String> exploreAggregateCacheKeyCandidates(
    bool isLocalMode,
    String section,
    String location,
  ) {
    final modeKey = isLocalMode ? 'local' : 'travel';
    final loc = location.toLowerCase().trim();
    return [
      exploreAggregateCacheKey(isLocalMode, section, location),
      'explore_v6_${modeKey}_adventurous_$loc',
      'explore_v6_${modeKey}_relaxed_$loc',
      'explore_v6_${modeKey}_cultural_$loc',
      'explore_v3_quality_adventurous_$loc',
      'explore_adventurous_$loc',
    ];
  }

  /// Canonical cache key for list-style Explore responses (Edge + `places_cache` aggregate row).
  static String standardExploreCacheKey(bool isLocalMode, String section, String city) =>
      exploreAggregateCacheKey(isLocalMode, section, city);

  /// Per-place row `cache_key` suffix (when used): `${aggregate}_${placeId}`.
  static String explorePerPlaceCacheKey(
    bool isLocalMode,
    String section,
    String location,
    String placeId,
  ) {
    final trimmed = placeId.trim();
    final raw = trimmed.startsWith('google_') ? trimmed.substring(7) : trimmed;
    return '${exploreAggregateCacheKey(isLocalMode, section, location)}_$raw';
  }

  static List<String> explorePerPlaceCacheKeyCandidates(
    bool isLocalMode,
    String section,
    String location,
    String placeId,
  ) {
    final trimmed = placeId.trim();
    final raw = trimmed.startsWith('google_') ? trimmed.substring(7) : trimmed;
    return exploreAggregateCacheKeyCandidates(isLocalMode, section, location)
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
  }) async {
    final local = isLocalMode ?? await readExploreIsLocalMode(client);
    final secs = section != null && section.trim().isNotEmpty
        ? [section.toLowerCase().trim()]
        : exploreV7SectionIds;
    for (final sec in secs) {
      for (final key in explorePerPlaceCacheKeyCandidates(local, sec, location, placeId)) {
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
  }) async {
    final data = await tryLoadExplorePlaceData(
      client,
      location,
      placeId,
      section: section,
      isLocalMode: isLocalMode,
    );
    final u = data?['photo_url'] as String?;
    return (u != null && u.isNotEmpty) ? u : null;
  }

  /// Loads Explore cards from `places_cache` when the aggregate row exists and is not expired.
  /// Does not filter by `user_id` (shared cache rows use NULL).
  ///
  /// [isLocalMode] must match moody `fetchUserContext` (`currently_exploring === 'local'`).
  /// When null, reads from `profiles` for the signed-in user (travel when unknown / guest).
  static Future<List<Place>?> tryLoadExplorePlaces(
    SupabaseClient client,
    String section,
    String location, {
    bool? isLocalMode,
  }) async {
    final local = isLocalMode ?? await readExploreIsLocalMode(client);
    final keys = exploreAggregateCacheKeyCandidates(local, section, location);

    for (final cacheKey in keys) {
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
          continue;
        }

        final expiresRaw = row['expires_at'];
        if (expiresRaw == null) continue;
        final expiresAt = DateTime.parse(expiresRaw as String);
        if (!expiresAt.isAfter(DateTime.now())) {
          if (kDebugMode) {
            debugPrint('🔴 Cache MISS (expired) — $cacheKey');
          }
          continue;
        }

        final raw = row['data'];
        if (raw is! Map) {
          if (kDebugMode) {
            debugPrint('🔴 Cache MISS (bad data shape) — $cacheKey');
          }
          continue;
        }
        final data = Map<String, dynamic>.from(raw);
        final cards = data['cards'] as List<dynamic>?;
        if (cards == null || cards.isEmpty) {
          if (kDebugMode) {
            debugPrint('🔴 Cache MISS (no cards) — $cacheKey');
          }
          continue;
        }

        if (kDebugMode) {
          debugPrint(
            '🟢 Cache HIT — skip Edge call for explore ($cacheKey, ${cards.length} cards)',
          );
        }

        return cards.map((c) {
          final m = c is Map<String, dynamic> ? c : Map<String, dynamic>.from(c as Map);
          return placeFromMoodyExploreCard(m);
        }).toList();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('⚠️ places_cache explore read error ($cacheKey): $e\n$st');
        }
      }
    }
    return null;
  }

  /// Maps a Moody `get_explore` card to [Place] (same shape as Edge Function JSON).
  static Place placeFromMoodyExploreCard(Map<String, dynamic> card) {
    final locationData = card['location'] as Map<String, dynamic>? ?? {};

    final photoUrl = card['photo_url'] as String?;
    final photos = photoUrl != null && photoUrl.isNotEmpty ? <String>[photoUrl] : <String>[];

    final address = card['address'] as String? ??
        card['vicinity'] as String? ??
        '';

    final types = (card['types'] as List<dynamic>?)?.cast<String>() ?? <String>[];

    final editorial = (card['editorial_summary'] as String?)?.trim();
    final description = (editorial != null && editorial.isNotEmpty)
        ? editorial
        : card['description'] as String?;

    final openingRaw = card['opening_hours'] as Map<String, dynamic>?;
    PlaceOpeningHours? openingHours;
    if (openingRaw != null && openingRaw.isNotEmpty) {
      openingHours = PlaceOpeningHours(
        isOpen: openingRaw['open_now'] as bool? ?? false,
        currentStatus: (openingRaw['open_now'] as bool?) == true ? 'open' : 'closed',
        weekdayText: (openingRaw['weekday_text'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
    }

    return Place(
      id: card['id'] as String? ?? '',
      name: card['name'] as String? ?? 'Unknown Place',
      address: address,
      rating: (card['rating'] as num?)?.toDouble() ?? 0.0,
      photos: photos,
      types: types,
      location: PlaceLocation(
        lat: (locationData['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (locationData['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      description: description,
      priceLevel: card['price_level'] as int?,
      isFree: card['price_level'] == null || card['price_level'] == 0,
      reviewCount: (card['user_ratings_total'] as num?)?.toInt() ?? 0,
      openingHours: openingHours,
    );
  }

  static const String _fallbackFreeTimeImage =
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80';

  /// Maps cached [Place]s to [MyDayFreeTimeCarousel] activity maps (no network besides image URLs).
  static List<Map<String, dynamic>> toMyDayFreeTimeCarouselMaps(
    List<Place> places, {
    double? userLat,
    double? userLng,
    int maxItems = 5,
  }) {
    if (places.isEmpty) return [];
    final shuffled = List<Place>.from(places)..shuffle();
    return shuffled.take(maxItems).map((p) {
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
      final desc = (p.description != null && p.description!.trim().isNotEmpty)
          ? p.description!.trim()
          : (p.address.isNotEmpty ? p.address : 'A spot worth checking out');
      return <String, dynamic>{
        'title': p.name,
        'description': desc,
        'category': _freeTimeCategoryFromPlace(p),
        'distance': distanceLabel,
        'duration': _guessDurationMinutes(p),
        'imageUrl': imageUrl,
        'lat': p.location.lat,
        'lng': p.location.lng,
        'placeId': p.id,
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
