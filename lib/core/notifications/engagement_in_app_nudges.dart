import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/notifications/in_app_notification_copy.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/utils/nl_engagement_public_days.dart';

/// Contextual Moody rows in `realtime_events` (in-app bell). Rate-limited per day / per place.
class EngagementInAppNudges {
  EngagementInAppNudges._();

  static const _prefsHoliday = 'wm_eng_inapp_holiday_v1_';
  static const _prefsNoMood = 'wm_eng_inapp_no_mood_v1_';
  static const _prefsEmptyPlan = 'wm_eng_inapp_empty_plan_v1_';
  static const _prefsSavedPlace = 'wm_eng_saved_place_v1_';

  static String _dayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// One nudge max per cold start (priority: public day → no mood → empty plan).
  static Future<void> runAfterMainVisible({
    required String userId,
    required Locale locale,
    String? homeBase,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final client = Supabase.instance.client;
      final nl = locale.languageCode.toLowerCase().startsWith('nl');
      final now = MoodyClock.now();
      final dayKey = _dayKey(now);
      var sent = false;

      Future<void> sendRpc({
        required String event,
        required Map<String, dynamic> data,
      }) async {
        if (sent) return;
        final message =
            InAppNotificationCopy.moodyMessage(nl: nl, event: event, data: data);
        await client.rpc(
          'send_realtime_notification',
          params: {
            'target_user_id': userId,
            'event_type': 'moodySuggestion',
            'event_title': 'Moody',
            'event_message': message,
            'event_data': {'event': event, ...data},
            'source_user_id': userId,
            'related_post_id': null,
            'priority_level': 2,
          },
        );
        sent = true;
      }

      if (shouldOfferNlEngagementDays(
        languageCode: locale.languageCode,
        homeBaseLowercase: homeBase,
      )) {
        final public = nlEngagementPublicDayOn(now);
        if (public != null) {
          final pk = '$_prefsHoliday${public.id}_$dayKey';
          if (prefs.getBool(pk) != true) {
            try {
              await sendRpc(
                event: 'moody_holiday_greeting',
                data: {'holiday_id': public.id},
              );
              await prefs.setBool(pk, true);
            } catch (e, st) {
              if (kDebugMode) {
                debugPrint('EngagementInAppNudges holiday: $e\n$st');
              }
            }
          }
        }
      }

      if (sent) return;

      if (engagementPastNoMoodCutoffHour()) {
        final pk = '$_prefsNoMood$dayKey';
        if (prefs.getBool(pk) != true) {
          final hasMood = await _hasMoodToday(client, userId);
          if (!hasMood) {
            try {
              await sendRpc(event: 'moody_nudge_check_in', data: const {});
              await prefs.setBool(pk, true);
            } catch (e, st) {
              if (kDebugMode) {
                debugPrint('EngagementInAppNudges no mood: $e\n$st');
              }
            }
          }
        }
      }

      if (sent) return;

      if (engagementPastEmptyPlanCutoffHour()) {
        final pk = '$_prefsEmptyPlan$dayKey';
        if (prefs.getBool(pk) != true) {
          final hasPlan = await _hasScheduledToday(client, userId);
          if (!hasPlan) {
            try {
              await sendRpc(event: 'moody_nudge_plan_today', data: const {});
              await prefs.setBool(pk, true);
            } catch (e, st) {
              if (kDebugMode) {
                debugPrint('EngagementInAppNudges empty plan: $e\n$st');
              }
            }
          }
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('EngagementInAppNudges: $e\n$st');
      }
    }
  }

  static Future<bool> _hasMoodToday(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      final now = MoodyClock.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      final rows = await client
          .from('moods')
          .select('id')
          .eq('user_id', userId)
          .gte('timestamp', start.toUtc().toIso8601String())
          .lt('timestamp', end.toUtc().toIso8601String())
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> _hasScheduledToday(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      final now = MoodyClock.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final rows = await client
          .from('scheduled_activities')
          .select('id')
          .eq('user_id', userId)
          .eq('scheduled_date', dateStr)
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      // If RLS/schema differs, do not nudge.
      return true;
    }
  }

  /// Fires when a place is saved — at most once per [placeId] per 7 days.
  static Future<void> onPlaceSaved({
    required String userId,
    required String placeId,
    required String placeName,
  }) async {
    if (placeId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefsSavedPlace$placeId';
      final lastRaw = prefs.getString(key);
      if (lastRaw != null) {
        final last = DateTime.tryParse(lastRaw);
        if (last != null && MoodyClock.now().difference(last).inDays < 7) {
          return;
        }
      }
      final nl = PlatformDispatcher.instance.locale.languageCode
          .toLowerCase()
          .startsWith('nl');
      final message = InAppNotificationCopy.moodyMessage(
        nl: nl,
        event: 'moody_saved_place_interest',
        data: {'place_name': placeName, 'place_id': placeId},
      );
      await Supabase.instance.client.rpc(
        'send_realtime_notification',
        params: {
          'target_user_id': userId,
          'event_type': 'moodySuggestion',
          'event_title': 'Moody',
          'event_message': message,
          'event_data': {
            'event': 'moody_saved_place_interest',
            'place_id': placeId,
            'place_name': placeName,
          },
          'source_user_id': userId,
          'related_post_id': null,
          'priority_level': 2,
        },
      );
      await prefs.setString(key, MoodyClock.now().toIso8601String());
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('EngagementInAppNudges.onPlaceSaved: $e\n$st');
      }
    }
  }

  static const _prefsPostTrip = 'wm_inapp_post_trip_v1_';

  /// In-app bell row when every activity on [scheduledDateYyyyMmDd] is marked done (My Day).
  static Future<void> sendPostTripReflectionIfNeeded({
    required String userId,
    required String scheduledDateYyyyMmDd,
    required bool nl,
  }) async {
    if (userId.isEmpty || scheduledDateYyyyMmDd.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pk = '$_prefsPostTrip$scheduledDateYyyyMmDd';
      if (prefs.getBool(pk) == true) return;

      final message = InAppNotificationCopy.moodyMessage(
        nl: nl,
        event: 'moody_post_trip_reflection',
        data: {'day': scheduledDateYyyyMmDd},
      );
      await Supabase.instance.client.rpc(
        'send_realtime_notification',
        params: {
          'target_user_id': userId,
          'event_type': 'moodySuggestion',
          'event_title': 'Moody',
          'event_message': message,
          'event_data': {
            'event': 'moody_post_trip_reflection',
            'scheduled_date': scheduledDateYyyyMmDd,
          },
          'source_user_id': userId,
          'related_post_id': null,
          'priority_level': 2,
        },
      );
      await prefs.setBool(pk, true);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('EngagementInAppNudges.sendPostTripReflectionIfNeeded: $e\n$st');
      }
    }
  }
}
