import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  /// [namedFilters] uses the same `places_cache` aggregate key suffix as moody (`_nf_…`).
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
    final hasNamedFilters =
        namedFilters != null && namedFilters.isNotEmpty;
    try {
      if (location.isEmpty || location.trim().isEmpty) {
        throw const ExploreLocationException(ExploreLocationReason.missingCity);
      }

      final effectiveLang = (languageCode != null && languageCode.isNotEmpty)
          ? languageCode.toLowerCase().split(RegExp(r'[-_]')).first
          : null;

      final isLocal = await _readIsLocalMode();

      // Supabase `places_cache` first — no session wait, no Edge cold start.
      // moody is the cache gatekeeper; all requests (including named filters) check DB first.
      if (!bypassPlacesCache) {
        final cacheSection = section ?? 'discovery';
        final cachedHit = await PlacesCacheUtils.tryLoadExplorePlacesHit(
          _supabase,
          cacheSection,
          location,
          isLocalMode: isLocal,
          languageCode: effectiveLang,
          namedFilters: hasNamedFilters ? namedFilters : null,
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
      payload['client_hour'] = DateTime.now().hour;

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
            namedFilters: hasNamedFilters ? namedFilters : null,
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
          namedFilters: hasNamedFilters ? namedFilters : null,
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

  /// Day plan from Edge (`create_day_plan`). Same transport rules as [getExplore]:
  /// session wait, `is_local` from [PlacesCacheUtils.readExploreIsLocalMode], and
  /// transient **502 / 503 / 429** retries so Mood Match and Plan-with-Moody stay aligned.
  ///
  /// [languageCode] is normalized like Explore (`normalizeExploreLanguageCode`).
  ///
  /// When [planResponseCache] is set and [bypassPlanResponseCache] is false, a recent
  /// successful response is read from disk **before** calling moody. Cache key is
  /// **location + moods + date + slots + filters** (device-local; reusable across
  /// accounts on the same install when inputs match).
  ///
  /// Returns the parsed JSON body (includes `activities`, `success`, `moodyMessage`, etc.).
  Future<Map<String, dynamic>> createDayPlan({
    required List<String> moods,
    required String location,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? filters,
    String? languageCode,
    DateTime? targetDate,
    String? quickPick,
    /// Moody `allowed_slots` (`morning` / `afternoon` / `evening`).
    List<String>? allowedSlots,
    SharedPreferences? planResponseCache,
    bool bypassPlanResponseCache = false,
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

    final String? moodyLang = (languageCode != null &&
            languageCode.trim().isNotEmpty)
        ? PlacesCacheUtils.normalizeExploreLanguageCode(languageCode)
        : null;

    final effectiveFilters = filters ?? <String, dynamic>{};
    if (planResponseCache != null && !bypassPlanResponseCache) {
      final cached = _tryReadDayPlanResponseCache(
        planResponseCache,
        moods: moods,
        location: location.trim(),
        latitude: latitude,
        longitude: longitude,
        filters: effectiveFilters,
        languageTag: moodyLang ?? 'en',
        isLocalMode: isLocal,
        targetDate: targetDate,
        quickPick: quickPick,
        allowedSlots: allowedSlots,
      );
      if (cached != null) {
        if (kDebugMode) {
          debugPrint('✅ create_day_plan: using local cached response (moody Edge skipped)');
        }
        return cached;
      }
    }

    final payload = <String, dynamic>{
      'action': 'create_day_plan',
      'moods': moods,
      'location': location.trim(),
      'is_local': isLocal,
      'coordinates': {'lat': latitude, 'lng': longitude},
      'filters': effectiveFilters,
      if (moodyLang != null) 'language_code': moodyLang,
      if (targetDate != null)
        'target_date': DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
        ).toIso8601String(),
      if (quickPick != null && quickPick.trim().isNotEmpty)
        'quick_pick': quickPick.trim().toLowerCase(),
      if (allowedSlots != null && allowedSlots.isNotEmpty)
        'allowed_slots': allowedSlots,
    };

    const maxAttempts = 4;
    late Response<dynamic> response;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt > 1) {
        final waitMs = 1200 * (attempt - 1);
        if (kDebugMode) {
          debugPrint(
            '⏳ create_day_plan retry $attempt/$maxAttempts after ${waitMs}ms',
          );
        }
        await Future.delayed(Duration(milliseconds: waitMs));
      }

      response = await dio.post(
        functionUrl,
        data: payload,
        options: Options(
          validateStatus: (status) => status != null && status < 600,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.anonKey,
          },
        ),
      );

      final code = response.statusCode ?? 0;
      if (code == 200) break;

      final retryable = code == 503 || code == 502 || code == 429;
      if (retryable && attempt < maxAttempts) {
        if (kDebugMode) {
          debugPrint('⚠️ create_day_plan HTTP $code — retrying');
        }
        continue;
      }

      final errorData = response.data;
      final errorMessage = errorData is Map<String, dynamic>
          ? (errorData['message'] as String? ??
              errorData['error'] as String? ??
              'Service error. Please try again.')
          : 'Service error. Please try again.';
      throw Exception(errorMessage);
    }

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: Service temporarily unavailable.',
      );
    }

    final raw = response.data;
    if (raw is! Map) {
      throw Exception('Empty response from create_day_plan');
    }
    final data = Map<String, dynamic>.from(raw);
    if (data['success'] == false) {
      final err = data['error']?.toString() ??
          data['message']?.toString() ??
          'create_day_plan failed';
      throw Exception(err);
    }
    if (planResponseCache != null &&
        !bypassPlanResponseCache &&
        data['success'] == true) {
      final total = data['total_found'];
      final okTotal = total is num && total > 0;
      final activities = data['activities'];
      final okActivities = activities is List && activities.isNotEmpty;
      if (okTotal || okActivities) {
        await _writeDayPlanResponseCache(
          planResponseCache,
          moods: moods,
          location: location.trim(),
          latitude: latitude,
          longitude: longitude,
          filters: effectiveFilters,
          languageTag: moodyLang ?? 'en',
          isLocalMode: isLocal,
          targetDate: targetDate,
          quickPick: quickPick,
          allowedSlots: allowedSlots,
          payload: data,
        );
      }
    }
    return data;
  }

  static const Duration _dayPlanLocalCacheTtl = Duration(days: 7);

  String _dayPlanResponseCacheStorageKey({
    required List<String> moods,
    required String location,
    required double latitude,
    required double longitude,
    required Map<String, dynamic> filters,
    required String languageTag,
    required bool isLocalMode,
    required DateTime? targetDate,
    required String? quickPick,
    required List<String>? allowedSlots,
  }) {
    final moodsKey = moods.map((e) => e.toLowerCase().trim()).toList()..sort();
    final latK = (latitude * 10000).round() / 10000;
    final lngK = (longitude * 10000).round() / 10000;
    final dateKey = targetDate != null
        ? DateTime(targetDate.year, targetDate.month, targetDate.day)
            .toIso8601String()
            .split('T')
            .first
        : '';
    final slots = [...?allowedSlots]..sort();
    final filt = jsonEncode(filters);
    return 'wandermood_day_plan_v1|${location.toLowerCase().trim()}|'
        '$latK|$lngK|${moodsKey.join(',')}|$languageTag|${isLocalMode ? 'L' : 'G'}|$dateKey|'
        '${quickPick ?? ''}|${slots.join(',')}|$filt';
  }

  Map<String, dynamic>? _tryReadDayPlanResponseCache(
    SharedPreferences prefs, {
    required List<String> moods,
    required String location,
    required double latitude,
    required double longitude,
    required Map<String, dynamic> filters,
    required String languageTag,
    required bool isLocalMode,
    required DateTime? targetDate,
    required String? quickPick,
    required List<String>? allowedSlots,
  }) {
    final key = _dayPlanResponseCacheStorageKey(
      moods: moods,
      location: location,
      latitude: latitude,
      longitude: longitude,
      filters: filters,
      languageTag: languageTag,
      isLocalMode: isLocalMode,
      targetDate: targetDate,
      quickPick: quickPick,
      allowedSlots: allowedSlots,
    );
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final wrap = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(wrap['savedAt'] as String? ?? '');
      if (savedAt == null) return null;
      if (DateTime.now().difference(savedAt) > _dayPlanLocalCacheTtl) {
        return null;
      }
      final body = wrap['payload'];
      if (body is! Map<String, dynamic>) return null;
      final out = Map<String, dynamic>.from(body);
      if (out['success'] != true) return null;
      final total = out['total_found'];
      final activities = out['activities'];
      final hasActivities = activities is List && activities.isNotEmpty;
      final hasTotal = total is num && total > 0;
      if (!hasActivities && !hasTotal) return null;
      return out;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDayPlanResponseCache(
    SharedPreferences prefs, {
    required List<String> moods,
    required String location,
    required double latitude,
    required double longitude,
    required Map<String, dynamic> filters,
    required String languageTag,
    required bool isLocalMode,
    required DateTime? targetDate,
    required String? quickPick,
    required List<String>? allowedSlots,
    required Map<String, dynamic> payload,
  }) async {
    final key = _dayPlanResponseCacheStorageKey(
      moods: moods,
      location: location,
      latitude: latitude,
      longitude: longitude,
      filters: filters,
      languageTag: languageTag,
      isLocalMode: isLocalMode,
      targetDate: targetDate,
      quickPick: quickPick,
      allowedSlots: allowedSlots,
    );
    final wrap = <String, dynamic>{
      'savedAt': DateTime.now().toIso8601String(),
      'payload': payload,
    };
    await prefs.setString(key, jsonEncode(wrap));
  }

}

