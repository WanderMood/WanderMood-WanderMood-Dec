import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/mood/data/repositories/supabase_mood_repository.dart';
import 'package:wandermood/features/mood/domain/models/activity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/mood_data.dart';
import 'package:wandermood/core/providers/notification_provider.dart';

part 'mood_service.g.dart';

// Provider voor MoodRepository
final moodRepositoryProvider = Provider<SupabaseMoodRepository>((ref) {
  return SupabaseMoodRepository(Supabase.instance.client);
});

// State voor de huidige geselecteerde stemming
final selectedMoodProvider = StateProvider<MoodData?>((ref) => null);

// Provider voor de lijst van stemmingen van de gebruiker
final userMoodsProvider = FutureProvider.family<List<MoodData>, String>((ref, userId) async {
  final moodService = ref.watch(moodServiceProvider.notifier);
  // Full journey for history screen (not the old default of 10 rows).
  return moodService.getMoodHistory(limit: 500);
});

// Provider voor de laatste stemming van de gebruiker
final latestMoodProvider = FutureProvider.family<MoodData?, String>((ref, userId) async {
  final moodService = ref.watch(moodServiceProvider.notifier);
  return moodService.getCurrentMood();
});

@riverpod
class MoodService extends _$MoodService {
  late final SupabaseMoodRepository _repository;
  final _client = Supabase.instance.client;

  @override
  FutureOr<List<MoodData>> build() async {
    _repository = ref.watch(moodRepositoryProvider);
    return getMoodHistory();
  }

  Future<MoodData?> getCurrentMood() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final response = await _client
          .from('moods')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return MoodData.fromJson(response);
    } catch (e) {
      print('Error getting current mood: $e');
      return null;
    }
  }

  Future<List<MoodData>> getMoodHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 120,
  }) async {
    try {
      var query = _client
          .from('moods')
          .select()
          .eq('user_id', _client.auth.currentUser!.id);

      if (startDate != null) {
        query = query.gt('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lt('timestamp', endDate.toIso8601String());
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List).map((item) => MoodData.fromJson(item)).toList();
    } catch (e) {
      print('Error getting mood history: $e');
      return [];
    }
  }

  Future<void> saveMoodData(MoodData mood) async {
    try {
      await _client.from('moods').insert(mood.toJson());
      ref.invalidateSelf();
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        ref.invalidate(userMoodsProvider(uid));
      }
      // Schedule mood follow-up notification 4 h after mood is logged.
      try {
        await ref
            .read(notificationTriggersProvider)
            .onMoodLogged(mood.moodType);
      } catch (_) {}
    } catch (e) {
      print('Error saving mood: $e');
      rethrow;
    }
  }

  Future<void> updateMoodData(MoodData mood) async {
    try {
      await _client
          .from('moods')
          .update(mood.toJson())
          .eq('id', mood.id)
          .eq('user_id', mood.userId);
      ref.invalidateSelf();
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        ref.invalidate(userMoodsProvider(uid));
      }
    } catch (e) {
      print('Error updating mood: $e');
      rethrow;
    }
  }

  Future<void> deleteMoodData(String moodId) async {
    try {
      await _client
          .from('moods')
          .delete()
          .eq('id', moodId)
          .eq('user_id', _client.auth.currentUser!.id);
      ref.invalidateSelf();
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        ref.invalidate(userMoodsProvider(uid));
      }
    } catch (e) {
      print('Error deleting mood: $e');
      rethrow;
    }
  }

  MoodAnalytics getMoodAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // TODO: Implementeer mood analytics berekening
    return MoodAnalytics(
      averageMood: 7.5,
      totalEntries: 10,
      moodTypes: {
        'Blij': 5,
        'Energiek': 3,
        'Rustig': 2,
      },
    );
  }

  Future<List<MoodData>> getMoods({DateTime? startDate, DateTime? endDate}) async {
    return getMoodHistory(startDate: startDate, endDate: endDate);
  }

  Future<MoodData> saveMood(MoodData mood) async {
    final result = await _repository.saveMood(mood);
    ref.invalidateSelf();
    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      ref.invalidate(userMoodsProvider(uid));
    }
    // Schedule mood follow-up notification 4 h after mood is logged.
    try {
      await ref
          .read(notificationTriggersProvider)
          .onMoodLogged(mood.moodType);
    } catch (_) {}
    return result;
  }

  Future<void> deleteMood(String moodId) async {
    await _repository.deleteMood(moodId);
    ref.invalidateSelf();
    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      ref.invalidate(userMoodsProvider(uid));
    }
  }

  Future<List<Activity>> getActivities() async {
    return _repository.getActivities();
  }

  Future<Activity> createActivity(Activity activity) async {
    return _repository.createActivity(activity);
  }

  Future<void> updateActivity(Activity activity) async {
    await _repository.updateActivity(activity);
  }

  Future<void> deleteActivity(String activityId) async {
    await _repository.deleteActivity(activityId);
  }

  Future<Map<String, dynamic>> getMoodStats() async {
    return _repository.getMoodStats();
  }

  Stream<List<MoodData>> watchMoods() {
    return _repository.watchMoods();
  }
}

class MoodAnalytics {
  final double averageMood;
  final int totalEntries;
  final Map<String, int> moodTypes;

  MoodAnalytics({
    required this.averageMood,
    required this.totalEntries,
    required this.moodTypes,
  });
} 