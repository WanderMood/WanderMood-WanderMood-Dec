import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/auth_helper.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:dio/dio.dart';
import 'package:wandermood/core/config/supabase_config.dart';

/// Service to call the `moody` Edge Function
class MoodyEdgeFunctionService {
  final SupabaseClient _supabase;

  MoodyEdgeFunctionService(this._supabase);
  
  /// Wait for session to be fully ready (not just valid)
  /// This prevents race conditions during email verification
  Future<void> _waitForSessionReady() async {
    // Wait up to 2 seconds for session to be fully established
    for (int i = 0; i < 20; i++) {
      final user = _supabase.auth.currentUser;
      final session = _supabase.auth.currentSession;
      final token = session?.accessToken;
      
      // All 3 must be true for session to be ready
      if (user != null && session != null && token != null) {
        // Double-check: verify token is not empty
        if (token.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('✅ Session ready: user=${user.id}, token exists');
          }
          return;
        }
      }
      
      // Wait 100ms before checking again
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // If we get here, session is still not ready after 2 seconds
    final user = _supabase.auth.currentUser;
    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;
    
    if (user == null || session == null || token == null) {
      throw Exception('Session not ready after waiting. Please sign in again.');
    }
  }

  /// Get explore places from Edge Function
  /// 
  /// Returns 60-80 places based on mood, location, and filters
  /// 
  /// CRITICAL: Location and coordinates are REQUIRED - no defaults
  Future<List<Place>> getExplore({
    required String mood,
    required String location,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // CRITICAL: Ensure session is valid before calling Edge Function
      await AuthHelper.ensureValidSession();
      
      // CRITICAL FIX: Wait for session to be fully established (not just valid)
      // This prevents race conditions during email verification
      await _waitForSessionReady();
      
      // CRITICAL: Validate location before calling Edge Function
      if (location.isEmpty || location.trim().isEmpty) {
        throw Exception('Location is required. Please provide a valid city name.');
      }

      // CRITICAL: Validate coordinates
      if (latitude == 0.0 && longitude == 0.0) {
        throw Exception('Coordinates are required. Please provide valid latitude and longitude.');
      }

      // FIX #1: Get token explicitly and verify it exists
      final session = _supabase.auth.currentSession;
      final token = session?.accessToken;
      final user = _supabase.auth.currentUser;
      
      // CRITICAL: All 3 must be true - user, session, and token
      if (user == null || session == null || token == null) {
        throw Exception('Session not ready. Please wait a moment and try again.');
      }
      
      if (kDebugMode) {
        debugPrint('🎯 Calling moody Edge Function: get_explore');
        debugPrint('   mood: $mood');
        debugPrint('   location: $location');
        debugPrint('   coordinates: ($latitude, $longitude)');
        debugPrint('   filters: $filters');
        debugPrint('   🔑 Auth token exists: true');
        debugPrint('   🔑 Token preview: ${token.substring(0, 20)}...');
      }

      // Use Dio to explicitly send Authorization header
      final dio = Dio();
      final supabaseUrl = SupabaseConfig.url;
      final functionUrl = '$supabaseUrl/functions/v1/moody';

      final response = await dio.post(
        functionUrl,
        data: {
          'action': 'get_explore',
          'mood': mood,
          'location': location,
          'coordinates': {
            'lat': latitude,
            'lng': longitude,
          },
          'filters': filters ?? {},
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.anonKey,
          },
        ),
      );

      if (kDebugMode) {
        debugPrint('📡 Edge Function response status: ${response.statusCode}');
        debugPrint('   🔑 Authorization header sent: Bearer ${token.substring(0, 20)}...');
      }

      if (response.statusCode != 200) {
        final errorData = response.data;
        if (kDebugMode) {
          debugPrint('❌ Edge Function error: Status ${response.statusCode}, Data: $errorData');
        }
        throw Exception('Edge Function returned status ${response.statusCode}: ${errorData ?? 'Unknown error'}');
      }

      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData.containsKey('error')) {
        throw Exception(responseData['error'] as String);
      }

      final cards = responseData['cards'] as List<dynamic>?;
      if (cards == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No cards in response, returning empty list');
        }
        return [];
      }

      // Transform Edge Function response to Place objects
      final places = cards.map((card) => _transformCardToPlace(card as Map<String, dynamic>)).toList();

      if (kDebugMode) {
        debugPrint('✅ Edge Function returned ${places.length} places');
        debugPrint('   cached: ${responseData['cached'] ?? false}');
        debugPrint('   total_found: ${responseData['total_found'] ?? 0}');
        debugPrint('   unfiltered_total: ${responseData['unfiltered_total'] ?? places.length}');
        
        // CRITICAL: If filtered results < 5, log warning
        final unfilteredTotal = responseData['unfiltered_total'] as int? ?? places.length;
        if (places.length < 5 && unfilteredTotal >= 50) {
          debugPrint('⚠️ Filters reduced results to ${places.length} places (${unfilteredTotal} unfiltered). Consider triggering wider fetch.');
        }
      }

      return places;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calling moody Edge Function: $e');
      }
      rethrow;
    }
  }

  /// Transform Edge Function card response to Place model
  Place _transformCardToPlace(Map<String, dynamic> card) {
    // Extract location
    final locationData = card['location'] as Map<String, dynamic>? ?? {};
    
    // CRITICAL: Use photo_url from Edge Function (already includes API key)
    // Edge Function now returns full photo URLs, so we don't need API key in Flutter
    final photoUrl = card['photo_url'] as String?;
    final photos = photoUrl != null && photoUrl.isNotEmpty
        ? [photoUrl]
        : <String>[];

    if (kDebugMode && photoUrl != null) {
      debugPrint('✅ Using photo URL from Edge Function: ${photoUrl.substring(0, 50)}...');
    }

    // Build address from vicinity or address field
    final address = card['address'] as String? ?? 
                    card['vicinity'] as String? ?? 
                    '';

    // Transform types
    final types = (card['types'] as List<dynamic>?)?.cast<String>() ?? [];

    return Place(
      id: card['id'] as String? ?? '',
      name: card['name'] as String? ?? 'Unknown Place',
      address: address,
      rating: (card['rating'] as num?)?.toDouble() ?? 0.0,
      photos: photos,
      types: types,
      location: PlaceLocation(
        lat: (locationData['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (locationData['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      description: card['description'] as String?,
      priceLevel: card['price_level'] as int?,
      isFree: card['price_level'] == null || card['price_level'] == 0,
    );
  }
}

