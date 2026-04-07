import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/utils/weather_condition_emoji.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'notification_category.dart';
import 'notification_copy.dart';
import 'notification_copy_provider.dart';
import 'notification_navigation.dart';

/// Resolves the 09:00 daily notification: plan reminder, mood check-in, or skip.
///
/// Repeating OS notifications keep fixed copy until the next [rescheduleAll];
/// we target the calendar date of the **next** 09:00 fire so copy matches the
/// first upcoming occurrence as closely as possible.
class MorningDailyNotificationResolver {
  MorningDailyNotificationResolver._();

  static DateTime _nextNineAmLocal() {
    final now = MoodyClock.now();
    var next = DateTime(now.year, now.month, now.day, 9, 0);
    if (!now.isBefore(next)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  static DateTime _calendarDayOfNextNineAm() {
    final next = _nextNineAmLocal();
    return DateTime(next.year, next.month, next.day);
  }

  static bool _hasMoodLoggedForDay(SharedPreferences prefs, DateTime day) {
    final raw = prefs.getString('last_mood_selection');
    if (raw == null || raw.isEmpty) return false;
    final d = DateTime.tryParse(raw);
    if (d == null) return false;
    return d.year == day.year && d.month == day.month && d.day == day.day;
  }

  static Future<bool> _hasScheduledActivitiesForDay(
    SupabaseClient client,
    String userId,
    String dateStr,
  ) async {
    try {
      final row = await client
          .from('scheduled_activities')
          .select('id')
          .eq('user_id', userId)
          .eq('scheduled_date', dateStr)
          .limit(1)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _firstActivityNameForDay(
    SupabaseClient client,
    String userId,
    String dateStr,
  ) async {
    try {
      final row = await client
          .from('scheduled_activities')
          .select('name')
          .eq('user_id', userId)
          .eq('scheduled_date', dateStr)
          .order('start_time', ascending: true)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      final name = row['name'] as String?;
      if (name == null || name.trim().isEmpty) return null;
      return name.trim();
    } catch (_) {
      return null;
    }
  }

  /// Returns null when the 09:00 slot should not be scheduled.
  static Future<NotificationCopy?> resolve({
    required NotificationCopyProvider copyProvider,
    required CommunicationStyle style,
    required SharedPreferences prefs,
    required AppLocalizations l10n,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final targetDay = _calendarDayOfNextNineAm();
    final dateStr =
        '${targetDay.year}-${targetDay.month.toString().padLeft(2, '0')}-${targetDay.day.toString().padLeft(2, '0')}';

    final hasPlan =
        await _hasScheduledActivitiesForDay(Supabase.instance.client, user.id, dateStr);
    final hasMood = _hasMoodLoggedForDay(prefs, targetDay);

    if (hasPlan) {
      final activityName = await _firstActivityNameForDay(
            Supabase.instance.client,
            user.id,
            dateStr,
          ) ??
          l10n.notifMorningWithPlanFallbackActivity;
      final emoji = readStoredWeatherEmoji(prefs);
      final copy = copyProvider.morningWithPlanCopy(
        style,
        l10n,
        weatherEmoji: emoji,
        activityName: activityName,
      );
      return copy.withPayload(NotificationNavPayload.mainMyDay);
    }

    if (hasMood) {
      return null;
    }

    return copyProvider.nextCopy(
      NotificationCategory.dailyMoodCheckIn,
      style,
      prefs,
      l10n,
    );
  }
}
