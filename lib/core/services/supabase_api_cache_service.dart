import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../config/api_config.dart';

/// Supabase-based API cache service for development cost savings
/// 
/// This service caches API responses in Supabase to avoid repeated API calls during development.
/// In dev mode, it serves cached data. In production, it uses live API calls.
class SupabaseApiCacheService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Check if we're in development mode
  static bool get isDevMode => kDebugMode;
  
  /// Check if we should use cache (dev mode only)
  static bool get shouldUseCache => isDevMode;
  
  /// Get cached API response from Supabase
  /// Returns null if not found or expired
  static Future<Map<String, dynamic>?> getCachedResponse({
    required String endpoint,
    required Map<String, dynamic> parameters,
  }) async {
    if (!shouldUseCache) {
      debugPrint('🌐 Production mode - skipping cache check');
      return null;
    }
    
    try {
      final cacheKey = _generateCacheKey(endpoint, parameters);
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      
      debugPrint('🔍 Checking Supabase cache for: $endpoint');
      debugPrint('   Cache key: $cacheKey');
      
      final cacheResponse = await _supabase
          .from('places_cache')
          .select('data, expires_at')
          .eq('cache_key', cacheKey)
          .maybeSingle();
      
      if (cacheResponse == null) {
        debugPrint('❌ Cache MISS: No data found');
        return null;
      }
      
      final cacheData = cacheResponse as Map<String, dynamic>;
      
      // Check if cache is expired
      final expiresAt = DateTime.parse(cacheData['expires_at'] as String);
      if (expiresAt.isBefore(DateTime.now())) {
        debugPrint('⏰ Cache EXPIRED: ${expiresAt.toIso8601String()}');
        return null;
      }
      
      // Return cached data
      final cachedData = cacheData['data'] as Map<String, dynamic>;
      debugPrint('✅ Cache HIT: Found cached response');
      debugPrint('💰 COST SAVED: ~\$${_getApiCost(endpoint)}');
      
      return cachedData;
    } catch (e) {
      debugPrint('❌ Error reading from Supabase cache: $e');
      return null;
    }
  }
  
  /// Save API response to Supabase cache
  static Future<void> cacheResponse({
    required String endpoint,
    required Map<String, dynamic> parameters,
    required Map<String, dynamic> response,
    Duration? cacheDuration,
  }) async {
    if (!shouldUseCache) {
      debugPrint('🌐 Production mode - skipping cache save');
      return;
    }
    
    try {
      final cacheKey = _generateCacheKey(endpoint, parameters);
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      final expiresAt = DateTime.now().add(cacheDuration ?? const Duration(days: 30));
      
      debugPrint('💾 Saving to Supabase cache: $endpoint');
      debugPrint('   Cache key: $cacheKey');
      debugPrint('   Expires at: ${expiresAt.toIso8601String()}');
      
      // Determine request type from endpoint
      String requestType = 'search';
      if (endpoint.contains('details')) requestType = 'details';
      else if (endpoint.contains('autocomplete')) requestType = 'autocomplete';
      else if (endpoint.contains('nearby')) requestType = 'nearby';
      else if (endpoint.contains('photo')) requestType = 'photos';
      
      // Extract location from parameters if available
      double? locationLat;
      double? locationLng;
      if (parameters.containsKey('lat') && parameters.containsKey('lng')) {
        locationLat = (parameters['lat'] as num).toDouble();
        locationLng = (parameters['lng'] as num).toDouble();
      } else if (parameters.containsKey('latitude') && parameters.containsKey('longitude')) {
        locationLat = (parameters['latitude'] as num).toDouble();
        locationLng = (parameters['longitude'] as num).toDouble();
      }
      
      // Extract query from parameters
      String? query;
      if (parameters.containsKey('query')) {
        query = parameters['query'].toString();
      } else if (parameters.containsKey('textQuery')) {
        query = parameters['textQuery'].toString();
      }
      
      final cacheResult = await _supabase
          .from('places_cache')
          .upsert({
            'cache_key': cacheKey,
            'user_id': userId,
            'data': response,
            'request_type': requestType,
            'query': query,
            'location_lat': locationLat,
            'location_lng': locationLng,
            'expires_at': expiresAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'cache_key');
      
      // Upsert doesn't return error in the same way, check for exceptions
      debugPrint('✅ Successfully cached API response in Supabase');
    } catch (e) {
      debugPrint('❌ Error caching response: $e');
    }
  }
  
  /// Generate a unique cache key from endpoint and parameters
  static String _generateCacheKey(String endpoint, Map<String, dynamic> parameters) {
    // Sort parameters for consistent keys
    final sortedParams = Map.fromEntries(
      parameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    // Create a normalized parameter string
    final paramString = sortedParams.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    
    // Create hash-like key (limit length for database)
    final baseKey = '${endpoint}_$paramString';
    final hash = baseKey.hashCode.abs();
    
    // Use hash + first 50 chars for uniqueness
    return '${endpoint}_${hash}_${baseKey.substring(0, baseKey.length > 50 ? 50 : baseKey.length)}'
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }
  
  /// Get API cost for an endpoint
  static double _getApiCost(String endpoint) {
    if (endpoint.contains('nearby') || endpoint.contains('search')) {
      return 0.032;
    } else if (endpoint.contains('details')) {
      return 0.017;
    } else if (endpoint.contains('photo')) {
      return 0.007;
    } else if (endpoint.contains('autocomplete')) {
      return 0.003;
    }
    return 0.020; // Default
  }
  
  /// Clear all cached data (for testing)
  static Future<void> clearAllCache() async {
    if (!shouldUseCache) return;
    
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      
      await _supabase
          .from('places_cache')
          .delete()
          .eq('user_id', userId);
      
      debugPrint('🧹 Cleared all cached API responses');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    if (!shouldUseCache) {
      return {'mode': 'production', 'cache_enabled': false};
    }
    
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      
      final statsResponse = await _supabase
          .from('places_cache')
          .select('cache_key, expires_at')
          .eq('user_id', userId);
      
      final data = statsResponse as List<dynamic>?;
      if (data == null || data.isEmpty) {
        return {
          'mode': 'development',
          'cache_enabled': true,
          'total_entries': 0,
          'valid_entries': 0,
          'expired_entries': 0,
        };
      }
      
      final now = DateTime.now();
      final validEntries = data
          .where((entry) {
            final entryMap = entry as Map<String, dynamic>;
            return DateTime.parse(entryMap['expires_at'] as String).isAfter(now);
          })
          .length;
      
      final expiredEntries = data.length - validEntries;
      
      return {
        'mode': 'development',
        'cache_enabled': true,
        'total_entries': data.length,
        'valid_entries': validEntries,
        'expired_entries': expiredEntries,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

