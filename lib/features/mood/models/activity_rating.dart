class ActivityRating {
  final String id;
  final String userId;
  final String activityId; // Reference to the scheduled activity
  final String activityName;
  final String? placeName;
  final int stars; // 1-5
  final List<String> tags; // ["The vibe", "The food", "The people", "The location"]
  final bool wouldRecommend;
  final String? notes;
  final DateTime completedAt;
  final String mood; // How they felt during/after
  
  ActivityRating({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.activityName,
    this.placeName,
    required this.stars,
    required this.tags,
    required this.wouldRecommend,
    this.notes,
    required this.completedAt,
    required this.mood,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'activity_id': activityId,
      'activity_name': activityName,
      'place_name': placeName,
      'stars': stars,
      'tags': tags,
      'would_recommend': wouldRecommend,
      'notes': notes,
      'completed_at': completedAt.toIso8601String(),
      'mood': mood,
    };
  }

  factory ActivityRating.fromJson(Map<String, dynamic> json) {
    return ActivityRating(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      activityId: json['activity_id'] as String,
      activityName: json['activity_name'] as String,
      placeName: json['place_name'] as String?,
      stars: json['stars'] as int,
      tags: List<String>.from(json['tags'] ?? []),
      wouldRecommend: json['would_recommend'] as bool,
      notes: json['notes'] as String?,
      completedAt: DateTime.parse(json['completed_at'] as String),
      mood: json['mood'] as String,
    );
  }

  // Calculate sentiment score for ML/pattern recognition
  double get sentimentScore {
    double score = stars / 5.0; // Base score from stars
    if (wouldRecommend) score += 0.1;
    if (tags.isNotEmpty) score += 0.05 * tags.length;
    return score.clamp(0.0, 1.0);
  }
}

// User preference patterns based on ratings
class UserPreferencePattern {
  final String userId;
  final Map<String, double> moodActivityScores; // "adventurous_hiking": 0.85
  final Map<String, int> tagCounts; // "The vibe": 15
  final Map<String, double> timePreferences; // "morning": 0.7
  final List<String> topRatedPlaces;
  final List<String> topRatedActivities;
  final DateTime lastUpdated;

  UserPreferencePattern({
    required this.userId,
    required this.moodActivityScores,
    required this.tagCounts,
    required this.timePreferences,
    required this.topRatedPlaces,
    required this.topRatedActivities,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'mood_activity_scores': moodActivityScores,
      'tag_counts': tagCounts,
      'time_preferences': timePreferences,
      'top_rated_places': topRatedPlaces,
      'top_rated_activities': topRatedActivities,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory UserPreferencePattern.fromJson(Map<String, dynamic> json) {
    return UserPreferencePattern(
      userId: json['user_id'] as String,
      moodActivityScores: Map<String, double>.from(json['mood_activity_scores'] ?? {}),
      tagCounts: Map<String, int>.from(json['tag_counts'] ?? {}),
      timePreferences: Map<String, double>.from(json['time_preferences'] ?? {}),
      topRatedPlaces: List<String>.from(json['top_rated_places'] ?? []),
      topRatedActivities: List<String>.from(json['top_rated_activities'] ?? []),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }
}

// Weekly reflection summary
class WeeklyReflection {
  final String id;
  final String userId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int activitiesCompleted;
  final int newPlacesTried;
  final Map<String, int> moodDistribution; // "adventurous": 3
  final List<ActivityRating> topRated;
  final List<ActivityRating> lowRated;
  final String dominantMood;
  final List<String> achievements; // ["Tried 3 new places!", "5-day check-in streak!"]
  final Map<String, dynamic> insights; // AI-generated insights

  WeeklyReflection({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.activitiesCompleted,
    required this.newPlacesTried,
    required this.moodDistribution,
    required this.topRated,
    required this.lowRated,
    required this.dominantMood,
    required this.achievements,
    required this.insights,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'week_start': weekStart.toIso8601String(),
      'week_end': weekEnd.toIso8601String(),
      'activities_completed': activitiesCompleted,
      'new_places_tried': newPlacesTried,
      'mood_distribution': moodDistribution,
      'top_rated': topRated.map((r) => r.toJson()).toList(),
      'low_rated': lowRated.map((r) => r.toJson()).toList(),
      'dominant_mood': dominantMood,
      'achievements': achievements,
      'insights': insights,
    };
  }

  factory WeeklyReflection.fromJson(Map<String, dynamic> json) {
    return WeeklyReflection(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      activitiesCompleted: json['activities_completed'] as int,
      newPlacesTried: json['new_places_tried'] as int,
      moodDistribution: Map<String, int>.from(json['mood_distribution'] ?? {}),
      topRated: (json['top_rated'] as List?)
          ?.map((r) => ActivityRating.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      lowRated: (json['low_rated'] as List?)
          ?.map((r) => ActivityRating.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      dominantMood: json['dominant_mood'] as String,
      achievements: List<String>.from(json['achievements'] ?? []),
      insights: json['insights'] as Map<String, dynamic>? ?? {},
    );
  }
}

