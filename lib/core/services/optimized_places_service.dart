import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:shared_preferences.dart';
import 'dart:convert';
import '../models/place.dart';
import '../models/weather.dart';

class OptimizedPlacesService {
  static const _maxResults = 20;
  static const _cacheExpiration = Duration(hours: 24);
  static final OptimizedPlacesService _instance = OptimizedPlacesService._internal();
  
  late SharedPreferences _prefs;
  final _rateLimiter = RateLimiter(
    maxRequests: 10,
    interval: const Duration(seconds: 1),
  );

  // Private constructor
  OptimizedPlacesService._internal();

  // Singleton factory
  factory OptimizedPlacesService() {
    return _instance;
  }

  // Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cleanExpiredCache();
  }

  Future<List<Place>> fetchPlaces({
    required List<String> moods,
    required LatLng userLocation,
    required String timeSlot,
    Weather? weather,
  }) async {
    try {
      // Generate cache key
      final cacheKey = _generateCacheKey(moods, userLocation, timeSlot);
      
      // Check cache first
      final cachedData = await _getCachedData(cacheKey);
      if (cachedData != null) {
        if (kDebugMode) debugPrint('Returning cached results');
        return cachedData;
      }

      // Generate optimized search queries
      final queries = _generateOptimizedQueries(
        moods: moods,
        timeSlot: timeSlot,
        weather: weather,
      );

      // Batch API calls
      final results = await _batchSearchPlaces(
        queries: queries,
        location: userLocation,
      );

      // Process and deduplicate results
      final places = _processResults(results);
      
      // Cache results
      await _cacheData(cacheKey, places);

      return places;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching places: $e');
      // Return empty list instead of throwing
      return [];
    }
  }

  String _generateCacheKey(List<String> moods, LatLng location, String timeSlot) {
    final moodsKey = moods.join('_').toLowerCase();
    final locationKey = '${location.lat.toStringAsFixed(2)}_${location.lng.toStringAsFixed(2)}';
    return 'places_${moodsKey}_${locationKey}_$timeSlot';
  }

  Future<List<Place>?> _getCachedData(String key) async {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return null;

      final data = json.decode(jsonString);
      if (data == null) return null;

      final timestamp = DateTime.parse(data['timestamp']);
      if (DateTime.now().difference(timestamp) > _cacheExpiration) {
        // Cache expired
        await _prefs.remove(key);
        return null;
      }

      return (data['places'] as List)
          .map((p) => Place.fromJson(p))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error reading cache: $e');
      return null;
    }
  }

  Future<void> _cacheData(String key, List<Place> places) async {
    try {
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'places': places.map((p) => p.toJson()).toList(),
      };
      await _prefs.setString(key, json.encode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('Error caching data: $e');
    }
  }

  Future<void> _cleanExpiredCache() async {
    try {
      final keys = _prefs.getKeys().where((k) => k.startsWith('places_'));
      for (final key in keys) {
        final data = json.decode(_prefs.getString(key) ?? '{}');
        if (data['timestamp'] != null) {
          final timestamp = DateTime.parse(data['timestamp']);
          if (DateTime.now().difference(timestamp) > _cacheExpiration) {
            await _prefs.remove(key);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error cleaning cache: $e');
    }
  }

  List<SearchQuery> _generateOptimizedQueries({
    required List<String> moods,
    required String timeSlot,
    Weather? weather,
  }) {
    final queries = <SearchQuery>[];
    final Map<String, List<String>> typeGroups = {};

    // Map moods to place types and keywords
    for (final mood in moods) {
      final (types, keywords) = _getMoodMappings(mood.toLowerCase());
      for (final type in types) {
        typeGroups.putIfAbsent(type, () => []).addAll(keywords);
      }
    }

    // Add time-specific queries
    final (timeTypes, timeKeywords) = _getTimeSlotMappings(timeSlot);
    for (final type in timeTypes) {
      typeGroups.putIfAbsent(type, () => []).addAll(timeKeywords);
    }

    // Add weather-specific queries if available
    if (weather != null) {
      final (weatherTypes, weatherKeywords) = _getWeatherMappings(weather);
      for (final type in weatherTypes) {
        typeGroups.putIfAbsent(type, () => []).addAll(weatherKeywords);
      }
    }

    // Create optimized queries
    for (final entry in typeGroups.entries) {
      // Remove duplicates and join keywords
      final uniqueKeywords = entry.value.toSet().toList();
      queries.add(SearchQuery(
        type: entry.key,
        keywords: uniqueKeywords,
      ));
    }

    return queries;
  }

  (List<String>, List<String>) _getMoodMappings(String mood) {
    switch (mood) {
      case 'relaxed':
        return (
          ['spa', 'park', 'cafe'],
          ['relaxing', 'peaceful', 'quiet']
        );
      case 'energetic':
        return (
          ['gym', 'park', 'sports_complex'],
          ['active', 'fitness', 'sports']
        );
      case 'romantic':
        return (
          ['restaurant', 'park', 'cafe'],
          ['romantic', 'cozy', 'intimate']
        );
      case 'creative':
        return (
          ['art_gallery', 'museum', 'cafe'],
          ['art', 'creative', 'inspiring']
        );
      case 'foody':
        return (
          ['restaurant', 'cafe', 'bakery'],
          ['food', 'dining', 'gourmet']
        );
      case 'cultural':
        return (
          ['museum', 'art_gallery', 'church'],
          ['cultural', 'historic', 'traditional']
        );
      case 'adventurous':
        return (
          ['park', 'tourist_attraction', 'amusement_park'],
          ['adventure', 'exciting', 'outdoor']
        );
      default:
        return (
          ['restaurant', 'cafe', 'park'],
          ['popular', 'recommended']
        );
    }
  }

  (List<String>, List<String>) _getTimeSlotMappings(String timeSlot) {
    switch (timeSlot.toLowerCase()) {
      case 'morning':
        return (
          ['cafe', 'bakery', 'park'],
          ['breakfast', 'brunch', 'morning']
        );
      case 'afternoon':
        return (
          ['restaurant', 'museum', 'shopping_mall'],
          ['lunch', 'activities']
        );
      case 'evening':
        return (
          ['restaurant', 'bar', 'movie_theater'],
          ['dinner', 'entertainment', 'nightlife']
        );
      default:
        return ([], []);
    }
  }

  (List<String>, List<String>) _getWeatherMappings(Weather weather) {
    if (weather.isRainy) {
      return (
        ['museum', 'shopping_mall', 'movie_theater'],
        ['indoor', 'covered']
      );
    } else if (weather.isSunny) {
      return (
        ['park', 'tourist_attraction', 'beach'],
        ['outdoor', 'sunny']
      );
    } else {
      return ([], []);
    }
  }

  Future<List<PlaceApiResult>> _batchSearchPlaces({
    required List<SearchQuery> queries,
    required LatLng location,
  }) async {
    final results = <PlaceApiResult>[];
    final seenPlaceIds = <String>{};

    for (final query in queries) {
      // Check rate limit
      await _rateLimiter.checkLimit();
      
      try {
        final response = await _searchPlaces(
          query: query,
          location: location,
        );
        
        if (response.status == "OK") {
          // Filter out duplicates
          final newResults = response.results.where(
            (result) => seenPlaceIds.add(result.placeId)
          );
          results.addAll(newResults);
          
          // Get next page only if we need more results
          if (results.length < _maxResults && response.nextPageToken != null) {
            await Future.delayed(const Duration(seconds: 2)); // Required by Google API
            final nextPageResults = await _getNextPageResults(response.nextPageToken!);
            
            // Filter and add new results
            final newNextResults = nextPageResults.where(
              (result) => seenPlaceIds.add(result.placeId)
            );
            results.addAll(newNextResults);
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error in batch search: $e');
      }

      // Break if we have enough results
      if (results.length >= _maxResults) break;
    }
    
    return results.take(_maxResults).toList();
  }

  List<Place> _processResults(List<PlaceApiResult> results) {
    return results.map((result) => Place(
      id: result.placeId,
      name: result.name,
      // Add other place properties here
    )).toList();
  }
}

class RateLimiter {
  final int maxRequests;
  final Duration interval;
  final Queue<DateTime> requests = Queue();
  
  RateLimiter({
    required this.maxRequests,
    required this.interval,
  });
  
  Future<void> checkLimit() async {
    final now = DateTime.now();
    
    // Remove old requests
    while (requests.isNotEmpty && 
           now.difference(requests.first) > interval) {
      requests.removeFirst();
    }
    
    // Check if we're at the limit
    if (requests.length >= maxRequests) {
      final oldestRequest = requests.first;
      final waitTime = interval - now.difference(oldestRequest);
      await Future.delayed(waitTime);
      return checkLimit(); // Recursively check again after waiting
    }
    
    requests.add(now);
  }
}

class SearchQuery {
  final String type;
  final List<String> keywords;

  SearchQuery({
    required this.type,
    required this.keywords,
  });

  @override
  String toString() => 'SearchQuery(type: $type, keywords: $keywords)';
} 