import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:wandermood/core/utils/moody_clock.dart';
import '../models/check_in.dart';

final checkInServiceProvider = Provider<CheckInService>((ref) {
  return CheckInService(Supabase.instance.client);
});

class CheckInService {
  final SupabaseClient _client;
  static const String _prefsKey = 'user_check_ins';

  CheckInService(this._client);

  /// Save a check-in to Supabase and local storage.
  /// Optionally creates a VisitedPlace on the globe if location data is provided.
  Future<void> saveCheckIn(
    CheckIn checkIn, {
    double? lat,
    double? lng,
    String? city,
    String? country,
    String? placeName,
  }) async {
    try {
      // Save to Supabase
      await _client.from('user_check_ins').insert({
        'id': checkIn.id,
        'user_id': checkIn.userId,
        'mood': checkIn.mood,
        'activities': checkIn.activities,
        'reactions': checkIn.reactions,
        'text': checkIn.text,
        'timestamp': checkIn.timestamp.toIso8601String(),
        'metadata': checkIn.extractKeyInfo(),
      });

      // If location is provided, add to Visited Places (Globe)
      if (lat != null && lng != null) {
        await _addToVisitedPlaces(
          checkIn,
          lat,
          lng,
          city: city,
          country: country,
          placeName: placeName,
        );
      } else {
        debugPrint('🌍 Skipping globe: No location data');
      }

      // Update streak locally and persist to Supabase so the profile screen
      // always reflects the real consecutive-day count (moods, check-ins, My Day).
      final streak = await getUnifiedEngagementStreak();
      await _updateStreakInLocalStorage(streak);
      await _updateStreakInSupabase(streak, checkIn.userId);

      debugPrint('✅ Check-in saved: ${checkIn.id}');
    } catch (e) {
      debugPrint('⚠️ Failed to save check-in: $e');
      // Continue to save locally as fallback
    }

    // Also save to local storage as backup
    await _saveToLocalStorage(checkIn);
  }

  Future<void> _addToVisitedPlaces(
    CheckIn checkIn,
    double lat,
    double lng, {
    String? city,
    String? country,
    String? placeName,
  }) async {
    try {
      // Map mood to emoji if possible (simple lookup or use what's in check-in if we had it)
      String? moodEmoji;
      // We could have a helper to get emoji from mood string, but for now let's leave it null
      // or try to find it in the check-in metadata if we stored it there.

      // Create note from check-in text or activities
      String note = checkIn.text ?? '';
      if (note.isEmpty && checkIn.activities.isNotEmpty) {
        note = 'Activities: ${checkIn.activities.join(", ")}';
      }

      final placeNameVal = placeName ?? city ?? 'Unknown Location';
      await _client.from('visited_places').insert({
        'user_id': checkIn.userId,
        'place_name': placeNameVal,
        'city': city,
        'country': country,
        'lat': lat,
        'lng': lng,
        'mood': checkIn.mood,
        'mood_emoji': moodEmoji,
        'notes': note.isNotEmpty ? note : null,
        'visited_at': checkIn.timestamp.toIso8601String(),
      });
      debugPrint('🌍 Added to globe: $placeNameVal ($city, $country) at $lat, $lng');
    } catch (e, st) {
      debugPrint('⚠️ Failed to add to globe: $e');
      debugPrint('Stack: $st');
    }
  }

  /// Get recent check-ins for the current user
  Future<List<CheckIn>> getRecentCheckIns({int limit = 10}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return await _loadFromLocalStorage();
      }

      final response = await _client
          .from('user_check_ins')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);

      if (response.isNotEmpty) {
        return response.map((json) => CheckIn.fromJson(json)).toList();
      }
    } catch (e) {
      print('⚠️ Failed to load check-ins from Supabase: $e');
    }

    // Fallback to local storage
    return await _loadFromLocalStorage();
  }

  /// Get check-in from yesterday (for morning greetings)
  Future<CheckIn?> getYesterdayCheckIn() async {
    final checkIns = await getRecentCheckIns(limit: 5);
    final now = MoodyClock.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    for (final checkIn in checkIns) {
      final checkInDate = DateTime(
        checkIn.timestamp.year,
        checkIn.timestamp.month,
        checkIn.timestamp.day,
      );
      if (checkInDate.year == yesterday.year &&
          checkInDate.month == yesterday.month &&
          checkInDate.day == yesterday.day) {
        return checkIn;
      }
    }
    return null;
  }

  /// Get the most recent check-in
  Future<CheckIn?> getLastCheckIn() async {
    final checkIns = await getRecentCheckIns(limit: 1);
    return checkIns.isNotEmpty ? checkIns.first : null;
  }

  static DateTime _dateOnlyLocal(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// Consecutive calendar days ending today or yesterday, given a set of
  /// local calendar dates that had any engagement.
  static int streakFromCalendarDaySet(Set<DateTime> days, DateTime nowLocal) {
    final today = _dateOnlyLocal(nowLocal);
    final yesterday = today.subtract(const Duration(days: 1));
    late DateTime cursor;
    if (days.contains(today)) {
      cursor = today;
    } else if (days.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Calculate check-in streak (consecutive days, check-ins only).
  Future<int> getCheckInStreak() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return await _getStreakFromLocalStorage();
      }

      final checkIns = await getRecentCheckIns(limit: 400);
      if (checkIns.isEmpty) return 0;

      final daySet = checkIns
          .map((c) => _dateOnlyLocal(c.timestamp.toLocal()))
          .toSet();
      return streakFromCalendarDaySet(daySet, MoodyClock.now());
    } catch (e) {
      print('⚠️ Error calculating streak: $e');
      return await _getStreakFromLocalStorage();
    }
  }

  /// Consecutive days with any of: Moody check-in, row in [moods], or
  /// [scheduled_activities] on that calendar day (My Day).
  Future<int> getUnifiedEngagementStreak() async {
    try {
      final userId = _client.auth.currentUser?.id;
      final now = MoodyClock.now();
      if (userId == null) {
        final local = await _loadFromLocalStorage();
        final daySet = local
            .map((c) => _dateOnlyLocal(c.timestamp.toLocal()))
            .toSet();
        return streakFromCalendarDaySet(daySet, now);
      }

      final daySet = <DateTime>{};

      final checkIns = await getRecentCheckIns(limit: 400);
      for (final c in checkIns) {
        daySet.add(_dateOnlyLocal(c.timestamp.toLocal()));
      }

      try {
        final moodRows = await _client
            .from('moods')
            .select('timestamp')
            .eq('user_id', userId)
            .order('timestamp', ascending: false)
            .limit(500);
        for (final row in moodRows as List<dynamic>) {
          final map = row as Map<String, dynamic>;
          final raw = map['timestamp'];
          if (raw == null) continue;
          final ts = DateTime.parse(raw as String).toLocal();
          daySet.add(_dateOnlyLocal(ts));
        }
      } catch (e) {
        debugPrint('⚠️ unified streak moods: $e');
      }

      try {
        final from = now.subtract(const Duration(days: 120));
        final fromIso =
            '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
        final sch = await _client
            .from('scheduled_activities')
            .select('scheduled_date')
            .eq('user_id', userId)
            .gte('scheduled_date', fromIso);
        for (final row in sch as List<dynamic>) {
          final map = row as Map<String, dynamic>;
          final s = map['scheduled_date'] as String?;
          if (s == null) continue;
          final parts = s.split('-');
          if (parts.length != 3) continue;
          daySet.add(DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          ));
        }
      } catch (e) {
        debugPrint('⚠️ unified streak schedule: $e');
      }

      return streakFromCalendarDaySet(daySet, now);
    } catch (e) {
      debugPrint('⚠️ Error unified streak: $e');
      return await _getStreakFromLocalStorage();
    }
  }

  /// Recompute unified streak and write [profiles.mood_streak] (+ local cache).
  Future<void> persistUnifiedStreakForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final streak = await getUnifiedEngagementStreak();
    await _updateStreakInLocalStorage(streak);
    await _updateStreakInSupabase(streak, userId);
  }

  Future<int> _getStreakFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('check_in_streak') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _updateStreakInLocalStorage(int streak) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('check_in_streak', streak);
    } catch (e) {
      print('⚠️ Error saving streak: $e');
    }
  }

  Future<void> _updateStreakInSupabase(int streak, String userId) async {
    try {
      await _client
          .from('profiles')
          .update({'mood_streak': streak})
          .eq('id', userId);
      debugPrint('✅ mood_streak updated to $streak in Supabase');
    } catch (e) {
      debugPrint('⚠️ Failed to update mood_streak in Supabase: $e');
    }
  }

  /// Save to local storage as fallback
  Future<void> _saveToLocalStorage(CheckIn checkIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checkIns = await _loadFromLocalStorage();
      checkIns.insert(0, checkIn); // Add to beginning

      // Keep only last 20 check-ins
      final limited = checkIns.take(20).toList();

      final jsonList = limited.map((c) => c.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(jsonList));

      print('✅ Check-in saved to local storage');
    } catch (e) {
      print('❌ Failed to save check-in to local storage: $e');
    }
  }

  /// Load from local storage
  Future<List<CheckIn>> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => CheckIn.fromJson(json)).toList();
    } catch (e) {
      print('❌ Failed to load check-ins from local storage: $e');
      return [];
    }
  }
}
