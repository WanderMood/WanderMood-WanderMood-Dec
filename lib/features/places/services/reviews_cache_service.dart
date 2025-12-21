import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to cache place reviews in Supabase to reduce API calls
class ReviewsCacheService {
  final SupabaseClient _supabase;
  static const Duration _cacheExpiry = Duration(days: 7); // Cache for 7 days

  ReviewsCacheService(this._supabase);

  /// Get cached reviews for a place
  /// Returns null if cache is missing or expired
  Future<List<Map<String, dynamic>>?> getCachedReviews(String placeId) async {
    try {
      final response = await _supabase
          .from('place_reviews_cache')
          .select()
          .eq('place_id', placeId)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) {
          debugPrint('📦 No cache found for place: $placeId');
        }
        return null;
      }

      final expiresAt = DateTime.parse(response['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        if (kDebugMode) {
          debugPrint('⏰ Cache expired for place: $placeId');
        }
        // Delete expired cache
        await _supabase
            .from('place_reviews_cache')
            .delete()
            .eq('place_id', placeId);
        return null;
      }

      final reviewsJson = response['reviews'] as List<dynamic>;
      final reviews = reviewsJson
          .map((r) => r as Map<String, dynamic>)
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Using cached reviews for place: $placeId (${reviews.length} reviews)');
      }

      return reviews;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting cached reviews: $e');
      }
      return null;
    }
  }

  /// Cache reviews for a place
  Future<void> cacheReviews(
    String placeId,
    List<Map<String, dynamic>> reviews,
  ) async {
    try {
      final expiresAt = DateTime.now().add(_cacheExpiry);

      await _supabase.from('place_reviews_cache').upsert({
        'place_id': placeId,
        'reviews': reviews,
        'last_updated': DateTime.now().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      }, onConflict: 'place_id');

      if (kDebugMode) {
        debugPrint('💾 Cached ${reviews.length} reviews for place: $placeId (expires: $expiresAt)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error caching reviews: $e');
      }
    }
  }

  /// Clear expired cache entries (can be called periodically)
  Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now().toIso8601String();
      await _supabase
          .from('place_reviews_cache')
          .delete()
          .lt('expires_at', now);

      if (kDebugMode) {
        debugPrint('🧹 Cleared expired review cache entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing expired cache: $e');
      }
    }
  }
}

/// Provider for ReviewsCacheService
final reviewsCacheServiceProvider = Provider<ReviewsCacheService>((ref) {
  return ReviewsCacheService(Supabase.instance.client);
});

