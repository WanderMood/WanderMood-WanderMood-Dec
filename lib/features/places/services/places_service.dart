import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_keys.dart';
import '../../../core/utils/explore_place_card_copy.dart';
import '../../../core/presentation/providers/language_provider.dart';
import '../../../core/utils/places_cache_utils.dart';
import '../models/place.dart';
import 'opening_hours_service.dart';

part 'places_service.g.dart';

@Riverpod(keepAlive: true)
class PlacesService extends _$PlacesService {
  late final GoogleMapsPlaces _places;
  bool _isInitialized = false;
  
  // Cache to store full Place objects from search results
  // This prevents re-fetching incomplete data from Google API
  final Map<String, Place> _placeCache = {};

  /// Deduped photo URL futures for Explore list/grid cards (avoids repeating details calls).
  final Map<String, Future<List<String>>> _exploreCardPhotoFutures = {};

  /// In-session Place Details by place id + language (avoids duplicate edge/Google calls).
  final Map<String, Map<String, dynamic>> _placeDetailsMemoryCache = {};

  /// Concurrent [getPlaceDetails] for the same key share one edge invocation.
  final Map<String, Future<Map<String, dynamic>>> _placeDetailsInflight = {};

  /// 7-day session cache for text-search results (query+lang → Google JSON results).
  final Map<String, List<PlacesSearchResult>> _searchMemoryCache = {};
  final Map<String, DateTime> _searchCacheTimestamps = {};
  final Map<String, Future<List<PlacesSearchResult>>> _searchInflight = {};
  static const Duration _searchCacheTtl = Duration(days: 7);

  @override
  Future<void> build() async {
    await _initializePlaces();
  }
  
  /// Cache a place object for later retrieval
  void cachePlaceObject(Place place) {
    _placeCache[place.id] = place;
    debugPrint('💾 Cached place: ${place.name} (${place.id})');
  }
  
  /// Get a cached place object
  Place? getCachedPlace(String placeId) {
    return _placeCache[placeId];
  }
  
  /// Clear the place cache
  void clearPlaceCache() {
    _placeCache.clear();
    _exploreCardPhotoFutures.clear();
    _placeDetailsMemoryCache.clear();
    _placeDetailsInflight.clear();
    _searchMemoryCache.clear();
    _searchCacheTimestamps.clear();
    _searchInflight.clear();
    debugPrint('🗑️ Cleared place cache');
  }

  String _normalizedGooglePlaceIdForDetails(String placeId) {
    final t = placeId.trim();
    if (t.startsWith('google_')) {
      return t.substring('google_'.length);
    }
    return t;
  }

  static List<String> mergeUniquePhotoUrls(
    Iterable<String> primary,
    Iterable<String> secondary, {
    int maxPhotos = 10,
  }) {
    final seen = <String>{};
    final out = <String>[];
    for (final u in [...primary, ...secondary]) {
      if (u.isEmpty || seen.contains(u)) continue;
      seen.add(u);
      out.add(u);
      if (out.length >= maxPhotos) break;
    }
    return out;
  }

  /// Resolves up to [maxPhotos] URLs for Explore cards. Bypasses [getPlaceById] cache
  /// so Google-backed places get the full gallery from the details API when the hub
  /// only sent a single preview photo.
  Future<List<String>> resolveExploreCardPhotos(
    Place place, {
    int maxPhotos = 10,
  }) async {
    if (!place.id.startsWith('google_')) {
      return place.photos.take(maxPhotos).toList();
    }
    if (place.photos.length >= maxPhotos) {
      return place.photos.take(maxPhotos).toList();
    }
    return _exploreCardPhotoFutures.putIfAbsent(place.id, () async {
      try {
        final urls = await fetchPhotoUrlsForGooglePlace(place.id);
        if (urls.isNotEmpty) {
          return mergeUniquePhotoUrls(urls, place.photos, maxPhotos: maxPhotos);
        }
      } catch (e) {
        debugPrint('❌ resolveExploreCardPhotos failed for ${place.id}: $e');
      }
      return place.photos.take(maxPhotos).toList();
    });
  }

  Future<void> _initializePlaces() async {
    if (_isInitialized) return;

    final apiKey = ApiKeys.googlePlacesKey;
    debugPrint('📍 Using Places API key: ${apiKey.substring(0, min(8, apiKey.length))}...');
    
    _places = GoogleMapsPlaces(apiKey: apiKey);
    _isInitialized = true;
    debugPrint('✅ Places service initialized with API key');
  }

  int min(int a, int b) => a < b ? a : b;

  /// Format review timestamp to relative time
  String _formatReviewTime(int timestamp) {
    final reviewDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(reviewDate);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return 'Recently';
    }
  }

  /// Search for places via the Supabase `places` edge function (server-side Google call).
  ///
  /// Results are cached in memory for 7 days per query+language.
  /// Concurrent calls for the same query share one edge invocation.
  Future<List<PlacesSearchResult>> searchPlaces(
    String query, {
    String? language,
  }) async {
    final lang = language ??
        PlacesCacheUtils.normalizeExploreLanguageCode(
          ref.read(localeProvider)?.languageCode ??
              ui.PlatformDispatcher.instance.locale.languageCode,
        );
    final cacheKey = '$query|$lang';

    final ts = _searchCacheTimestamps[cacheKey];
    if (ts != null && DateTime.now().difference(ts) < _searchCacheTtl) {
      final cached = _searchMemoryCache[cacheKey];
      if (cached != null) {
        if (kDebugMode) debugPrint('💾 searchPlaces cache hit: $query ($lang)');
        return cached;
      }
    }

    final fut = _searchInflight.putIfAbsent(
      cacheKey,
      () => _searchPlacesViaEdge(query, lang).then((r) {
            if (r.isNotEmpty) {
              _searchMemoryCache[cacheKey] = r;
              _searchCacheTimestamps[cacheKey] = DateTime.now();
            }
            return r;
          }).whenComplete(() {
            _searchInflight.remove(cacheKey);
          }),
    );
    return fut;
  }

  Future<List<PlacesSearchResult>> _searchPlacesViaEdge(
    String query,
    String lang,
  ) async {
    if (kDebugMode) debugPrint('🔍 searchPlaces via edge: $query ($lang)');

    try {
      final supabase = Supabase.instance.client;
      final fnResponse = await supabase.functions.invoke(
        'places',
        body: {
          'type': 'search',
          'query': query,
          'language': lang,
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Edge search timed out');
      });

      if (fnResponse.status != 200) {
        debugPrint('❌ Edge search error ${fnResponse.status}');
        return [];
      }

      final outer = fnResponse.data as Map<String, dynamic>?;
      final data = (outer?['data'] as Map<String, dynamic>?) ?? {};
      final status = data['status'] as String?;

      if (status != 'OK') {
        if (kDebugMode) debugPrint('❌ Edge search status: $status');
        return [];
      }

      final parsed = PlacesSearchResponse.fromJson(data);
      if (kDebugMode) {
        debugPrint('✅ Edge search: ${parsed.results.length} results for "$query"');
      }
      return parsed.results;
    } catch (e) {
      debugPrint('❌ searchPlaces edge error: $e');
      return [];
    }
  }

  /// Get detailed place information by place ID via the Supabase `places` edge function.
  /// Routes server-side so the Google API key is never exposed on the client.
  ///
  /// Deduplicates concurrent calls and caches successful responses in memory for the session
  /// so one open of place detail (photos + description + reviews + Moody) does not multiply
  /// billable Google Details requests.
  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final raw = _normalizedGooglePlaceIdForDetails(placeId);
    if (raw.isEmpty) return {};

    final lang = PlacesCacheUtils.normalizeExploreLanguageCode(
      ref.read(localeProvider)?.languageCode ??
          ui.PlatformDispatcher.instance.locale.languageCode,
    );
    final cacheKey = '$raw|$lang';

    final mem = _placeDetailsMemoryCache[cacheKey];
    if (mem != null) return mem;

    final fut = _placeDetailsInflight.putIfAbsent(
      cacheKey,
      () => _getPlaceDetailsFromEdge(raw, lang).then((r) {
            if (r.isNotEmpty) _placeDetailsMemoryCache[cacheKey] = r;
            return r;
          }).whenComplete(() {
            _placeDetailsInflight.remove(cacheKey);
          }),
    );
    return fut;
  }

  Future<Map<String, dynamic>> _getPlaceDetailsFromEdge(
    String rawPlaceId,
    String lang,
  ) async {
    debugPrint('🏷️ Getting details for place: $rawPlaceId');

    try {
      final supabase = Supabase.instance.client;
      final fnResponse = await supabase.functions.invoke(
        'places',
        body: {
          'type': 'details',
          'placeId': rawPlaceId,
          'language': lang,
        },
      );

      if (fnResponse.status != 200) {
        debugPrint('❌ Edge function error ${fnResponse.status}: ${fnResponse.data}');
        return {};
      }

      // Edge function wraps Google response as { success, data: { result, status } }
      final outer = fnResponse.data as Map<String, dynamic>?;
      final data = (outer?['data'] as Map<String, dynamic>?) ?? outer ?? {};

      final status = data['status'] as String?;
      debugPrint('🏷️ Place details status: $status');

      if (status != 'OK') {
        debugPrint('❌ Details error: ${data['error_message'] ?? status}');
        return {};
      }

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) {
        debugPrint('❌ Place details result is null');
        return {};
      }

      // Safely extract photos
      final photoReferences = <String>[];
      final photosRaw = result['photos'] as List<dynamic>?;
      if (photosRaw != null) {
        for (final photo in photosRaw) {
          final ref = (photo as Map<String, dynamic>?)?['photo_reference'] as String?;
          if (ref != null && ref.isNotEmpty) photoReferences.add(ref);
        }
      }

      // Safely extract reviews
      final reviews = <Map<String, dynamic>>[];
      final reviewsRaw = result['reviews'] as List<dynamic>?;
      if (reviewsRaw != null) {
        for (final review in reviewsRaw) {
          final r = review as Map<String, dynamic>?;
          if (r == null) continue;
          final time = r['time'] as num?;
          reviews.add({
            'author_name': r['author_name'] as String? ?? 'Anonymous',
            'rating': r['rating'] as num? ?? 0,
            'text': r['text'] as String? ?? '',
            'time': time ?? 0,
            'relative_time_description': time != null ? _formatReviewTime(time.toInt()) : 'Recently',
          });
        }
        debugPrint('✅ Extracted ${reviews.length} real reviews from Google Places API');
      } else {
        debugPrint('⚠️ No reviews available for this place');
      }

      // Safely extract location
      final geometry = result['geometry'] as Map<String, dynamic>?;
      final locationRaw = geometry?['location'] as Map<String, dynamic>?;

      // open_now from Google uses device local time (correct for user's timezone e.g. NL)
      final openingHours = result['opening_hours'] as Map<String, dynamic>?;
      final openNow = openingHours?['open_now'] as bool? ?? false;

      // editorial_summary gives a short human-readable overview in the requested language
      final editorialSummary = result['editorial_summary'] as Map<String, dynamic>?;
      final description = editorialSummary?['overview'] as String? ??
          result['vicinity'] as String? ?? '';

      final details = {
        'name': result['name'] as String? ?? '',
        'address': result['formatted_address'] as String? ?? '',
        'description': description,
        'rating': result['rating'] as num?,
        'user_ratings_total': reviews.length,
        'reviews': reviews,
        'photos': photoReferences,
        'types': (result['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        'priceLevel': result['price_level'] as int?,
        'location': locationRaw != null ? {
          'lat': locationRaw['lat'] as num? ?? 0.0,
          'lng': locationRaw['lng'] as num? ?? 0.0,
        } : null,
        'open_now': openNow,
        'website': result['website'] as String?,
        'phone_number': result['formatted_phone_number'] as String?,
      };

      debugPrint('✅ Got details for ${result['name']} with ${photoReferences.length} photos and ${reviews.length} reviews');
      return details;
    } catch (e) {
      debugPrint('❌ Failed to get place details: $e');
      return {};
    }
  }

  /// Photo URLs for a Google-backed place (bypasses in-memory place cache so cards/hero get full galleries).
  Future<List<String>> fetchPhotoUrlsForGooglePlace(String placeId) async {
    if (!_isInitialized) {
      await build();
    }
    final raw = placeId.startsWith('google_') ? placeId.substring('google_'.length) : placeId;
    if (raw.isEmpty) return [];
    try {
      final details = await getPlaceDetails(raw);
      final refs = (details['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final urls = <String>[];
      for (final ref in refs.take(10)) {
        if (ref.isEmpty) continue;
        try {
          urls.add(getPhotoUrl(ref));
        } catch (_) {}
      }
      return urls;
    } catch (e) {
      debugPrint('❌ fetchPhotoUrlsForGooglePlace failed: $e');
      return [];
    }
  }

  /// Get place by ID (can be either a place ID or an index for hardcoded places)
  Future<Place> getPlaceById(String placeId) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Places service not initialized, initializing now...');
      await build();
    }

    try {
      // First, check if we have this place cached from search results
      final cachedPlace = getCachedPlace(placeId);
      if (cachedPlace != null) {
        debugPrint('✅ Using cached place data for: ${cachedPlace.name}');
        return cachedPlace;
      }
      
      // Check if this is a Google Place ID or our internal ID
      if (placeId.startsWith('google_')) {
        // It's a Google Place ID - fetch from API as fallback
        debugPrint('🔄 Place not cached, fetching from Google API: $placeId');
        final googlePlaceId = placeId.substring('google_'.length);
        final details = await getPlaceDetails(googlePlaceId);
        
        // Check if details are valid
        if (details.isEmpty || details['name'] == null) {
          debugPrint('❌ Empty/invalid place details returned for $googlePlaceId');
          throw Exception('Could not fetch place details - data unavailable');
        }
        
        // Safely extract all fields with proper null handling
        final name = details['name'] as String?;
        if (name == null || name.isEmpty) {
          debugPrint('❌ Invalid place name for $googlePlaceId');
          throw Exception('Place name is required');
        }
        
        final address = details['address'] as String? ?? 'No address available';
        final description = details['description'] as String? ?? '';
        final rating = (details['rating'] as num?)?.toDouble() ?? 0.0;
        final placeTypes = (details['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final priceLevel = details['priceLevel'] as int?;
        
        final isFree = ExplorePlaceCardCopy.inferIsFreeFromDetails(
          types: placeTypes,
          priceLevel: priceLevel,
        );
        
        // Generate price range string if not free
        String? priceRange;
        if (!isFree && priceLevel != null) {
          switch (priceLevel) {
            case 1:
              priceRange = '€5-15';
              break;
            case 2:
              priceRange = '€15-30';
              break;
            case 3:
              priceRange = '€30-50';
              break;
            case 4:
              priceRange = '€50+';
              break;
          }
        }
        
        // Safely extract location
        final locationData = details['location'];
        double lat = 0.0;
        double lng = 0.0;
        if (locationData != null && locationData is Map<String, dynamic>) {
          lat = (locationData['lat'] as num?)?.toDouble() ?? 0.0;
          lng = (locationData['lng'] as num?)?.toDouble() ?? 0.0;
        }
        
        // Get photos and convert to URLs
        final photoReferences = (details['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final photoUrls = <String>[];
        for (final ref in photoReferences.take(10)) {
          if (ref.isNotEmpty) {
            try {
              final photoUrl = getPhotoUrl(ref);
              photoUrls.add(photoUrl);
              debugPrint('✅ Generated photo URL for place');
            } catch (e) {
              debugPrint('⚠️ Could not get photo URL for $ref: $e');
            }
          }
        }
        
        debugPrint('✅ Successfully created Place object: $name with ${photoUrls.length} photos, priceLevel=$priceLevel, isFree=$isFree');
        
        return Place(
          id: placeId,
          name: name,
          address: address,
          description: description.isNotEmpty ? description : null,
          rating: rating,
          photos: photoUrls,
          types: placeTypes,
          location: PlaceLocation(lat: lat, lng: lng),
          openingHours: OpeningHoursService.generateOpeningHours(placeTypes),
          priceLevel: priceLevel,
          priceRange: priceRange,
          isFree: isFree,
        );
      } else {
        // This is for our hardcoded places
        // Ideally we would fetch this from Supabase
        // For now, we'll return a dummy place
        final dummyPlaces = _getDummyPlaces();
        final place = dummyPlaces.firstWhere(
          (p) => p.id == placeId,
          orElse: () => dummyPlaces[0],
        );
        return place;
      }
    } catch (e) {
      debugPrint('❌ Error getting place by ID: $e');
      // Keep the requested id so navigation, share, and cache keys stay consistent.
      return Place(
        id: placeId,
        name: 'Place details unavailable',
        address: 'We could not load full details. Enable Maps billing or open this spot from Explore after it is cached.',
        location: const PlaceLocation(lat: 0, lng: 0),
      );
    }
  }

  /// Temporary method to get hardcoded places
  List<Place> _getDummyPlaces() {
    return [
      Place(
        id: 'markthal',
        name: 'Markthal Rotterdam',
        address: 'Dominee Jan Scharpstraat 298, 3011 GZ Rotterdam',
        rating: 4.6,
        photos: ['assets/images/philipp-kammerer-6Mxb_mZ_Q8E-unsplash.jpg'],
        types: ['point_of_interest', 'food', 'establishment'],
        location: const PlaceLocation(lat: 51.920, lng: 4.487),
        description: 'Stunning market hall with food stalls and apartments',
        emoji: '🍲',
        tag: 'Food & Culture',
        isAsset: true,
        activities: ['Food Tour', 'Shopping', 'Architecture'],
        openingHours: OpeningHoursService.generateOpeningHours(['food', 'establishment']),
      ),
      Place(
        id: 'fenixfood',
        name: 'Fenix Food Factory',
        address: 'Veerlaan 19D, 3072 AN Rotterdam',
        rating: 4.6,
        photos: ['assets/images/tom-podmore-3mEK924ZuTs-unsplash.jpg'],
        types: ['point_of_interest', 'food', 'establishment'],
        location: const PlaceLocation(lat: 51.898, lng: 4.492),
        description: 'Trendy food hall in historic warehouse',
        emoji: '🍺',
        tag: 'Food & Drinks',
        isAsset: true,
        activities: ['Food Tasting', 'Craft Beer', 'Local Market'],
        openingHours: OpeningHoursService.generateOpeningHours(['restaurant', 'food']),
      ),
      Place(
        id: 'euromast',
        name: 'Euromast Experience',
        address: 'Parkhaven 20, 3016 GM Rotterdam',
        rating: 4.7,
        photos: ['assets/images/pietro-de-grandi-T7K4aEPoGGk-unsplash.jpg'],
        types: ['point_of_interest', 'tourist_attraction'],
        location: const PlaceLocation(lat: 51.905, lng: 4.467),
        description: 'Iconic tower with panoramic city views',
        emoji: '🗼',
        tag: 'Landmark',
        isAsset: true,
        activities: ['Observation', 'Fine Dining', 'Abseiling'],
        openingHours: OpeningHoursService.generateOpeningHours(['tourist_attraction']),
      ),
    ];
  }

  /// Get place photos by photo reference
  String getPhotoUrl(String photoReference) {
    if (!_isInitialized) {
      debugPrint('⚠️ Warning: Getting photo URL before service initialization');
      _initializePlaces();
    }

    return _places.buildPhotoUrl(
      photoReference: photoReference,
      maxWidth: 400,
    );
  }
  
  // Helper to check if place type indicates it's free
  bool _isFreePlaceType(List<String> types) {
    final freeTypes = [
      'park',
      'natural_feature',
      'cemetery',
      'church',
      'mosque',
      'synagogue',
      'hindu_temple',
      'library',
      'public_square',
      'plaza',
      'beach',
      'hiking_area',
      'walking_street',
      'street',
      'route',
      'neighborhood',
      'locality',
    ];
    
    return types.any((type) => 
      freeTypes.any((freeType) => 
        type.toLowerCase().contains(freeType.toLowerCase())
      )
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
} 