import 'package:flutter_google_maps_webservices/places.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../models/place.dart';
import '../services/places_service.dart';
import '../services/opening_hours_service.dart';
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
        photos: ['https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['tourist_attraction', 'shopping_mall'],
        location: const PlaceLocation(lat: 51.9200, lng: 4.4850),
        description: 'Cozy indoor food paradise featuring 100+ stalls with fresh produce, international cuisine, and unique Rotterdam specialties. This architectural marvel combines shopping with dining in a vibrant covered market.',
        emoji: '🏢',
        tag: 'Architecture',
        isAsset: false,
        activities: ['Shopping', 'Food', 'Architecture'],
        reviewCount: 134,
        energyLevel: 'Medium',
        isIndoor: true,
      ),
      Place(
        id: 'kunsthal_fallback', 
        name: 'Kunsthal Rotterdam',
        address: 'Westzeedijk 341, 3015 AA Rotterdam',
        rating: 4.3,
        photos: ['https://images.unsplash.com/photo-1554072675-66db59dba46f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['museum', 'art_gallery'],
        location: const PlaceLocation(lat: 51.9088, lng: 4.4661),
        description: 'Inspiring indoor cultural hub showcasing contemporary art exhibitions, innovative installations, and rotating galleries. Features works by both emerging and established artists from around the world.',
        emoji: '🎨',
        tag: 'Culture',
        isAsset: false,
        activities: ['Art', 'Culture', 'Museums'],
        reviewCount: 89,
        energyLevel: 'Low',
        isIndoor: true,
      ),
      Place(
        id: 'euromast_fallback',
        name: 'Euromast Rotterdam', 
        address: 'Parkhaven 20, 3016 GM Rotterdam',
        rating: 4.5,
        photos: ['https://images.unsplash.com/photo-1599582909646-8c3c64e25ce4?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['tourist_attraction', 'point_of_interest'],
        location: const PlaceLocation(lat: 51.9054, lng: 4.4643),
        description: 'Thrilling outdoor tower adventure offering 360° panoramic views from 185m high. Take the high-speed elevator to the observation deck and enjoy the revolving restaurant with spectacular city vistas.',
        emoji: '🗼',
        tag: 'Sightseeing',
        isAsset: false,
        activities: ['Sightseeing', 'Photography', 'Views'],
        reviewCount: 267,
        energyLevel: 'High',
        isIndoor: false,
      ),
      Place(
        id: 'erasmus_bridge_fallback',
        name: 'Erasmus Bridge Rotterdam',
        address: 'Erasmusbrug, Rotterdam',
        rating: 4.6,
        photos: ['https://images.unsplash.com/photo-1583037189850-1921ae7c6c22?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['tourist_attraction', 'point_of_interest'],
        location: const PlaceLocation(lat: 51.9085, lng: 4.4824),
        description: 'Stunning outdoor landmark walk across Rotterdam\'s iconic cable-stayed bridge. This 800m architectural masterpiece offers breathtaking harbor views and connects the historic city center with modern Kop van Zuid.',
        emoji: '🌉',
        tag: 'Landmark',
        isAsset: false,
        activities: ['Sightseeing', 'Photography', 'Walking'],
        reviewCount: 512,
        energyLevel: 'Medium',
        isIndoor: false,
      ),
      Place(
        id: 'cube_houses_fallback',
        name: 'Cube Houses Rotterdam',
        address: 'Overblaak 70, 3011 MH Rotterdam',
        rating: 4.2,
        photos: ['https://images.unsplash.com/photo-1599659465412-4f5bb2a87f0e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['tourist_attraction', 'architecture'],
        location: const PlaceLocation(lat: 51.9200, lng: 4.4900),
        description: 'Fascinating indoor architectural wonder featuring tilted cube-shaped houses designed by Piet Blom. Visit the show cube to see how residents live in these unique 45-degree angled homes with guided tours available.',
        emoji: '🏠',
        tag: 'Architecture',
        isAsset: false,
        activities: ['Architecture', 'Photography', 'Tours'],
        reviewCount: 341,
        energyLevel: 'Medium',
        isIndoor: true,
      ),
      Place(
        id: 'ss_rotterdam_fallback',
        name: 'SS Rotterdam',
        address: '3e Katendrechtsehoofd 25, 3072 AM Rotterdam',
        rating: 4.3,
        photos: ['https://images.unsplash.com/photo-1544737150-6f4b999de2a5?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['tourist_attraction', 'museum'],
        location: const PlaceLocation(lat: 51.8992, lng: 4.4851),
        description: 'Magnificent indoor maritime experience aboard a historic 1959 ocean liner. Explore luxurious state rooms, dining halls, and the engine room. Now serves as a floating hotel, restaurant, and museum.',
        emoji: '🚢',
        tag: 'History',
        isAsset: false,
        activities: ['History', 'Tours', 'Dining'],
        reviewCount: 187,
        energyLevel: 'Medium',
        isIndoor: true,
      ),
      
      // === ACCOMMODATIONS ===
      Place(
        id: 'mainport_hotel_fallback',
        name: 'Mainport Design Hotel',
        address: 'Leuvehaven 77, 3011 EA Rotterdam',
        rating: 4.4,
        photos: ['https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['lodging', 'hotel'],
        location: const PlaceLocation(lat: 51.9165, lng: 4.4821),
        description: 'Luxurious waterfront hotel with spa and harbor views.',
        emoji: '🏨',
        tag: 'Luxury',
        isAsset: false,
        activities: ['Accommodation', 'Spa', 'Dining'],
      ),
      Place(
        id: 'nhow_hotel_fallback',
        name: 'nhow Rotterdam',
        address: 'Wilhelminakade 137, 3072 AP Rotterdam',
        rating: 4.2,
        photos: ['https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['lodging', 'hotel'],
        location: const PlaceLocation(lat: 51.9045, lng: 4.4823),
        description: 'Colorful designer hotel in the heart of the city.',
        emoji: '🎨',
        tag: 'Design',
        isAsset: false,
        activities: ['Accommodation', 'Design', 'Modern'],
      ),
      
      // === NATURE ===
      Place(
        id: 'kralingse_bos_fallback',
        name: 'Kralingse Bos',
        address: 'Kralingse Bos, Rotterdam',
        rating: 4.3,
        photos: ['https://images.unsplash.com/photo-1441974231531-c6227db76b6e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['park', 'natural_feature'],
        location: const PlaceLocation(lat: 51.9244, lng: 4.5188),
        description: 'Energizing outdoor nature escape featuring a beautiful lake, forest trails, and recreational facilities. Perfect for cycling, walking, boating, and picnicking. Includes playground areas and waterfront cafés.',
        emoji: '🌳',
        tag: 'Nature',
        isAsset: false,
        activities: ['Walking', 'Cycling', 'Boating'],
        reviewCount: 203,
        energyLevel: 'High',
        isIndoor: false,
      ),
      Place(
        id: 'het_park_fallback',
        name: 'Het Park',
        address: 'Het Park, Rotterdam',
        rating: 4.1,
        photos: ['https://images.unsplash.com/photo-1569587112025-0d460e81a126?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['park', 'natural_feature'],
        location: const PlaceLocation(lat: 51.9063, lng: 4.4618),
        description: 'Peaceful outdoor urban oasis featuring beautifully landscaped gardens, rose beds, and tree-lined paths. Perfect spot for morning runs, family picnics, and peaceful moments near the Euromast tower.',
        emoji: '🌺',
        tag: 'Garden',
        isAsset: false,
        activities: ['Walking', 'Picnic', 'Gardens'],
        reviewCount: 142,
        energyLevel: 'Low',
        isIndoor: false,
      ),
      
      // === FOOD ===
      Place(
        id: 'fenix_food_factory_fallback',
        name: 'Fenix Food Factory',
        address: 'Veerlaan 19D, 3072 AN Rotterdam',
        rating: 4.2,
        photos: ['https://images.unsplash.com/photo-1555396273-367ea4eb4db5?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['restaurant', 'food'],
        location: const PlaceLocation(lat: 51.9058, lng: 4.4903),
        description: 'Relaxed indoor culinary journey in a former warehouse featuring artisanal food producers, craft breweries, and specialty restaurants. Enjoy locally-sourced ingredients and innovative dining concepts.',
        emoji: '🍽️',
        tag: 'Local Food',
        isAsset: false,
        activities: ['Dining', 'Shopping', 'Local Products'],
        reviewCount: 156,
        energyLevel: 'Low',
        isIndoor: true,
      ),
      Place(
        id: 'witte_de_with_fallback',
        name: 'Witte de Withstraat',
        address: 'Witte de Withstraat, Rotterdam',
        rating: 4.3,
        photos: ['https://images.unsplash.com/photo-1514933651103-005eec06c04b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['restaurant', 'cafe', 'bar'],
        location: const PlaceLocation(lat: 51.9142, lng: 4.4736),
        description: 'Vibrant outdoor cultural street lined with trendy restaurants, cozy cafés, art galleries, and boutique shops. Rotterdam\'s creative heart comes alive at night with live music venues and bustling terraces.',
        emoji: '🍻',
        tag: 'Nightlife',
        isAsset: false,
        activities: ['Dining', 'Nightlife', 'Culture'],
        reviewCount: 298,
        energyLevel: 'High',
        isIndoor: false,
      ),
      
      // === CULTURE ===
      Place(
        id: 'boijmans_museum_fallback',
        name: 'Museum Boijmans Van Beuningen',
        address: 'Museumpark 18, 3015 CX Rotterdam',
        rating: 4.2,
        photos: ['https://images.unsplash.com/photo-1554072675-66db59dba46f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['museum', 'art_gallery'],
        location: const PlaceLocation(lat: 51.9142, lng: 4.4697),
        description: 'Prestigious indoor art sanctuary housing masterpieces from Van Gogh to Picasso, plus contemporary installations. Features rotating exhibitions, sculpture garden, and interactive digital art experiences.',
        emoji: '🖼️',
        tag: 'Art',
        isAsset: false,
        activities: ['Art', 'Culture', 'History'],
        reviewCount: 224,
        energyLevel: 'Low',
        isIndoor: true,
      ),
      Place(
        id: 'maritime_museum_fallback',
        name: 'Maritime Museum Rotterdam',
        address: 'Leuvehaven 1, 3011 EA Rotterdam',
        rating: 4.1,
        photos: ['https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['museum'],
        location: const PlaceLocation(lat: 51.9165, lng: 4.4813),
        description: 'Discover Rotterdam\'s maritime history and shipping heritage.',
        emoji: '⚓',
        tag: 'Maritime',
        isAsset: false,
        activities: ['History', 'Maritime', 'Education'],
      ),
      
      // === ACTIVITIES ===
      Place(
        id: 'de_doelen_fallback',
        name: 'De Doelen Concert Hall',
        address: 'Schouwburgplein 50, 3012 CL Rotterdam',
        rating: 4.4,
        photos: ['https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['amusement_park', 'establishment'],
        location: const PlaceLocation(lat: 51.9208, lng: 4.4803),
        description: 'Premier concert hall hosting classical and contemporary music.',
        emoji: '🎵',
        tag: 'Music',
        isAsset: false,
        activities: ['Music', 'Concerts', 'Entertainment'],
      ),
      Place(
        id: 'climbing_wall_fallback',
        name: 'Klimcentrum Rotterdam',
        address: 'Baan 10, 3071 AA Rotterdam',
        rating: 4.0,
        photos: ['https://images.unsplash.com/photo-1522778119026-d647f0596c20?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
        types: ['gym', 'sports_complex'],
        location: const PlaceLocation(lat: 51.8967, lng: 4.4681),
        description: 'Indoor climbing center with routes for all skill levels.',
        emoji: '🧗',
        tag: 'Sports',
        isAsset: false,
        activities: ['Climbing', 'Sports', 'Fitness'],
      ),
    ],
    // Removed San Francisco fallback data to prevent incorrect location content
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

  // 🚨 SMART CACHING: Enable controlled API calls with intelligent caching
  static const bool _enableSmartApiCalls = true; // Smart caching enabled!

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
    // Skip persistent storage for now to ensure fresh data
    // final storedPlaces = await _loadFromPersistentStorage(cacheKey);
    // if (storedPlaces != null && storedPlaces.isNotEmpty) {
    //   debugPrint('💾 Using persistent storage for $cacheKey (🚫 NO API CALLS!)');
    //   _updateCache(cacheKey, storedPlaces);
    //   return storedPlaces;
    // }

    // 🎯 OFFLINE-FIRST STRATEGY: ALWAYS use fallbacks, NO API calls
    final fallbacksForCity = _fallbackPlaces[cityName];
    
    if (fallbacksForCity != null && fallbacksForCity.isNotEmpty) {
      debugPrint('🏗️ Using rich offline content for $cityName (🚫 ZERO API CALLS!)');
      final placesWithOpeningHours = _addOpeningHoursToPlaces(fallbacksForCity);
      _updateCache(cacheKey, placesWithOpeningHours);
      await _saveToPersistentStorage(cacheKey, placesWithOpeningHours);
      return placesWithOpeningHours;
    }

    // 🚨 EMERGENCY FALLBACK: Create content without any API calls
    debugPrint('🆘 Creating emergency fallback content for $cityName (🚫 ZERO API CALLS!)');
    final emergencyPlaces = [_getDefaultPlace(cityName)];
    final emergencyPlacesWithHours = _addOpeningHoursToPlaces(emergencyPlaces);
    _updateCache(cacheKey, emergencyPlacesWithHours);
    await _saveToPersistentStorage(cacheKey, emergencyPlacesWithHours);
    return emergencyPlacesWithHours;

    // 🚨 DEAD CODE: API calling section completely removed to eliminate all API usage
    // This ensures ZERO API calls are made under any circumstances
  }

  // 🕐 OPENING HOURS HELPER: Add realistic opening hours to places
  List<Place> _addOpeningHoursToPlaces(List<Place> places) {
    return places.map((place) {
      // If place already has opening hours, return as is
      if (place.openingHours != null) {
        return place;
      }
      
      // Generate opening hours based on place types
      final openingHours = OpeningHoursService.generateOpeningHours(place.types);
      
      // Return place with opening hours
      return place.copyWith(openingHours: openingHours);
    }).toList();
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
    final placeTypes = ['point_of_interest', 'tourist_attraction'];
    return Place(
      id: 'default_place',
      name: 'Popular Place in $cityName',
      address: '$cityName, Netherlands',
      rating: 4.5,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: placeTypes,
      location: const PlaceLocation(lat: 0.0, lng: 0.0),
      description: 'A popular destination in $cityName',
      emoji: '🏙️',
      tag: 'Popular',
      isAsset: true,
      activities: ['Sightseeing', 'Culture', 'Food'],
      openingHours: OpeningHoursService.generateOpeningHours(placeTypes),
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
    if (!_enableSmartApiCalls) {
      debugPrint('🚫 Smart API calls disabled - use offline content');
      return build(city: city);
    }
    
    debugPrint('🔄 Force refresh with smart caching for: ${city ?? "default"}');
    
    // Clear cache for this city and rebuild
    final cacheKey = city ?? 'Rotterdam';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('places_cache_$cacheKey');
    await prefs.remove('places_timestamp_$cacheKey');
    
    return build(city: city);
  }
} 