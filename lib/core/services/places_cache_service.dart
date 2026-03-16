import 'dart:async';
import 'package:flutter/foundation.dart';

class PlacesCacheService {
  static final PlacesCacheService _instance = PlacesCacheService._internal();
  factory PlacesCacheService() => _instance;
  PlacesCacheService._internal();

  final Map<String, _CacheEntry<dynamic>> _cache = {};
  final Map<String, DateTime> _rateLimits = {};
  
  // Cache configuration
  static const Duration cacheDuration = Duration(hours: 24);
  static const int maxCacheEntries = 100;
  
  // Rate limiting configuration
  static const Duration rateLimitWindow = Duration(minutes: 1);
  static const int maxRequestsPerWindow = 50;
  
  // Usage monitoring
  int _dailyRequestCount = 0;
  DateTime _lastResetDate = DateTime.now();
  final Map<String, int> _endpointUsage = {};

  Future<T?> getCached<T>(String key) async {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value as T;
  }

  Future<void> cache<T>(String key, T value) async {
    // Remove oldest entries if cache is full
    if (_cache.length >= maxCacheEntries) {
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
          .key;
      _cache.remove(oldestKey);
    }
    
    _cache[key] = _CacheEntry<T>(value);
  }

  Future<bool> canMakeRequest(String endpoint) async {
    final now = DateTime.now();
    
    // Reset daily counter if it's a new day
    if (now.difference(_lastResetDate).inDays >= 1) {
      _dailyRequestCount = 0;
      _lastResetDate = now;
    }

    // Check rate limiting
    final windowKey = '${endpoint}_${now.minute}';
    final lastRequest = _rateLimits[windowKey] ?? DateTime.fromMillisecondsSinceEpoch(0);
    
    if (now.difference(lastRequest) >= rateLimitWindow) {
      _rateLimits.clear();
    }

    final requestsInWindow = _rateLimits.keys
        .where((k) => k.startsWith(endpoint))
        .length;

    if (requestsInWindow >= maxRequestsPerWindow) {
      if (kDebugMode) debugPrint('Rate limit exceeded for $endpoint');
      return false;
    }

    // Update monitoring
    _dailyRequestCount++;
    _endpointUsage[endpoint] = (_endpointUsage[endpoint] ?? 0) + 1;
    _rateLimits[windowKey] = now;

    return true;
  }

  // Monitoring methods
  int getDailyRequestCount() => _dailyRequestCount;
  
  Map<String, int> getEndpointUsage() => Map.unmodifiable(_endpointUsage);
  
  void clearCache() => _cache.clear();
  
  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalEntries': _cache.length,
      'oldestEntry': _cache.isEmpty ? null : _cache.values
          .map((e) => e.timestamp)
          .reduce((a, b) => a.isBefore(b) ? a : b),
      'endpointUsage': _endpointUsage,
      'dailyRequestCount': _dailyRequestCount,
    };
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;
  
  _CacheEntry(this.value) : timestamp = DateTime.now();
  
  bool get isExpired => 
      DateTime.now().difference(timestamp) > PlacesCacheService.cacheDuration;
}

// API Cost estimation
class PlacesApiCost {
  static const Map<String, double> costPerRequest = {
    'nearby': 0.032,      // Basic data
    'details': 0.017,     // Place details
    'photo': 0.007,       // Place photo
    'textsearch': 0.032,  // Text search
  };

  static double estimateCost(String endpoint, int requests) {
    return (costPerRequest[endpoint] ?? 0.0) * requests;
  }
} 