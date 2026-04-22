import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

/// Updates [profiles.mood_streak] from [scheduled_activities]: any row on a
/// calendar day counts as engagement (planning counts — not only [is_confirmed]).
///
/// This runs after inserts and when marking activities done so the profile /
/// mood journey streak matches "I added something to My Day today".
class ProfileMoodStreakFromSchedule {
  ProfileMoodStreakFromSchedule._();

  static const String _prefsKey = 'mood_streak_last_update';

  static Future<void> syncAfterScheduleChange(SupabaseClient client) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final now = MoodyClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final todayIso =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final yesterdayIso =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString(_prefsKey);
    if (lastUpdate == todayIso) return;

    final todayRows = await client
        .from('scheduled_activities')
        .select('id')
        .eq('user_id', userId)
        .eq('scheduled_date', todayIso)
        .limit(1);

    if (todayRows.isEmpty) return;

    final yesterdayRows = await client
        .from('scheduled_activities')
        .select('id')
        .eq('user_id', userId)
        .eq('scheduled_date', yesterdayIso)
        .limit(1);

    final profile = await client
        .from('profiles')
        .select('mood_streak')
        .eq('id', userId)
        .maybeSingle();
    final currentStreak = (profile?['mood_streak'] as int?) ?? 0;

    final nextStreak = yesterdayRows.isNotEmpty
        ? (currentStreak > 0 ? currentStreak + 1 : 1)
        : 1;

    await client.from('profiles').update({
      'mood_streak': nextStreak,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    await prefs.setString(_prefsKey, todayIso);
  }
}
