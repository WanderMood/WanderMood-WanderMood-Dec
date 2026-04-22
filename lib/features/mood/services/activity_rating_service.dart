import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/services/taste_profile_service.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import '../models/activity_rating.dart';

final activityRatingServiceProvider = Provider<ActivityRatingService>((ref) {
  return ActivityRatingService(Supabase.instance.client);
});

/// Watch the current user's rating for a specific activity.
final activityRatingForActivityProvider =
    FutureProvider.family<ActivityRating?, String>((ref, activityId) async {
  final service = ref.watch(activityRatingServiceProvider);
  return service.getRatingForActivity(activityId);
});

class ActivityRatingService {
  final SupabaseClient _client;

  ActivityRatingService(this._client);

  /// Save an activity rating
  Future<void> saveRating(ActivityRating rating) async {
    try {
      await _client.from('activity_ratings').upsert(
        rating.toJson(),
        onConflict: 'user_id,activity_id',
      );
      print('✅ Activity rating saved: ${rating.activityName} - ${rating.stars} stars');
      TasteProfileService.recordFromActivityRating(rating);

      // Update user patterns after each rating
      await _updateUserPatterns(rating.userId);
      await _mergeRatingIntoLocalCache(rating);
    } catch (e) {
      print('⚠️ Failed to save activity rating: $e');
      // Fallback to local storage
      await _mergeRatingIntoLocalCache(rating);
      TasteProfileService.recordFromActivityRating(rating);
    }
  }


  /// Get ratings for a specific activity
  Future<ActivityRating?> getRatingForActivity(String activityId) async {
    if (activityId.isEmpty) return null;
    final userId = _client.auth.currentUser?.id;

    if (userId != null) {
      try {
        final response = await _client
            .from('activity_ratings')
            .select()
            .eq('user_id', userId)
            .eq('activity_id', activityId)
            .maybeSingle();

        if (response != null) {
          return ActivityRating.fromJson(Map<String, dynamic>.from(response));
        }
      } catch (e) {
        print('⚠️ Failed to get activity rating: $e');
      }
    }

    final local = await _loadRatingsLocally();
    for (final r in local) {
      if (r.activityId == activityId && (userId == null || r.userId == userId)) {
        return r;
      }
    }
    return null;
  }

  /// Get recent ratings for user
  Future<List<ActivityRating>> getRecentRatings({int limit = 20}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('activity_ratings')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(limit);

      return response.map((json) => ActivityRating.fromJson(json)).toList();
    } catch (e) {
      print('⚠️ Failed to get recent ratings: $e');
      return [];
    }
  }

  /// Get top-rated activities
  Future<List<ActivityRating>> getTopRated({int limit = 5}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('activity_ratings')
          .select()
          .eq('user_id', userId)
          .gte('stars', 4) // 4 or 5 stars
          .order('stars', ascending: false)
          .order('completed_at', ascending: false)
          .limit(limit);

      return response.map((json) => ActivityRating.fromJson(json)).toList();
    } catch (e) {
      print('⚠️ Failed to get top rated: $e');
      return [];
    }
  }

  /// Get ratings by mood
  Future<List<ActivityRating>> getRatingsByMood(String mood) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('activity_ratings')
          .select()
          .eq('user_id', userId)
          .eq('mood', mood)
          .order('completed_at', ascending: false);

      return response.map((json) => ActivityRating.fromJson(json)).toList();
    } catch (e) {
      print('⚠️ Failed to get ratings by mood: $e');
      return [];
    }
  }

  /// Calculate average rating for an activity type
  Future<double> getAverageRatingForActivityType(String activityType) async {
    try {
      final ratings = await getRecentRatings();
      final matchingRatings = ratings
          .where((r) => r.activityName.toLowerCase().contains(activityType.toLowerCase()))
          .toList();
      
      if (matchingRatings.isEmpty) return 0.0;
      
      final sum = matchingRatings.fold<int>(0, (sum, r) => sum + r.stars);
      return sum / matchingRatings.length;
    } catch (e) {
      return 0.0;
    }
  }

  /// Update user preference patterns based on ratings
  Future<void> _updateUserPatterns(String userId) async {
    try {
      final ratings = await getRecentRatings(limit: 50);
      if (ratings.isEmpty) return;

      // Calculate mood-activity scores
      final moodActivityScores = <String, double>{};
      final moodActivityCounts = <String, int>{};
      
      for (final rating in ratings) {
        final key = '${rating.mood}_${rating.activityName}';
        moodActivityScores[key] = (moodActivityScores[key] ?? 0.0) + rating.sentimentScore;
        moodActivityCounts[key] = (moodActivityCounts[key] ?? 0) + 1;
      }

      // Average the scores
      moodActivityScores.forEach((key, value) {
        moodActivityScores[key] = value / moodActivityCounts[key]!;
      });

      // Count tags
      final tagCounts = <String, int>{};
      for (final rating in ratings) {
        for (final tag in rating.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      // Get top rated items
      final topRated = ratings.where((r) => r.stars >= 4).take(10).toList();
      final topPlaces = topRated
          .where((r) => r.placeName != null)
          .map((r) => r.placeName!)
          .toSet()
          .toList();
      final topActivities = topRated
          .map((r) => r.activityName)
          .toSet()
          .toList();

      // Time preferences (mock for now - would need actual time data)
      final timePreferences = <String, double>{
        'morning': 0.6,
        'afternoon': 0.7,
        'evening': 0.8,
      };

      final pattern = UserPreferencePattern(
        userId: userId,
        moodActivityScores: moodActivityScores,
        tagCounts: tagCounts,
        timePreferences: timePreferences,
        topRatedPlaces: topPlaces,
        topRatedActivities: topActivities,
        lastUpdated: MoodyClock.now(),
      );

      // Save pattern to database
      await _client.from('user_preference_patterns').upsert({
        ...pattern.toJson(),
        'id': userId, // Use userId as primary key
      });

      print('✅ User patterns updated');
    } catch (e) {
      print('⚠️ Failed to update user patterns: $e');
    }
  }

  /// Get user preference patterns
  Future<UserPreferencePattern?> getUserPatterns(String userId) async {
    try {
      final response = await _client
          .from('user_preference_patterns')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return UserPreferencePattern.fromJson(response);
      }
    } catch (e) {
      print('⚠️ Failed to get user patterns: $e');
    }
    return null;
  }

  /// Generate weekly reflection
  Future<WeeklyReflection?> generateWeeklyReflection(String userId) async {
    try {
      final now = MoodyClock.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Get all ratings from this week
      final allRatings = await getRecentRatings(limit: 100);
      final weekRatings = allRatings
          .where((r) => r.completedAt.isAfter(weekStart) && r.completedAt.isBefore(weekEnd))
          .toList();

      if (weekRatings.isEmpty) return null;

      // Calculate mood distribution
      final moodDistribution = <String, int>{};
      for (final rating in weekRatings) {
        moodDistribution[rating.mood] = (moodDistribution[rating.mood] ?? 0) + 1;
      }

      // Get top and low rated
      final sorted = weekRatings..sort((a, b) => b.stars.compareTo(a.stars));
      final topRated = sorted.take(3).toList();
      final lowRated = sorted.where((r) => r.stars <= 3).take(3).toList();

      // Determine dominant mood
      final dominantMood = moodDistribution.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // Calculate achievements
      final achievements = <String>[];
      if (weekRatings.length >= 5) achievements.add('Completed ${weekRatings.length} activities! 🎉');
      final newPlaces = weekRatings.where((r) => r.placeName != null).length;
      if (newPlaces >= 3) achievements.add('Tried $newPlaces new places! 🗺️');
      final highRated = weekRatings.where((r) => r.stars >= 4).length;
      if (highRated >= 3) achievements.add('Loved $highRated experiences! ❤️');

      final reflection = WeeklyReflection(
        id: 'weekly_${userId}_${weekStart.millisecondsSinceEpoch}',
        userId: userId,
        weekStart: weekStart,
        weekEnd: weekEnd,
        activitiesCompleted: weekRatings.length,
        newPlacesTried: newPlaces,
        moodDistribution: moodDistribution,
        topRated: topRated,
        lowRated: lowRated,
        dominantMood: dominantMood,
        achievements: achievements,
        insights: {
          'most_loved_tag': _getMostLovedTag(weekRatings),
          'improvement_areas': _getImprovementAreas(weekRatings),
        },
      );

      // Save to database
      await _client.from('weekly_reflections').upsert(reflection.toJson());

      return reflection;
    } catch (e) {
      print('⚠️ Failed to generate weekly reflection: $e');
      return null;
    }
  }

  String _getMostLovedTag(List<ActivityRating> ratings) {
    final tagCounts = <String, int>{};
    final highRated = ratings.where((r) => r.stars >= 4);
    
    for (final rating in highRated) {
      for (final tag in rating.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    if (tagCounts.isEmpty) return 'The vibe';
    
    return tagCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<String> _getImprovementAreas(List<ActivityRating> ratings) {
    final areas = <String>[];
    final lowRated = ratings.where((r) => r.stars <= 2);
    
    if (lowRated.length >= 2) {
      areas.add('Consider trying different types of activities');
    }
    
    return areas;
  }

  /// Keeps one row per (user_id, activity_id) in SharedPreferences for offline reads.
  Future<void> _mergeRatingIntoLocalCache(ActivityRating rating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratings = await _loadRatingsLocally();
      final filtered = ratings
          .where((r) =>
              !(r.userId == rating.userId && r.activityId == rating.activityId))
          .toList();
      filtered.insert(0, rating);
      final limited = filtered.take(50).toList();
      await prefs.setString(
        'activity_ratings',
        jsonEncode(limited.map((r) => r.toJson()).toList()),
      );
    } catch (e) {
      print('❌ Failed to merge rating into local cache: $e');
    }
  }

  Future<List<ActivityRating>> _loadRatingsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('activity_ratings');
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => ActivityRating.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}

