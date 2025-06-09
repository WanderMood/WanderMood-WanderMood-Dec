import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_keys.dart';
import 'smart_api_cache.dart';

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
  });

  factory GooglePlace.fromJson(Map<String, dynamic> json) {
    final List<String> allPhotoRefs = [];
    if (json['photos'] != null) {
      for (final photo in json['photos']) {
        if (photo['photo_reference'] != null) {
          allPhotoRefs.add(photo['photo_reference']);
        }
      }
    }

    return GooglePlace(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown Place',
      vicinity: json['vicinity'],
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      types: List<String>.from(json['types'] ?? []),
      photoReference: allPhotoRefs.isNotEmpty ? allPhotoRefs.first : null,
      photoReferences: allPhotoRefs,
      lat: json['geometry']?['location']?['lat']?.toDouble(),
      lng: json['geometry']?['location']?['lng']?.toDouble(),
      priceLevel: json['price_level'],
      openNow: json['opening_hours']?['open_now'],
      businessStatus: json['business_status'],
    );
  }

  /// Get the best available photo URL for this place
  String getBestPhotoUrl({int maxWidth = 800}) {
    return GooglePlacesService.getBestPhotoUrl(photoReference, types);
  }

  /// Get multiple photo URLs for this place
  List<String> getAllPhotoUrls({int maxWidth = 600, int maxPhotos = 3}) {
    return GooglePlacesService.getPhotoUrls(photoReferences, maxWidth: maxWidth, maxPhotos: maxPhotos);
  }
}

class GooglePlaceDetails {
  final String placeId;
  final String name;
  final String? formattedAddress;
  final String? formattedPhoneNumber;
  final String? website;
  final double? rating;
  final List<String> types;
  final List<String> photoReferences;
  final double? lat;
  final double? lng;
  final int? priceLevel;
  final List<Map<String, dynamic>> reviews;
  final Map<String, dynamic>? openingHours;

  GooglePlaceDetails({
    required this.placeId,
    required this.name,
    this.formattedAddress,
    this.formattedPhoneNumber,
    this.website,
    this.rating,
    this.types = const [],
    this.photoReferences = const [],
    this.lat,
    this.lng,
    this.priceLevel,
    this.reviews = const [],
    this.openingHours,
  });

  factory GooglePlaceDetails.fromJson(Map<String, dynamic> json) {
    return GooglePlaceDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown Place',
      formattedAddress: json['formatted_address'],
      formattedPhoneNumber: json['formatted_phone_number'],
      website: json['website'],
      rating: (json['rating'] as num?)?.toDouble(),
      types: List<String>.from(json['types'] ?? []),
      photoReferences: (json['photos'] as List<dynamic>?)
          ?.map((photo) => photo['photo_reference'] as String)
          .toList() ?? [],
      lat: json['geometry']?['location']?['lat']?.toDouble(),
      lng: json['geometry']?['location']?['lng']?.toDouble(),
      priceLevel: json['price_level'],
      reviews: List<Map<String, dynamic>>.from(json['reviews'] ?? []),
      openingHours: json['opening_hours'],
    );
  }
}

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  
  static String get _apiKey => ApiKeys.googlePlacesApi;

  /// Search for places near a location based on query with smart caching
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
      endpoint: 'nearby_search',
      parameters: parameters,
    );

    if (cachedResponse != null) {
      // Return cached results
      final List<dynamic> results = cachedResponse['results'] ?? [];
      return results.map((result) => GooglePlace.fromJson(result)).toList();
    }

    // Check if we should make API call
    final shouldCall = await SmartApiCache.shouldMakeApiCall(
      endpoint: 'nearby_search',
      parameters: parameters,
    );

    if (!shouldCall) {
      debugPrint('🚫 API call blocked by smart cache system for: $query');
      return [];
    }

    // Make API call
    try {
      if (_apiKey.isEmpty) {
        debugPrint('❌ Google Places API key not found');
        return [];
      }

      final String url = '$_baseUrl/nearbysearch/json?'
          'location=$lat,$lng&'
          'radius=$radius&'
          'keyword=$query&'
          'type=$type&'
          'key=$_apiKey';

      debugPrint('🔍 Making REAL API call for: $query near ($lat, $lng)');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          // Cache the response for future use
          await SmartApiCache.cacheResponse(
            endpoint: 'nearby_search',
            parameters: parameters,
            response: data,
          );

          final List<dynamic> results = data['results'] ?? [];
          final places = results.map((result) => GooglePlace.fromJson(result)).toList();
          
          debugPrint('✅ Found ${places.length} places for: $query (CACHED for 30 days)');
          return places;
        } else {
          debugPrint('❌ Places API error: ${data['status']} - ${data['error_message']}');
          return [];
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error searching places: $e');
      return [];
    }
  }

  /// Get detailed information about a specific place with smart caching
  static Future<GooglePlaceDetails?> getPlaceDetails(String placeId) async {
    final parameters = {'place_id': placeId};

    // Check cache first
    final cachedResponse = await SmartApiCache.getCachedResponse(
      endpoint: 'place_details',
      parameters: parameters,
    );

    if (cachedResponse != null) {
      // Return cached details
      return GooglePlaceDetails.fromJson(cachedResponse['result']);
    }

    // Check if we should make API call
    final shouldCall = await SmartApiCache.shouldMakeApiCall(
      endpoint: 'place_details',
      parameters: parameters,
    );

    if (!shouldCall) {
      debugPrint('🚫 Place details API call blocked by smart cache for: $placeId');
      return null;
    }

    // Make API call
    try {
      if (_apiKey.isEmpty) {
        debugPrint('❌ Google Places API key not found');
        return null;
      }

      final String url = '$_baseUrl/details/json?'
          'place_id=$placeId&'
          'fields=place_id,name,formatted_address,formatted_phone_number,website,rating,types,photos,geometry,price_level,reviews,opening_hours&'
          'key=$_apiKey';

      debugPrint('🔍 Making REAL API call for place details: $placeId');

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          // Cache the response for future use
          await SmartApiCache.cacheResponse(
            endpoint: 'place_details',
            parameters: parameters,
            response: data,
          );

          debugPrint('✅ Got place details for: ${data['result']['name']} (CACHED for 30 days)');
          return GooglePlaceDetails.fromJson(data['result']);
        } else {
          debugPrint('❌ Place details API error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting place details: $e');
      return null;
    }
  }

  /// Get photo URL from photo reference with enhanced quality options
  static String getPhotoUrl(String photoReference, {int maxWidth = 800}) {
    if (_apiKey.isEmpty || photoReference.isEmpty) {
      return 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b'; // Fallback image
    }
    
    // Use higher resolution for better quality
    return '$_baseUrl/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$_apiKey';
  }

  /// Get multiple photo URLs for a place (for variety)
  static List<String> getPhotoUrls(List<String> photoReferences, {int maxWidth = 600, int maxPhotos = 3}) {
    if (_apiKey.isEmpty || photoReferences.isEmpty) {
      return ['https://images.unsplash.com/photo-1544367567-0f2fcb009e0b'];
    }
    
    return photoReferences
        .take(maxPhotos)
        .map((ref) => '$_baseUrl/photo?maxwidth=$maxWidth&photo_reference=$ref&key=$_apiKey')
        .toList();
  }

  /// Get best quality photo URL for a place  
  static String getBestPhotoUrl(String? photoReference, List<String> placeTypes) {
    // Prioritize actual Google Places photos over generic fallbacks
    if (photoReference != null && photoReference.isNotEmpty && _apiKey.isNotEmpty) {
      debugPrint('📸 Using actual Google Places photo: ${photoReference.substring(0, photoReference.length > 10 ? 10 : photoReference.length)}...');
      // Use high resolution for main images
      return '$_baseUrl/photo?maxwidth=1200&photo_reference=$photoReference&key=$_apiKey';
    }
    
    debugPrint('⚠️ No photo reference available, using enhanced fallback for types: $placeTypes');
    // Enhanced fallback images based on place type
    return _getEnhancedFallbackImage(placeTypes);
  }

  /// Get enhanced fallback images based on place types
  static String _getEnhancedFallbackImage(List<String> types) {
    // High-quality Unsplash images for different venue types
    if (types.contains('restaurant') || types.contains('food')) {
      return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80'; // Restaurant interior
    } else if (types.contains('museum') || types.contains('art_gallery')) {
      return 'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&q=80'; // Museum interior
    } else if (types.contains('park')) {
      return 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80'; // Beautiful park
    } else if (types.contains('gym') || types.contains('health')) {
      return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80'; // Modern gym
    } else if (types.contains('spa')) {
      return 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&q=80'; // Spa/wellness
    } else if (types.contains('cafe') || types.contains('bakery')) {
      return 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&q=80'; // Cozy cafe
    } else if (types.contains('bar') || types.contains('night_club')) {
      return 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&q=80'; // Stylish bar
    } else if (types.contains('tourist_attraction')) {
      return 'https://images.unsplash.com/photo-1539650116574-75c0c6d73c6e?w=800&q=80'; // Tourist attraction
    } else if (types.contains('shopping_mall') || types.contains('store')) {
      return 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=800&q=80'; // Shopping center
    } else if (types.contains('zoo') || types.contains('amusement_park')) {
      return 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&q=80'; // Family fun
    }
    
    // Default high-quality city/venue image
    return 'https://images.unsplash.com/photo-1444653389962-8149286c578a?w=800&q=80';
  }

  // Tourism platform search strategy - like GetYourGuide/TripAdvisor
  static const Map<String, List<Map<String, dynamic>>> moodToTourismQueries = {
    'adventure': [
      {'query': 'adventure activities', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 20},
      {'query': 'outdoor adventures', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 15},
      {'query': 'things to do adventure', 'type': 'tourist_attraction', 'minRating': 3.8, 'minReviews': 10},
      {'query': 'popular attractions active', 'type': 'amusement_park', 'minRating': 4.0, 'minReviews': 25},
    ],
    'relaxed': [
      {'query': 'peaceful places', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 15},
      {'query': 'relaxing spots', 'type': 'park', 'minRating': 3.8, 'minReviews': 10},
      {'query': 'tranquil attractions', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 20},
      {'query': 'best cafes scenic', 'type': 'cafe', 'minRating': 4.2, 'minReviews': 30},
    ],
    'romantic': [
      {'query': 'romantic places', 'type': 'tourist_attraction', 'minRating': 4.2, 'minReviews': 25},
      {'query': 'romantic restaurants', 'type': 'restaurant', 'minRating': 4.3, 'minReviews': 50},
      {'query': 'sunset viewpoints', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 15},
      {'query': 'romantic dinner spots', 'type': 'restaurant', 'minRating': 4.4, 'minReviews': 40},
    ],
    'energetic': [
      {'query': 'active things to do', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 20},
      {'query': 'popular activities energetic', 'type': 'tourist_attraction', 'minRating': 3.9, 'minReviews': 15},
      {'query': 'fun activities', 'type': 'amusement_park', 'minRating': 4.1, 'minReviews': 30},
      {'query': 'active attractions', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 25},
    ],
    'excited': [
      {'query': 'top attractions', 'type': 'tourist_attraction', 'minRating': 4.2, 'minReviews': 50},
      {'query': 'must see places', 'type': 'tourist_attraction', 'minRating': 4.3, 'minReviews': 75},
      {'query': 'popular tourist spots', 'type': 'tourist_attraction', 'minRating': 4.1, 'minReviews': 40},
      {'query': 'famous attractions', 'type': 'tourist_attraction', 'minRating': 4.2, 'minReviews': 60},
    ],
    'surprise': [
      {'query': 'hidden gems', 'type': 'tourist_attraction', 'minRating': 4.3, 'minReviews': 15},
      {'query': 'unique places', 'type': 'tourist_attraction', 'minRating': 4.1, 'minReviews': 12},
      {'query': 'unusual attractions', 'type': 'museum', 'minRating': 4.0, 'minReviews': 20},
      {'query': 'off beaten path', 'type': 'tourist_attraction', 'minRating': 4.2, 'minReviews': 10},
    ],
    'foody': [
      // High-end dining (afternoon/evening perfect)
      {'query': 'best restaurants', 'type': 'restaurant', 'minRating': 4.3, 'minReviews': 100},
      {'query': 'popular restaurants', 'type': 'restaurant', 'minRating': 4.2, 'minReviews': 75},
      {'query': 'top rated dining', 'type': 'restaurant', 'minRating': 4.4, 'minReviews': 60},
      
      // Local cuisine & experiences (perfect for tourists)
      {'query': 'local cuisine', 'type': 'restaurant', 'minRating': 4.1, 'minReviews': 50},
      {'query': 'food experiences', 'type': 'restaurant', 'minRating': 4.2, 'minReviews': 40},
      {'query': 'must try restaurants', 'type': 'restaurant', 'minRating': 4.0, 'minReviews': 35},
      
      // Afternoon dining options
      {'query': 'lunch spots', 'type': 'restaurant', 'minRating': 4.0, 'minReviews': 30},
      {'query': 'casual dining', 'type': 'restaurant', 'minRating': 3.9, 'minReviews': 25},
      {'query': 'bistro restaurants', 'type': 'restaurant', 'minRating': 4.1, 'minReviews': 20},
      
      // Morning options
      {'query': 'famous bakeries', 'type': 'bakery', 'minRating': 4.0, 'minReviews': 30},
      {'query': 'breakfast spots', 'type': 'cafe', 'minRating': 4.1, 'minReviews': 25},
      {'query': 'coffee culture', 'type': 'cafe', 'minRating': 4.0, 'minReviews': 20},
      
      // Food tourism experiences
      {'query': 'cooking workshops', 'type': 'tourist_attraction', 'minRating': 4.3, 'minReviews': 15},
      {'query': 'food tours', 'type': 'tourist_attraction', 'minRating': 4.2, 'minReviews': 20},
      {'query': 'food markets', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 15},
    ],
    'festive': [
      {'query': 'nightlife spots', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 30},
      {'query': 'entertainment venues', 'type': 'tourist_attraction', 'minRating': 4.1, 'minReviews': 25},
      {'query': 'popular bars', 'type': 'bar', 'minRating': 4.2, 'minReviews': 40},
      {'query': 'lively restaurants', 'type': 'restaurant', 'minRating': 4.0, 'minReviews': 50},
    ],
    'mindful': [
      {'query': 'peaceful attractions', 'type': 'tourist_attraction', 'minRating': 4.2, 'minReviews': 20},
      {'query': 'art museums', 'type': 'museum', 'minRating': 4.1, 'minReviews': 30},
      {'query': 'spiritual places', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 15},
      {'query': 'contemplative spots', 'type': 'park', 'minRating': 3.9, 'minReviews': 12},
    ],
    'family fun': [
      {'query': 'family attractions', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 40},
      {'query': 'kid friendly places', 'type': 'zoo', 'minRating': 4.1, 'minReviews': 50},
      {'query': 'family activities', 'type': 'amusement_park', 'minRating': 4.2, 'minReviews': 60},
      {'query': 'children attractions', 'type': 'aquarium', 'minRating': 4.0, 'minReviews': 35},
    ],
    'creative': [
      {'query': 'art galleries', 'type': 'art_gallery', 'minRating': 4.0, 'minReviews': 20},
      {'query': 'creative attractions', 'type': 'tourist_attraction', 'minRating': 4.1, 'minReviews': 15},
      {'query': 'art museums', 'type': 'museum', 'minRating': 4.2, 'minReviews': 30},
      {'query': 'artistic places', 'type': 'tourist_attraction', 'minRating': 4.0, 'minReviews': 12},
    ],
    'luxurious': [
      {'query': 'luxury restaurants', 'type': 'restaurant', 'minRating': 4.4, 'minReviews': 75},
      {'query': 'premium experiences', 'type': 'tourist_attraction', 'minRating': 4.3, 'minReviews': 30},
      {'query': 'upscale dining', 'type': 'restaurant', 'minRating': 4.5, 'minReviews': 50},
      {'query': 'luxury attractions', 'type': 'spa', 'minRating': 4.2, 'minReviews': 25},
    ],
    'freactives': [
      {'query': 'fun activities', 'type': 'amusement_park', 'minRating': 4.0, 'minReviews': 30},
      {'query': 'entertainment centers', 'type': 'tourist_attraction', 'minRating': 3.9, 'minReviews': 25},
      {'query': 'activity venues', 'type': 'bowling_alley', 'minRating': 3.8, 'minReviews': 20},
      {'query': 'recreational spots', 'type': 'amusement_park', 'minRating': 4.1, 'minReviews': 35},
    ],
  };

  /// Search like tourism platforms (GetYourGuide/TripAdvisor) with popularity filtering
  /// Returns POPULAR tourist experiences that tourists actually book and recommend
  static Future<List<GooglePlace>> searchByMood({
    required List<String> moods,
    required double lat,
    required double lng,
    int radius = 10000,
  }) async {
    // 🚨 API KILL SWITCH: This method would make dozens of API calls per mood search!
    debugPrint('🚫 SEARCH BY MOOD DISABLED - Would have made ${moods.length * 10}+ API calls!');
    debugPrint('💰 MASSIVE COST SAVINGS: Prevented tourism search for moods: $moods');
    return [];
  }

  /// Check if a place is an everyday facility that tourists typically don't want
  static bool _isEverydayFacility(GooglePlace place) {
    final everydayTypes = {
      'gas_station', 'car_repair', 'laundry', 'pharmacy', 'bank', 
      'atm', 'post_office', 'dentist', 'doctor', 'veterinary_care',
      'car_wash', 'storage', 'locksmith', 'plumber', 'electrician'
    };
    
    final everydayKeywords = {
      'chain gym', 'basic-fit', 'anytime fitness', 'planet fitness',
      'mcdonalds', 'burger king', 'subway', 'starbucks chain',
      'grocery store', 'supermarket', 'convenience store'
    };
    
    // Filter out everyday facility types
    if (place.types.any((type) => everydayTypes.contains(type))) {
      return true;
    }
    
    // Filter out everyday facility names
    final nameLower = place.name.toLowerCase();
    if (everydayKeywords.any((keyword) => nameLower.contains(keyword))) {
      return true;
    }
    
    return false;
  }
} 