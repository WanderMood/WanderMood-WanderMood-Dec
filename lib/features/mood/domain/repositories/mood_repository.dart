import 'package:wandermood/features/mood/domain/models/activity.dart';
import 'package:wandermood/features/mood/domain/models/mood_data.dart';

abstract class MoodRepository {
  /// Haalt alle stemmingen op voor een specifieke gebruiker
  Future<List<MoodData>> getMoods(String userId, {DateTime? startDate, DateTime? endDate});
  
  /// Haalt een specifieke stemming op op basis van ID
  Future<MoodData?> getMood(String moodId);
  
  /// Slaat een nieuwe stemming op
  Future<MoodData> saveMood(MoodData mood);
  
  /// Verwijdert een stemming
  Future<void> deleteMood(String moodId);
  
  /// Haalt de meest recente stemming op voor een gebruiker
  Future<MoodData?> getLatestMood(String userId);
  
  /// Haalt stemmingen op voor een specifieke periode
  Future<List<MoodData>> getMoodsForPeriod(String userId, DateTime start, DateTime end);
  
  Future<List<Activity>> getActivities();
  Future<Activity> createActivity(Activity activity);
  Future<void> updateActivity(Activity activity);
  Future<void> deleteActivity(String activityId);
  Future<List<String>> getMostUsedActivities({int limit = 5});
  Future<Map<String, dynamic>> getMoodStats({DateTime? startDate, DateTime? endDate});
  Stream<List<MoodData>> watchMoods();
} 