import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'smart_api_cache.dart';
import '../config/api_config.dart';
import '../constants/api_keys.dart';

class GooglePlace {
  final String placeId;
  final String name;
  final String? vicinity;
  final double? rating;
  final int? userRatingsTotal; // Tourism platform popularity indicator
  final List<String> types;
  final String? photoReference;
  final List<String> photoReferences;
  final double? lat;
  final double? lng;
  final int? priceLevel;
  final bool? openNow;
  final String? businessStatus;
  final String? formattedAddress;
  final String? phoneNumber;
  final String? website;

  GooglePlace({
    required this.placeId,
    required this.name,
    this.vicinity,
    this.rating,
    this.userRatingsTotal,
    this.types = const [],
    this.photoReference,
    this.photoReferences = const [],
    this.lat,
    this.lng,
    this.priceLevel,
    this.openNow,
    this.businessStatus,
    this.formattedAddress,
    this.phoneNumber,
    this.website,
  });

  factory GooglePlace.fromNewApiJson(Map<String, dynamic> json) {
    final List<String> allPhotoRefs = [];
    if (json['photos'] != null) {
      for (final photo in json['photos']) {
        if (photo['name'] != null) {
          allPhotoRefs.add(photo['name']);
        }
      }
    }

    return GooglePlace(
      placeId: json['id'] ?? '',
      name: json['displayName']?['text'] ?? 'Unknown Place',
      vicinity: json['shortFormattedAddress'],
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['userRatingCount'],
      types: List<String>.from(json['types'] ?? []),
      photoReference: allPhotoRefs.isNotEmpty ? allPhotoRefs.first : null,
      photoReferences: allPhotoRefs,
      lat: json['location']?['latitude']?.toDouble(),
      lng: json['location']?['longitude']?.toDouble(),
      priceLevel: json['priceLevel'] != null ? _parsePriceLevel(json['priceLevel']) : null,
      openNow: json['currentOpeningHours']?['openNow'],
      businessStatus: json['businessStatus'],
      formattedAddress: json['formattedAddress'],
      phoneNumber: json['nationalPhoneNumber'],
      website: json['websiteUri'],
    );
  }

  static int _parsePriceLevel(String priceLevel) {
    switch (priceLevel) {
      case 'PRICE_LEVEL_FREE':
        return 0;
      case 'PRICE_LEVEL_INEXPENSIVE':
        return 1;
      case 'PRICE_LEVEL_MODERATE':
        return 2;
      case 'PRICE_LEVEL_EXPENSIVE':
        return 3;
      case 'PRICE_LEVEL_VERY_EXPENSIVE':
        return 4;
      default:
        return 0;
    }
  }

  /// Get the best available photo URL for this place using Legacy API (WORKING!)
  /// Returns only Google Places API photos - NO fallbacks
  static String getBestPhotoUrl(
    String? photoReference, 
    List<String> placeTypes, {
    String? placeName,
    String? placeId,
  }) {
    if (kDebugMode) debugPrint('🔍 getBestPhotoUrl called with:');
    if (kDebugMode) debugPrint('   📷 photoReference: ${photoReference ?? "null"}');
    if (kDebugMode) debugPrint('   🏷️ placeTypes: $placeTypes');
    if (kDebugMode) debugPrint('   🏢 placeName: ${placeName ?? "not provided"}');
    if (kDebugMode) debugPrint('   🆔 placeId: ${placeId ?? "not provided"}');
    
    // Return Google Places API photo URL ONLY if photo reference exists
    if (photoReference != null && photoReference.isNotEmpty) {
      // Check if this is a NEW API photo reference (starts with "places/")
      if (photoReference.startsWith('places/')) {
        if (kDebugMode) debugPrint('🔄 NEW API photo reference detected, conversion to Legacy needed');
        // For NEW API references, we need async conversion to Legacy format
        // Return placeholder for now - this will be handled by async methods
        return '';
      } else {
        // This is already a Legacy API photo reference - use it directly
        final photoUrl = GooglePlacesService.getPhotoUrl(photoReference, 800, 600, placeId);
        if (kDebugMode) debugPrint('✅ Using Legacy Google Places API photo: $photoUrl');
        return photoUrl;
      }
    }
    
    // No photo reference available - return empty string
    if (kDebugMode) debugPrint('❌ No photo reference available');
    return '';
  }

  /// Get the best available photo URL for this place (ASYNC - handles NEW API conversion)
  /// This method can convert NEW API photo references to Legacy API format
  static Future<String> getBestPhotoUrlAsync(
    String? photoReference, 
    List<String> placeTypes, {
    String? placeName,
    String? placeId,
  }) async {
    if (kDebugMode) debugPrint('🔍 getBestPhotoUrlAsync called with:');
    if (kDebugMode) debugPrint('   📷 photoReference: ${photoReference ?? "null"}');
    if (kDebugMode) debugPrint('   🆔 placeId: ${placeId ?? "not provided"}');
    
    // Return Google Places API photo URL ONLY if photo reference exists
    if (photoReference != null && photoReference.isNotEmpty) {
      // Check if this is a NEW API photo reference (starts with "places/")
      if (photoReference.startsWith('places/') && placeId != null && placeId.isNotEmpty) {
        if (kDebugMode) debugPrint('🔄 NEW API photo reference detected, converting to Legacy format');
        // Get Legacy photo reference for this place
        final legacyPhotoRef = await GooglePlacesService.getLegacyPhotoReference(placeId);
        if (legacyPhotoRef != null) {
          final photoUrl = GooglePlacesService.getPhotoUrl(legacyPhotoRef, 800, 600, placeId);
          if (kDebugMode) debugPrint('✅ Using converted Legacy Google Places API photo: $photoUrl');
          return photoUrl;
        } else {
          if (kDebugMode) debugPrint('❌ Could not get Legacy photo reference for place: $placeId');
          return '';
        }
      } else {
        // This is already a Legacy API photo reference - use it directly
        final photoUrl = GooglePlacesService.getPhotoUrl(photoReference, 800, 600, placeId);
        if (kDebugMode) debugPrint('✅ Using Legacy Google Places API photo: $photoUrl');
        return photoUrl;
      }
    }
    
    // No photo reference available - return empty string
    if (kDebugMode) debugPrint('❌ No photo reference available');
    return '';
  }

  /// Get multiple photo URLs for this place
  List<String> getAllPhotoUrls({int maxWidth = 600, int maxPhotos = 3}) {
    return GooglePlacesService.getPhotoUrls(photoReferences, maxWidth: maxWidth, maxPhotos: maxPhotos, placeId: placeId);
  }
}

class GooglePlaceDetails {
  final String placeId;
  final String name;
  final String? formattedAddress;
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final List<String> types;
  final List<String> photoReferences;
  final double? lat;
  final double? lng;
  final int? priceLevel;
  final Map<String, dynamic>? openingHours;

  GooglePlaceDetails({
    required this.placeId,
    required this.name,
    this.formattedAddress,
    this.phoneNumber,
    this.website,
    this.rating,
    this.types = const [],
    this.photoReferences = const [],
    this.lat,
    this.lng,
    this.priceLevel,
    this.openingHours,
  });

  factory GooglePlaceDetails.fromNewApiJson(Map<String, dynamic> json) {
    final List<String> allPhotoRefs = [];
    if (json['photos'] != null) {
      for (final photo in json['photos']) {
        if (photo['name'] != null) {
          allPhotoRefs.add(photo['name']);
        }
      }
    }

    return GooglePlaceDetails(
      placeId: json['id'] ?? '',
      name: json['displayName']?['text'] ?? 'Unknown Place',
      formattedAddress: json['formattedAddress'],
      phoneNumber: json['nationalPhoneNumber'],
      website: json['websiteUri'],
      rating: (json['rating'] as num?)?.toDouble(),
      types: List<String>.from(json['types'] ?? []),
      photoReferences: allPhotoRefs,
      lat: json['location']?['latitude']?.toDouble(),
      lng: json['location']?['longitude']?.toDouble(),
      priceLevel: json['priceLevel'] != null ? GooglePlace._parsePriceLevel(json['priceLevel']) : null,
      openingHours: json['currentOpeningHours'],
    );
  }
}

class GooglePlacesService {
  static const String _baseUrl = 'https://places.googleapis.com/v1/places';
  static String get _apiKey => ApiKeys.googlePlacesKey;
  
  /// Search for places near a location using NEW Places API with smart caching
  static Future<List<GooglePlace>> searchPlaces({
    required String query,
    required double lat,
    required double lng,
    int radius = 5000,
    String type = '',
  }) async {
    final parameters = {
      'query': query,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'type': type,
    };

    // Check cache first
    final cachedResponse = await SmartApiCache.getCachedResponse(
      endpoint: 'nearby_search_new',
      parameters: parameters,
    );

    if (cachedResponse != null) {
      final List<dynamic> results = cachedResponse['places'] ?? [];
      return results.map((result) => GooglePlace.fromNewApiJson(result)).toList();
    }

    // Check if we should make API call
    final shouldCall = await SmartApiCache.shouldMakeApiCall(
      endpoint: 'nearby_search_new',
      parameters: parameters,
    );

    if (!shouldCall) {
      if (kDebugMode) debugPrint('🚫 NEW API call blocked by smart cache system for: $query');
      return [];
    }

    try {
      // Check if API is enabled in configuration
      if (!ApiConfig.shouldUseApi) {
        if (kDebugMode) debugPrint('🚫 Google Places API disabled by configuration');
        return [];
      }

      if (_apiKey.isEmpty || _apiKey == 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
        if (kDebugMode) debugPrint('❌ Google Places API key not configured!');
        if (kDebugMode) debugPrint('🔧 Please update lib/core/constants/api_keys.dart with your Google Places API key');
        if (kDebugMode) debugPrint('📖 Instructions: https://console.cloud.google.com/');
        return [];
      }

      if (kDebugMode) debugPrint('🔍 Making NEW Places API call for: $query near ($lat, $lng)');

      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'places.id,places.displayName,places.shortFormattedAddress,places.rating,places.userRatingCount,places.types,places.photos,places.location,places.priceLevel,places.currentOpeningHours,places.businessStatus,places.formattedAddress,places.nationalPhoneNumber,places.websiteUri',
      };

      final body = jsonEncode({
        'textQuery': '$query near ${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}',
        'locationBias': {
          'circle': {
            'center': {
              'latitude': lat,
              'longitude': lng,
            },
            'radius': radius.toDouble(),
          }
        },
        'maxResultCount': 20,
        'includedType': type.isNotEmpty ? type : null,
      });
      
      final response = await http.post(
        Uri.parse('$_baseUrl:searchText'),
        headers: headers,
        body: body,
      );

      if (kDebugMode) debugPrint('🔍 NEW API Response Status: ${response.statusCode}');
      if (kDebugMode) debugPrint('🔍 NEW API Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
          // Cache the response for future use
          await SmartApiCache.cacheResponse(
          endpoint: 'nearby_search_new',
            parameters: parameters,
            response: data,
          );

        final List<dynamic> results = data['places'] ?? [];
        final places = results.map((result) => GooglePlace.fromNewApiJson(result)).toList();
          
        if (kDebugMode) debugPrint('✅ Found ${places.length} places for: $query (NEW API - CACHED for 30 days)');
        for (final place in places.take(3)) {
          if (kDebugMode) debugPrint('   📍 ${place.name} - Photo: ${place.photoReference != null ? "✅" : "❌"}');
        }
        return places;
      } else {
        if (kDebugMode) debugPrint('❌ NEW API HTTP error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error with NEW Places API: $e');
      return [];
    }
  }

  /// Get detailed information about a specific place using NEW API with smart caching
  static Future<GooglePlaceDetails?> getPlaceDetails(String placeId) async {
    final parameters = {'place_id': placeId};

    // Check cache first
    final cachedResponse = await SmartApiCache.getCachedResponse(
      endpoint: 'place_details_new',
      parameters: parameters,
    );

    if (cachedResponse != null) {
      return GooglePlaceDetails.fromNewApiJson(cachedResponse);
    }

    // Check if we should make API call
    final shouldCall = await SmartApiCache.shouldMakeApiCall(
      endpoint: 'place_details_new',
      parameters: parameters,
    );

    if (!shouldCall) {
      if (kDebugMode) debugPrint('🚫 NEW API place details call blocked by smart cache for: $placeId');
      return null;
    }

    try {
      if (_apiKey.isEmpty) {
        if (kDebugMode) debugPrint('❌ Google Places NEW API key not found');
        return null;
      }

      if (kDebugMode) debugPrint('🔍 Making NEW Places API call for place details: $placeId');

      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,nationalPhoneNumber,websiteUri,rating,types,photos,location,priceLevel,currentOpeningHours',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/$placeId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
          // Cache the response for future use
          await SmartApiCache.cacheResponse(
          endpoint: 'place_details_new',
            parameters: parameters,
            response: data,
          );

        if (kDebugMode) debugPrint('✅ Got place details for: ${data['displayName']?['text']} (NEW API - CACHED for 30 days)');
        return GooglePlaceDetails.fromNewApiJson(data);
      } else {
        if (kDebugMode) debugPrint('❌ NEW API place details error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting place details with NEW API: $e');
      return null;
    }
  }

  /// Search for places using nearby search with NEW API
  static Future<List<GooglePlace>> nearbySearch({
    required double lat,
    required double lng,
    int radius = 5000,
    List<String> includedTypes = const [],
    int maxResults = 20,
  }) async {
    final parameters = {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'types': includedTypes,
      'maxResults': maxResults,
    };

    // Check cache first
    final cachedResponse = await SmartApiCache.getCachedResponse(
      endpoint: 'nearby_search_new',
      parameters: parameters,
    );

    if (cachedResponse != null) {
      final List<dynamic> results = cachedResponse['places'] ?? [];
      return results.map((result) => GooglePlace.fromNewApiJson(result)).toList();
    }

    // Check if we should make API call
    final shouldCall = await SmartApiCache.shouldMakeApiCall(
      endpoint: 'nearby_search_new',
      parameters: parameters,
    );

    if (!shouldCall) {
      if (kDebugMode) debugPrint('🚫 NEW API nearby search blocked by smart cache');
      return [];
    }

    try {
      if (_apiKey.isEmpty) {
        if (kDebugMode) debugPrint('❌ Google Places NEW API key not found');
        return [];
      }

      if (kDebugMode) debugPrint('🔍 Making NEW Places API nearby search at ($lat, $lng)');

      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'places.id,places.displayName,places.shortFormattedAddress,places.rating,places.userRatingCount,places.types,places.photos,places.location,places.priceLevel,places.currentOpeningHours,places.businessStatus',
      };

      final body = jsonEncode({
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': lat,
              'longitude': lng,
            },
            'radius': radius.toDouble(),
          }
        },
        'includedTypes': includedTypes.isNotEmpty ? includedTypes : null,
        'maxResultCount': maxResults,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl:searchNearby'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache the response for future use
        await SmartApiCache.cacheResponse(
          endpoint: 'nearby_search_new',
          parameters: parameters,
          response: data,
        );

        final List<dynamic> results = data['places'] ?? [];
        final places = results.map((result) => GooglePlace.fromNewApiJson(result)).toList();
        
        if (kDebugMode) debugPrint('✅ Found ${places.length} nearby places (NEW API - CACHED for 30 days)');
        return places;
      } else {
        if (kDebugMode) debugPrint('❌ NEW API nearby search error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error with NEW Places API nearby search: $e');
      return [];
    }
  }

  /// Get place photo URL using Legacy Places API - WORKING with current API key!
  /// 
  /// ✅ WORKING: Legacy Places API photos work with current billing tier
  /// This method now uses the Legacy API format that successfully returns photos
  /// 
  /// For NEW API photos (Enterprise tier required):
  /// - Contact Google Cloud Sales to enable Enterprise tier + "Place Details Photos" SKU
  /// 
  /// For now, using Legacy API which works perfectly with current setup
  static String getPhotoUrl(String photoReference, [int? maxWidth, int? maxHeight, String? placeId]) {
    // Handle legacy call format: getPhotoUrl(photoReference, width)
    if (maxHeight == null && maxWidth != null) {
      maxHeight = maxWidth;
    }
    
    // Set defaults
    maxWidth ??= 800;
    maxHeight ??= 600;
    
    if (photoReference.isEmpty || _apiKey.isEmpty) {
      if (kDebugMode) debugPrint('❌ Missing photo reference or API key');
      return '';
    }
    
    // Check if this is a NEW API photo reference format (starts with "places/")
    if (photoReference.startsWith('places/')) {
      if (kDebugMode) debugPrint('🔄 NEW API photo reference detected, need to get Legacy reference for place: $placeId');
      // For NEW API references, we need to get the Legacy photo reference
      // This will be handled by a separate method
      return '';
  }

    // Use Legacy Places API format (WORKING!)
    // Format: https://maps.googleapis.com/maps/api/place/photo?photoreference={PHOTO_REFERENCE}&key={API_KEY}&maxheight={HEIGHT}
    final photoUrl = 'https://maps.googleapis.com/maps/api/place/photo?photoreference=$photoReference&key=$_apiKey&maxheight=$maxHeight';
    
    if (kDebugMode) debugPrint('🔗 Using Legacy API photo URL: $photoUrl');
    return photoUrl;
  }

  /// Get Legacy photo reference for a place (WORKING with current API key)
  static Future<String?> getLegacyPhotoReference(String placeId) async {
    try {
      if (kDebugMode) debugPrint('🔍 Getting Legacy photo reference for place: $placeId');
      
      final response = await http.get(
        Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=photos&key=$_apiKey'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['result']?['photos'];
        
        if (photos != null && photos.isNotEmpty) {
          final photoReference = photos[0]['photo_reference'];
          if (kDebugMode) debugPrint('✅ Got Legacy photo reference: ${photoReference.substring(0, 50)}...');
          return photoReference;
        }
      }
      
      if (kDebugMode) debugPrint('❌ No Legacy photo reference found for place: $placeId');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting Legacy photo reference: $e');
      return null;
    }
  }

  /// Get best photo URL for backward compatibility with existing code
  static String getBestPhotoUrl(String? photoReference, List<String> placeTypes, {String? placeName, String? placeId}) {
    return GooglePlace.getBestPhotoUrl(photoReference, placeTypes, placeName: placeName, placeId: placeId);
  }

  /// Get multiple photo URLs for a place (for variety) - NEW API version
  static List<String> getPhotoUrls(List<String> photoReferences, {int maxWidth = 600, int maxPhotos = 3, String? placeId}) {
    if (placeId == null || placeId.isEmpty) {
      if (kDebugMode) debugPrint('❌ Missing place ID for photo URLs construction');
      return [];
    }
    
    // Return only Google Places API photos
    return photoReferences
        .take(maxPhotos)
        .map((ref) => getPhotoUrl(ref, maxWidth, maxWidth, placeId))
        .where((url) => url.isNotEmpty)
        .toList();
  }

  // Enhanced tourism-focused search strategy with GetYourGuide-style queries
  static const Map<String, List<Map<String, dynamic>>> moodToTourismQueries = {
    'adventure': [
      {'query': 'outdoor activities Rotterdam', 'types': ['tourist_attraction'], 'minRating': 4.0, 'minReviews': 25},
      {'query': 'adventure tours Rotterdam', 'types': ['tourist_attraction'], 'minRating': 4.1, 'minReviews': 20},
      {'query': 'sports activities Rotterdam', 'types': ['amusement_park'], 'minRating': 4.0, 'minReviews': 30},
      {'query': 'active attractions Rotterdam', 'types': ['tourist_attraction'], 'minRating': 4.0, 'minReviews': 15},
      {'query': 'adventure experiences Rotterdam', 'types': ['tourist_attraction'], 'minRating': 4.0, 'minReviews': 10},
    ],
    'relaxed': [
      {'query': 'luxury spa experiences', 'types': ['spa', 'tourist_attraction'], 'minRating': 4.3, 'minReviews': 40},
      {'query': 'beautiful parks gardens', 'types': ['park', 'tourist_attraction'], 'minRating': 4.0, 'minReviews': 30},
      {'query': 'peaceful tourist attractions', 'types': ['tourist_attraction', 'museum'], 'minRating': 4.2, 'minReviews': 25},
      {'query': 'scenic peaceful places', 'types': ['park', 'tourist_attraction'], 'minRating': 4.1, 'minReviews': 20},
      {'query': 'relaxing experiences', 'types': ['spa', 'park'], 'minRating': 4.0, 'minReviews': 15},
    ],
    'romantic': [
      {'query': 'romantic restaurants Rotterdam', 'types': ['restaurant'], 'minRating': 4.3, 'minReviews': 50},
      {'query': 'couples activities Rotterdam', 'types': ['tourist_attraction'], 'minRating': 4.2, 'minReviews': 25},
      {'query': 'romantic bars Rotterdam', 'types': ['bar'], 'minRating': 4.1, 'minReviews': 30},
      {'query': 'scenic viewpoints Rotterdam', 'types': ['tourist_attraction'], 'minRating': 4.0, 'minReviews': 20},
      {'query': 'romantic parks Rotterdam', 'types': ['park'], 'minRating': 4.0, 'minReviews': 15},
    ],
    'energetic': [
      {'query': 'exciting tourist attractions', 'types': ['tourist_attraction', 'amusement_park'], 'minRating': 4.2, 'minReviews': 40},
      {'query': 'fun entertainment venues', 'types': ['amusement_park', 'tourist_attraction'], 'minRating': 4.1, 'minReviews': 35},
      {'query': 'active fun experiences', 'types': ['tourist_attraction', 'amusement_park'], 'minRating': 4.0, 'minReviews': 25},
      {'query': 'energetic attractions', 'types': ['amusement_park', 'bowling_alley'], 'minRating': 4.0, 'minReviews': 30},
    ],
    'excited': [
      {'query': 'top tourist attractions', 'types': ['tourist_attraction', 'museum'], 'minRating': 4.3, 'minReviews': 100},
      {'query': 'must visit attractions', 'types': ['tourist_attraction', 'museum'], 'minRating': 4.4, 'minReviews': 150},
      {'query': 'famous landmarks sights', 'types': ['tourist_attraction', 'park'], 'minRating': 4.2, 'minReviews': 75},
      {'query': 'popular tourist destinations', 'types': ['tourist_attraction', 'amusement_park'], 'minRating': 4.3, 'minReviews': 80},
      {'query': 'iconic attractions', 'types': ['tourist_attraction', 'museum'], 'minRating': 4.2, 'minReviews': 60},
    ],
    'surprise': [
      {'query': 'hidden gem attractions', 'types': ['tourist_attraction', 'museum'], 'minRating': 4.4, 'minReviews': 20},
      {'query': 'unique tourist experiences', 'types': ['tourist_attraction', 'art_gallery'], 'minRating': 4.2, 'minReviews': 15},
      {'query': 'unusual attractions', 'types': ['museum', 'tourist_attraction'], 'minRating': 4.1, 'minReviews': 25},
      {'query': 'secret spots attractions', 'types': ['tourist_attraction', 'park'], 'minRating': 4.3, 'minReviews': 12},
      {'query': 'off beaten path experiences', 'types': ['tourist_attraction', 'art_gallery'], 'minRating': 4.0, 'minReviews': 18},
    ],
    'foody': [
      // High-end culinary experiences
      {'query': 'restaurants Rotterdam', 'types': ['restaurant'], 'minRating': 4.3, 'minReviews': 100},
      {'query': 'local cuisine Rotterdam', 'types': ['restaurant'], 'minRating': 4.2, 'minReviews': 75},
      {'query': 'food markets Rotterdam', 'types': ['tourist_attraction'], 'minRating': 4.0, 'minReviews': 30},
      
      // Food experiences
      {'query': 'cooking classes Rotterdam', 'types': ['tourist_attraction'], 'minRating': 4.2, 'minReviews': 15},
      {'query': 'food tours Rotterdam', 'types': ['tourist_attraction'], 'minRating': 4.1, 'minReviews': 20},
      
      // Popular dining spots
      {'query': 'cafes Rotterdam', 'types': ['cafe'], 'minRating': 4.1, 'minReviews': 40},
      {'query': 'bakeries Rotterdam', 'types': ['bakery'], 'minRating': 4.0, 'minReviews': 30},
      {'query': 'coffee shops Rotterdam', 'types': ['cafe'], 'minRating': 4.0, 'minReviews': 25},
    ],
    'festive': [
      {'query': 'popular nightlife bars', 'types': ['bar', 'night_club'], 'minRating': 4.1, 'minReviews': 50},
      {'query': 'entertainment attractions', 'types': ['tourist_attraction', 'amusement_park'], 'minRating': 4.2, 'minReviews': 40},
      {'query': 'lively venues restaurants', 'types': ['restaurant', 'bar'], 'minRating': 4.1, 'minReviews': 60},
      {'query': 'fun nightlife experiences', 'types': ['bar', 'night_club'], 'minRating': 4.0, 'minReviews': 35},
      {'query': 'party entertainment venues', 'types': ['night_club', 'bar'], 'minRating': 4.0, 'minReviews': 25},
    ],
    'mindful': [
      {'query': 'peaceful tourist attractions', 'types': ['tourist_attraction', 'park'], 'minRating': 4.3, 'minReviews': 30},
      {'query': 'art museums galleries', 'types': ['museum', 'art_gallery'], 'minRating': 4.2, 'minReviews': 50},
      {'query': 'spiritual cultural sites', 'types': ['church', 'tourist_attraction'], 'minRating': 4.1, 'minReviews': 25},
      {'query': 'meditation peaceful places', 'types': ['park', 'tourist_attraction'], 'minRating': 4.2, 'minReviews': 20},
      {'query': 'cultural heritage sites', 'types': ['museum', 'tourist_attraction'], 'minRating': 4.3, 'minReviews': 40},
    ],
    'family fun': [
      {'query': 'family tourist attractions', 'types': ['tourist_attraction', 'amusement_park'], 'minRating': 4.2, 'minReviews': 75},
      {'query': 'kids family activities', 'types': ['amusement_park', 'zoo'], 'minRating': 4.1, 'minReviews': 100},
      {'query': 'family entertainment venues', 'types': ['amusement_park', 'aquarium'], 'minRating': 4.3, 'minReviews': 80},
      {'query': 'children attractions', 'types': ['zoo', 'amusement_park'], 'minRating': 4.2, 'minReviews': 60},
      {'query': 'family friendly experiences', 'types': ['tourist_attraction', 'museum'], 'minRating': 4.1, 'minReviews': 50},
    ],
    'creative': [
      {'query': 'art galleries museums', 'types': ['art_gallery', 'museum'], 'minRating': 4.2, 'minReviews': 40},
      {'query': 'creative cultural attractions', 'types': ['museum', 'tourist_attraction'], 'minRating': 4.1, 'minReviews': 30},
      {'query': 'artistic experiences', 'types': ['art_gallery', 'tourist_attraction'], 'minRating': 4.2, 'minReviews': 25},
      {'query': 'cultural art venues', 'types': ['museum', 'art_gallery'], 'minRating': 4.3, 'minReviews': 35},
      {'query': 'design creative spaces', 'types': ['art_gallery', 'museum'], 'minRating': 4.0, 'minReviews': 20},
    ],
    'luxurious': [
      {'query': 'luxury fine dining', 'types': ['restaurant'], 'minRating': 4.5, 'minReviews': 100},
      {'query': 'premium spa experiences', 'types': ['spa'], 'minRating': 4.4, 'minReviews': 50},
      {'query': 'upscale luxury venues', 'types': ['restaurant', 'bar'], 'minRating': 4.5, 'minReviews': 75},
      {'query': 'exclusive experiences', 'types': ['tourist_attraction', 'spa'], 'minRating': 4.4, 'minReviews': 40},
      {'query': 'high end attractions', 'types': ['tourist_attraction', 'restaurant'], 'minRating': 4.4, 'minReviews': 60},
    ],
    'freactives': [
      {'query': 'entertainment activity venues', 'types': ['amusement_park', 'tourist_attraction'], 'minRating': 4.1, 'minReviews': 40},
      {'query': 'fun activity centers', 'types': ['bowling_alley', 'amusement_park'], 'minRating': 4.0, 'minReviews': 35},
      {'query': 'recreational attractions', 'types': ['tourist_attraction', 'amusement_park'], 'minRating': 4.0, 'minReviews': 30},
      {'query': 'active fun experiences', 'types': ['amusement_park', 'bowling_alley'], 'minRating': 3.9, 'minReviews': 25},
    ],
  };

  /// Search like GetYourGuide/TripAdvisor with enhanced tourism filtering
  /// Returns ONLY high-quality tourist experiences that tourists actually book
  /// Cost-optimized with smart API usage limits + ENHANCED VARIETY
  static Future<List<GooglePlace>> searchByMood({
    required List<String> moods,
    required double lat,
    required double lng,
    int radius = 8000, // Reduced for better local results
    String cityName = 'Rotterdam', // Default city
  }) async {
    // Check if API is enabled in configuration
    if (!ApiConfig.shouldUseApi) {
      if (kDebugMode) debugPrint('🚫 Google Places API disabled by configuration for mood search');
    return [];
  }

    if (kDebugMode) debugPrint('🎯 TOURISM SEARCH: Finding diverse GetYourGuide-style experiences for: $moods in $cityName');
    
    final allPlaces = <GooglePlace>[];
    final seenPlaceIds = <String>{};
    int apiCallCount = 0;
    const maxApiCalls = 8; // Increased for more variety
    
    // Add time-based rotation to prevent same results
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rotationOffset = (timestamp ~/ (1000 * 60 * 60)) % 10; // Changes every hour
    
    // Process only the first mood for focused results
    for (final mood in moods.take(1)) {
      final queries = moodToTourismQueries[mood.toLowerCase()] ?? [];
      
      // ENHANCED VARIETY: Rotate through queries based on time + shuffle
      final shuffledQueries = List.from(queries);
      shuffledQueries.shuffle();
      
      // Use different queries each time with rotation
      final startIndex = rotationOffset % queries.length;
      final rotatedQueries = [
        ...queries.skip(startIndex),
        ...queries.take(startIndex),
      ];
      
      // Use best 3 queries per mood for more variety
      for (final queryConfig in rotatedQueries.take(3)) {
        if (apiCallCount >= maxApiCalls) break;
        
        try {
          final types = List<String>.from(queryConfig['types'] ?? []);
          
          // Search with the primary type only for focused results
          for (final placeType in types.take(1)) {
            if (apiCallCount >= maxApiCalls) break;
            
            // Replace "Rotterdam" in query with actual city name
            String searchQuery = (queryConfig['query'] as String).replaceAll('Rotterdam', cityName);
            
            if (kDebugMode) debugPrint('🔍 TOURISM API: Searching "$searchQuery" type:"$placeType"');
            
            // Add radius variation for more diverse results
            final searchRadius = radius + (rotationOffset * 1000); // Vary search radius
            
            final places = await searchPlaces(
              query: searchQuery,
              lat: lat,
              lng: lng,
              radius: searchRadius,
              type: placeType,
            );
            
            apiCallCount++;
            
            // Apply STRICT tourism filtering
            for (final place in places) {
              if (seenPlaceIds.contains(place.placeId)) continue;
              
              // Enhanced quality filters for tourism
              final minRating = queryConfig['minRating'] as double? ?? 4.0;
              final minReviews = queryConfig['minReviews'] as int? ?? 20;
              
              if ((place.rating ?? 0) >= minRating && 
                  (place.userRatingsTotal ?? 0) >= minReviews &&
                  _isTouristRelevant(place)) {
                
                final touristScore = _calculateTouristScore(place);
                if (kDebugMode) debugPrint('✅ TOURIST EXPERIENCE: ${place.name}');
                if (kDebugMode) debugPrint('   🏆 Tourist Score: $touristScore/10');
                if (kDebugMode) debugPrint('   📷 Has photo: ${place.photoReference != null}');
                if (kDebugMode) debugPrint('   🌟 Rating: ${place.rating} (${place.userRatingsTotal} reviews)');
                if (kDebugMode) debugPrint('   🏷️ Types: ${place.types.take(3).join(", ")}');
                
                allPlaces.add(place);
                seenPlaceIds.add(place.placeId);
              } else {
                if (kDebugMode) debugPrint('❌ FILTERED OUT: ${place.name} (Rating: ${place.rating}, Reviews: ${place.userRatingsTotal})');
              }
            }
          }
          
          // Controlled delay between requests
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Stop if we have enough high-quality tourism results
          if (allPlaces.length >= 10) break;
          
        } catch (e) {
          if (kDebugMode) debugPrint('❌ Tourism search error "${queryConfig['query']}": $e');
        }
      }
      
      if (allPlaces.length >= 10) break;
    }
    
    // Sort by tourist relevance score (highest first) AND rating
    allPlaces.sort((a, b) {
      final scoreA = _calculateTouristScore(a);
      final scoreB = _calculateTouristScore(b);
      
      // Primary sort: tourist score
      final scoreComparison = scoreB.compareTo(scoreA);
      if (scoreComparison != 0) return scoreComparison;
      
      // Secondary sort: rating (higher is better)
      final ratingA = a.rating ?? 0.0;
      final ratingB = b.rating ?? 0.0;
      return ratingB.compareTo(ratingA);
    });
    
    if (kDebugMode) debugPrint('✅ TOURISM RESULTS: Found ${allPlaces.length} high-quality tourist experiences in $cityName');
    if (kDebugMode) debugPrint('📊 API calls used: $apiCallCount/$maxApiCalls');
    
    return allPlaces.take(10).toList(); // Return top 10 tourist experiences
  }

  /// Enhanced filter for tourist-relevant places only - GetYourGuide style
  static bool _isTouristRelevant(GooglePlace place) {
    // HIGH-PRIORITY tourist place types (what tourists actually want)
    final touristTypes = {
      'tourist_attraction', 'museum', 'art_gallery', 'amusement_park',
      'aquarium', 'zoo', 'park', 'restaurant', 'cafe', 'bar',
      'night_club', 'movie_theater', 'casino', 'bowling_alley', 
      'travel_agency', 'lodging', 'bakery', 'shopping_mall',
      'church', 'synagogue', 'hindu_temple', 'mosque', 'library'
    };
    
    // ABSOLUTELY EXCLUDE these everyday/personal services
    final excludeTypes = {
      'gas_station', 'atm', 'bank', 'pharmacy', 'hospital', 'dentist',
      'veterinary_care', 'car_repair', 'car_wash', 'parking',
      'post_office', 'local_government_office', 'embassy', 'storage',
      'funeral_home', 'cemetery', 'laundry', 'hair_care', 'beauty_salon',
      'real_estate_agency', 'insurance_agency', 'accounting',
      'lawyer', 'physiotherapist', 'doctor', 'locksmith', 'plumber',
      'electrician', 'roofing_contractor', 'moving_company',
      'fire_station', 'police', 'gym', 'health', // Added gym and health
    };
    
    // COMPREHENSIVE EXCLUDE list for business names (personal care, medical, services)
    final excludeKeywords = {
      // Personal care & body services
      'bodycare', 'body care', 'men\'s bodycare', 'massage therapy', 
      'physiotherapy', 'physical therapy', 'yoga school', 'yogaschool',
      'fitness center', 'fitness centre', 'personal trainer', 'gym',
      'pilates studio', 'pilates', 'crossfit', 'bootcamp',
      
      // Medical & health services  
      'dental clinic', 'medical center', 'pharmacy', 'optician', 
      'clinic', 'medical', 'therapy', 'rehabilitation', 'health center',
      'treatment center', 'care center', 'diagnostic', 'surgical',
      'zwanger', 'pregnancy', 'maternity', 'wellness center',
      
      // Beauty & personal services
      'hair salon', 'nail salon', 'beauty salon', 'dry cleaning',
      'barbershop', 'barber shop', 'nail bar', 'manicure', 'pedicure',
      
      // Professional services
      'tax service', 'insurance office', 'auto repair', 'tire shop',
      'law office', 'legal services', 'accounting', 'bookkeeping',
      
      // Automotive & technical
      'car wash', 'auto service', 'repair shop', 'mechanic',
      'tire center', 'oil change', 'brake service',
      
      // Personal services
      'cleaning service', 'laundromat', 'dry cleaner', 'tailor',
      'alterations', 'shoe repair', 'locksmith', 'plumber',
      
      // Dutch/Local specific exclusions
      'zorgcentrum', 'medisch centrum', 'tandarts', 'apotheek',
      'fysiotherapie', 'behandeling', 'verzorging', 'gezondheid',
    };
    
    // REQUIRE tourism keywords for spas/wellness (to avoid medical services)
    final touristSpaKeywords = {
      'luxury spa', 'resort spa', 'day spa', 'spa hotel', 'thermal spa',
      'wellness retreat', 'relaxation spa', 'beauty spa', 'spa experience',
      'hotel spa', 'destination spa', 'retreat center'
    };
    
    final nameLower = place.name.toLowerCase();
    
    // Check place types - EXCLUDE if has any excluded type
    final hasExcludedType = place.types.any((type) => excludeTypes.contains(type));
    if (hasExcludedType) {
      if (kDebugMode) debugPrint('🚫 Excluded by type: ${place.name} (types: ${place.types})');
      return false;
    }
    
    // Check business name for exclusions - STRICT filtering
    final hasExcludedKeyword = excludeKeywords.any((keyword) => nameLower.contains(keyword));
    if (hasExcludedKeyword) {
      if (kDebugMode) debugPrint('🚫 Excluded by keyword: ${place.name}');
      return false;
    }
    
    // Special handling for spas/wellness - must have tourist keywords to be included
    final isSpaOrWellness = place.types.any((type) => ['spa', 'gym', 'health'].contains(type));
    if (isSpaOrWellness) {
      final hasTouristSpaKeywords = touristSpaKeywords.any((keyword) => nameLower.contains(keyword));
      if (!hasTouristSpaKeywords) {
        if (kDebugMode) debugPrint('🚫 Excluded wellness/spa without tourist keywords: ${place.name}');
        return false;
      }
    }
    
    // Check if has relevant tourist type
    final hasRelevantType = place.types.any((type) => touristTypes.contains(type));
    if (!hasRelevantType) {
      if (kDebugMode) debugPrint('🚫 Excluded - no tourist relevant type: ${place.name} (types: ${place.types})');
      return false;
    }
    
    // Additional tourist-relevance scoring
    final touristScore = _calculateTouristScore(place);
    if (touristScore < 3) {
      if (kDebugMode) debugPrint('🚫 Excluded - low tourist score ($touristScore): ${place.name}');
      return false;
    }
    
    if (kDebugMode) debugPrint('✅ TOURIST APPROVED: ${place.name} (score: $touristScore, types: ${place.types.take(3).join(", ")})');
    return true;
  }
  
  /// Calculate tourist relevance score (1-10)
  static int _calculateTouristScore(GooglePlace place) {
    final nameLower = place.name.toLowerCase();
    int score = 0;
    
    // High tourist keywords (+3 points each)
    final highTouristKeywords = {
      'attraction', 'museum', 'gallery', 'tour', 'experience', 'adventure',
      'heritage', 'historic', 'landmark', 'scenic', 'viewpoint', 'park',
      'entertainment', 'show', 'theater', 'cultural', 'art', 'exhibition'
    };
    
    // Medium tourist keywords (+2 points each)
    final mediumTouristKeywords = {
      'restaurant', 'cafe', 'bar', 'dining', 'cuisine', 'food', 'drink',
      'shopping', 'market', 'boutique', 'souvenir', 'gift'
    };
    
    // Tourism-positive place types (+2 points each)
    final positiveTypes = {
      'tourist_attraction', 'museum', 'art_gallery', 'amusement_park',
      'zoo', 'aquarium', 'park', 'restaurant', 'bar', 'cafe'
    };
    
    // Check for high tourist keywords
    for (final keyword in highTouristKeywords) {
      if (nameLower.contains(keyword)) score += 3;
    }
    
    // Check for medium tourist keywords
    for (final keyword in mediumTouristKeywords) {
      if (nameLower.contains(keyword)) score += 2;
    }
    
    // Check for positive place types
    for (final type in positiveTypes) {
      if (place.types.contains(type)) score += 2;
    }
    
    // High rating bonus (+1 point)
    if ((place.rating ?? 0) >= 4.2) score += 1;
    
    // Popular place bonus (+1 point)
    if ((place.userRatingsTotal ?? 0) >= 100) score += 1;
    
    return score;
    }
    
  /// Test method to check tourist filtering logic
  static bool testTouristFiltering(GooglePlace place) {
    return _isTouristRelevant(place);
  }
} 