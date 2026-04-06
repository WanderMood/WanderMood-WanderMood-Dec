import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:wandermood/features/places/models/place.dart';

/// Fire-and-forget calls to Supabase `update_taste_profile` for personalization.
/// Never awaited by callers; errors are swallowed (debug log only).
class TasteProfileService {
  TasteProfileService._();

  /// Morning: 5–12, afternoon: 12–17, else evening (aligned with scheduled activities).
  static String inferTimeSlotFromHour(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    return 'evening';
  }

  static List<String> typesFromActivityRaw(Map<String, dynamic> raw) {
    final tags = raw['tags'];
    if (tags is String && tags.isNotEmpty) {
      return tags
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    if (tags is List) {
      return tags
          .map((e) => e.toString().trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static void recordFromPlace(
    Place place, {
    required String interactionType,
    String? moodContext,
    String? timeSlot,
  }) {
    unawaited(_invoke(
      placeId: place.id,
      placeName: place.name,
      placeTypes: List<String>.from(place.types),
      priceLevel: place.priceLevel,
      interactionType: interactionType,
      moodContext: moodContext,
      timeSlot: timeSlot,
    ));
  }

  /// My Day / scheduled row map (Supabase-shaped or in-memory activity).
  static void recordFromActivityRaw(
    Map<String, dynamic> raw, {
    required String interactionType,
    String? moodContext,
    String? timeSlot,
  }) {
    final placeId = raw['placeId'] as String? ?? raw['place_id'] as String?;
    if (placeId == null || placeId.isEmpty) return;
    final name = raw['title'] as String? ??
        raw['name'] as String? ??
        raw['placeName'] as String? ??
        '';
    final types = typesFromActivityRaw(raw);
    int? priceLevel;
    final pl = raw['priceLevel'] ?? raw['price_level'];
    if (pl is int) {
      priceLevel = pl;
    } else if (pl is num) {
      priceLevel = pl.toInt();
    }

    unawaited(_invoke(
      placeId: placeId,
      placeName: name,
      placeTypes: types,
      priceLevel: priceLevel,
      interactionType: interactionType,
      moodContext: moodContext,
      timeSlot: timeSlot,
    ));
  }

  static void recordFromActivityRating(ActivityRating rating) {
    final pid = rating.googlePlaceId;
    if (pid == null || pid.isEmpty) return;
    if (rating.stars < 1) return;
    final String interaction;
    if (rating.stars >= 4) {
      interaction = 'rated_positive';
    } else if (rating.stars <= 2) {
      interaction = 'rated_negative';
    } else {
      return;
    }
    unawaited(_invoke(
      placeId: pid,
      placeName: rating.activityName,
      placeTypes: const [],
      priceLevel: null,
      interactionType: interaction,
      moodContext: rating.mood.isNotEmpty ? rating.mood : null,
      timeSlot: inferTimeSlotFromHour(MoodyClock.now().hour),
    ));
  }

  static Future<void> _invoke({
    required String placeId,
    required String placeName,
    required List<String> placeTypes,
    required int? priceLevel,
    required String interactionType,
    String? moodContext,
    String? timeSlot,
  }) async {
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;

      var mood = moodContext;
      var slot = timeSlot;
      final prefs = await SharedPreferences.getInstance();
      mood ??= prefs.getString('current_mood');
      slot ??= inferTimeSlotFromHour(MoodyClock.now().hour);

      await client.rpc(
        'update_taste_profile',
        params: {
          'p_user_id': uid,
          'p_place_id': placeId,
          'p_place_name': placeName,
          'p_place_types': placeTypes,
          'p_price_level': priceLevel,
          'p_interaction_type': interactionType,
          'p_mood_context': mood,
          'p_time_slot': slot,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('update_taste_profile (ignored): $e');
      }
    }
  }
}
