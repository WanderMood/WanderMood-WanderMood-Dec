class TravelMoodPreferences {
  final String id;
  final String userId;
  final Map<String, MoodCategorySettings> moodCategories;
  final ActivityPreferences activityPreferences;
  final NotificationTriggers notificationTriggers;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TravelMoodPreferences({
    required this.id,
    required this.userId,
    required this.moodCategories,
    required this.activityPreferences,
    required this.notificationTriggers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TravelMoodPreferences.fromJson(Map<String, dynamic> json) {
    final moodCategoriesJson = json['mood_categories'] as Map<String, dynamic>;
    final moodCategories = <String, MoodCategorySettings>{};
    
    moodCategoriesJson.forEach((key, value) {
      moodCategories[key] = MoodCategorySettings.fromJson(value as Map<String, dynamic>);
    });

    return TravelMoodPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      moodCategories: moodCategories,
      activityPreferences: ActivityPreferences.fromJson(
        json['activity_preferences'] as Map<String, dynamic>,
      ),
      notificationTriggers: NotificationTriggers.fromJson(
        json['notification_triggers'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final moodCategoriesJson = <String, dynamic>{};
    moodCategories.forEach((key, value) {
      moodCategoriesJson[key] = value.toJson();
    });

    return {
      'id': id,
      'user_id': userId,
      'mood_categories': moodCategoriesJson,
      'activity_preferences': activityPreferences.toJson(),
      'notification_triggers': notificationTriggers.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class MoodCategorySettings {
  final bool enabled;
  final double weight;

  const MoodCategorySettings({
    required this.enabled,
    required this.weight,
  });

  factory MoodCategorySettings.fromJson(Map<String, dynamic> json) {
    return MoodCategorySettings(
      enabled: json['enabled'] as bool,
      weight: (json['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'weight': weight,
    };
  }
}

class ActivityPreferences {
  final List<String> timeOfDay;
  final List<String> duration;
  final List<String> groupSize;
  final List<String> budgetRange;

  const ActivityPreferences({
    required this.timeOfDay,
    required this.duration,
    required this.groupSize,
    required this.budgetRange,
  });

  factory ActivityPreferences.fromJson(Map<String, dynamic> json) {
    return ActivityPreferences(
      timeOfDay: List<String>.from(json['time_of_day'] as List),
      duration: List<String>.from(json['duration'] as List),
      groupSize: List<String>.from(json['group_size'] as List),
      budgetRange: List<String>.from(json['budget_range'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_of_day': timeOfDay,
      'duration': duration,
      'group_size': groupSize,
      'budget_range': budgetRange,
    };
  }
}

class NotificationTriggers {
  final bool newRecommendations;
  final bool moodReminders;
  final bool weatherUpdates;
  final bool friendActivities;

  const NotificationTriggers({
    required this.newRecommendations,
    required this.moodReminders,
    required this.weatherUpdates,
    required this.friendActivities,
  });

  factory NotificationTriggers.fromJson(Map<String, dynamic> json) {
    return NotificationTriggers(
      newRecommendations: json['new_recommendations'] as bool,
      moodReminders: json['mood_reminders'] as bool,
      weatherUpdates: json['weather_updates'] as bool,
      friendActivities: json['friend_activities'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new_recommendations': newRecommendations,
      'mood_reminders': moodReminders,
      'weather_updates': weatherUpdates,
      'friend_activities': friendActivities,
    };
  }
} 