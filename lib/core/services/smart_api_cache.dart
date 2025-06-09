import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smart API caching system that permanently stores API responses
/// This allows reusing expensive Google Places data without repeat API calls
class SmartApiCache {
  static const String _keyPrefix = 'api_cache_';
  static const String _usageKey = 'api_usage_tracker';
  static const String _costKey = 'api_cost_tracker';
  
  // Cache duration: 30 days for places data (places don't change often)
  static const Duration _cacheValidDuration = Duration(days: 30);
  
  // Cost tracking
  static const Map<String, double> _apiCosts = {
    'nearby_search': 0.032,
    'text_search': 0.032,
    'place_details': 0.017,
    'place_photo': 0.007,
    'geocoding': 0.005,
  };

  /// Check if we have cached data for a specific API call
  static Future<Map<String, dynamic>?> getCachedResponse({
    required String endpoint,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(endpoint, parameters);
      
      final cachedJson = prefs.getString('$_keyPrefix$cacheKey');
      final cachedTimestamp = prefs.getInt('${_keyPrefix}${cacheKey}_timestamp');
      
      if (cachedJson != null && cachedTimestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
        final isExpired = DateTime.now().difference(cacheTime) > _cacheValidDuration;
        
        if (!isExpired) {
          final cachedData = json.decode(cachedJson);
          debugPrint('💾 Cache HIT for $endpoint: ${parameters.toString().substring(0, 50)}...');
          debugPrint('💰 COST SAVED: ~\$${_apiCosts[endpoint] ?? 0.020}');
          
          // Track cost savings
          await _trackCostSavings(endpoint);
          
          return Map<String, dynamic>.from(cachedData);
        } else {
          debugPrint('🗑️ Cache EXPIRED for $endpoint - cleaning up');
          await _cleanupExpiredEntry(cacheKey);
        }
      }
      
      debugPrint('❌ Cache MISS for $endpoint: ${parameters.toString().substring(0, 50)}...');
      return null;
    } catch (e) {
      debugPrint('❌ Error reading from cache: $e');
      return null;
    }
  }

  /// Save API response to cache for future reuse
  static Future<void> cacheResponse({
    required String endpoint,
    required Map<String, dynamic> parameters,
    required Map<String, dynamic> response,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(endpoint, parameters);
      
      final responseJson = json.encode(response);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString('$_keyPrefix$cacheKey', responseJson);
      await prefs.setInt('${_keyPrefix}${cacheKey}_timestamp', timestamp);
      
      debugPrint('💾 CACHED API response for $endpoint');
      debugPrint('🔑 Cache key: $cacheKey');
      debugPrint('📦 Data size: ${responseJson.length} chars');
      
      // Track API usage
      await _trackApiUsage(endpoint);
      
    } catch (e) {
      debugPrint('❌ Error saving to cache: $e');
    }
  }

  /// Generate unique cache key from endpoint and parameters
  static String _generateCacheKey(String endpoint, Map<String, dynamic> parameters) {
    // Sort parameters to ensure consistent cache keys
    final sortedParams = Map.fromEntries(
      parameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    final paramString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    // Create a compact hash-like key
    final baseKey = '${endpoint}_$paramString';
    return baseKey.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').substring(0, 
        baseKey.length > 100 ? 100 : baseKey.length);
  }

  /// Track API usage for cost monitoring
  static Future<void> _trackApiUsage(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
      final usageKey = '${_usageKey}_$today';
      
      final currentUsage = prefs.getStringList(usageKey) ?? [];
      currentUsage.add('$endpoint:${DateTime.now().millisecondsSinceEpoch}');
      
      await prefs.setStringList(usageKey, currentUsage);
      
      debugPrint('📊 API Usage tracked: $endpoint (${currentUsage.length} calls today)');
    } catch (e) {
      debugPrint('❌ Error tracking API usage: $e');
    }
  }

  /// Track cost savings from cache hits
  static Future<void> _trackCostSavings(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final savingsKey = '${_costKey}_savings_$today';
      
      final currentSavings = prefs.getDouble(savingsKey) ?? 0.0;
      final newSavings = currentSavings + (_apiCosts[endpoint] ?? 0.020);
      
      await prefs.setDouble(savingsKey, newSavings);
      
      debugPrint('💰 Cost savings tracked: +\$${_apiCosts[endpoint]} (Total today: \$${newSavings.toStringAsFixed(3)})');
    } catch (e) {
      debugPrint('❌ Error tracking cost savings: $e');
    }
  }

  /// Clean up expired cache entry
  static Future<void> _cleanupExpiredEntry(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$cacheKey');
      await prefs.remove('${_keyPrefix}${cacheKey}_timestamp');
    } catch (e) {
      debugPrint('❌ Error cleaning up cache entry: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      final cacheKeys = allKeys.where((key) => key.startsWith(_keyPrefix)).toList();
      final usageKeys = allKeys.where((key) => key.startsWith(_usageKey)).toList();
      final savingsKeys = allKeys.where((key) => key.startsWith(_costKey)).toList();
      
      // Calculate total cache size
      int totalCacheSize = 0;
      for (final key in cacheKeys) {
        if (!key.endsWith('_timestamp')) {
          final data = prefs.getString(key);
          totalCacheSize += data?.length ?? 0;
        }
      }
      
      // Calculate today's savings
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final todaySavings = prefs.getDouble('${_costKey}_savings_$today') ?? 0.0;
      
      return {
        'cached_responses': cacheKeys.length ~/ 2, // Divide by 2 (data + timestamp)
        'total_cache_size_kb': (totalCacheSize / 1024).round(),
        'todays_savings': todaySavings,
        'cache_hit_ratio': 'Check logs for real-time ratio',
      };
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Clear all cached data (use with caution!)
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      final cacheKeys = allKeys.where((key) => 
        key.startsWith(_keyPrefix) || 
        key.startsWith(_usageKey) || 
        key.startsWith(_costKey)
      ).toList();
      
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
      
      debugPrint('🧹 Cleared all API cache (${cacheKeys.length} entries)');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Clean up old cache entries (older than cache duration)
  static Future<void> cleanupExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      final timestampKeys = allKeys.where((key) => 
        key.startsWith(_keyPrefix) && key.endsWith('_timestamp')
      ).toList();
      
      int cleanedCount = 0;
      final now = DateTime.now();
      
      for (final timestampKey in timestampKeys) {
        final timestamp = prefs.getInt(timestampKey);
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (now.difference(cacheTime) > _cacheValidDuration) {
            final dataKey = timestampKey.replaceAll('_timestamp', '');
            await prefs.remove(dataKey);
            await prefs.remove(timestampKey);
            cleanedCount++;
          }
        }
      }
      
      if (cleanedCount > 0) {
        debugPrint('🧹 Cleaned up $cleanedCount expired cache entries');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning expired cache: $e');
    }
  }

  /// Check if we should make an API call based on cache and usage limits
  static Future<bool> shouldMakeApiCall({
    required String endpoint,
    required Map<String, dynamic> parameters,
  }) async {
    // First check if we have cached data
    final cachedData = await getCachedResponse(
      endpoint: endpoint,
      parameters: parameters,
    );
    
    if (cachedData != null) {
      return false; // Don't make API call, use cache
    }
    
    // Check daily usage limits
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();
    final todayUsage = prefs.getStringList('${_usageKey}_$today') ?? [];
    
    if (todayUsage.length >= 50) { // Daily limit
      debugPrint('⚠️ Daily API limit reached (${todayUsage.length}/50)');
      return false;
    }
    
    return true; // OK to make API call
  }
} 