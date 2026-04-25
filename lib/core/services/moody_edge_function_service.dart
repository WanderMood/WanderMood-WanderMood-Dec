import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/auth_helper.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:dio/dio.dart';
import 'package:wandermood/core/config/supabase_config.dart';
import 'package:wandermood/core/errors/explore_location_exception.dart';
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
  /// CRITICAL: Location and coordinates are REQUIRED - no defaults
  ///
  /// [section] — `food` | `trending` | `solo` | `different` | null (broad discovery).
  /// When non-empty, [namedFilters] skips Flutter cache read — backend fetches fresh.
  ///
  /// [bypassPlacesCache] — when true, skips the direct `places_cache` read so the
  /// Edge Function can refresh (pull-to-refresh, background revalidation).
  Future<List<Place>> getExplore({
    required String location,
    required double latitude,
    required double longitude,
    String? section,
    Map<String, dynamic>? filters,
    List<String>? namedFilters,
    /// BCP-47 primary tag (`en`, `nl`, `es`, …). Matches moody `normalizeAppLang`.
    String? languageCode,
    bool bypassPlacesCache = false,
  }) async {
    try {
      if (location.isEmpty || location.trim().isEmpty) {
        throw const ExploreLocationException(ExploreLocationReason.missingCity);
      }

      final hasNamedFilters =
          namedFilters != null && namedFilters.isNotEmpty;

      final effectiveLang = (languageCode != null && languageCode.isNotEmpty)
          ? languageCode.toLowerCase().split(RegExp(r'[-_]')).first
          : null;

      final isLocal = await _readIsLocalMode();

      // Supabase `places_cache` first — no session wait, no Edge cold start.
      // Named-filter requests skip cache (moody always recomputes).
      if (!hasNamedFilters && !bypassPlacesCache) {
        final cacheSection = section ?? 'discovery';
        final cachedHit = await PlacesCacheUtils.tryLoadExplorePlacesHit(
          _supabase,
          cacheSection,
          location,
          isLocalMode: isLocal,
          languageCode: effectiveLang,
        );
        if (cachedHit != null && cachedHit.places.isNotEmpty) {
          return cachedHit.places;
        }
      }

      await AuthHelper.ensureValidSession();
      await _waitForSessionReady();

      if (latitude == 0.0 && longitude == 0.0) {
        throw const ExploreLocationException(
            ExploreLocationReason.invalidCoordinates);
      }

      final session = _supabase.auth.currentSession;
      final token = session?.accessToken;
      final user = _supabase.auth.currentUser;

      if (user == null || session == null || token == null) {
        throw Exception('Session not ready. Please wait a moment and try again.');
      }

      if (kDebugMode) {
        debugPrint('🔴 moody get_explore via network');
        debugPrint(
            '   section: $section | location: $location | filters: $filters | namedFilters: $namedFilters');
        debugPrint('   🔑 Token preview: ${token.substring(0, 20)}...');
      }

      // Use Dio to explicitly send Authorization header
      final dio = Dio();
      final functionUrl = SupabaseConfig.moodyFunctionUrl;

      final payload = <String, dynamic>{
        'action': 'get_explore',
        'location': location,
        'is_local': isLocal,
        'coordinates': {
          'lat': latitude,
          'lng': longitude,
        },
      };
      if (section != null && section.isNotEmpty) {
        payload['section'] = section;
      }
      if (filters != null && filters.isNotEmpty) {
        payload['filters'] = filters;
      }
      if (hasNamedFilters) {
        payload['namedFilters'] = namedFilters;
      }
      if (effectiveLang != null) {
        payload['language_code'] = effectiveLang;
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
        if (response.statusCode == 503) {
          // Edge cold start / transient outage: fail soft for Explore UI.
          final fallback = await PlacesCacheUtils.tryLoadExplorePlacesHit(
            _supabase,
            section ?? 'discovery',
            location,
            isLocalMode: isLocal,
            languageCode: effectiveLang,
          );
          if (fallback != null && fallback.places.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                '⚠️ moody 503 -> using cached explore fallback (${fallback.places.length} places)',
              );
            }
            return fallback.places;
          }
          if (kDebugMode) {
            debugPrint('⚠️ moody 503 -> returning empty explore list (no cache fallback)');
          }
          return const <Place>[];
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

      // #region agent log – H-A: log photo_url distinctness from edge function cards
      final _photoUrls9a3a3b = <String>{};
      for (final c in cards.take(8)) {
        final m9 = c is Map<String, dynamic> ? c : Map<String, dynamic>.from(c as Map);
        _photoUrls9a3a3b.add((m9['photo_url'] as String?) ?? '');
      }
      debugPrint('🔍 dbg9a3a3b explore_response: cached=${responseData['cached']} total=${cards.length} distinct_photo_urls=${_photoUrls9a3a3b.length}');
      for (int _i9 = 0; _i9 < cards.length && _i9 < 5; _i9++) {
        final m9 = cards[_i9] is Map<String, dynamic> ? cards[_i9] as Map<String, dynamic> : Map<String, dynamic>.from(cards[_i9] as Map);
        final url9 = (m9['photo_url'] as String?) ?? '';
        debugPrint('  [${_i9}] ${m9['name']} | photo_url_path=${url9.length > 50 ? url9.substring(30, url9.length > 100 ? 100 : url9.length) : url9}');
      }
      // #endregion

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
      if (e is DioException && e.response?.statusCode == 503) {
        final effectiveLangForFallback =
            (languageCode != null && languageCode.isNotEmpty)
                ? languageCode.toLowerCase().split(RegExp(r'[-_]')).first
                : null;
        final isLocalForFallback = await _readIsLocalMode();
        final fallback = await PlacesCacheUtils.tryLoadExplorePlacesHit(
          _supabase,
          section ?? 'discovery',
          location,
          isLocalMode: isLocalForFallback,
          languageCode: effectiveLangForFallback,
        );
        if (fallback != null && fallback.places.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ moody Dio 503 -> cached explore fallback (${fallback.places.length} places)',
            );
          }
          return fallback.places;
        }
        return const <Place>[];
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
    /// Calendar day the user picked in the hub / Mood Match (moody may use later).
    DateTime? targetDate,
    /// When set, moody returns a single coffee-focused activity.
    String? quickPick,
  }) async {
    await AuthHelper.ensureValidSession();
    await _waitForSessionReady();

    if (location.trim().isEmpty) {
      throw const ExploreLocationException(ExploreLocationReason.missingCity);
    }

    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;
    final user = _supabase.auth.currentUser;
    if (user == null || session == null || token == null || token.isEmpty) {
      throw Exception('Session not ready. Please wait a moment and try again.');
    }

    final dio = Dio();
    final functionUrl = SupabaseConfig.moodyFunctionUrl;

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
        if (targetDate != null)
          'target_date': DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
          ).toIso8601String(),
        if (quickPick != null && quickPick.trim().isNotEmpty)
          'quick_pick': quickPick.trim().toLowerCase(),
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

