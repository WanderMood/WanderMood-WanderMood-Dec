import 'package:flutter_google_maps_webservices/places.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../models/place.dart';
import '../services/places_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

part 'explore_places_provider.g.dart';

@riverpod
class ExplorePlaces extends _$ExplorePlaces {
  // 🚨 ULTRA-AGGRESSIVE CACHING: Cache for 7 days to minimize API calls
  static final Map<String, List<Place>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(days: 7); // 7-day cache!
  
  // 🚨 REMOVED: No longer needed since we eliminated all API calls
  // _cityPlaces removed to clean up code - we use only offline content now

  // 🏗️ MASSIVE FALLBACK DATABASE: Rich content without API calls
  final Map<String, List<Place>> _fallbackPlaces = {
    'Rotterdam': [
      Place(
        id: 'markthal_fallback',
        name: 'Markthal Rotterdam',
        address: 'Dominee Jan Scharpstraat 298, 3011 GZ Rotterdam',
        rating: 4.4,
        photos: [],
        types: ['tourist_attraction', 'shopping_mall'],
        location: const PlaceLocation(lat: 51.9200, lng: 4.4850),
        description: 'Iconic market hall with apartments above, featuring food stalls and restaurants.',
        emoji: '🏢',
        tag: 'Architecture',
        isAsset: true,
        activities: ['Shopping', 'Food', 'Architecture'],
      ),
      Place(
        id: 'kunsthal_fallback', 
        name: 'Kunsthal Rotterdam',
        address: 'Westzeedijk 341, 3015 AA Rotterdam',
        rating: 4.3,
        photos: [],
        types: ['museum', 'art_gallery'],
        location: const PlaceLocation(lat: 51.9088, lng: 4.4661),
        description: 'Contemporary art museum showcasing rotating exhibitions.',
        emoji: '🎨',
        tag: 'Culture',
        isAsset: true,
        activities: ['Art', 'Culture', 'Museums'],
      ),
      Place(
        id: 'euromast_fallback',
        name: 'Euromast Rotterdam', 
        address: 'Parkhaven 20, 3016 GM Rotterdam',
        rating: 4.5,
        photos: [],
        types: ['tourist_attraction', 'point_of_interest'],
        location: const PlaceLocation(lat: 51.9054, lng: 4.4643),
        description: 'Iconic observation tower offering panoramic views of Rotterdam.',
        emoji: '🗼',
        tag: 'Sightseeing',
        isAsset: true,
        activities: ['Sightseeing', 'Photography', 'Views'],
      ),
      Place(
        id: 'erasmus_bridge_fallback',
        name: 'Erasmus Bridge Rotterdam',
        address: 'Erasmusbrug, Rotterdam',
        rating: 4.6,
        photos: [],
        types: ['tourist_attraction', 'point_of_interest'],
        location: const PlaceLocation(lat: 51.9085, lng: 4.4824),
        description: 'Iconic cable-stayed bridge nicknamed "The Swan".',
        emoji: '🌉',
        tag: 'Landmark',
        isAsset: true,
        activities: ['Sightseeing', 'Photography', 'Walking'],
      ),
      Place(
        id: 'cube_houses_fallback',
        name: 'Cube Houses Rotterdam',
        address: 'Overblaak 70, 3011 MH Rotterdam',
        rating: 4.2,
        photos: [],
        types: ['tourist_attraction', 'architecture'],
        location: const PlaceLocation(lat: 51.9200, lng: 4.4900),
        description: 'Innovative cube-shaped houses designed by Piet Blom.',
        emoji: '🏠',
        tag: 'Architecture',
        isAsset: true,
        activities: ['Architecture', 'Photography', 'Tours'],
      ),
      Place(
        id: 'ss_rotterdam_fallback',
        name: 'SS Rotterdam',
        address: '3e Katendrechtsehoofd 25, 3072 AM Rotterdam',
        rating: 4.3,
        photos: [],
        types: ['tourist_attraction', 'museum'],
        location: const PlaceLocation(lat: 51.8992, lng: 4.4851),
        description: 'Historic ocean liner turned floating hotel and museum.',
        emoji: '🚢',
        tag: 'History',
        isAsset: true,
        activities: ['History', 'Tours', 'Dining'],
      ),
    ],
    'San Francisco': [
      Place(
        id: 'golden_gate_fallback',
        name: 'Golden Gate Bridge',
        address: 'Golden Gate Bridge, San Francisco, CA',
        rating: 4.7,
        photos: ['assets/images/fallbacks/golden_gate.jpg'],
        types: ['tourist_attraction', 'landmark'],
        location: const PlaceLocation(lat: 37.8199, lng: -122.4783),
        description: 'Iconic suspension bridge spanning the Golden Gate strait.',
        emoji: '🌉',
        tag: 'Landmark',
        isAsset: true,
        activities: ['Sightseeing', 'Photography', 'Walking'],
      ),
    ],
  };

  final Map<String, List<String>> _categoryToPlaceTypes = {
    'Architecture': ['landmark', 'tourist_attraction', 'point_of_interest'],
    'Culture': ['museum', 'art_gallery', 'library', 'tourist_attraction'],
    'Food': ['restaurant', 'cafe', 'bakery', 'food', 'meal_takeaway'],
    'Nature': ['park', 'natural_feature', 'zoo', 'campground'],
    'History': ['museum', 'cemetery', 'church', 'mosque', 'synagogue', 'hindu_temple', 'place_of_worship'],
    'Art': ['art_gallery', 'museum'],
    'Family': ['amusement_park', 'aquarium', 'zoo', 'park'],
    'Photography': ['tourist_attraction', 'natural_feature', 'point_of_interest', 'landmark'],
    'Sports': ['stadium', 'gym', 'park', 'sports_complex'],
    'Accommodation': ['lodging', 'hotel', 'apartment_rental'],
  };

  // 🚨 API KILL SWITCH: Set to false to completely disable API calls
  static const bool _enableApiCalls = false; // ZERO API CALLS!

  @override
  Future<List<Place>> build({String? city}) async {
    final cacheKey = city ?? 'Rotterdam';
    final cityName = city ?? 'Rotterdam';
    
    // ⚡ ULTRA-AGGRESSIVE CACHE CHECK: Return cached data if available and fresh
    if (_isCacheValid(cacheKey)) {
      debugPrint('📱 Using 7-day cached places for $cacheKey (🚫 NO API CALLS!)');
      return _cache[cacheKey]!;
    }

    // 💾 PERSISTENT STORAGE CHECK: Check device storage before API
    final storedPlaces = await _loadFromPersistentStorage(cacheKey);
    if (storedPlaces != null && storedPlaces.isNotEmpty) {
      debugPrint('💾 Using persistent storage for $cacheKey (🚫 NO API CALLS!)');
      _updateCache(cacheKey, storedPlaces);
      return storedPlaces;
    }

    // 🎯 OFFLINE-FIRST STRATEGY: ALWAYS use fallbacks, NO API calls
    final fallbacksForCity = _fallbackPlaces[cityName];
    
    if (fallbacksForCity != null && fallbacksForCity.isNotEmpty) {
      debugPrint('🏗️ Using rich offline content for $cityName (🚫 ZERO API CALLS!)');
      _updateCache(cacheKey, fallbacksForCity);
      await _saveToPersistentStorage(cacheKey, fallbacksForCity);
      return fallbacksForCity;
    }

    // 🚨 EMERGENCY FALLBACK: Create content without any API calls
    debugPrint('🆘 Creating emergency fallback content for $cityName (🚫 ZERO API CALLS!)');
    final emergencyPlaces = [_getDefaultPlace(cityName)];
    _updateCache(cacheKey, emergencyPlaces);
    await _saveToPersistentStorage(cacheKey, emergencyPlaces);
    return emergencyPlaces;

    // 🚨 DEAD CODE: API calling section completely removed to eliminate all API usage
    // This ensures ZERO API calls are made under any circumstances
  }

  // 🔍 CACHE MANAGEMENT METHODS
  bool _isCacheValid(String cacheKey) {
    if (!_cache.containsKey(cacheKey) || !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[cacheKey]!;
    final isExpired = DateTime.now().difference(cacheTime) > _cacheValidDuration;
    return !isExpired;
  }

  void _cacheResults(String cacheKey, List<Place> results) {
    _cache[cacheKey] = results;
    _cacheTimestamps[cacheKey] = DateTime.now();
    debugPrint('💾 Cached ${results.length} places for $cacheKey');
  }

  // 🧹 CACHE CLEANUP: Call this method to clear old cache
  static void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) > _cacheValidDuration)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('🧹 Cleared expired cache for: ${expiredKeys.join(", ")}');
    }
  }

  // 🎨 HELPER METHODS
  String _getEmojiForPlace(List<String> types) {
    if (types.contains('museum') || types.contains('art_gallery')) return '🎨';
    if (types.contains('restaurant') || types.contains('food')) return '🍽️';
    if (types.contains('park') || types.contains('natural_feature')) return '🌳';
    if (types.contains('tourist_attraction')) return '🏛️';
    if (types.contains('shopping_mall')) return '🛍️';
    return '📍';
  }

  String _getTagForPlace(List<String> types) {
    if (types.contains('museum') || types.contains('art_gallery')) return 'Culture';
    if (types.contains('restaurant') || types.contains('food')) return 'Food';
    if (types.contains('park')) return 'Nature';
    if (types.contains('tourist_attraction')) return 'Sightseeing';
    if (types.contains('shopping_mall')) return 'Shopping';
    return 'Popular';
  }

  Place _getDefaultPlace(String cityName) {
    return Place(
      id: 'default_place',
      name: 'Popular Place in $cityName',
      address: '$cityName, Netherlands',
      rating: 4.5,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['point_of_interest', 'tourist_attraction'],
      location: const PlaceLocation(lat: 0.0, lng: 0.0),
      description: 'A popular destination in $cityName',
      emoji: '🏙️',
      tag: 'Popular',
      isAsset: true,
      activities: ['Sightseeing', 'Culture', 'Food'],
    );
  }

  String getPhotoUrl(String photoReference) {
    final service = ref.read(placesServiceProvider.notifier);
    return service.getPhotoUrl(photoReference);
  }

  // 💾 PERSISTENT STORAGE METHODS: Cache data across app restarts
  Future<List<Place>?> _loadFromPersistentStorage(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('places_cache_$cacheKey');
      final storedTimestamp = prefs.getInt('places_timestamp_$cacheKey');
      
      if (storedData != null && storedTimestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(storedTimestamp);
        final isExpired = DateTime.now().difference(cacheTime) > _cacheValidDuration;
        
        if (!isExpired) {
          final List<dynamic> jsonList = json.decode(storedData);
          final places = jsonList.map((json) => Place.fromJson(json)).toList();
          debugPrint('💾 Loaded ${places.length} places from persistent storage');
          return places;
        } else {
          debugPrint('🗑️ Persistent cache expired for $cacheKey');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading from persistent storage: $e');
    }
    return null;
  }

  Future<void> _saveToPersistentStorage(String cacheKey, List<Place> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = places.map((place) => place.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await prefs.setString('places_cache_$cacheKey', jsonString);
      await prefs.setInt('places_timestamp_$cacheKey', DateTime.now().millisecondsSinceEpoch);
      debugPrint('💾 Saved ${places.length} places to persistent storage');
    } catch (e) {
      debugPrint('❌ Error saving to persistent storage: $e');
    }
  }

  void _updateCache(String cacheKey, List<Place> places) {
    _cache[cacheKey] = places;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  // 🔧 DEVELOPER ONLY: Method to force refresh with API calls (for testing/admin)
  Future<List<Place>> forceRefreshWithApi({String? city}) async {
    if (!_enableApiCalls) {
      debugPrint('🚫 API calls disabled by kill switch - use offline content');
      return build(city: city);
    }
    
    // This method would make API calls - but currently disabled by kill switch
    debugPrint('⚠️ Force refresh requested but API calls are disabled for cost optimization');
    return build(city: city);
  }
} 