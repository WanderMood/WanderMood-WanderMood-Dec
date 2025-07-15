import 'package:flutter_google_maps_webservices/places.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../models/place.dart';
import '../services/places_service.dart';
import '../services/opening_hours_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../../../features/location/services/location_service.dart';

part 'explore_places_provider.g.dart';

@riverpod
class ExplorePlaces extends _$ExplorePlaces {
  // Cache for broad place data
  static final Map<String, List<Place>> _broadCache = {};
  static final Map<String, DateTime> _broadCacheTimestamps = {};
  static const Duration _broadCacheValidDuration = Duration(hours: 24); // 24 hour cache for broad data
  
  // Track last location to prevent redundant API calls
  static Position? _lastLocation;
  static String? _lastCityName;
  
  /// Simple distance calculation to check if location changed significantly
  static bool _hasLocationChanged(double lat1, double lng1, double lat2, double lng2, {required double threshold}) {
    final distance = math.sqrt(math.pow(lat2 - lat1, 2) + math.pow(lng2 - lng1, 2));
    return distance > threshold;
  }
  
  // Comprehensive search queries for broad data fetching - EXPANDED to cover ALL filters
  static const List<String> _comprehensiveSearchQueries = [
    // === RESTAURANTS & FINE DINING ===
    'Grace Restaurant Rotterdam',       // Specific popular restaurant
    'Noya Restaurant Rotterdam',        // Specific popular restaurant  
    'Supermercado Rotterdam',          // Specific popular restaurant
    'FG Restaurant Rotterdam',          // Michelin star restaurant
    'Zeezout Rotterdam',               // Popular seafood
    'Restaurant Fitzgerald Rotterdam',  // Fine dining
    'Restaurant De Jongens Rotterdam',  // Local favorite
    'best restaurants Rotterdam',
    'michelin restaurants Rotterdam',
    'fine dining Rotterdam',
    'seafood restaurants Rotterdam',
    'asian restaurants Rotterdam',
    'italian restaurants Rotterdam',
    'mediterranean restaurants Rotterdam',
    'vegan restaurants Rotterdam',
    'halal restaurants Rotterdam',
    'gluten free restaurants Rotterdam',

    // === BARS & NIGHTLIFE ===
    '1NUL8 Rotterdam',                 // Specific popular bar
    'The Oyster Club Rotterdam',       // Specific popular bar  
    'Biergarten Rotterdam',            // Specific beer garden
    'Thoms Rotterdam',                 // Specific party spot
    'De Witte Aap Rotterdam',         // Specific party venue
    'Café Beurs Rotterdam',           // Specific party cafe
    'Caffe Italia Rotterdam',
    'Bar Restaurant Lemon Rotterdam',
    'Vrolijk Rotterdam',              // LGBTQ+ venue
    'rooftop bars Rotterdam',
    'cocktail bars Rotterdam',
    'craft beer Rotterdam',
    'wine bars Rotterdam',
    'speakeasy Rotterdam',
    'hidden bars Rotterdam',
    'best nightlife Rotterdam',
    'dance clubs Rotterdam',
    'live music venues Rotterdam',
    'gay bars Rotterdam',
    'lgbtq bars Rotterdam',

    // === CAFES & COFFEE ===
    'best coffee Rotterdam',
    'specialty coffee Rotterdam',
    'cozy cafes Rotterdam',
    'wifi cafes Rotterdam',
    'breakfast cafes Rotterdam',
    'brunch Rotterdam',
    'local coffee shops Rotterdam',
    'hipster cafes Rotterdam',
    'study cafes Rotterdam',

    // === CULTURAL & FAMILY ATTRACTIONS ===
    'Diergaarde Blijdorp Rotterdam',  // Rotterdam Zoo
    'Boijmans van Beuningen Rotterdam', // Museum
    'Kunsthal Rotterdam',
    'Maritiem Museum Rotterdam',
    'Euromast Rotterdam',
    'Markthal Rotterdam',
    'Rotterdam Central Station',
    'Cube Houses Rotterdam',
    'Erasmus Bridge Rotterdam',
    'museums Rotterdam',
    'art galleries Rotterdam',
    'cultural attractions Rotterdam',
    'family activities Rotterdam',
    'kids activities Rotterdam',
    'tourist attractions Rotterdam',
    'architecture Rotterdam',
    'landmarks Rotterdam',

    // === SHOPPING & ENTERTAINMENT ===
    'Lijnbaan Rotterdam shopping',
    'Koopgoot Rotterdam',
    'Witte de Withstraat shopping',
    'vintage shops Rotterdam',
    'local boutiques Rotterdam',
    'markets Rotterdam',
    'shopping centers Rotterdam',
    'entertainment Rotterdam',
    'cinema Rotterdam',
    'theaters Rotterdam',

    // === PARKS & NATURE ===
    'Kralingse Bos Rotterdam',
    'Het Park Rotterdam',
    'Zuiderpark Rotterdam',
    'Vroesenpark Rotterdam',
    'parks Rotterdam',
    'outdoor activities Rotterdam',
    'walking routes Rotterdam',
    'bike routes Rotterdam',
    'green spaces Rotterdam',
    'waterfront Rotterdam',

    // === INSTAGRAMMABLE & AESTHETIC SPOTS ===
    'instagrammable spots Rotterdam',
    'photo spots Rotterdam',
    'aesthetic cafes Rotterdam',
    'rooftop views Rotterdam',
    'scenic views Rotterdam',
    'street art Rotterdam',
    'murals Rotterdam',
    'architecture photography Rotterdam',
    'sunset spots Rotterdam',
    'hidden gems Rotterdam',
    'unique venues Rotterdam',
    'design shops Rotterdam',
    'art spaces Rotterdam',

    // === WELLNESS & RELAXATION ===
    'spas Rotterdam',
    'wellness centers Rotterdam',
    'yoga studios Rotterdam',
    'massage Rotterdam',
    'fitness centers Rotterdam',
    'gyms Rotterdam',
    'swimming pools Rotterdam',
    'thermal baths Rotterdam',

    // === DIVERSE & INCLUSIVE VENUES ===
    'black owned restaurants Rotterdam',
    'diverse restaurants Rotterdam',
    'multicultural venues Rotterdam',
    'international cuisine Rotterdam',
    'ethnic restaurants Rotterdam',
    'cultural venues Rotterdam',
    'community centers Rotterdam',

    // === ACCESSIBILITY FOCUSED ===
    'accessible restaurants Rotterdam',
    'wheelchair accessible venues Rotterdam',
    'family friendly restaurants Rotterdam',
    'baby friendly cafes Rotterdam',
    'senior friendly venues Rotterdam',
    'quiet restaurants Rotterdam',

    // === ROMANTIC & SPECIAL OCCASIONS ===
    'romantic restaurants Rotterdam',
    'date night Rotterdam',
    'romantic bars Rotterdam',
    'intimate venues Rotterdam',
    'special occasion restaurants Rotterdam',
    'wine tasting Rotterdam',
    'champagne bars Rotterdam',

    // === UNIQUE EXPERIENCES ===
    'boat restaurants Rotterdam',
    'floating venues Rotterdam',
    'unique dining Rotterdam',
    'experimental venues Rotterdam',
    'pop up restaurants Rotterdam',
    'food trucks Rotterdam',
    'street food Rotterdam',
    'local markets Rotterdam',

    // === SEASONAL & TIME-BASED ===
    'best lunch spots Rotterdam',
    'breakfast places Rotterdam',
    'late night food Rotterdam',
    'sunday brunch Rotterdam',
    'outdoor dining Rotterdam',
    'heated terraces Rotterdam',
    'winter activities Rotterdam',
    'summer venues Rotterdam',
  ];

  // Enhanced metadata mapping for advanced filters
  final Map<String, Map<String, dynamic>> _filterMetadata = {
    // Dietary Preferences
    'vegan': {
      'keywords': ['vegan', 'plant-based', 'plant based', 'vegetarian'],
      'types': ['restaurant', 'cafe', 'bakery', 'food'],
      'boost_rating': 0.2, // Boost rating for vegan places
    },
    'vegetarian': {
      'keywords': ['vegetarian', 'veggie', 'vegan', 'plant'],
      'types': ['restaurant', 'cafe', 'bakery', 'food'],
      'boost_rating': 0.1,
    },
    'halal': {
      'keywords': ['halal', 'islamic', 'muslim', 'middle eastern', 'turkish', 'moroccan'],
      'types': ['restaurant', 'cafe', 'food'],
      'boost_rating': 0.2,
    },
    'gluten_free': {
      'keywords': ['gluten free', 'gluten-free', 'celiac', 'wheat free'],
      'types': ['restaurant', 'cafe', 'bakery', 'food'],
      'boost_rating': 0.2,
    },
    
    // Accessibility & Inclusion
    'wheelchair_accessible': {
      'keywords': ['accessible', 'wheelchair', 'disability', 'ramp', 'elevator'],
      'types': ['establishment'],
      'rating_threshold': 4.0, // Assume higher-rated places are more accessible
    },
    'lgbtq_friendly': {
      'keywords': ['lgbtq', 'gay', 'lesbian', 'queer', 'pride', 'inclusive', 'diverse'],
      'types': ['bar', 'restaurant', 'cafe', 'night_club'],
      'rating_threshold': 4.2,
    },
    'baby_friendly': {
      'keywords': ['family', 'kids', 'children', 'baby', 'stroller', 'playground'],
      'types': ['restaurant', 'cafe', 'park', 'zoo', 'museum'],
      'rating_threshold': 4.0,
    },
    'senior_friendly': {
      'keywords': ['senior', 'elderly', 'accessible', 'quiet', 'comfortable'],
      'types': ['restaurant', 'cafe', 'park', 'museum', 'library'],
      'rating_threshold': 4.0,
    },
    'black_owned': {
      'keywords': ['black owned', 'african', 'caribbean', 'soul food', 'ethnic'],
      'types': ['restaurant', 'cafe', 'store', 'business'],
      'boost_rating': 0.3,
    },
    
    // Photo & Aesthetic
    'instagrammable': {
      'keywords': ['instagram', 'photo', 'aesthetic', 'beautiful', 'scenic', 'view', 'rooftop'],
      'types': ['tourist_attraction', 'restaurant', 'cafe', 'art_gallery', 'park'],
      'rating_threshold': 4.2,
    },
    'aesthetic_spaces': {
      'keywords': ['aesthetic', 'design', 'modern', 'architecture', 'art', 'stylish', 'trendy'],
      'types': ['restaurant', 'cafe', 'art_gallery', 'hotel', 'store'],
      'rating_threshold': 4.0,
    },
    'scenic_views': {
      'keywords': ['view', 'scenic', 'panoramic', 'overlooking', 'waterfront', 'rooftop', 'terrace'],
      'types': ['restaurant', 'bar', 'tourist_attraction', 'park'],
      'rating_threshold': 4.0,
    },
    'best_at_sunset': {
      'keywords': ['sunset', 'evening', 'golden hour', 'view', 'terrace', 'rooftop'],
      'types': ['bar', 'restaurant', 'tourist_attraction', 'park'],
      'rating_threshold': 4.0,
    },
    
    // Comfort & Convenience
    'wifi_available': {
      'keywords': ['wifi', 'internet', 'coworking', 'laptop', 'work', 'study'],
      'types': ['cafe', 'restaurant', 'library', 'hotel'],
      'rating_threshold': 3.8,
    },
    'charging_points': {
      'keywords': ['charging', 'power', 'electric', 'outlets', 'usb'],
      'types': ['cafe', 'restaurant', 'hotel', 'shopping_mall'],
      'rating_threshold': 3.8,
    },
    'parking_available': {
      'keywords': ['parking', 'garage', 'valet', 'free parking'],
      'types': ['restaurant', 'shopping_mall', 'hotel', 'tourist_attraction'],
      'rating_threshold': 3.5,
    },
    'credit_cards': {
      'keywords': ['cards', 'payment', 'visa', 'mastercard', 'contactless'],
      'types': ['restaurant', 'store', 'hotel'],
      'rating_threshold': 3.5,
    },
  };

  // Map categories to place types for local filtering
  final Map<String, List<String>> _categoryToPlaceTypes = {
    'All': [], // Empty means show all
    'Popular': ['tourist_attraction', 'point_of_interest'],
    'Accommodations': ['lodging', 'hotel', 'apartment_rental', 'rv_park'],
    'Nature': ['park', 'natural_feature', 'zoo', 'campground'],
    'Culture': ['museum', 'art_gallery', 'library', 'university', 'theater'],
    'Food': ['restaurant', 'cafe', 'bakery', 'food', 'meal_takeaway'],
    'Activities': ['amusement_park', 'aquarium', 'bowling_alley', 'gym', 'spa'],
    'History': ['museum', 'cemetery', 'church', 'mosque', 'synagogue', 'hindu_temple'],
    'Shopping': ['shopping_mall', 'store', 'shopping_center'],
    'Nightlife': ['bar', 'night_club', 'casino'],
    'Entertainment': ['movie_theater', 'amusement_park', 'stadium', 'theater'],
  };

  @override
  Future<List<Place>> build({String? city}) async {
    final cityName = city ?? 'Rotterdam';
    
    // Check if we already have recent data for the same location to prevent rebuilds
    if (_lastCityName == cityName && _lastLocation != null) {
      final broadCacheKey = '${cityName}_broad_cache';
      if (_broadCache.containsKey(broadCacheKey)) {
        final cachedTime = _broadCacheTimestamps[broadCacheKey];
        if (cachedTime != null && 
            DateTime.now().difference(cachedTime) < const Duration(minutes: 2)) {
          debugPrint('🚀 Using recent build cache for $cityName (${_broadCache[broadCacheKey]!.length} places)');
          return _broadCache[broadCacheKey]!;
        }
      }
    }
    
    // Check if we have broad cached data for this city
    final broadCacheKey = '${cityName}_broad_cache';
    
    // First check memory cache
    if (_broadCache.containsKey(broadCacheKey) && 
        _broadCacheTimestamps.containsKey(broadCacheKey)) {
      final cacheTime = _broadCacheTimestamps[broadCacheKey]!;
      final isExpired = DateTime.now().difference(cacheTime) > _broadCacheValidDuration;
      
      if (!isExpired) {
        debugPrint('📋 Using cached data for $cityName (${_broadCache[broadCacheKey]!.length} places)');
        return _broadCache[broadCacheKey]!;
      } else {
        debugPrint('🗑️ Cache expired for $cityName, fetching fresh data');
        _broadCache.remove(broadCacheKey);
        _broadCacheTimestamps.remove(broadCacheKey);
      }
    }
    
    // Check persistent storage cache
    final persistentCachedPlaces = await _loadBroadCacheFromPersistentStorage(broadCacheKey);
    if (persistentCachedPlaces != null) {
      debugPrint('💾 Loading $cityName data from persistent storage (${persistentCachedPlaces.length} places)');
      _updateBroadCache(broadCacheKey, persistentCachedPlaces);
      return persistentCachedPlaces;
    }

    debugPrint('🌍 No cached data found for $cityName, fetching fresh comprehensive data...');

    // Debounce the data fetching to prevent rapid successive builds
    return await _buildPlacesInternal(cityName, broadCacheKey);
  }

  /// Internal method for building places with location optimization
  Future<List<Place>> _buildPlacesInternal(String cityName, String broadCacheKey) async {
    try {
      // Get current location for nearby search - with fallback based on city
      Position currentPosition;
      try {
        currentPosition = await LocationService.getCurrentLocation();
        
        // Check if location changed significantly since last fetch
        if (_lastLocation != null) {
          final locationChanged = _hasLocationChanged(
            _lastLocation!.latitude, _lastLocation!.longitude,
            currentPosition.latitude, currentPosition.longitude,
            threshold: 0.001, // ~100 meters
          );
          
          if (!locationChanged && _lastCityName == cityName) {
            debugPrint('📍 Location unchanged for $cityName, returning cached data');
            return _broadCache[broadCacheKey] ?? _getMinimalFallbackPlaces(cityName);
          }
        }
        
        // Check if location seems unrealistic for Netherlands (fallback to Rotterdam)
        if (currentPosition.latitude < 50.0 || currentPosition.latitude > 54.0 || 
            currentPosition.longitude < 3.0 || currentPosition.longitude > 8.0) {
          debugPrint('🎯 Detected simulator coordinates, using $cityName fallback');
          currentPosition = _getCityCoordinates(cityName);
        }
      } catch (e) {
        debugPrint('⚠️ Location service failed, using $cityName fallback: $e');
        currentPosition = _getCityCoordinates(cityName);
      }
      
      // Update tracking variables
      _lastLocation = currentPosition;
      _lastCityName = cityName;
      
      debugPrint('📍 Using position for $cityName: ${currentPosition.latitude}, ${currentPosition.longitude}');
      
      // Fetch comprehensive place data for the city
      final broadPlaces = await _fetchBroadPlaceData(cityName, currentPosition);
      
      if (broadPlaces.isNotEmpty) {
        debugPrint('✅ Fetched ${broadPlaces.length} places for $cityName');
        _updateBroadCache(broadCacheKey, broadPlaces);
        await _saveBroadCacheToPersistentStorage(broadCacheKey, broadPlaces);
        return broadPlaces;
      }
    } catch (e) {
      debugPrint('❌ Error fetching places for $cityName: $e');
    }

    // Final fallback to a few basic places
    debugPrint('⚠️ Using minimal fallback data for $cityName');
    return _getMinimalFallbackPlaces(cityName);
  }

  // Helper method to get coordinates for different cities
  Position _getCityCoordinates(String cityName) {
    Map<String, Map<String, double>> cityCoords = {
      'Rotterdam': {'lat': 51.9244, 'lng': 4.4777},
      'Amsterdam': {'lat': 52.3676, 'lng': 4.9041},
      'The Hague': {'lat': 52.0705, 'lng': 4.3007},
      'Utrecht': {'lat': 52.0907, 'lng': 5.1214},
      'Eindhoven': {'lat': 51.4416, 'lng': 5.4697},
      'Groningen': {'lat': 53.2194, 'lng': 6.5665},
    };
    
    final coords = cityCoords[cityName] ?? cityCoords['Rotterdam']!;
    
    return Position(
      latitude: coords['lat']!,
      longitude: coords['lng']!,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  // New method to filter places by category locally
  List<Place> filterPlacesByCategory(String? category, {String? city}) {
    final cityName = city ?? 'Rotterdam';
    final broadCacheKey = '${cityName}_broad_cache';
    
    // Get all cached places
    final allPlaces = _broadCache[broadCacheKey] ?? [];
    
    if (allPlaces.isEmpty) {
      debugPrint('⚠️ No cached places available for filtering');
      return [];
    }

    // If no category or "All", return all places
    if (category == null || category == 'All') {
      debugPrint('📋 Returning all ${allPlaces.length} places');
      return allPlaces;
    }

    // Get place types for this category
    final targetTypes = _categoryToPlaceTypes[category] ?? [];
    
    if (targetTypes.isEmpty) {
      debugPrint('⚠️ Unknown category: $category, returning all places');
      return allPlaces;
    }

    // Filter places locally
    final filteredPlaces = allPlaces.where((place) {
      // Check if place types overlap with target types
      return place.types.any((type) => targetTypes.contains(type));
    }).toList();

    debugPrint('🔍 Filtered $category: ${filteredPlaces.length} places from ${allPlaces.length} total');

    // If no results, return popular places as fallback
    if (filteredPlaces.isEmpty) {
      debugPrint('🎯 No $category places found, returning popular places as fallback');
      final popularPlaces = allPlaces.where((place) {
        return place.types.any((type) => ['tourist_attraction', 'point_of_interest'].contains(type));
      }).toList();
      
      if (popularPlaces.isNotEmpty) {
        return popularPlaces.take(10).toList();
      }
      
      // If still no popular places, return top-rated places
      final topRated = List<Place>.from(allPlaces)
        ..sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
      return topRated.take(10).toList();
    }

    return filteredPlaces;
  }

  Future<List<Place>> _fetchBroadPlaceData(String cityName, Position currentPosition) async {
    final List<Place> allPlaces = [];
    final Set<String> usedPlaceIds = {};
    
    // Generate city-specific search queries
    final allQueries = _generateCitySpecificQueries(cityName);
    
    // **OPTIMIZATION 1: Smart Query Selection**
    // Prioritize queries that are more likely to return results
    final prioritizedQueries = _prioritizeQueries(allQueries, cityName);
    
    // **OPTIMIZATION 2: Parallel Processing**
    // Process queries in parallel batches instead of sequential
    final batchSize = 8; // Process 8 queries simultaneously
    final maxQueries = 25; // Limit total queries to most important ones
    
    final selectedQueries = prioritizedQueries.take(maxQueries).toList();
    
    debugPrint('🚀 SPEED OPTIMIZATION: Processing ${selectedQueries.length} high-priority queries in parallel batches of $batchSize');
    
    // Process in parallel batches
    for (int i = 0; i < selectedQueries.length; i += batchSize) {
      final batch = selectedQueries.skip(i).take(batchSize).toList();
      
      debugPrint('🔄 Processing batch ${(i ~/ batchSize) + 1}: ${batch.length} queries in parallel');
      
      // **PARALLEL EXECUTION** - Run all queries in this batch simultaneously
      final batchResults = await Future.wait(
        batch.map((query) => _executeSingleQuery(query, currentPosition)),
        eagerError: false, // Don't fail entire batch if one query fails
      );
      
      // Process results from parallel batch
      int addedFromBatch = 0;
      for (int j = 0; j < batchResults.length; j++) {
        final results = batchResults[j];
        final query = batch[j];
        
        if (results.isNotEmpty) {
          debugPrint('✅ ${query}: Found ${results.length} places');
          
          // Smart result selection based on query type
          final resultLimit = _getResultLimitForQuery(query);
          
          for (final result in results.take(resultLimit)) {
            if (!usedPlaceIds.contains(result.placeId)) {
              final place = await _convertToPlace(result, currentPosition);
              if (place != null) {
                allPlaces.add(place);
                usedPlaceIds.add(result.placeId);
                addedFromBatch++;
              }
            }
          }
        } else {
          debugPrint('❌ ${query}: No results');
        }
      }
      
      debugPrint('📈 Batch ${(i ~/ batchSize) + 1} completed: Added $addedFromBatch places (Total: ${allPlaces.length})');
      
      // **OPTIMIZATION 3: Early Termination**
      // Stop early if we have enough places
      if (allPlaces.length >= 60) {
        debugPrint('🎯 EARLY TERMINATION: Reached ${allPlaces.length} places, stopping for faster loading');
        break;
      }
      
      // Small delay between batches to respect rate limits
      if (i + batchSize < selectedQueries.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // **OPTIMIZATION 4: Smart Sorting**
    // Sort by rating and distance for best results first
    allPlaces.sort((a, b) {
      final ratingDiff = (b.rating ?? 0.0).compareTo(a.rating ?? 0.0);
      if (ratingDiff != 0) return ratingDiff;
      
      final aDistance = _calculateDistance(currentPosition, a.location);
      final bDistance = _calculateDistance(currentPosition, b.location);
      return aDistance.compareTo(bDistance);
    });

    debugPrint('🎉 SPEED OPTIMIZATION COMPLETE: Collected ${allPlaces.length} unique places for $cityName');
    return allPlaces;
  }

  /// Execute a single query with error handling
  Future<List<PlacesSearchResult>> _executeSingleQuery(String query, Position currentPosition) async {
    try {
      final service = ref.read(placesServiceProvider.notifier);
      final results = await service.searchPlaces(query);
      return results;
    } catch (e) {
      debugPrint('❌ Query failed: $query - $e');
      return [];
    }
  }

  /// Prioritize queries based on likelihood of returning good results
  List<String> _prioritizeQueries(List<String> allQueries, String cityName) {
    // **HIGH PRIORITY**: Queries that almost always return results
    final highPriority = <String>[];
    
    // **MEDIUM PRIORITY**: Queries that often return results
    final mediumPriority = <String>[];
    
    // **LOW PRIORITY**: Queries that may return zero results
    final lowPriority = <String>[];
    
    for (final query in allQueries) {
      if (_isHighPriorityQuery(query)) {
        highPriority.add(query);
      } else if (_isMediumPriorityQuery(query)) {
        mediumPriority.add(query);
      } else {
        lowPriority.add(query);
      }
    }
    
    // Return prioritized list
    return [
      ...highPriority,
      ...mediumPriority,
      ...lowPriority,
    ];
  }

  /// Check if query is high priority (almost always returns results)
  bool _isHighPriorityQuery(String query) {
    return query.contains('restaurants') || 
           query.contains('cafes') || 
           query.contains('tourist attractions') ||
           query.contains('museums') ||
           query.contains('parks') ||
           query.contains('bars') ||
           query.contains('shopping');
  }

  /// Check if query is medium priority (often returns results)
  bool _isMediumPriorityQuery(String query) {
    return query.contains('hotels') ||
           query.contains('activities') ||
           query.contains('entertainment') ||
           query.contains('food') ||
           query.contains('nightlife') ||
           query.contains('culture');
  }

  /// Get result limit based on query type
  int _getResultLimitForQuery(String query) {
    // High-value queries get more results
    if (query.contains('best') || query.contains('top') || query.contains('popular')) {
      return 4;
    }
    
    // Specific categories get moderate results
    if (query.contains('restaurants') || query.contains('cafes') || query.contains('bars')) {
      return 3;
    }
    
    // Niche categories get fewer results but keep them
    if (query.contains('vegan') || query.contains('halal') || query.contains('accessible')) {
      return 5;
    }
    
    // Default limit
    return 2;
  }

  /// Generate city-specific search queries
  List<String> _generateCitySpecificQueries(String cityName) {
    return [
      // === HIGH PRIORITY: Almost always return results ===
      'best restaurants $cityName',
      'popular restaurants $cityName',
      'cafes $cityName',
      'coffee shops $cityName',
      'tourist attractions $cityName',
      'museums $cityName',
      'parks $cityName',
      'best bars $cityName',
      'shopping $cityName',
      'things to do $cityName',
      
      // === MEDIUM PRIORITY: Often return results ===
      'hotels $cityName',
      'activities $cityName',
      'entertainment $cityName',
      'nightlife $cityName',
      'cultural attractions $cityName',
      'local restaurants $cityName',
      'markets $cityName',
      'historic sites $cityName',
      'landmarks $cityName',
      'fine dining $cityName',
      
      // === LOWER PRIORITY: May return fewer results ===
      'michelin restaurants $cityName',
      'craft beer $cityName',
      'cocktail bars $cityName',
      'rooftop bars $cityName',
      'art galleries $cityName',
      'theaters $cityName',
      'tours $cityName',
      'experiences $cityName',
      'gardens $cityName',
      'outdoor activities $cityName',
      'boutiques $cityName',
      'local shops $cityName',
      'vegan restaurants $cityName',
      'halal restaurants $cityName',
      'family friendly $cityName',
      'instagrammable spots $cityName',
      'photo spots $cityName',
      'hidden gems $cityName',
      'local favorites $cityName',
      'unique venues $cityName',
      'brunch spots $cityName',
      'bakeries $cityName',
      'specialty coffee $cityName',
      'wine bars $cityName',
      'rooftop restaurants $cityName',
      'waterfront $cityName',
      'viewpoints $cityName',
      'street art $cityName',
      'architecture $cityName',
      'scenic spots $cityName',
      'bike tours $cityName',
      'walking tours $cityName',
    ];
  }

  Future<Place?> _convertToPlace(PlacesSearchResult result, Position currentPosition) async {
    try {
      // Get basic information without expensive place details API call for now
      // This will be much faster and still provide comprehensive data
      
      // Calculate distance
      final distance = _calculateDistance(currentPosition, PlaceLocation(
        lat: result.geometry?.location.lat ?? 0,
        lng: result.geometry?.location.lng ?? 0,
      ));

      // Convert photos to URLs
      final photoUrls = <String>[];
      if (result.photos != null && result.photos!.isNotEmpty) {
        for (final photo in result.photos!.take(2)) { // Reduced to 2 photos for speed
          try {
            final service = ref.read(placesServiceProvider.notifier);
            final photoUrl = service.getPhotoUrl(photo.photoReference);
            photoUrls.add(photoUrl);
          } catch (e) {
            debugPrint('❌ Error getting photo URL: $e');
          }
        }
      }

      // Get activities based on types
      final activities = _getActivitiesFromTypes(result.types ?? []);
      
      // Get energy level based on place type
      final energyLevel = _getEnergyLevelFromTypes(result.types ?? []);
      
      // Determine if indoor
      final isIndoor = _isIndoorPlace(result.types ?? []);

      // Enhanced description with metadata for better filtering
      final enhancedDescription = _generateEnhancedDescription(result, {});
      
      return Place(
        id: 'google_${result.placeId}',
        name: result.name ?? 'Unknown Place',
        address: result.formattedAddress ?? result.vicinity ?? '',
        rating: result.rating?.toDouble() ?? 0.0,
        photos: photoUrls.isNotEmpty ? photoUrls : _getFallbackImageUrls(result.types ?? []),
        types: result.types ?? [],
        location: PlaceLocation(
          lat: result.geometry?.location.lat ?? 0,
          lng: result.geometry?.location.lng ?? 0,
        ),
        description: enhancedDescription,
        emoji: _getEmojiForPlace(result.types ?? []),
        tag: _getTagForPlace(result.types ?? []),
        isAsset: false,
        activities: activities,
        reviewCount: 0, // Places API data doesn't include review count in basic search
        energyLevel: energyLevel,
        isIndoor: isIndoor,
        openingHours: null, // Skip opening hours for now to improve speed
      );
    } catch (e) {
      debugPrint('❌ Error converting place: $e');
      return null;
    }
  }

  double _calculateDistance(dynamic pos1, PlaceLocation pos2) {
    if (pos1 is Position) {
      return Geolocator.distanceBetween(pos1.latitude, pos1.longitude, pos2.lat, pos2.lng) / 1000;
    } else if (pos1 is PlaceLocation) {
      return Geolocator.distanceBetween(pos1.lat, pos1.lng, pos2.lat, pos2.lng) / 1000;
    }
    return 0.0;
  }

  List<String> _getActivitiesFromTypes(List<String> types) {
    final activities = <String>[];
    
    for (final type in types) {
      switch (type) {
        case 'restaurant':
        case 'cafe':
        case 'bar':
        case 'meal_takeaway':
          activities.add('Dining');
          break;
        case 'museum':
        case 'art_gallery':
          activities.add('Culture');
          break;
        case 'park':
        case 'natural_feature':
          activities.add('Nature');
          break;
        case 'tourist_attraction':
        case 'point_of_interest':
          activities.add('Sightseeing');
          break;
        case 'shopping_mall':
        case 'store':
          activities.add('Shopping');
          break;
        case 'amusement_park':
        case 'aquarium':
        case 'zoo':
          activities.add('Entertainment');
          break;
        case 'gym':
        case 'spa':
          activities.add('Wellness');
          break;
        case 'church':
        case 'mosque':
        case 'synagogue':
          activities.add('Spiritual');
          break;
      }
    }
    
    return activities.toSet().toList();
  }

  String _getEnergyLevelFromTypes(List<String> types) {
    if (types.any((type) => ['gym', 'amusement_park', 'zoo', 'sports_complex'].contains(type))) {
      return 'High';
    }
    if (types.any((type) => ['spa', 'library', 'cafe', 'art_gallery'].contains(type))) {
      return 'Low';
    }
    return 'Medium';
  }

  bool _isIndoorPlace(List<String> types) {
    final indoorTypes = ['restaurant', 'cafe', 'museum', 'art_gallery', 'shopping_mall', 'spa', 'gym', 'library'];
    final outdoorTypes = ['park', 'zoo', 'campground', 'amusement_park'];
    
    if (types.any((type) => indoorTypes.contains(type))) return true;
    if (types.any((type) => outdoorTypes.contains(type))) return false;
    return false; // Default to outdoor if uncertain
  }

  String _generateDescription(PlacesSearchResult result) {
    final types = result.types ?? [];
    final name = result.name;
    
    if (types.contains('restaurant') || types.contains('cafe')) {
      return 'Discover culinary delights at $name. Enjoy delicious food and great atmosphere in this local dining spot.';
    }
    if (types.contains('museum') || types.contains('art_gallery')) {
      return 'Immerse yourself in culture at $name. Explore fascinating exhibitions and artistic treasures.';
    }
    if (types.contains('park')) {
      return 'Enjoy the outdoors at $name. Perfect for walking, relaxation, and connecting with nature.';
    }
    if (types.contains('tourist_attraction')) {
      return 'Experience the unique charm of $name. A must-visit destination that captures the essence of the area.';
    }
    
    return 'Discover $name, a popular local destination offering unique experiences and memorable moments.';
  }

  String _generateEnhancedDescription(PlacesSearchResult result, Map<String, dynamic> details) {
    final types = result.types ?? [];
    final name = result.name ?? '';
    final rating = result.rating ?? 0.0;
    
    // Start with base description
    String description = _generateDescription(result);
    
    // Add filter-friendly metadata based on place characteristics
    List<String> tags = [];
    
    // Add rating-based tags
    if (rating >= 4.5) tags.add('highly rated');
    if (rating >= 4.2) tags.add('excellent reviews');
    
    // Specific venue recognition and tagging
    final nameUpper = name.toUpperCase();
    
    // High-end restaurants
    if (nameUpper.contains('GRACE') || nameUpper.contains('NOYA') || nameUpper.contains('FG') ||
        nameUpper.contains('FITZGERALD') || nameUpper.contains('ZEEZOUT')) {
      tags.addAll(['fine dining', 'michelin quality', 'instagrammable', 'romantic', 'special occasion']);
    }
    
    // Popular bars and nightlife
    if (nameUpper.contains('1NUL8') || nameUpper.contains('OYSTER CLUB') || nameUpper.contains('THOMS') ||
        nameUpper.contains('DE WITTE AAP') || nameUpper.contains('CAFÉ BEURS')) {
      tags.addAll(['trendy bar', 'night out', 'social scene', 'instagrammable', 'best at night']);
    }
    
    // LGBTQ+ venues
    if (nameUpper.contains('VROLIJK') || nameUpper.contains('PINK') || nameUpper.contains('PRIDE')) {
      tags.addAll(['lgbtq friendly', 'inclusive environment', 'diverse clientele', 'safe space']);
    }
    
    // Cultural attractions
    if (nameUpper.contains('BOIJMANS') || nameUpper.contains('KUNSTHAL') || nameUpper.contains('MARITIEM') ||
        nameUpper.contains('EUROMAST') || nameUpper.contains('MARKTHAL')) {
      tags.addAll(['cultural landmark', 'tourist attraction', 'instagrammable', 'photo worthy', 'family friendly']);
    }
    
    // Zoo and family attractions
    if (nameUpper.contains('BLIJDORP') || nameUpper.contains('ZOO') || nameUpper.contains('DIERGAARDE')) {
      tags.addAll(['family friendly', 'kids activities', 'baby friendly', 'educational', 'outdoor fun']);
    }
    
    // Add type-based filter tags
    if (types.contains('restaurant') || types.contains('cafe')) {
      // Check for dietary options in name/description
      if (nameUpper.contains('VEGAN') || nameUpper.contains('PLANT') || nameUpper.contains('GREEN')) {
        tags.add('vegan friendly');
      }
      if (nameUpper.contains('HALAL') || nameUpper.contains('MIDDLE EASTERN') || nameUpper.contains('TURKISH') ||
          nameUpper.contains('MOROCCAN') || nameUpper.contains('PERSIAN')) {
        tags.add('halal options');
      }
      if (nameUpper.contains('GLUTEN FREE') || nameUpper.contains('CELIAC')) {
        tags.add('gluten free options');
      }
      
      // General restaurant tags
      if (rating >= 4.0) tags.add('family friendly');
      if (types.contains('cafe')) tags.add('wifi available');
      tags.add('credit cards accepted');
      
      // International cuisine tags
      if (nameUpper.contains('ASIA') || nameUpper.contains('SUSHI') || nameUpper.contains('THAI') ||
          nameUpper.contains('INDIAN') || nameUpper.contains('CHINESE')) {
        tags.add('international cuisine');
      }
    }
    
    // Add accessibility tags for highly rated places
    if (rating >= 4.0) {
      tags.add('accessible venue');
      if (types.contains('restaurant') || types.contains('cafe')) {
        tags.add('baby friendly');
      }
    }
    
    // Add photo-friendly tags
    if (types.contains('tourist_attraction') || types.contains('art_gallery') || 
        types.contains('museum') || nameUpper.contains('TOWER') ||
        nameUpper.contains('BRIDGE') || nameUpper.contains('VIEW') ||
        nameUpper.contains('ROOFTOP') || nameUpper.contains('TERRACE')) {
      tags.addAll(['instagrammable', 'photo worthy']);
    }
    
    if (types.contains('rooftop') || nameUpper.contains('ROOFTOP') || 
        nameUpper.contains('TERRACE') || rating >= 4.3) {
      tags.add('scenic views');
    }
    
    // Add convenience tags
    if (types.contains('shopping_mall') || types.contains('cafe') || types.contains('hotel')) {
      tags.addAll(['charging points available', 'parking available']);
    }
    
    // Add social inclusion tags for highly rated places
    if (rating >= 4.2) {
      tags.addAll(['inclusive environment', 'lgbtq friendly', 'diverse clientele']);
    }
    
    // Add aesthetic tags for art/design places
    if (types.contains('art_gallery') || types.contains('museum') || 
        nameUpper.contains('DESIGN') || nameUpper.contains('MODERN') ||
        nameUpper.contains('STUDIO') || nameUpper.contains('GALLERY')) {
      tags.addAll(['aesthetic spaces', 'artistic design']);
    }
    
    // Add time-based tags
    if (types.contains('bar') || types.contains('restaurant') && rating >= 4.0) {
      tags.add('best at sunset');
      if (types.contains('bar')) tags.add('best at night');
    }
    
    // Add location-specific tags
    if (nameUpper.contains('WATERFRONT') || nameUpper.contains('HARBOR') || nameUpper.contains('RIVER')) {
      tags.addAll(['waterfront location', 'scenic views']);
    }
    
    // Add cozy/romantic tags
    if (nameUpper.contains('INTIMATE') || nameUpper.contains('COZY') || nameUpper.contains('ROMANTIC') ||
        (types.contains('restaurant') && rating >= 4.3)) {
      tags.addAll(['cozy atmosphere', 'romantic setting']);
    }
    
    // Append metadata tags to description for filtering
    if (tags.isNotEmpty) {
      description += ' Features: ${tags.join(', ')}.';
    }
    
    return description;
  }

  List<String> _getFallbackImageUrls(List<String> types) {
    // Use existing fallback assets instead of broken Unsplash URLs
    if (types.contains('restaurant')) {
      return ['assets/images/fallbacks/restaurant.jpg'];
    }
    if (types.contains('cafe')) {
      return ['assets/images/fallbacks/cafe.jpg'];
    }
    if (types.contains('museum') || types.contains('art_gallery')) {
      return ['assets/images/fallbacks/museum.jpg'];
    }
    if (types.contains('park')) {
      return ['assets/images/fallbacks/park.jpg'];
    }
    if (types.contains('bar') || types.contains('night_club')) {
      return ['assets/images/fallbacks/bar.jpg'];
    }
    if (types.contains('lodging')) {
      return ['assets/images/fallbacks/hotel.jpg'];
    }
    // Default fallback for unknown types
    return ['assets/images/fallbacks/default.jpg'];
  }

  PlaceOpeningHours? _parseOpeningHours(dynamic openingHoursData) {
    if (openingHoursData == null) return null;
    
    try {
      final isOpen = openingHoursData['open_now'] as bool? ?? false;
      final weekdayText = List<String>.from(openingHoursData['weekday_text'] ?? []);
      
      return PlaceOpeningHours(
        isOpen: isOpen,
        currentStatus: isOpen ? 'Open' : 'Closed',
        weekdayText: weekdayText,
      );
    } catch (e) {
      debugPrint('❌ Error parsing opening hours: $e');
      return null;
    }
  }

  String _getEmojiForPlace(List<String> types) {
    if (types.contains('museum') || types.contains('art_gallery')) return '🎨';
    if (types.contains('restaurant') || types.contains('food')) return '🍽️';
    if (types.contains('park') || types.contains('natural_feature')) return '🌳';
    if (types.contains('tourist_attraction')) return '🏛️';
    if (types.contains('shopping_mall')) return '🛍️';
    if (types.contains('spa')) return '🧘';
    if (types.contains('gym')) return '💪';
    if (types.contains('bar')) return '🍺';
    return '📍';
  }

  String _getTagForPlace(List<String> types) {
    if (types.contains('museum') || types.contains('art_gallery')) return 'Culture';
    if (types.contains('restaurant') || types.contains('food')) return 'Food';
    if (types.contains('park')) return 'Nature';
    if (types.contains('tourist_attraction')) return 'Sightseeing';
    if (types.contains('shopping_mall')) return 'Shopping';
    if (types.contains('spa')) return 'Wellness';
    if (types.contains('lodging')) return 'Stay';
    return 'Popular';
  }

  List<Place> _getMinimalFallbackPlaces(String cityName) {
    // City-specific fallback places with correct coordinates
    switch (cityName.toLowerCase()) {
      case 'amsterdam':
        return [
          Place(
            id: 'fallback_rijksmuseum',
            name: 'Rijksmuseum',
            address: 'Museumstraat 1, 1071 XX Amsterdam, Netherlands',
            rating: 4.6,
            photos: ['https://images.unsplash.com/photo-1551818255-e6e10975bc17?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
            types: ['museum', 'tourist_attraction'],
            location: const PlaceLocation(lat: 52.3600, lng: 4.8852),
            description: 'World-renowned art museum featuring Dutch masterpieces and cultural treasures.',
            emoji: '🎨',
            tag: 'Museum',
            isAsset: false,
            activities: ['Culture', 'Art'],
            reviewCount: 50000,
            energyLevel: 'Medium energy',
            isIndoor: true,
          ),
          Place(
            id: 'fallback_vondelpark',
            name: 'Vondelpark',
            address: 'Vondelpark, Amsterdam, Netherlands',
            rating: 4.4,
            photos: ['https://images.unsplash.com/photo-1534351590666-13e3e96b5017?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
            types: ['park', 'tourist_attraction'],
            location: const PlaceLocation(lat: 52.3579, lng: 4.8686),
            description: 'Beautiful urban park perfect for walks, picnics, and outdoor activities.',
            emoji: '🌳',
            tag: 'Nature',
            isAsset: false,
            activities: ['Nature', 'Walking'],
            reviewCount: 25000,
            energyLevel: 'Low energy',
            isIndoor: false,
          ),
          Place(
            id: 'fallback_dam_square',
            name: 'Dam Square',
            address: 'Dam, Amsterdam, Netherlands',
            rating: 4.2,
            photos: ['https://images.unsplash.com/photo-1512470876302-972faa2aa9a4?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
            types: ['tourist_attraction', 'point_of_interest'],
            location: const PlaceLocation(lat: 52.3738, lng: 4.8910),
            description: 'Historic central square, heart of Amsterdam with royal palace and vibrant atmosphere.',
            emoji: '🏛️',
            tag: 'Landmark',
            isAsset: false,
            activities: ['Culture', 'History'],
            reviewCount: 30000,
            energyLevel: 'Medium energy',
            isIndoor: false,
          ),
        ];
        
      case 'utrecht':
        return [
          Place(
            id: 'fallback_dom_tower',
            name: 'Dom Tower Utrecht',
            address: 'Domplein 21, 3512 JE Utrecht, Netherlands',
      rating: 4.5,
            photos: ['https://images.unsplash.com/photo-1544644181-1484b3fdfc62?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
            types: ['tourist_attraction', 'historical_landmark'],
            location: const PlaceLocation(lat: 52.0907, lng: 5.1214),
            description: 'Iconic medieval bell tower offering panoramic views of Utrecht.',
            emoji: '🗼',
            tag: 'Landmark',
            isAsset: false,
            activities: ['Culture', 'History'],
            reviewCount: 15000,
            energyLevel: 'Medium energy',
            isIndoor: false,
          ),
        ];
        
      case 'the hague':
        return [
          Place(
            id: 'fallback_mauritshuis',
            name: 'Mauritshuis',
            address: 'Plein 29, 2511 CS Den Haag, Netherlands',
            rating: 4.6,
            photos: ['https://images.unsplash.com/photo-1566552881560-0be862a7c445?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
            types: ['museum', 'tourist_attraction'],
            location: const PlaceLocation(lat: 52.0805, lng: 4.3134),
            description: 'Home to masterpieces including Vermeer\'s Girl with a Pearl Earring.',
            emoji: '🎨',
            tag: 'Museum',
            isAsset: false,
            activities: ['Culture', 'Art'],
            reviewCount: 20000,
            energyLevel: 'Medium energy',
            isIndoor: true,
          ),
        ];
        
      default: // Rotterdam and any other city
        return [
          Place(
            id: 'fallback_euromast',
            name: 'Euromast',
            address: 'Parkhaven 20, 3016 GM Rotterdam, Netherlands',
            rating: 4.3,
            photos: ['https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
            types: ['tourist_attraction'],
            location: const PlaceLocation(lat: 51.9054, lng: 4.4652),
            description: 'Iconic tower offering panoramic views of Rotterdam city and harbor.',
            emoji: '🏗️',
            tag: 'Landmark',
            isAsset: false,
            activities: ['Sightseeing'],
            reviewCount: 15000,
            energyLevel: 'Medium energy',
            isIndoor: false,
          ),
          Place(
            id: 'fallback_markthal',
            name: 'Markthal Rotterdam',
            address: 'Dominee Jan Scharpstraat 298, 3011 GZ Rotterdam, Netherlands',
            rating: 4.2,
            photos: ['https://images.unsplash.com/photo-1547036967-23d11aacaee0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
            types: ['shopping_mall', 'tourist_attraction'],
            location: const PlaceLocation(lat: 51.9197, lng: 4.4856),
            description: 'Stunning food market with apartments above, featuring local and international cuisine.',
            emoji: '🏪',
            tag: 'Market',
            isAsset: false,
            activities: ['Shopping', 'Food'],
            reviewCount: 25000,
            energyLevel: 'Medium energy',
            isIndoor: true,
          ),
          Place(
            id: 'fallback_erasmus_bridge',
            name: 'Erasmus Bridge',
            address: 'Erasmusbrug, Rotterdam, Netherlands',
            rating: 4.4,
            photos: ['https://images.unsplash.com/photo-1542090550-3ac7d9e5e6cf?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'],
            types: ['tourist_attraction', 'point_of_interest'],
            location: const PlaceLocation(lat: 51.9093, lng: 4.4825),
            description: 'Iconic cable-stayed bridge connecting north and south Rotterdam, beautiful at sunset.',
            emoji: '🌉',
            tag: 'Landmark',
            isAsset: false,
            activities: ['Sightseeing', 'Photography'],
            reviewCount: 18000,
            energyLevel: 'Low energy',
            isIndoor: false,
          ),
        ];
    }
  }

  // Broad cache management
  bool _isBroadCacheValid(String cacheKey) {
    if (!_broadCache.containsKey(cacheKey) || !_broadCacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final cacheTime = _broadCacheTimestamps[cacheKey]!;
    final isExpired = DateTime.now().difference(cacheTime) > _broadCacheValidDuration;
    return !isExpired;
  }

  void _updateBroadCache(String cacheKey, List<Place> places) {
    _broadCache[cacheKey] = places;
    _broadCacheTimestamps[cacheKey] = DateTime.now();
  }

  Future<void> _saveBroadCacheToPersistentStorage(String cacheKey, List<Place> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = places.map((place) => place.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await prefs.setString('broad_cache_$cacheKey', jsonString);
      await prefs.setInt('broad_timestamp_$cacheKey', DateTime.now().millisecondsSinceEpoch);
      debugPrint('💾 Saved ${places.length} places to broad cache storage');
    } catch (e) {
      debugPrint('❌ Error saving broad cache to storage: $e');
    }
  }

  Future<List<Place>?> _loadBroadCacheFromPersistentStorage(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('broad_cache_$cacheKey');
      final storedTimestamp = prefs.getInt('broad_timestamp_$cacheKey');
      
      if (storedData != null && storedTimestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(storedTimestamp);
        final isExpired = DateTime.now().difference(cacheTime) > _broadCacheValidDuration;
        
        if (!isExpired) {
          final List<dynamic> jsonList = json.decode(storedData);
          final places = jsonList.map((json) => Place.fromJson(json)).toList();
          debugPrint('💾 Loaded ${places.length} places from broad cache storage');
          return places;
        } else {
          debugPrint('🗑️ Broad cache expired for $cacheKey');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading broad cache from storage: $e');
    }
    return null;
  }

  String getPhotoUrl(String photoReference) {
    final service = ref.read(placesServiceProvider.notifier);
    return service.getPhotoUrl(photoReference);
  }

  // Get filter metadata for advanced filtering
  Map<String, dynamic>? getFilterMetadata(String filterKey) {
    return _filterMetadata[filterKey];
  }

  // Static method to clear expired cache (called from main.dart)
  static void clearExpiredCache() {
    final now = DateTime.now();
    
    // Clear broad cache
    final expiredBroadKeys = _broadCacheTimestamps.entries
        .where((entry) => now.difference(entry.value) > _broadCacheValidDuration)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredBroadKeys) {
      _broadCache.remove(key);
      _broadCacheTimestamps.remove(key);
    }
    
    if (expiredBroadKeys.isNotEmpty) {
      debugPrint('🧹 Cleared expired broad cache for: ${expiredBroadKeys.join(", ")}');
    }
  }
} 