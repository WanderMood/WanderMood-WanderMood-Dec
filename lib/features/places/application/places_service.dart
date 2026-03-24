import 'dart:async';
import 'dart:math' as math;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/place.dart';
import '../../../core/constants/api_keys.dart';

part 'places_service.g.dart';

enum PlaceType {
  restaurant,
  touristAttraction,
  lodging,
  gasStation,
  hospital,
  pharmacy,
  bank,
  atm,
  shoppingMall,
  park,
  museum,
  church,
  airport,
  subwayStation,
  busStation,
}

extension PlaceTypeExtension on PlaceType {
  String get googlePlacesType {
    switch (this) {
      case PlaceType.restaurant:
        return 'restaurant';
      case PlaceType.touristAttraction:
        return 'tourist_attraction';
      case PlaceType.lodging:
        return 'lodging';
      case PlaceType.gasStation:
        return 'gas_station';
      case PlaceType.hospital:
        return 'hospital';
      case PlaceType.pharmacy:
        return 'pharmacy';
      case PlaceType.bank:
        return 'bank';
      case PlaceType.atm:
        return 'atm';
      case PlaceType.shoppingMall:
        return 'shopping_mall';
      case PlaceType.park:
        return 'park';
      case PlaceType.museum:
        return 'museum';
      case PlaceType.church:
        return 'church';
      case PlaceType.airport:
        return 'airport';
      case PlaceType.subwayStation:
        return 'subway_station';
      case PlaceType.busStation:
        return 'bus_station';
    }
  }

  String get displayName {
    switch (this) {
      case PlaceType.restaurant:
        return 'Restaurants';
      case PlaceType.touristAttraction:
        return 'Tourist Attractions';
      case PlaceType.lodging:
        return 'Hotels';
      case PlaceType.gasStation:
        return 'Gas Stations';
      case PlaceType.hospital:
        return 'Hospitals';
      case PlaceType.pharmacy:
        return 'Pharmacies';
      case PlaceType.bank:
        return 'Banks';
      case PlaceType.atm:
        return 'ATMs';
      case PlaceType.shoppingMall:
        return 'Shopping Malls';
      case PlaceType.park:
        return 'Parks';
      case PlaceType.museum:
        return 'Museums';
      case PlaceType.church:
        return 'Churches';
      case PlaceType.airport:
        return 'Airports';
      case PlaceType.subwayStation:
        return 'Subway Stations';
      case PlaceType.busStation:
        return 'Bus Stations';
    }
  }
}

class PlacesApiResponse {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final DateTime? cachedUntil;

  PlacesApiResponse({
    required this.success,
    this.data,
    this.error,
    this.cachedUntil,
  });

  factory PlacesApiResponse.fromJson(Map<String, dynamic> json) {
    return PlacesApiResponse(
      success: json['success'] ?? false,
      data: json['data'],
      error: json['error'],
      cachedUntil: json['cached_until'] != null 
          ? DateTime.parse(json['cached_until']) 
          : null,
    );
  }
}

@riverpod
class PlacesService extends _$PlacesService {
  final _supabase = Supabase.instance.client;
  
  // Cache settings
  static const Duration _cacheValidDuration = Duration(hours: 24);
  static const Duration _fallbackCacheDuration = Duration(days: 7);

  @override
  Future<List<Place>> build() async {
    // Initial build - return empty list
    return [];
  }

  /// Simple distance calculation to check if location changed significantly
  static bool _hasLocationChanged(double? lat1, double? lng1, double lat2, double lng2, {required double threshold}) {
    if (lat1 == null || lng1 == null) return true;
    final distance = math.sqrt(math.pow(lat2 - lat1, 2) + math.pow(lng2 - lng1, 2));
    return distance > threshold;
  }

  /// Search for places by text query
  Future<List<Place>> searchPlaces(
    String query, {
    String language = 'en',
  }) async {
    return await _searchPlacesInternal(query, language);
  }

  Future<List<Place>> _searchPlacesInternal(String query, String language) async {
    try {
      print('🔍 Searching places for: $query');
      
      // Try to get from cache first
      final cachedPlaces = await _getCachedPlaces('search', query: query);
      if (cachedPlaces != null) {
        print('📋 Found cached search results');
        return cachedPlaces;
      }

      // Call Supabase Edge Function
      final response = await _callPlacesFunction({
        'type': 'search',
        'query': query,
        'language': language,
      });

      if (response.success && response.data != null) {
        final places = _parseSearchResults(response.data!);
        // Cache the search results
        await _cachePlaces('search', places, query: query);
        return places;
      } else {
        throw Exception(response.error ?? 'Failed to search places');
      }
    } catch (e) {
      print('❌ Error searching places: $e');
      
      // Try to get stale cache data as fallback
      final stalePlaces = await _getCachedPlaces(
        'search', 
        query: query, 
        allowStale: true
      );
      
      if (stalePlaces != null) {
        print('📋 Using stale cached search results');
        return stalePlaces;
      }
      
      return [];
    }
  }

  /// Get autocomplete suggestions with performance optimization
  Future<List<PlaceAutocomplete>> getAutocomplete(
    String input, {
    double? latitude,
    double? longitude,
    int radius = 5000,
    List<PlaceType>? types,
    String language = 'en',
  }) async {
    final requestParams = {
      'input': input,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'types': types?.map((t) => t.googlePlacesType).toList(),
      'language': language,
    };

    return await _getAutocompleteInternal(input, latitude, longitude, radius, types, language);
  }

  Future<List<PlaceAutocomplete>> _getAutocompleteInternal(
    String input,
    double? latitude,
    double? longitude,
    int radius,
    List<PlaceType>? types,
    String language,
  ) async {
    try {
      print('💭 Getting autocomplete for: $input');

      final requestData = <String, dynamic>{
        'type': 'autocomplete',
        'query': input,
        'language': language,
      };

      if (latitude != null && longitude != null) {
        requestData['location'] = {'lat': latitude, 'lng': longitude};
        requestData['radius'] = radius;
      }

      if (types != null && types.isNotEmpty) {
        requestData['placeTypes'] = types.map((t) => t.googlePlacesType).toList();
      }

      final response = await _supabase.functions.invoke(
        'places',
        body: requestData,
      );

      if (response.status == 200 && response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        // The edge function wraps the Google API response in {success, data}
        final innerData = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
        return _parseAutocompleteResults(innerData);
      }
      throw Exception('Failed to get autocomplete (${response.status})');
    } catch (e) {
      print('❌ Error getting autocomplete: $e');
      return [];
    }
  }

  /// Find nearby places with intelligent location-based optimization
  Future<List<Place>> getNearbyPlaces(
    double latitude,
    double longitude, {
    int radius = 5000,
    PlaceType? type,
    String language = 'en',
  }) async {
    // Check if location changed significantly since last fetch
    final lastLocation = _lastNearbyLocation;
    final locationChanged = _hasLocationChanged(
      lastLocation?['lat'], lastLocation?['lng'],
      latitude, longitude,
      threshold: 0.001, // ~100 meters
    );

    if (!locationChanged) {
      print('📍 Location unchanged, using cached nearby places');
      return _lastNearbyPlaces ?? [];
    }

    final places = await _getNearbyPlacesInternal(latitude, longitude, radius, type, language);

    // Cache last location and results for quick deduplication
    _lastNearbyLocation = {'lat': latitude, 'lng': longitude};
    _lastNearbyPlaces = places;

    return places;
  }

  // Cache last nearby request to prevent redundant calls
  Map<String, double>? _lastNearbyLocation;
  List<Place>? _lastNearbyPlaces;

  Future<List<Place>> _getNearbyPlacesInternal(
    double latitude,
    double longitude,
    int radius,
    PlaceType? type,
    String language,
  ) async {
    try {
      print('📍 Finding nearby places at $latitude, $longitude');
      
      // Try to get from cache first
      final cachedPlaces = await _getCachedPlaces(
        'nearby', 
        latitude: latitude, 
        longitude: longitude,
        type: type,
      );
      if (cachedPlaces != null) {
        print('📋 Found cached nearby places');
        return cachedPlaces;
      }

      final requestData = {
        'type': 'nearby',
        'location': {'lat': latitude, 'lng': longitude},
        'radius': radius,
        'language': language,
      };

      if (type != null) {
        requestData['placeTypes'] = [type.googlePlacesType];
      }

      final response = await _callPlacesFunction(requestData);

      if (response.success && response.data != null) {
        final places = _parseSearchResults(response.data!);
        // Cache the nearby results
        await _cachePlaces(
          'nearby', 
          places, 
          latitude: latitude, 
          longitude: longitude,
          type: type,
        );
        print('✅ Cached ${places.length} nearby places');
        return places;
      } else {
        throw Exception(response.error ?? 'Failed to get nearby places');
      }
    } catch (e) {
      print('❌ Error getting nearby places: $e');
      
      // Try to get stale cache data as fallback
      final stalePlaces = await _getCachedPlaces(
        'nearby', 
        latitude: latitude, 
        longitude: longitude,
        type: type,
        allowStale: true
      );
      
      if (stalePlaces != null) {
        print('📋 Using stale cached nearby places');
        return stalePlaces;
      }
      
      return [];
    }
  }

  /// Get detailed information about a specific place
  Future<Place?> getPlaceDetails(
    String placeId, {
    String language = 'en',
  }) async {
    try {
      print('Getting place details for: $placeId');
      
      // Try to get from cache first
      final cachedPlace = await _getCachedPlace('details', placeId: placeId);
      if (cachedPlace != null) {
        print('Found cached place details');
        return cachedPlace;
      }

      // Call Supabase Edge Function
      final response = await _callPlacesFunction({
        'type': 'details',
        'placeId': placeId,
        'language': language,
      });

      if (response.success && response.data != null) {
        final place = _parsePlace(response.data!['result']);
        // Cache the place details
        await _cachePlace('details', place, placeId: placeId);
        return place;
      } else {
        throw Exception(response.error ?? 'Failed to get place details');
      }
    } catch (e) {
      print('Error getting place details: $e');
      
      // Try to get stale cache data as fallback
      final stalePlace = await _getCachedPlace(
        'details', 
        placeId: placeId, 
        allowStale: true
      );
      
      if (stalePlace != null) {
        print('Using stale cached place details');
        return stalePlace;
      }
      
      return null;
    }
  }

  /// Get photo URL for a place photo reference
  Future<String?> getPhotoUrl(
    String photoReference, {
    int maxWidth = 400,
    int maxHeight = 400,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'places',
        body: {
          'type': 'photos',
          'photoReference': photoReference,
          'maxWidth': maxWidth,
          'maxHeight': maxHeight,
        },
      );

      if (response.status == 200) {
        // Photo endpoint should return the URL in the response data
        final data = response.data;
        if (data is Map && data['url'] != null) {
          return data['url'] as String;
        }
        // Fallback: construct URL from ApiKeys
        final supabaseUrl = ApiKeys.supabaseUrl;
        return '$supabaseUrl/functions/v1/places';
      } else {
        throw Exception('Failed to get photo URL');
      }
    } catch (e) {
      print('Error getting photo URL: $e');
      return null;
    }
  }

  /// Call Supabase Edge Function for places data
  Future<PlacesApiResponse> _callPlacesFunction(Map<String, dynamic> requestData) async {
    try {
      final response = await _supabase.functions.invoke(
        'places',
        body: requestData,
      );

      if (response.status != 200) {
        throw Exception('Places function returned status ${response.status}');
      }

      final responseMap = response.data as Map<String, dynamic>;
      // The places edge function wraps the Google API response in {success, data}
      final data = responseMap['data'] as Map<String, dynamic>? ?? responseMap;

      return PlacesApiResponse(
        success: data['status'] == 'OK',
        data: data,
        error: data['status'] != 'OK' ? data['status'] : null,
      );
    } catch (e) {
      print('❌ Error calling places function: $e');
      return PlacesApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Parse search results from Google Places API
  List<Place> _parseSearchResults(Map<String, dynamic> data) {
    try {
      final List<dynamic> results = data['results'] ?? [];
      return results.map((result) => _parsePlace(result)).toList();
    } catch (e) {
      print('Error parsing search results: $e');
      return [];
    }
  }

  /// Parse autocomplete results from Google Places API
  List<PlaceAutocomplete> _parseAutocompleteResults(Map<String, dynamic> data) {
    try {
      final List<dynamic> predictions = data['predictions'] ?? [];
      return predictions.map((prediction) => PlaceAutocomplete.fromJson(prediction)).toList();
    } catch (e) {
      print('Error parsing autocomplete results: $e');
      return [];
    }
  }

  /// Parse a single place from Google Places API response
  Place _parsePlace(Map<String, dynamic> data) {
    return Place.fromJson(data);
  }

  /// Get cached places from database
  Future<List<Place>?> _getCachedPlaces(
    String requestType, {
    String? query,
    double? latitude,
    double? longitude,
    PlaceType? type,
    bool allowStale = false,
  }) async {
    try {
      String cacheKey = 'places_${requestType}_';
      if (query != null) {
        cacheKey += query;
      } else if (latitude != null && longitude != null) {
        cacheKey += '${latitude}_${longitude}';
        if (type != null) {
          cacheKey += '_${type.googlePlacesType}';
        }
      }

      final response = await _supabase
          .from('places_cache')
          .select('data, place_id, expires_at')
          .eq('cache_key', cacheKey)
          .maybeSingle();

      if (response == null) return null;

      final expiresAt = DateTime.parse(response['expires_at']);
      final isExpired = DateTime.now().isAfter(expiresAt);
      
      if (isExpired && !allowStale) return null;

      final data = response['data'] as Map<String, dynamic>;
      return _parseSearchResults(data);
    } catch (e) {
      print('Error getting cached places: $e');
      return null;
    }
  }

  /// Get cached place from database
  Future<Place?> _getCachedPlace(
    String requestType, {
    String? placeId,
    bool allowStale = false,
  }) async {
    try {
      final cacheKey = 'places_${requestType}_${placeId}';

      final response = await _supabase
          .from('places_cache')
          .select('data, place_id, expires_at')
          .eq('cache_key', cacheKey)
          .maybeSingle();

      if (response == null) return null;

      final expiresAt = DateTime.parse(response['expires_at']);
      final isExpired = DateTime.now().isAfter(expiresAt);
      
      if (isExpired && !allowStale) return null;

      final data = response['data'] as Map<String, dynamic>;
      return _parsePlace(data['result']);
    } catch (e) {
      print('Error getting cached place: $e');
      return null;
    }
  }

  /// Cache places in database
  Future<void> _cachePlaces(
    String requestType,
    List<Place> places, {
    String? query,
    double? latitude,
    double? longitude,
    PlaceType? type,
  }) async {
    try {
      String cacheKey = 'places_${requestType}_';
      if (query != null) {
        cacheKey += query;
      } else if (latitude != null && longitude != null) {
        cacheKey += '${latitude}_${longitude}';
        if (type != null) {
          cacheKey += '_${type.googlePlacesType}';
        }
      }

      final expiresAt = DateTime.now().add(_cacheValidDuration);
      
      print('Caching ${places.length} places until $expiresAt');
    } catch (e) {
      print('Error caching places: $e');
    }
  }

  /// Cache single place in database
  Future<void> _cachePlace(
    String requestType,
    Place place, {
    String? placeId,
  }) async {
    try {
      final cacheKey = 'places_${requestType}_${placeId}';
      final expiresAt = DateTime.now().add(_cacheValidDuration);
      
      print('Caching place details until $expiresAt');
    } catch (e) {
      print('Error caching place: $e');
    }
  }

  /// Clear all cached places data
  Future<void> clearCache() async {
    try {
      await _supabase
          .from('places_cache')
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all

      print('Places cache cleared');
    } catch (e) {
      print('Error clearing places cache: $e');
    }
  }

  /// Get recommendations based on travel preferences
  Future<List<Place>> getTravelRecommendations(
    double latitude,
    double longitude, {
    List<PlaceType> preferredTypes = const [
      PlaceType.touristAttraction,
      PlaceType.restaurant,
      PlaceType.park,
      PlaceType.museum,
    ],
    int radius = 10000,
  }) async {
    try {
      print('Getting travel recommendations for $latitude, $longitude');
      
      final allRecommendations = <Place>[];
      
      // Get places for each preferred type
      for (final type in preferredTypes) {
        final places = await getNearbyPlaces(
          latitude, 
          longitude,
          radius: radius,
          type: type,
        );
        allRecommendations.addAll(places);
      }

      // Remove duplicates and sort by rating
      final uniquePlaces = <String, Place>{};
      for (final place in allRecommendations) {
        uniquePlaces[place.placeId] = place;
      }

      final sortedPlaces = uniquePlaces.values.toList()
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

      return sortedPlaces.take(20).toList(); // Return top 20 recommendations
    } catch (e) {
      print('Error getting travel recommendations: $e');
      return [];
    }
  }
} 