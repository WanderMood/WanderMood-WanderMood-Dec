import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../utils/performance_manager.dart';

/// Smart Prefetching Manager for anticipating user needs and preloading content intelligently
class SmartPrefetchManager with PerformanceAware {
  static final SmartPrefetchManager _instance = SmartPrefetchManager._internal();
  factory SmartPrefetchManager() => _instance;
  SmartPrefetchManager._internal();

  // User behavior tracking
  final Map<String, int> _screenVisitCounts = {};
  final Map<String, DateTime> _lastVisitTimes = {};
  final Map<String, List<String>> _navigationPatterns = {};
  final Map<String, Duration> _screenDurations = {};
  
  // Location-based prefetching
  Position? _lastPrefetchLocation;
  DateTime? _lastLocationPrefetch;
  
  // Time-based patterns
  final Map<int, List<String>> _hourlyScreenPatterns = {}; // hour -> screens
  final Map<String, List<int>> _moodTimePatterns = {}; // mood -> hours
  
  // Prefetch cache
  final Map<String, dynamic> _prefetchCache = {};
  final Map<String, DateTime> _prefetchTimestamps = {};
  
  static const Duration _prefetchValidDuration = Duration(minutes: 30);
  static const double _prefetchDistanceThreshold = 1000; // meters
  
  /// Initialize smart prefetching with performance monitoring
  Future<void> initialize(PerformanceManager performanceManager) async {
    initializePerformance(performanceManager);
    await _loadBehaviorData();
    _startPeriodicPrefetching();
    if (kDebugMode) debugPrint('🧠 Smart Prefetching Manager initialized');
  }

  /// Track screen visit for behavior analysis
  Future<void> trackScreenVisit(String screenName) async {
    final now = DateTime.now();
    
    // Update visit counts
    _screenVisitCounts[screenName] = (_screenVisitCounts[screenName] ?? 0) + 1;
    
    // Track visit time for duration calculation
    if (_lastVisitTimes.containsKey(screenName)) {
      final lastVisit = _lastVisitTimes[screenName]!;
      final duration = now.difference(lastVisit);
      _screenDurations[screenName] = duration;
    }
    _lastVisitTimes[screenName] = now;
    
    // Track hourly patterns
    final hour = now.hour;
    if (!_hourlyScreenPatterns.containsKey(hour)) {
      _hourlyScreenPatterns[hour] = [];
    }
    if (!_hourlyScreenPatterns[hour]!.contains(screenName)) {
      _hourlyScreenPatterns[hour]!.add(screenName);
    }
    
    await _saveBehaviorData();
    
    // Trigger intelligent prefetching based on visit
    _prefetchBasedOnVisit(screenName);
    
    if (kDebugMode) debugPrint('🧠 Tracked visit to $screenName (${_screenVisitCounts[screenName]} visits)');
  }

  /// Track navigation pattern for prediction
  Future<void> trackNavigation(String fromScreen, String toScreen) async {
    if (!_navigationPatterns.containsKey(fromScreen)) {
      _navigationPatterns[fromScreen] = [];
    }
    _navigationPatterns[fromScreen]!.add(toScreen);
    
    // Keep only last 10 navigations per screen
    if (_navigationPatterns[fromScreen]!.length > 10) {
      _navigationPatterns[fromScreen]!.removeAt(0);
    }
    
    await _saveBehaviorData();
    if (kDebugMode) debugPrint('🧠 Tracked navigation: $fromScreen → $toScreen');
  }

  /// Track mood selection for time-based patterns
  Future<void> trackMoodSelection(String mood) async {
    final hour = DateTime.now().hour;
    
    if (!_moodTimePatterns.containsKey(mood)) {
      _moodTimePatterns[mood] = [];
    }
    if (!_moodTimePatterns[mood]!.contains(hour)) {
      _moodTimePatterns[mood]!.add(hour);
    }
    
    await _saveBehaviorData();
    if (kDebugMode) debugPrint('🧠 Tracked mood "$mood" at hour $hour');
  }

  /// Predict next likely screens based on current screen
  List<String> predictNextScreens(String currentScreen, {int limit = 3}) {
    final patterns = _navigationPatterns[currentScreen] ?? [];
    if (patterns.isEmpty) return [];
    
    // Count frequency of next screens
    final Map<String, int> nextScreenCounts = {};
    for (final screen in patterns) {
      nextScreenCounts[screen] = (nextScreenCounts[screen] ?? 0) + 1;
    }
    
    // Sort by frequency and return top predictions
    final sortedScreens = nextScreenCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final predictions = sortedScreens
        .take(limit)
        .map((entry) => entry.key)
        .toList();
    
    if (kDebugMode) debugPrint('🧠 Predicted next screens from $currentScreen: $predictions');
    return predictions;
  }

  /// Prefetch content based on location proximity
  Future<void> prefetchNearbyContent(Position currentLocation) async {
    // Check if we need to prefetch based on location change
    if (_lastPrefetchLocation != null) {
      final distance = Geolocator.distanceBetween(
        _lastPrefetchLocation!.latitude,
        _lastPrefetchLocation!.longitude,
        currentLocation.latitude,
        currentLocation.longitude,
      );
      
      if (distance < _prefetchDistanceThreshold && 
          _lastLocationPrefetch != null &&
          DateTime.now().difference(_lastLocationPrefetch!) < _prefetchValidDuration) {
        if (kDebugMode) debugPrint('🧠 Skipping nearby prefetch - recent location and data');
        return;
      }
    }

    await performanceCall(
      'prefetch_nearby',
      {
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
      },
      () => _performNearbyPrefetch(currentLocation),
    );

    _lastPrefetchLocation = currentLocation;
    _lastLocationPrefetch = DateTime.now();
  }

  /// Prefetch content based on time patterns
  Future<void> prefetchTimeBasedContent() async {
    final currentHour = DateTime.now().hour;
    final likelyScreens = _hourlyScreenPatterns[currentHour] ?? [];
    
    for (final screen in likelyScreens) {
      await _prefetchScreenContent(screen, 'time_based');
    }
    
    if (kDebugMode) debugPrint('🧠 Prefetched time-based content for hour $currentHour: $likelyScreens');
  }

  /// Prefetch content based on mood patterns
  Future<void> prefetchMoodBasedContent(String selectedMood) async {
    final likelyHours = _moodTimePatterns[selectedMood] ?? [];
    final currentHour = DateTime.now().hour;
    
    // If current hour matches mood pattern, prefetch related content
    if (likelyHours.contains(currentHour)) {
      await _prefetchMoodContent(selectedMood);
      if (kDebugMode) debugPrint('🧠 Prefetched mood-based content for "$selectedMood"');
    }
  }

  /// Get prefetched data if available
  T? getPrefetchedData<T>(String key) {
    if (!_prefetchCache.containsKey(key)) return null;
    
    final timestamp = _prefetchTimestamps[key];
    if (timestamp == null || 
        DateTime.now().difference(timestamp) > _prefetchValidDuration) {
      _prefetchCache.remove(key);
      _prefetchTimestamps.remove(key);
      return null;
    }
    
    if (kDebugMode) debugPrint('🧠 Retrieved prefetched data for key: $key');
    return _prefetchCache[key] as T?;
  }

  /// Store prefetched data
  void storePrefetchedData(String key, dynamic data) {
    _prefetchCache[key] = data;
    _prefetchTimestamps[key] = DateTime.now();
    if (kDebugMode) debugPrint('🧠 Stored prefetched data for key: $key');
  }

  /// Get user behavior insights
  Map<String, dynamic> getBehaviorInsights() {
    final mostVisitedScreen = _screenVisitCounts.entries
        .fold<MapEntry<String, int>?>(null, (prev, curr) => 
          prev == null || curr.value > prev.value ? curr : prev);
    
    final averageSessionDuration = _screenDurations.values.isNotEmpty
        ? _screenDurations.values
            .map((d) => d.inSeconds)
            .reduce((a, b) => a + b) / _screenDurations.length
        : 0.0;
    
    return {
      'total_tracked_screens': _screenVisitCounts.length,
      'most_visited_screen': mostVisitedScreen?.key,
      'most_visited_count': mostVisitedScreen?.value,
      'average_session_duration_seconds': averageSessionDuration,
      'navigation_patterns_count': _navigationPatterns.length,
      'mood_time_patterns_count': _moodTimePatterns.length,
      'prefetch_cache_size': _prefetchCache.length,
    };
  }

  // Private methods

  Future<void> _performNearbyPrefetch(Position location) async {
    try {
      // Simulate prefetching nearby places
      // In real implementation, this would call places service
      final nearbyKey = 'nearby_${location.latitude.toStringAsFixed(3)}_${location.longitude.toStringAsFixed(3)}';
      
      // Mock data for nearby places
      final mockNearbyData = {
        'places': List.generate(5, (i) => 'place_$i'),
        'location': {'lat': location.latitude, 'lng': location.longitude},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      storePrefetchedData(nearbyKey, mockNearbyData);
      if (kDebugMode) debugPrint('🧠 Prefetched nearby content for location: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error prefetching nearby content: $e');
    }
  }

  Future<void> _prefetchScreenContent(String screenName, String reason) async {
    try {
      final cacheKey = 'screen_${screenName}_content';
      
      // Mock prefetch data based on screen type
      Map<String, dynamic> mockData;
      switch (screenName) {
        case 'explore':
          mockData = {'places': List.generate(10, (i) => 'place_$i')};
          break;
        case 'mood':
          mockData = {'moods': ['happy', 'relaxed', 'energetic']};
          break;
        default:
          mockData = {'data': 'generic_content'};
      }
      
      storePrefetchedData(cacheKey, mockData);
      if (kDebugMode) debugPrint('🧠 Prefetched content for screen "$screenName" (reason: $reason)');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error prefetching screen content: $e');
    }
  }

  Future<void> _prefetchMoodContent(String mood) async {
    try {
      final cacheKey = 'mood_${mood}_content';
      
      // Mock mood-based content
      final mockMoodData = {
        'recommendations': List.generate(5, (i) => 'recommendation_${mood}_$i'),
        'places': List.generate(8, (i) => 'mood_place_$i'),
        'activities': List.generate(6, (i) => 'activity_$i'),
      };
      
      storePrefetchedData(cacheKey, mockMoodData);
      if (kDebugMode) debugPrint('🧠 Prefetched mood content for "$mood"');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error prefetching mood content: $e');
    }
  }

  void _prefetchBasedOnVisit(String currentScreen) {
    // Predict and prefetch next likely screens
    final predictions = predictNextScreens(currentScreen);
    for (final screen in predictions) {
      _prefetchScreenContent(screen, 'navigation_prediction');
    }
  }

  void _startPeriodicPrefetching() {
    // Periodic prefetching every 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      prefetchTimeBasedContent();
      _startPeriodicPrefetching(); // Schedule next run
    });
  }

  Future<void> _loadBehaviorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load visit counts
      final visitCountsJson = prefs.getString('behavior_visit_counts');
      if (visitCountsJson != null) {
        final Map<String, dynamic> data = json.decode(visitCountsJson);
        _screenVisitCounts.addAll(data.cast<String, int>());
      }
      
      // Load navigation patterns
      final navigationJson = prefs.getString('behavior_navigation_patterns');
      if (navigationJson != null) {
        final Map<String, dynamic> data = json.decode(navigationJson);
        data.forEach((key, value) {
          _navigationPatterns[key] = List<String>.from(value);
        });
      }
      
      // Load mood patterns
      final moodPatternsJson = prefs.getString('behavior_mood_patterns');
      if (moodPatternsJson != null) {
        final Map<String, dynamic> data = json.decode(moodPatternsJson);
        data.forEach((key, value) {
          _moodTimePatterns[key] = List<int>.from(value);
        });
      }
      
      if (kDebugMode) debugPrint('🧠 Loaded behavior data: ${_screenVisitCounts.length} screens tracked');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading behavior data: $e');
    }
  }

  Future<void> _saveBehaviorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save visit counts
      await prefs.setString('behavior_visit_counts', json.encode(_screenVisitCounts));
      
      // Save navigation patterns
      await prefs.setString('behavior_navigation_patterns', json.encode(_navigationPatterns));
      
      // Save mood patterns
      await prefs.setString('behavior_mood_patterns', json.encode(_moodTimePatterns));
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving behavior data: $e');
    }
  }

  /// Clean up old prefetch data
  void cleanup() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _prefetchTimestamps.entries) {
      if (now.difference(entry.value) > _prefetchValidDuration) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _prefetchCache.remove(key);
      _prefetchTimestamps.remove(key);
    }
    
    if (kDebugMode) debugPrint('🧠 Cleaned up ${keysToRemove.length} expired prefetch entries');
  }
} 