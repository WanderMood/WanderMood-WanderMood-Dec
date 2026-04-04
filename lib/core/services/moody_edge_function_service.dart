import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/auth_helper.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:dio/dio.dart';
import 'package:wandermood/core/config/supabase_config.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';

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

  /// Same rule as moody `fetchUserContext`: local only when `currently_exploring == 'local'`.
  Future<bool> _readIsLocalMode() async {
    return PlacesCacheUtils.readExploreIsLocalMode(_supabase);
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
    /// When non-empty, skips Flutter cache read — backend fetches fresh (named filter paths are not cached server-side).
    List<String>? namedFilters,
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

      final isLocal = await _readIsLocalMode();

      final hasNamedFilters =
          namedFilters != null && namedFilters.isNotEmpty;

      // Cache-first for standard explore only — named filter combinations are not cached (backend always refreshes).
      if (!hasNamedFilters) {
        final cachedPlaces = await PlacesCacheUtils.tryLoadExplorePlaces(
          _supabase,
          mood,
          location,
          isLocalMode: isLocal,
        );
        if (cachedPlaces != null) {
          return cachedPlaces;
        }
      }
      if (kDebugMode) {
        debugPrint('🔴 moody get_explore via network');
        debugPrint(
            '   mood: $mood | location: $location | filters: $filters | namedFilters: $namedFilters');
        debugPrint('   🔑 Token preview: ${token.substring(0, 20)}...');
      }

      // Use Dio to explicitly send Authorization header
      final dio = Dio();
      final supabaseUrl = SupabaseConfig.url;
      final functionUrl = '$supabaseUrl/functions/v1/moody';

      final payload = <String, dynamic>{
        'action': 'get_explore',
        'mood': mood,
        'location': location,
        'is_local': isLocal,
        'coordinates': {
          'lat': latitude,
          'lng': longitude,
        },
        'filters': filters ?? {},
      };
      if (hasNamedFilters) {
        payload['namedFilters'] = namedFilters;
      }

      final response = await dio.post(
        functionUrl,
        data: payload,
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

      final cards = responseData['cards'] as List<dynamic>?;
      if (responseData.containsKey('error') &&
          (cards == null || cards.isEmpty)) {
        final detail = responseData['message'] as String? ??
            responseData['error'] as String? ??
            'Explore unavailable';
        throw Exception(detail);
      }

      if (cards == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No cards in response, returning empty list');
        }
        return [];
      }

      // Transform Edge Function response to Place objects
      final places = cards.map((card) {
        final m = card is Map<String, dynamic>
            ? card
            : Map<String, dynamic>.from(card as Map);
        return PlacesCacheUtils.placeFromMoodyExploreCard(m);
      }).toList();

      // Note: Edge Function already caches the response, so we don't need to cache again here
      // The Edge Function's cachePlaces() function handles caching automatically

      if (kDebugMode) {
        debugPrint('✅ Edge Function returned ${places.length} places');
        debugPrint('   cached: ${responseData['cached'] ?? false}');
        debugPrint('   total_found: ${responseData['total_found'] ?? 0}');
        debugPrint('   unfiltered_total: ${responseData['unfiltered_total'] ?? places.length}');
        
        // CRITICAL: If filtered results < 5, log warning
        final unfilteredTotal = responseData['unfiltered_total'] as int? ?? places.length;
        if (places.length < 5 && unfilteredTotal >= 50) {
          debugPrint('⚠️ Filters reduced results to ${places.length} places ($unfilteredTotal unfiltered). Consider triggering wider fetch.');
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

  /// Day plan from Edge (`create_day_plan`). Google Places runs only on the server.
  ///
  /// Returns the parsed JSON body (includes `activities`, `success`, `moodyMessage`, etc.).
  /// Callers map to app models as needed.
  Future<Map<String, dynamic>> createDayPlan({
    required List<String> moods,
    required String location,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? filters,
    String? languageCode,
  }) async {
    await AuthHelper.ensureValidSession();
    await _waitForSessionReady();

    if (location.trim().isEmpty) {
      throw Exception('Location is required. Please provide a valid city name.');
    }

    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;
    final user = _supabase.auth.currentUser;
    if (user == null || session == null || token == null || token.isEmpty) {
      throw Exception('Session not ready. Please wait a moment and try again.');
    }

    final dio = Dio();
    final functionUrl = '${SupabaseConfig.url}/functions/v1/moody';

    final isLocal = await _readIsLocalMode();
    final response = await dio.post<Map<String, dynamic>>(
      functionUrl,
      data: {
        'action': 'create_day_plan',
        'moods': moods,
        'location': location.trim(),
        'is_local': isLocal,
        'coordinates': {'lat': latitude, 'lng': longitude},
        'filters': filters ?? <String, dynamic>{},
        if (languageCode != null && languageCode.isNotEmpty)
          'language_code': languageCode,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'apikey': SupabaseConfig.anonKey,
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Edge Function returned status ${response.statusCode}: ${response.data}',
      );
    }

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from create_day_plan');
    }
    if (data['success'] == false) {
      final err = data['error']?.toString() ??
          data['message']?.toString() ??
          'create_day_plan failed';
      throw Exception(err);
    }
    return data;
  }
}

