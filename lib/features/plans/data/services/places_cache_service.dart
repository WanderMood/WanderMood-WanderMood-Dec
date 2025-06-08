import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/google_places_service.dart';

class PlacesCacheService {
  static final _supabase = Supabase.instance.client;
  
  /// Cache duration in days
  static const int cacheDurationDays = 7;
  
  /// Get cached places for specific moods and location
  static Future<List<GooglePlace>> getCachedPlaces({
    required List<String> moods,
    required double lat,
    required double lng,
    double radiusKm = 15.0,
  }) async {
    try {
      debugPrint('🗄️ Checking cache for moods: $moods near ($lat, $lng)');
      
      // Calculate cache cutoff date
      final cutoffDate = DateTime.now().subtract(Duration(days: cacheDurationDays));
      
      // Query cached places within radius that match moods and are fresh
      final response = await _supabase
          .from('places_cache')
          .select('*')
          .gte('updated_at', cutoffDate.toIso8601String())
          .overlaps('mood_tags', moods);
      
      if (response.isEmpty) {
        debugPrint('📭 No cached places found for these moods');
        return [];
      }
      
      debugPrint('🎯 Found ${response.length} cached places');
      
      // Filter by distance and convert to GooglePlace objects
      final places = <GooglePlace>[];
      
      for (final item in response) {
        final placeLat = item['latitude'] as double?;
        final placeLng = item['longitude'] as double?;
        
        if (placeLat != null && placeLng != null) {
          final distance = _calculateDistance(lat, lng, placeLat, placeLng);
          
          if (distance <= radiusKm) {
            final place = _convertToGooglePlace(item);
            if (place != null) {
              places.add(place);
            }
          }
        }
      }
      
      debugPrint('✅ Returning ${places.length} cached places within ${radiusKm}km');
      return places;
      
    } catch (e) {
      debugPrint('❌ Error getting cached places: $e');
      return [];
    }
  }
  
  /// Cache places in Supabase
  static Future<void> cachePlaces({
    required List<GooglePlace> places,
    required List<String> moods,
    required double lat,
    required double lng,
  }) async {
    try {
      debugPrint('💾 Caching ${places.length} places for moods: $moods');
      
      final now = DateTime.now().toIso8601String();
      final cacheData = <Map<String, dynamic>>[];
      
      for (final place in places) {
        // Check if place already exists
        final existing = await _supabase
            .from('places_cache')
            .select('place_id, mood_tags')
            .eq('place_id', place.placeId)
            .maybeSingle();
        
        if (existing != null) {
          // Update existing place with new moods
          final existingMoods = List<String>.from(existing['mood_tags'] ?? []);
          final updatedMoods = {...existingMoods, ...moods}.toList();
          
          await _supabase
              .from('places_cache')
              .update({
                'mood_tags': updatedMoods,
                'updated_at': now,
              })
              .eq('place_id', place.placeId);
              
          debugPrint('🔄 Updated existing place: ${place.name}');
        } else {
          // Insert new place
          cacheData.add({
            'place_id': place.placeId,
            'name': place.name,
            'rating': place.rating,
            'latitude': place.lat,
            'longitude': place.lng,
            'types': place.types,
            'photo_reference': place.photoReference,
            'photo_references': place.photoReferences,
            'vicinity': place.vicinity,
            'price_level': place.priceLevel,
            'mood_tags': moods,
            'search_lat': lat,
            'search_lng': lng,
            'created_at': now,
            'updated_at': now,
          });
        }
      }
      
      if (cacheData.isNotEmpty) {
        await _supabase
            .from('places_cache')
            .insert(cacheData);
        
        debugPrint('✅ Cached ${cacheData.length} new places');
      }
      
    } catch (e) {
      debugPrint('❌ Error caching places: $e');
    }
  }
  
  /// Convert cached data back to GooglePlace object
  static GooglePlace? _convertToGooglePlace(Map<String, dynamic> data) {
    try {
      return GooglePlace(
        placeId: data['place_id'] ?? '',
        name: data['name'] ?? 'Unknown Place',
        rating: data['rating']?.toDouble(),
        lat: data['latitude']?.toDouble(),
        lng: data['longitude']?.toDouble(),
        types: List<String>.from(data['types'] ?? []),
        photoReference: data['photo_reference'],
        photoReferences: List<String>.from(data['photo_references'] ?? []),
        vicinity: data['vicinity'],
        priceLevel: data['price_level'],
      );
    } catch (e) {
      debugPrint('❌ Error converting cached data to GooglePlace: $e');
      return null;
    }
  }
  
  /// Calculate distance between two points in kilometers
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  /// Clear old cache entries
  static Future<void> clearOldCache() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: cacheDurationDays * 2));
      
      await _supabase
          .from('places_cache')
          .delete()
          .lt('updated_at', cutoffDate.toIso8601String());
      
      debugPrint('🧹 Cleared old cache entries');
    } catch (e) {
      debugPrint('❌ Error clearing old cache: $e');
    }
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final response = await _supabase
          .from('places_cache')
          .select('place_id, updated_at, mood_tags');
      
      final total = response.length;
      final cutoffDate = DateTime.now().subtract(Duration(days: cacheDurationDays));
      
      final fresh = response.where((item) {
        final updatedAt = DateTime.parse(item['updated_at']);
        return updatedAt.isAfter(cutoffDate);
      }).length;
      
      return {
        'total_places': total,
        'fresh_places': fresh,
        'stale_places': total - fresh,
        'cache_duration_days': cacheDurationDays,
      };
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }
} 