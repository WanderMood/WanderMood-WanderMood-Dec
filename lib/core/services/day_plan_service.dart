import 'package:flutter/foundation.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:uuid/uuid.dart';
import '../models/day_plan.dart';
import '../models/activity.dart';
import '../models/place.dart';
import '../models/weather.dart';
import 'optimized_places_service.dart';

class DayPlanService {
  static final DayPlanService _instance = DayPlanService._internal();
  final OptimizedPlacesService _placesService = OptimizedPlacesService();
  final _uuid = const Uuid();

  // Time slot default durations in minutes
  static const Map<TimeSlot, int> _defaultDurations = {
    TimeSlot.morning: 120,    // 2 hours
    TimeSlot.afternoon: 180,  // 3 hours
    TimeSlot.evening: 150,    // 2.5 hours
    TimeSlot.night: 90,       // 1.5 hours
  };

  // Default start times for each slot
  static final Map<TimeSlot, (int, int)> _defaultStartTimes = {
    TimeSlot.morning: (9, 0),     // 9:00 AM
    TimeSlot.afternoon: (14, 0),  // 2:00 PM
    TimeSlot.evening: (19, 0),    // 7:00 PM
    TimeSlot.night: (22, 0),      // 10:00 PM
  };

  DayPlanService._internal();

  factory DayPlanService() {
    return _instance;
  }

  Future<DayPlan> generateDayPlan({
    required List<String> moods,
    required LatLng location,
    required DateTime date,
    Weather? weather,
  }) async {
    try {
      final activities = <Activity>[];

      // Generate activities for each time slot
      for (final slot in TimeSlot.values) {
        final places = await _placesService.fetchPlaces(
          moods: moods,
          userLocation: location,
          timeSlot: slot.toString().split('.').last,
          weather: weather,
        );

        if (places.isNotEmpty) {
          final startTime = _getDefaultStartTime(date, slot);
          final activity = Activity(
            id: _uuid.v4(),
            place: places.first,
            startTime: startTime,
            duration: Duration(minutes: _defaultDurations[slot]!),
            timeSlot: slot,
            tags: [...places.first.tags, ...moods],
            moodScore: _calculateMoodScore(places.first, moods),
          );
          activities.add(activity);
        }
      }

      // Create and return the day plan
      return DayPlan(
        id: _uuid.v4(),
        date: date,
        activities: activities,
        moods: moods,
        overallMoodScore: _calculateOverallMoodScore(activities),
        weatherData: weather?.toJson(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error generating day plan: $e');
      rethrow;
    }
  }

  DateTime _getDefaultStartTime(DateTime date, TimeSlot slot) {
    final (hour, minute) = _defaultStartTimes[slot]!;
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  double _calculateMoodScore(Place place, List<String> moods) {
    // Simple scoring based on matching tags and types
    var score = 0.0;
    final keywords = moods.expand((mood) => _getMoodKeywords(mood)).toSet();
    
    // Check place tags
    score += place.tags.where((tag) => 
      keywords.any((keyword) => tag.toLowerCase().contains(keyword.toLowerCase()))
    ).length * 0.2;

    // Check place types
    score += place.types.where((type) =>
      keywords.any((keyword) => type.toLowerCase().contains(keyword.toLowerCase()))
    ).length * 0.15;

    // Add rating contribution
    if (place.rating != null) {
      score += (place.rating! / 5.0) * 0.3;
    }

    // Normalize to 0-1 range
    return score.clamp(0.0, 1.0);
  }

  double _calculateOverallMoodScore(List<Activity> activities) {
    if (activities.isEmpty) return 0.0;
    
    final scores = activities
        .map((a) => a.moodScore ?? 0.0)
        .toList();
    
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  Set<String> _getMoodKeywords(String mood) {
    switch (mood.toLowerCase()) {
      case 'relaxed':
        return {'relaxing', 'peaceful', 'quiet', 'calm', 'serene'};
      case 'energetic':
        return {'active', 'energetic', 'fitness', 'sports', 'dynamic'};
      case 'romantic':
        return {'romantic', 'intimate', 'cozy', 'charming', 'elegant'};
      case 'creative':
        return {'creative', 'artistic', 'inspiring', 'innovative', 'cultural'};
      case 'foody':
        return {'food', 'cuisine', 'gourmet', 'dining', 'culinary'};
      case 'cultural':
        return {'cultural', 'historic', 'traditional', 'authentic', 'heritage'};
      case 'adventurous':
        return {'adventure', 'exciting', 'outdoor', 'thrilling', 'exploration'};
      default:
        return {'popular', 'recommended', 'favorite'};
    }
  }

  Future<DayPlan> refreshActivity({
    required DayPlan plan,
    required String activityId,
    required LatLng location,
    Weather? weather,
  }) async {
    try {
      // Find the activity to refresh
      final activityIndex = plan.activities.indexWhere((a) => a.id == activityId);
      if (activityIndex == -1) throw Exception('Activity not found');

      final oldActivity = plan.activities[activityIndex];

      // Fetch new places
      final places = await _placesService.fetchPlaces(
        moods: plan.moods,
        userLocation: location,
        timeSlot: oldActivity.timeSlot.toString().split('.').last,
        weather: weather,
      );

      if (places.isEmpty) throw Exception('No alternative places found');

      // Create new activity with the same timing
      final newActivity = Activity(
        id: _uuid.v4(),
        place: places.first,
        startTime: oldActivity.startTime,
        duration: oldActivity.duration,
        timeSlot: oldActivity.timeSlot,
        tags: [...places.first.tags, ...plan.moods],
        moodScore: _calculateMoodScore(places.first, plan.moods),
      );

      // Update the plan
      final newActivities = List<Activity>.from(plan.activities);
      newActivities[activityIndex] = newActivity;

      return plan.copyWith(
        activities: newActivities,
        overallMoodScore: _calculateOverallMoodScore(newActivities),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error refreshing activity: $e');
      rethrow;
    }
  }
} 