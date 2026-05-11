import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/config/supabase_config.dart';
import 'package:wandermood/core/models/ai_recommendation.dart';
import 'package:wandermood/core/models/ai_chat_message.dart';
import 'package:wandermood/core/services/ai_chat_quota_service.dart';
import 'package:wandermood/core/services/moody_edge_function_service.dart';
import 'package:wandermood/core/services/partner_listing_service.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/features/places/models/place.dart';

/// Orchestration layer for all AI interactions in WanderMood.
/// All methods route through the `moody` Edge Function.
///
/// The supabase_flutter client attaches `Authorization: Bearer <access_token>` when
/// [auth.currentSession] is non-null.
class WanderMoodAIService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static String get _moodyFunctionName => SupabaseConfig.moodyFunction;

  /// Maps [preferences] into `moody` `get_explore` filter keys (`rating`, `priceLevel`).
  static Map<String, dynamic> _preferencesToExploreFilters(
    Map<String, dynamic>? preferences,
  ) {
    if (preferences == null || preferences.isEmpty) return {};
    final filters = <String, dynamic>{};
    final budget = preferences['budget'];
    if (budget is num) {
      final b = budget.toDouble();
      if (b <= 30) {
        filters['priceLevel'] = 1;
      } else if (b <= 70) {
        filters['priceLevel'] = 2;
      } else {
        filters['priceLevel'] = 4;
      }
    }
    final minRating = preferences['minRating'] ?? preferences['rating'];
    if (minRating is num) {
      filters['rating'] = minRating.toDouble();
    }
    return filters;
  }

  static AIRecommendation _exploreCardToAiRecommendation(
    Map<String, dynamic> card,
    List<String> moods,
    Map<String, dynamic>? preferences,
  ) {
    final types =
        (card['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            <String>[];
    final type = types.isNotEmpty ? types.first : 'place';

    Map<String, dynamic>? location;
    final loc = card['location'];
    if (loc is Map) {
      final m = Map<String, dynamic>.from(loc);
      final lat = (m['lat'] as num?)?.toDouble();
      final lng = (m['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        location = {'latitude': lat, 'longitude': lng};
      }
    }

    final moodMatch = moods.isNotEmpty ? moods.join(', ') : 'exploring';
    final ts = preferences?['timeSlot'];
    final timeSlot = ts is String ? ts : 'flexible';

    return AIRecommendation(
      name: card['name']?.toString() ?? 'Place',
      type: type,
      rating: (card['rating'] as num?)?.toDouble() ?? 0.0,
      description: card['description']?.toString() ??
          card['vicinity']?.toString() ??
          card['address']?.toString() ??
          '',
      duration: '60 min',
      cost: _priceLevelToCostLabel(card['price_level']),
      moodMatch: moodMatch,
      timeSlot: timeSlot,
      imageUrl: card['photo_url']?.toString(),
      location: location,
    );
  }

  static String _priceLevelToCostLabel(dynamic priceLevel) {
    if (priceLevel == null) return '€€';
    final n = priceLevel is num
        ? priceLevel.toInt()
        : int.tryParse(priceLevel.toString()) ?? 2;
    switch (n.clamp(0, 4)) {
      case 0:
        return 'Free';
      case 1:
        return '€';
      case 2:
        return '€€';
      case 3:
        return '€€€';
      default:
        return '€€€€';
    }
  }

  static String _activityCostLabel(Map<String, dynamic> act) {
    final pl = act['priceLevel'] ?? act['price_level'];
    if (pl is String && pl.contains('€')) return pl;
    return _priceLevelToCostLabel(pl);
  }

  static String _activityDurationLabel(Map<String, dynamic> act) {
    final dur = act['duration'];
    if (dur is num) return '${dur.toInt()} min';
    final s = dur?.toString().trim() ?? '';
    if (s.isEmpty) return '60 min';
    if (s.contains('min')) return s;
    final n = int.tryParse(s);
    return n != null ? '$n min' : '60 min';
  }

  /// Maps a moody `create_day_plan` activity JSON into [AIRecommendation].
  static AIRecommendation _createDayPlanActivityToRecommendation(
    Map<String, dynamic> act,
    List<String> moods,
  ) {
    Map<String, dynamic>? location;
    final loc = act['location'];
    if (loc is Map) {
      final m = Map<String, dynamic>.from(loc);
      final lat = (m['latitude'] as num?)?.toDouble();
      final lng = (m['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        location = {
          'latitude': lat,
          'longitude': lng,
        };
        final pid = act['placeId']?.toString() ?? act['place_id']?.toString();
        if (pid != null && pid.trim().isNotEmpty) {
          location['placeId'] = pid.trim();
        }
      }
    }
    final tags = act['tags'];
    final type = tags is List && tags.isNotEmpty
        ? tags.first.toString()
        : (act['paymentType']?.toString() ?? 'place');
    final rawSlot = act['timeSlot'] ?? act['time_slot'];
    final slot = rawSlot?.toString().trim().toLowerCase() ?? '';
    final timeSlot =
        (slot == 'morning' || slot == 'afternoon' || slot == 'evening')
            ? slot
            : 'flexible';
    final moodMatch = moods.isNotEmpty ? moods.join(', ') : '';

    return AIRecommendation(
      name: act['name']?.toString() ?? 'Place',
      type: type,
      rating: (act['rating'] as num?)?.toDouble() ?? 0.0,
      description: act['description']?.toString() ?? '',
      duration: _activityDurationLabel(act),
      cost: _activityCostLabel(act),
      moodMatch: moodMatch,
      timeSlot: timeSlot,
      imageUrl: act['imageUrl']?.toString() ?? act['image_url']?.toString(),
      location: location,
    );
  }

  /// Mood Match shared plan: same pipeline as hub **Plan my day** (`create_day_plan`).
  static Future<AIRecommendationResponse> getGroupMatchCreateDayPlan({
    required List<String> moods,
    required String location,
    required double latitude,
    required double longitude,
    String? languageCode,
    DateTime? plannedDay,
    String? partnerContext,
  }) async {
    debugPrint(
      '🤖 Mood Match: moody create_day_plan for moods: $moods @ $location',
    );
    final svc = MoodyEdgeFunctionService(_supabase);
    final prefs = await SharedPreferences.getInstance();
    final data = await svc.createDayPlan(
      moods: moods,
      location: location,
      latitude: latitude,
      longitude: longitude,
      filters: const <String, dynamic>{},
      languageCode: languageCode,
      targetDate: plannedDay,
      partnerContext: partnerContext,
      planResponseCache: prefs,
    );

    final activities = data['activities'] as List<dynamic>? ?? [];
    final recommendations = <AIRecommendation>[];
    for (final raw in activities) {
      if (raw is Map<String, dynamic>) {
        recommendations.add(_createDayPlanActivityToRecommendation(raw, moods));
      } else if (raw is Map) {
        recommendations.add(
          _createDayPlanActivityToRecommendation(
            Map<String, dynamic>.from(raw),
            moods,
          ),
        );
      }
    }

    final summary = data['moodyMessage']?.toString() ??
        'Plan for ${moods.join(' & ')} in $location';

    return AIRecommendationResponse(
      success: recommendations.isNotEmpty,
      action: 'create_day_plan',
      timestamp: MoodyClock.now().toIso8601String(),
      summary: summary,
      availablePlaces: recommendations.length,
      recommendations: recommendations,
    );
  }

  /// Place recommendations from the **`moody`** Edge Function (`get_explore`).
  ///
  /// [conversationId] / [conversationContext] are accepted for API compatibility;
  /// `get_explore` does not use them.
  static Future<AIRecommendationResponse> getRecommendations({
    required List<String> moods,
    required double latitude,
    required double longitude,
    String? city,
    Map<String, dynamic>? preferences,
    String? conversationId,
    List<String>? conversationContext,
    String? plannedDate,
    String? timeSlot,
    List<String>? participantNames,
    bool groupMatch = false,
  }) async {
    debugPrint(
        '🤖 Getting explore recommendations (moody/get_explore) for moods: $moods');

    try {
      final locationName = city ?? 'Rotterdam';
      final primaryMood = moods.isNotEmpty ? moods.first : 'adventurous';

      final userId = _supabase.auth.currentUser?.id;
      var isLocal = false;
      if (userId != null) {
        final profile = await _supabase
            .from('profiles')
            .select('currently_exploring')
            .eq('id', userId)
            .maybeSingle();
        final v =
            (profile?['currently_exploring'] as String?)?.toLowerCase().trim();
        isLocal = v == 'local';
      }

      final requestBody = <String, dynamic>{
        'action': 'get_explore',
        'location': locationName,
        'is_local': isLocal,
        'coordinates': {
          'lat': latitude,
          'lng': longitude,
        },
        'mood': primaryMood,
        'filters': _preferencesToExploreFilters(preferences),
      };
      if (groupMatch) {
        requestBody['group_match'] = true;
        final pd = plannedDate?.trim();
        if (pd != null && pd.isNotEmpty) {
          requestBody['planned_date'] = pd;
        }
        final ts = timeSlot?.trim();
        if (ts != null && ts.isNotEmpty) {
          requestBody['time_slot'] = ts;
        }
        if (participantNames != null && participantNames.isNotEmpty) {
          requestBody['participant_names'] = participantNames;
        }
      }

      debugPrint('📤 Invoking moody (get_explore): $requestBody');

      final response = await _supabase.functions.invoke(
        _moodyFunctionName,
        body: requestBody,
      );

      if (response.status != 200) {
        throw Exception(
          'Moody get_explore error: HTTP ${response.status} ${response.data}',
        );
      }

      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Moody get_explore: expected JSON object response');
      }

      final data = raw;
      final cards = (data['cards'] as List<dynamic>?) ?? [];
      if (data['error'] != null && cards.isEmpty) {
        debugPrint(
          '⚠️ Moody get_explore returned no cards: ${data['error']} — ${data['message']}',
        );
      }

      final recommendations = <AIRecommendation>[];
      for (final item in cards) {
        if (item is Map<String, dynamic>) {
          recommendations
              .add(_exploreCardToAiRecommendation(item, moods, preferences));
        } else if (item is Map) {
          recommendations.add(
            _exploreCardToAiRecommendation(
              Map<String, dynamic>.from(item),
              moods,
              preferences,
            ),
          );
        }
      }

      debugPrint(
          '✅ Moody explore cards mapped: ${recommendations.length} items');

      return AIRecommendationResponse(
        success: recommendations.isNotEmpty,
        action: 'recommend',
        timestamp: MoodyClock.now().toIso8601String(),
        summary:
            'Explore recommendations for ${moods.join(', ')} in $locationName',
        availablePlaces: recommendations.length,
        recommendations: recommendations,
      );
    } catch (e) {
      debugPrint('❌ Error getting recommendations from moody: $e');
      rethrow;
    }
  }

  /// Mood Match reveal copy: localized + communication style via **`moody`** (`group_match_moody_message`).
  /// Returns empty string on failure so the client can fall back to tier strings.
  static Future<String> getGroupMatchMoodyMessage({
    required List<String> moods,
    required int compatibilityScore,
    required String languageCode,
    required String communicationStyle,
    String? plannedDate,
    String? mood1,
    String? mood2,
    String? name1,
    String? name2,
    String? location,
  }) async {
    final lang = languageCode.toLowerCase().split(RegExp(r'[-_]')).first;
    try {
      final body = <String, dynamic>{
        'action': 'group_match_moody_message',
        'moods': moods,
        'compatibility_score': compatibilityScore,
        'language': lang,
        'communication_style': communicationStyle,
      };
      final pd = plannedDate?.trim();
      if (pd != null && pd.isNotEmpty) body['planned_date'] = pd;
      final m1 = mood1?.trim();
      if (m1 != null && m1.isNotEmpty) body['mood1'] = m1;
      final m2 = mood2?.trim();
      if (m2 != null && m2.isNotEmpty) body['mood2'] = m2;
      final n1 = name1?.trim();
      if (n1 != null && n1.isNotEmpty) body['name1'] = n1;
      final n2 = name2?.trim();
      if (n2 != null && n2.isNotEmpty) body['name2'] = n2;
      final loc = location?.trim();
      if (loc != null && loc.isNotEmpty) body['location'] = loc;

      final response = await _supabase.functions.invoke(
        _moodyFunctionName,
        body: body,
      );
      if (response.status != 200) {
        debugPrint(
          'Moody group_match_moody_message: HTTP ${response.status} ${response.data}',
        );
        return '';
      }
      final raw = response.data;
      if (raw is! Map) return '';
      final msg = raw['moodyMessage']?.toString().trim();
      return (msg != null && msg.isNotEmpty) ? msg : '';
    } catch (e) {
      debugPrint('❌ getGroupMatchMoodyMessage: $e');
      return '';
    }
  }

  /// One Moody call that returns a short line per time slot for Mood Match
  /// plan cards (`group_match_activity_notes` on the `moody` edge function).
  static Future<Map<String, String>> getGroupMatchActivityMoodyNotes({
    required List<AIRecommendation> recommendations,
    required String languageCode,
    required String communicationStyle,
  }) async {
    final lang = languageCode.toLowerCase().split(RegExp(r'[-_]')).first;
    final activities = <Map<String, dynamic>>[];
    for (final r in recommendations) {
      final slot = r.timeSlot.toLowerCase().trim();
      if (slot != 'morning' && slot != 'afternoon' && slot != 'evening') {
        continue;
      }
      activities.add({
        'slot': slot,
        'name': r.name,
        'type': r.type,
        'description': r.description,
        'mood_match': r.moodMatch,
      });
    }
    if (activities.isEmpty) return const {};
    try {
      final response = await _supabase.functions.invoke(
        _moodyFunctionName,
        body: {
          'action': 'group_match_activity_notes',
          'language_code': lang,
          'communication_style': communicationStyle,
          'activities': activities,
        },
      );
      if (response.status != 200) {
        debugPrint(
          'Moody group_match_activity_notes: HTTP ${response.status} ${response.data}',
        );
        return const {};
      }
      final raw = response.data;
      if (raw is! Map) return const {};
      final notesRaw = raw['notes'];
      if (notesRaw is! Map) return const {};
      final out = <String, String>{};
      for (final e in notesRaw.entries) {
        final k = e.key.toString().toLowerCase().trim();
        final v = e.value?.toString().trim() ?? '';
        if ((k == 'morning' || k == 'afternoon' || k == 'evening') &&
            v.isNotEmpty) {
          out[k] = v;
        }
      }
      return out;
    } catch (e) {
      debugPrint('❌ getGroupMatchActivityMoodyNotes: $e');
      return const {};
    }
  }

  /// Clock fields the `moody` `chat` action uses for greetings, time-of-day tone,
  /// and "today" vs planner-day disambiguation. [at] defaults to [MoodyClock.now].
  static Map<String, dynamic> moodyChatClientClockFields({
    DateTime? at,
    String? planningCalendarDateIso,
  }) {
    final local = (at ?? MoodyClock.now()).toLocal();
    const weekdaysEn = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final y = local.year.toString().padLeft(4, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final da = local.day.toString().padLeft(2, '0');
    final hm =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final out = <String, dynamic>{
      'client_local_date_iso': '$y-$mo-$da',
      'client_local_time_hm': hm,
      'client_weekday_en': weekdaysEn[local.weekday - 1],
      'client_utc_offset_minutes': local.timeZoneOffset.inMinutes,
      'client_time_zone_name': local.timeZoneName,
    };
    final p = planningCalendarDateIso?.trim();
    if (p != null && p.isNotEmpty) {
      out['planning_date_iso'] = p;
    }
    return out;
  }

  /// Start or continue a chat conversation with the AI.
  /// Routes through the `moody` edge function (action: chat) so the
  /// OpenAI key stays server-side and never needs to be baked into the app.
  static Future<AIChatResponse> chat({
    required String message,
    String? conversationId,
    List<String>? moods,
    double? latitude,
    double? longitude,
    String? city,
    DateTime? clientLocalSnapshot,
    String? planningCalendarDateIso,

    /// Prior turns in the current UI session (excluding the message being sent).
    /// Used when [getConversationHistory] is empty (e.g. guest or failed saves).
    List<Map<String, String>>? clientTurns,

    /// BCP 47 language code (e.g. `de`, `nl`) so Moody replies match app locale.
    String languageCode = 'en',

    /// Optional grounded context (e.g. My Day "free time" card) — sent as `shared_place` to moody.
    Map<String, dynamic>? sharedPlace,
  }) async {
    debugPrint('💬 Routing chat through moody edge function');

    final convId = conversationId ?? _generateConversationId();

    final quotaMsg =
        await AiChatQuotaService.blockingMessageIfOverQuota(_supabase);
    if (quotaMsg != null) {
      return AIChatResponse(
        success: true,
        action: 'chat',
        timestamp: MoodyClock.now().toIso8601String(),
        message: quotaMsg,
        conversationId: convId,
        contextUsed: {'quotaExceeded': true},
      );
    }

    // Load conversation history for context continuity
    List<Map<String, String>> history = [];
    try {
      final dbHistory = await getConversationHistory(convId);
      history = dbHistory
          .map((msg) => {
                'role': msg.role,
                'content': msg.content,
              })
          .toList();
      if (history.isNotEmpty) {
        debugPrint('📚 Loaded ${history.length} messages from DB history');
      }
    } catch (_) {}

    // Fall back to client-provided turns when DB is empty
    if (history.isEmpty && clientTurns != null && clientTurns.isNotEmpty) {
      history = clientTurns.map((m) => Map<String, String>.from(m)).toList();
      debugPrint('📚 Using ${history.length} client turns for context');
    }

    final resolvedLat = latitude ?? 51.9225;
    final resolvedLng = longitude ?? 4.4792;
    final resolvedCity =
        (city != null && city.trim().isNotEmpty) ? city.trim() : 'Rotterdam';

    try {
      final clockFields = moodyChatClientClockFields(
        at: clientLocalSnapshot,
        planningCalendarDateIso: planningCalendarDateIso,
      );
      try {
        final tz = await FlutterTimezone.getLocalTimezone();
        final trimmed = tz.identifier.trim();
        if (trimmed.isNotEmpty) {
          clockFields['client_time_zone_id'] = trimmed;
        }
      } catch (_) {}

      final body = <String, dynamic>{
        'action': 'chat',
        'message': message,
        'history': history,
        'conversationId': convId,
        'location': resolvedCity,
        'coordinates': {
          'lat': resolvedLat,
          'lng': resolvedLng,
        },
        'language_code': languageCode,
        'moods': moods ?? <String>[],
        ...clockFields,
      };
      try {
        final partnerContext =
            await PartnerListingService.buildChatPartnerContext(
          city: resolvedCity,
          moods: moods ?? const <String>[],
        );
        if (partnerContext.trim().isNotEmpty) {
          body['partner_context'] = partnerContext;
        }
      } catch (_) {
        // Optional enrichment only; never block chat path.
      }
      if (sharedPlace != null && sharedPlace.isNotEmpty) {
        body['shared_place'] = sharedPlace;
      }

      final response = await _supabase.functions.invoke(
        _moodyFunctionName,
        body: body,
      );

      if (response.status != 200) {
        throw Exception('Moody chat returned HTTP ${response.status}');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected moody chat response format');
      }

      final reply = (data['reply'] as String?)?.trim() ?? '';
      if (reply.isEmpty) throw Exception('Empty reply from moody');

      List<Place>? suggestedPlaces;
      final rawPlaces = data['suggested_places'];
      if (rawPlaces is List) {
        final out = <Place>[];
        for (final e in rawPlaces) {
          if (e is Map) {
            try {
              final m = Map<String, dynamic>.from(e);

              // The API's PlaceCard shape often provides a single `photo_url` string.
              // Our `Place` model expects `photos: List<String>`.
              final photos = m['photos'];
              final hasPhotosList = photos is List && photos.isNotEmpty;
              if (!hasPhotosList) {
                final photoUrl =
                    (m['photo_url'] ?? m['photoUrl'] ?? m['image_url'])
                        ?.toString()
                        .trim();
                if (photoUrl != null && photoUrl.isNotEmpty) {
                  m['photos'] = [photoUrl];
                }
              }

              out.add(Place.fromJson(m));
            } catch (_) {}
          }
        }
        if (out.isNotEmpty) suggestedPlaces = out;
      }

      debugPrint('✅ Moody chat response received');

      await AiChatQuotaService.recordSuccessfulChat(_supabase);

      return AIChatResponse(
        success: true,
        action: 'chat',
        timestamp: MoodyClock.now().toIso8601String(),
        message: reply,
        conversationId: data['conversationId'] as String? ?? convId,
        contextUsed: {
          'moods': moods ?? [],
          'location': resolvedCity,
        },
        suggestedPlaces: suggestedPlaces,
      );
    } catch (e) {
      debugPrint('❌ Moody chat error: $e — using fallback');

      return AIChatResponse(
        success: true,
        action: 'chat',
        timestamp: MoodyClock.now().toIso8601String(),
        message: _getFallbackResponse(
          message,
          moods?.first ?? 'exploring',
          hasPriorExchanges: history.isNotEmpty,
          city: resolvedCity,
        ),
        conversationId: convId,
        contextUsed: {},
      );
    }
  }

  /// True when the message is only a short greeting (not e.g. "this" or "ship").
  static bool _isStandaloneGreeting(String trimmedLower) {
    final t = trimmedLower.replaceAll(RegExp(r'[\s\u200b]+'), ' ').trim();
    return RegExp(
      r'^(hi+|hey+|hello+|heya+|howdy+|yo+|sup+|hola+|hallo+)(\s*[!.?👋🙂😊]*)$',
      caseSensitive: false,
    ).hasMatch(t);
  }

  /// Fallback response when AI service is unavailable
  static String _getFallbackResponse(
    String userMessage,
    String mood, {
    required bool hasPriorExchanges,
    String? city,
  }) {
    final lowerMessage = userMessage.toLowerCase().trim();

    if (_isStandaloneGreeting(lowerMessage)) {
      if (hasPriorExchanges) {
        final place = (city != null && city.isNotEmpty) ? city : 'your area';
        return "Hey again! 👋 What kind of spots are you in the mood for in $place?";
      }
      return "Hey there! 👋 I'm Moody, your travel companion! I'm here to help you discover amazing places based on your ${mood} mood. What would you like to explore today?";
    }

    if (lowerMessage.contains('how are you') ||
        lowerMessage.contains('how r u') ||
        lowerMessage.contains('howre you')) {
      return "I'm feeling great and ready to plan something fun ✨ Want food, culture, or outdoors today?";
    }

    if (lowerMessage == 'moody' ||
        lowerMessage == 'moodyyy' ||
        lowerMessage == 'moodyyyy' ||
        lowerMessage.startsWith('moody ')) {
      final place = (city != null && city.isNotEmpty) ? city : 'your city';
      return "I'm here 🙌 Tell me one vibe for $place: cozy cafe, unique dinner, scenic walk, or hidden gems.";
    }

    if (lowerMessage.contains('help') ||
        lowerMessage.contains('what can you do')) {
      return "I can help you find activities, restaurants, and places that match your mood! Just tell me what you're feeling, and I'll suggest the perfect spots. 🎯";
    }

    if (lowerMessage.contains('food') ||
        lowerMessage.contains('eat') ||
        lowerMessage.contains('restaurant')) {
      return "Great choice! 🍽️ Based on your ${mood} mood, I'd recommend checking out some local favorites. Want me to find specific restaurants or cafes?";
    }

    if (lowerMessage.contains('activity') ||
        lowerMessage.contains('do') ||
        lowerMessage.contains('fun')) {
      return "Let's find something fun! 🎉 For your ${mood} vibe, I suggest exploring local attractions, parks, or cultural spots. What type of activity interests you?";
    }

    // Default response
    if (hasPriorExchanges) {
      return "Nice — tell me a bit more so I can narrow it down: budget, distance, and whether you want indoor or outdoor spots.";
    }
    return "I'm here to help you discover amazing places! 🌟 Tell me more about what you're looking for, and I'll suggest the perfect spots for your ${mood} mood.";
  }

  /// Submit feedback for AI recommendations
  static Future<void> submitRecommendationFeedback({
    required String recommendationId,
    required int rating,
    List<String>? selectedRecommendations,
    String? notes,
  }) async {
    debugPrint('📊 Submitting AI recommendation feedback: $rating/5');

    try {
      await _supabase.from('ai_recommendations').update({
        'user_feedback': rating,
        'user_selected': selectedRecommendations,
        'feedback_notes': notes,
      }).eq('id', recommendationId);

      debugPrint('✅ Feedback submitted successfully');
    } catch (e) {
      debugPrint('❌ Error submitting feedback: $e');
      rethrow;
    }
  }

  /// Get user's AI conversation history
  static Future<List<AIChatMessage>> getConversationHistory(
      String conversationId) async {
    debugPrint('📜 Loading conversation history: $conversationId');

    try {
      final response = await _supabase
          .from('ai_conversations')
          .select('role, content, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .limit(50); // Limit to last 50 messages to avoid token limits

      final messages = (response as List)
          .map((json) => AIChatMessage.fromJson(json))
          .toList();

      debugPrint(
          '✅ Loaded ${messages.length} conversation messages for context');
      return messages;
    } catch (e) {
      debugPrint('❌ Error loading conversation history: $e');
      // Return empty list instead of throwing - allows chat to continue without history
      return [];
    }
  }

  /// Update user preferences for better AI recommendations
  static Future<void> updateUserPreferences({
    int? budgetRange,
    List<String>? preferredTimeSlots,
    List<String>? favoriteMoods,
    List<String>? dietaryRestrictions,
    List<String>? mobilityRequirements,
    String? languagePreference,
  }) async {
    debugPrint('⚙️ Updating user AI preferences');

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};
      if (budgetRange != null) updateData['budget_range'] = budgetRange;
      if (preferredTimeSlots != null)
        updateData['preferred_time_slots'] = preferredTimeSlots;
      if (favoriteMoods != null) updateData['favorite_moods'] = favoriteMoods;
      if (dietaryRestrictions != null)
        updateData['dietary_restrictions'] = dietaryRestrictions;
      if (mobilityRequirements != null)
        updateData['mobility_requirements'] = mobilityRequirements;
      if (languagePreference != null)
        updateData['language_preference'] = languagePreference;

      await _supabase.from('user_preferences').upsert({
        'user_id': user.id,
        ...updateData,
      });

      debugPrint('✅ User preferences updated');
    } catch (e) {
      debugPrint('❌ Error updating user preferences: $e');
      rethrow;
    }
  }

  /// Log activity completion for AI learning
  static Future<void> logActivityCompletion({
    required String activityId,
    required String name,
    required String mood,
    required double latitude,
    required double longitude,
    double? rating,
    int? feedbackRating,
    String? feedbackNotes,
  }) async {
    debugPrint('📝 Logging activity completion: $name');

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('user_activity_history').insert({
        'user_id': user.id,
        'activity_id': activityId,
        'name': name,
        'mood': mood,
        'location_lat': latitude,
        'location_lng': longitude,
        'rating': rating,
        'feedback_rating': feedbackRating,
        'feedback_notes': feedbackNotes,
        'completed_at': MoodyClock.now().toIso8601String(),
      });

      debugPrint('✅ Activity completion logged');
    } catch (e) {
      debugPrint('❌ Error logging activity completion: $e');
      rethrow;
    }
  }

  /// Generate a unique conversation ID (new chat thread).
  static String _generateConversationId() {
    return 'conv_${MoodyClock.now().millisecondsSinceEpoch}_${_supabase.auth.currentUser?.id.substring(0, 8) ?? 'anon'}';
  }

  /// Public wrapper for starting a fresh Moody chat session.
  static String newChatConversationId() => _generateConversationId();

  /// Get or create a persistent conversation ID for the current user
  /// This ensures conversations persist across app sessions
  static Future<String> getOrCreateConversationId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return _generateConversationId();
      }

      // Try to get the most recent conversation ID for this user
      final response = await _supabase
          .from('ai_conversations')
          .select('conversation_id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['conversation_id'] != null) {
        final existingId = response['conversation_id'] as String;
        debugPrint('✅ Found existing conversation ID: $existingId');
        return existingId;
      }

      // No existing conversation, create a new one
      final newId =
          'conv_${user.id}_${MoodyClock.now().millisecondsSinceEpoch}';
      debugPrint('🆕 Created new conversation ID: $newId');
      return newId;
    } catch (e) {
      debugPrint('⚠️ Error getting conversation ID: $e');
      // Fallback to generating a new one
      return _generateConversationId();
    }
  }
}

// Removed custom debugPrint function - using Flutter's debugPrint from foundation.dart instead
