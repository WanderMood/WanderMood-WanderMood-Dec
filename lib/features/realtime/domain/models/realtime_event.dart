import 'package:freezed_annotation/freezed_annotation.dart';

part 'realtime_event.freezed.dart';
part 'realtime_event.g.dart';

@freezed
class RealtimeEvent with _$RealtimeEvent {
  const factory RealtimeEvent({
    required String id,
    required String userId,
    required RealtimeEventType type,
    required String title,
    required String message,
    required Map<String, dynamic> data,
    required DateTime timestamp,
    @Default(false) bool isRead,
    String? imageUrl,
    String? actionUrl,
    String? relatedUserId,
    String? relatedPostId,
    int? priority,
  }) = _RealtimeEvent;

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) => _$RealtimeEventFromJson(json);
}

enum RealtimeEventType {
  // Social interactions
  postLike,
  postComment,
  postShare,
  newFollower,
  postReaction,
  friendRequest,

  // Travel updates
  weatherAlert,
  placeRecommendation,

  // System notifications
  welcomeMessage,
  achievementUnlocked,

  // Real-time updates
  liveLocationUpdate,
  groupTravelUpdate,
  planUpdate,
  activityReminder,
  activityReview,
  moodySuggestion,
  milestone,
  systemUpdate,

  // Safety and alerts
  emergencyAlert,
  travelAdvisory,
}

extension RealtimeEventTypeExtension on RealtimeEventType {
  String get displayName {
    switch (this) {
      case RealtimeEventType.postLike:
        return 'Post Liked';
      case RealtimeEventType.postComment:
        return 'New Comment';
      case RealtimeEventType.postShare:
        return 'Post Shared';
      case RealtimeEventType.newFollower:
        return 'New Follower';
      case RealtimeEventType.postReaction:
        return 'Post Reaction';
      case RealtimeEventType.friendRequest:
        return 'Friend Request';
      case RealtimeEventType.weatherAlert:
        return 'Weather Alert';
      case RealtimeEventType.placeRecommendation:
        return 'Place Recommendation';
      case RealtimeEventType.welcomeMessage:
        return 'Welcome';
      case RealtimeEventType.achievementUnlocked:
        return 'Achievement Unlocked';
      case RealtimeEventType.liveLocationUpdate:
        return 'Location Update';
      case RealtimeEventType.groupTravelUpdate:
        return 'Group Travel Update';
      case RealtimeEventType.planUpdate:
        return 'Plan Update';
      case RealtimeEventType.activityReminder:
        return 'Activity Reminder';
      case RealtimeEventType.activityReview:
        return 'Activity Review';
      case RealtimeEventType.moodySuggestion:
        return 'Moody Suggestion';
      case RealtimeEventType.milestone:
        return 'Milestone';
      case RealtimeEventType.systemUpdate:
        return 'System Update';
      case RealtimeEventType.emergencyAlert:
        return 'Emergency Alert';
      case RealtimeEventType.travelAdvisory:
        return 'Travel Advisory';
    }
  }

  String get icon {
    switch (this) {
      case RealtimeEventType.postLike:
        return '❤️';
      case RealtimeEventType.postComment:
        return '💬';
      case RealtimeEventType.postShare:
        return '📤';
      case RealtimeEventType.newFollower:
        return '👥';
      case RealtimeEventType.postReaction:
        return '✨';
      case RealtimeEventType.friendRequest:
        return '🤝';
      case RealtimeEventType.weatherAlert:
        return '🌩️';
      case RealtimeEventType.placeRecommendation:
        return '📍';
      case RealtimeEventType.welcomeMessage:
        return '👋';
      case RealtimeEventType.achievementUnlocked:
        return '🏆';
      case RealtimeEventType.liveLocationUpdate:
        return '📍';
      case RealtimeEventType.groupTravelUpdate:
        return '🚐';
      case RealtimeEventType.planUpdate:
        return '📋';
      case RealtimeEventType.activityReminder:
        return '⏰';
      case RealtimeEventType.activityReview:
        return '⭐';
      case RealtimeEventType.moodySuggestion:
        return '💡';
      case RealtimeEventType.milestone:
        return '🎯';
      case RealtimeEventType.systemUpdate:
        return 'ℹ️';
      case RealtimeEventType.emergencyAlert:
        return '🚨';
      case RealtimeEventType.travelAdvisory:
        return '⚠️';
    }
  }

  int get defaultPriority {
    switch (this) {
      case RealtimeEventType.emergencyAlert:
        return 5;
      case RealtimeEventType.travelAdvisory:
        return 4;
      case RealtimeEventType.weatherAlert:
        return 3;
      case RealtimeEventType.groupTravelUpdate:
        return 3;
      case RealtimeEventType.postLike:
      case RealtimeEventType.postComment:
      case RealtimeEventType.newFollower:
      case RealtimeEventType.postReaction:
      case RealtimeEventType.friendRequest:
        return 2;
      case RealtimeEventType.placeRecommendation:
      case RealtimeEventType.liveLocationUpdate:
      case RealtimeEventType.planUpdate:
      case RealtimeEventType.activityReminder:
      case RealtimeEventType.activityReview:
      case RealtimeEventType.moodySuggestion:
      case RealtimeEventType.milestone:
      case RealtimeEventType.systemUpdate:
        return 1;
      case RealtimeEventType.welcomeMessage:
      case RealtimeEventType.achievementUnlocked:
      case RealtimeEventType.postShare:
        return 0;
    }
  }

  bool get shouldShowInApp {
    return true; // All events should show in-app notifications
  }

  bool get shouldSendPush {
    switch (this) {
      case RealtimeEventType.emergencyAlert:
      case RealtimeEventType.travelAdvisory:
      case RealtimeEventType.weatherAlert:
        return true;
      case RealtimeEventType.groupTravelUpdate:
      case RealtimeEventType.newFollower:
      case RealtimeEventType.postComment:
      case RealtimeEventType.postReaction:
      case RealtimeEventType.friendRequest:
      case RealtimeEventType.planUpdate:
      case RealtimeEventType.activityReminder:
        return true;
      case RealtimeEventType.postLike:
      case RealtimeEventType.postShare:
      case RealtimeEventType.placeRecommendation:
      case RealtimeEventType.liveLocationUpdate:
      case RealtimeEventType.welcomeMessage:
      case RealtimeEventType.achievementUnlocked:
      case RealtimeEventType.activityReview:
      case RealtimeEventType.moodySuggestion:
      case RealtimeEventType.milestone:
      case RealtimeEventType.systemUpdate:
        return false;
    }
  }
}

@freezed
class LiveUpdate with _$LiveUpdate {
  const factory LiveUpdate({
    required String id,
    required String table,
    required LiveUpdateType type,
    required Map<String, dynamic> record,
    required Map<String, dynamic>? oldRecord,
    required DateTime timestamp,
    String? userId,
  }) = _LiveUpdate;

  factory LiveUpdate.fromJson(Map<String, dynamic> json) => _$LiveUpdateFromJson(json);
}

enum LiveUpdateType {
  insert,
  update,
  delete,
}

@freezed
class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    required String userId,
    @Default(true) bool pushNotifications,
    @Default(true) bool inAppNotifications,
    @Default(true) bool emailNotifications,
    @Default(true) bool socialInteractions,
    @Default(true) bool travelUpdates,
    @Default(true) bool weatherAlerts,
    @Default(true) bool emergencyAlerts,
    @Default(false) bool quietHours,
    @Default(22) int quietStartHour,
    @Default(7) int quietEndHour,
    @Default([]) List<String> mutedUsers,
    @Default([]) List<RealtimeEventType> mutedEventTypes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _NotificationSettings;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => _$NotificationSettingsFromJson(json);
}

// Extension methods for business logic
extension RealtimeEventExtension on RealtimeEvent {
  /// Check if this event should be displayed to the user
  bool get shouldDisplay {
    return type.shouldShowInApp && !isRead;
  }

  /// Check if this event should trigger a push notification
  bool get shouldPush {
    return type.shouldSendPush;
  }

  /// Get the display message with user context
  String getDisplayMessage(String? currentUserName) {
    final userName = data['userName'] as String? ?? 'Someone';
    
    switch (type) {
      case RealtimeEventType.postLike:
        return '$userName liked your post';
      case RealtimeEventType.postComment:
        return '$userName commented on your post';
      case RealtimeEventType.postShare:
        return '$userName shared your post';
      case RealtimeEventType.newFollower:
        return '$userName started following you';
      case RealtimeEventType.weatherAlert:
        return 'Weather alert for your location: $message';
      case RealtimeEventType.placeRecommendation:
        return 'New place recommendation: $message';
      case RealtimeEventType.groupTravelUpdate:
        return 'Group travel update: $message';
      case RealtimeEventType.liveLocationUpdate:
        return '$userName updated their location';
      default:
        return message;
    }
  }

  /// Check if this event is time-sensitive
  bool get isTimeSensitive {
    return type == RealtimeEventType.emergencyAlert ||
           type == RealtimeEventType.travelAdvisory ||
           type == RealtimeEventType.weatherAlert;
  }

  /// Get the priority level for display ordering
  int get displayPriority {
    return priority ?? type.defaultPriority;
  }
} 