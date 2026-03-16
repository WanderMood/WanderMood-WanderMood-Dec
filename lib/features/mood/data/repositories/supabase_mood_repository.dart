import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/mood/domain/models/activity.dart';
import 'package:wandermood/features/mood/domain/models/mood_data.dart';
import 'package:wandermood/features/mood/domain/repositories/mood_repository.dart';

class SupabaseMoodRepository implements MoodRepository {
  final SupabaseClient _client;

  SupabaseMoodRepository(this._client);

  @override
  Future<List<MoodData>> getMoods(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = _client.from('moods').select().eq('user_id', userId);
      
      if (startDate != null) {
        query = query.gt('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lt('timestamp', endDate.toIso8601String());
      }

      final response = await query.order('timestamp', ascending: false);
      return (response as List).map((item) => MoodData.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting moods: $e');
      return [];
    }
  }

  @override
  Future<MoodData?> getLatestMood(String userId) async {
    final response = await _client
        .from('moods')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response != null ? MoodData.fromJson(response) : null;
  }

  @override
  Future<MoodData> saveMood(MoodData mood) async {
    try {
      final response = await _client.from('moods').insert(mood.toJson()).select().single();
      return MoodData.fromJson(response);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving mood: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMood(String moodId) async {
    try {
      await _client.from('moods').delete().eq('id', moodId);
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting mood: $e');
      rethrow;
    }
  }

  @override
  Future<List<Activity>> getActivities() async {
    try {
      final response = await _client.from('activities').select();
      return (response as List).map((item) => Activity.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting activities: $e');
      return [];
    }
  }

  @override
  Future<Activity> createActivity(Activity activity) async {
    try {
      final response = await _client.from('activities').insert(activity.toJson()).select().single();
      return Activity.fromJson(response);
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating activity: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateActivity(Activity activity) async {
    try {
      await _client.from('activities').update(activity.toJson()).eq('id', activity.id);
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating activity: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    try {
      await _client.from('activities').delete().eq('id', activityId);
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting activity: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getMostUsedActivities({int limit = 5}) async {
    final response = await _client
        .rpc('get_most_used_activities', params: {'limit': limit});

    return (response as List).map((json) => json['name'] as String).toList();
  }

  @override
  Future<Map<String, dynamic>> getMoodStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await _client.rpc(
        'get_mood_stats',
        params: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting mood stats: $e');
      return {};
    }
  }

  @override
  Stream<List<MoodData>> watchMoods() {
    return _client
        .from('moods')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((item) => MoodData.fromJson(item)).toList());
  }

  @override
  Future<MoodData?> getMood(String moodId) async {
    try {
      final response = await _client
          .from('moods')
          .select()
          .eq('id', moodId)
          .single();
      
      if (response == null) return null;
      return MoodData.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get mood: $e');
    }
  }

  @override
  Future<List<MoodData>> getMoodsForPeriod(String userId, DateTime start, DateTime end) async {
    try {
      final response = await _client
          .from('moods')
          .select()
          .eq('user_id', userId)
          .filter('created_at', 'gt', start.toIso8601String())
          .filter('created_at', 'lt', end.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List).map((json) => MoodData.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get moods for period: $e');
    }
  }
} 