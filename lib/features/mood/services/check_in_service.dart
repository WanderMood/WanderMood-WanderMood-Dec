import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

      // Update streak
      final streak = await getCheckInStreak();
      await _updateStreakInLocalStorage(streak);

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
    final now = DateTime.now();
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

  /// Calculate check-in streak (consecutive days)
  Future<int> getCheckInStreak() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return await _getStreakFromLocalStorage();
      }

      final checkIns = await getRecentCheckIns(limit: 30);
      if (checkIns.isEmpty) return 0;

      // Sort by date (most recent first)
      checkIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      int streak = 0;
      DateTime expectedDate = DateTime.now();

      // Check if there's a check-in today
      final today =
          DateTime(expectedDate.year, expectedDate.month, expectedDate.day);
      final firstCheckInDate = DateTime(
        checkIns.first.timestamp.year,
        checkIns.first.timestamp.month,
        checkIns.first.timestamp.day,
      );

      // If first check-in is not today, start from yesterday
      if (firstCheckInDate.year != today.year ||
          firstCheckInDate.month != today.month ||
          firstCheckInDate.day != today.day) {
        expectedDate = today.subtract(const Duration(days: 1));
      }

      for (final checkIn in checkIns) {
        final checkInDate = DateTime(
          checkIn.timestamp.year,
          checkIn.timestamp.month,
          checkIn.timestamp.day,
        );
        final expectedDateOnly = DateTime(
          expectedDate.year,
          expectedDate.month,
          expectedDate.day,
        );

        if (checkInDate.year == expectedDateOnly.year &&
            checkInDate.month == expectedDateOnly.month &&
            checkInDate.day == expectedDateOnly.day) {
          streak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else if (checkInDate.isBefore(expectedDateOnly)) {
          // Gap in streak
          break;
        }
      }

      return streak;
    } catch (e) {
      print('⚠️ Error calculating streak: $e');
      return await _getStreakFromLocalStorage();
    }
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
