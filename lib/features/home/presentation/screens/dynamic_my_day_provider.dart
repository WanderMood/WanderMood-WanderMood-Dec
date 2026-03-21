import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../plans/data/services/scheduled_activity_service.dart';
import '../../../plans/domain/models/activity.dart';

// Enum for activity status
enum ActivityStatus {
  upcoming,    // Scheduled for later today
  activeNow,   // Currently happening  
  awaitingCompletion, // Planned end passed; waiting for user confirmation
  completed,   // Recently finished
  overdue,     // Missed/passed time
  scheduled,   // Future days
  cancelled,   // User cancelled
}

// Enhanced activity data structure
class EnhancedActivityData {
  final Map<String, dynamic> rawData;
  final ActivityStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final Duration? timeRemaining;
  final Duration? timeSinceStart;

  EnhancedActivityData({
    required this.rawData,
    required this.status,
    required this.startTime,
    required this.endTime,
    this.timeRemaining,
    this.timeSinceStart,
  });

  EnhancedActivityData copyWith({
    Map<String, dynamic>? rawData,
    ActivityStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    Duration? timeRemaining,
    Duration? timeSinceStart,
  }) {
    return EnhancedActivityData(
      rawData: rawData ?? this.rawData,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      timeSinceStart: timeSinceStart ?? this.timeSinceStart,
    );
  }
}

// State notifier class for managing activity updates
class ActivityManagerState {
  final List<Map<String, dynamic>> activities;
  final Map<String, ActivityStatus> statusUpdates;
  final Map<String, DateTime> completionPromptSnoozes;

  ActivityManagerState({
    required this.activities,
    required this.statusUpdates,
    required this.completionPromptSnoozes,
  });

  ActivityManagerState copyWith({
    List<Map<String, dynamic>>? activities,
    Map<String, ActivityStatus>? statusUpdates,
    Map<String, DateTime>? completionPromptSnoozes,
  }) {
    return ActivityManagerState(
      activities: activities ?? this.activities,
      statusUpdates: statusUpdates ?? this.statusUpdates,
      completionPromptSnoozes:
          completionPromptSnoozes ?? this.completionPromptSnoozes,
    );
  }
}

class ActivityManagerNotifier extends StateNotifier<ActivityManagerState> {
  ActivityManagerNotifier()
      : super(
          ActivityManagerState(
            activities: [],
            statusUpdates: {},
            completionPromptSnoozes: {},
          ),
        );

  void updateActivities(List<Map<String, dynamic>> activities) {
    state = state.copyWith(activities: activities);
  }

  void updateActivityStatus(String activityId, ActivityStatus status) {
    final newStatusUpdates = Map<String, ActivityStatus>.from(state.statusUpdates);
    newStatusUpdates[activityId] = status;
    state = state.copyWith(statusUpdates: newStatusUpdates);
  }

  void snoozeCompletionPrompt(
    String activityId, {
    Duration duration = const Duration(minutes: 45),
  }) {
    final newSnoozes =
        Map<String, DateTime>.from(state.completionPromptSnoozes);
    newSnoozes[activityId] = MoodyClock.now().add(duration);

    final newStatusUpdates = Map<String, ActivityStatus>.from(state.statusUpdates);
    newStatusUpdates[activityId] = ActivityStatus.activeNow;

    state = state.copyWith(
      statusUpdates: newStatusUpdates,
      completionPromptSnoozes: newSnoozes,
    );
  }

  void clearCompletionPromptSnooze(String activityId) {
    if (!state.completionPromptSnoozes.containsKey(activityId)) return;

    final newSnoozes =
        Map<String, DateTime>.from(state.completionPromptSnoozes);
    newSnoozes.remove(activityId);
    state = state.copyWith(completionPromptSnoozes: newSnoozes);
  }

  void cancelActivity(String activityId) {
    updateActivityStatus(activityId, ActivityStatus.cancelled);
  }

  void updateActivity(String activityId, Map<String, dynamic> updatedData) {
    final newActivities = state.activities.map((activity) {
      if (activity['id'] == activityId) {
        return {...activity, ...updatedData};
      }
      return activity;
    }).toList();
    state = state.copyWith(activities: newActivities);
  }

  ActivityStatus getActivityStatus(String activityId) {
    return state.statusUpdates[activityId] ?? ActivityStatus.upcoming;
  }
}

// Provider for activity manager
final activityManagerProvider = StateNotifierProvider<ActivityManagerNotifier, ActivityManagerState>((ref) {
  return ActivityManagerNotifier();
});

/// Converts a plan [Activity] to the rawData map format expected by My Day UI.
Map<String, dynamic> _activityToRawData(Activity activity) {
  return {
    'id': activity.id,
    'title': activity.name,
    'description': activity.description,
    'category': activity.tags.isNotEmpty ? activity.tags.first : 'activity',
    'timeOfDay': activity.timeSlot,
    'duration': activity.duration,
    'imageUrl': activity.imageUrl,
    'isRecommended': true,
    'isScheduled': true,
    'startTime': activity.startTime.toIso8601String(),
    'paymentType': activity.paymentType.toString(),
    'location': '${activity.location.latitude},${activity.location.longitude}',
    'price': activity.price ?? 0.0,
    'rating': activity.rating,
  };
}

/// Provider for today's scheduled activities from Supabase (single source of truth for My Day).
/// When invalidated (e.g. after plan save), My Day refreshes from the database.
final scheduledActivitiesForTodayProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(scheduledActivityServiceProvider);
  final activities = await service.getScheduledActivities();
  final now = MoodyClock.now();
  final today = DateTime(now.year, now.month, now.day);

  final todayMaps = <Map<String, dynamic>>[];
  for (final activity in activities) {
    final start = activity.startTime;
    if (start.year != today.year || start.month != today.month || start.day != today.day) {
      continue;
    }
    todayMaps.add(_activityToRawData(activity));
  }
  return todayMaps;
});

/// Provider for cached activity suggestions from the prefetch loading screen
/// CRITICAL: NOT autoDispose to prevent API calls on hot reload
final cachedActivitySuggestionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final activitiesJson = prefs.getStringList('cached_activity_suggestions') ?? [];
  
  final cachedActivities = activitiesJson.map((json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return <String, dynamic>{};
    }
  }).where((activity) => activity.isNotEmpty).toList();
  
  // Return only cached activities (scheduled activities loading disabled to avoid rebuild loops).
  final allActivities = cachedActivities;
  if (allActivities.isEmpty) return [];
  return allActivities;
});

/// Provider for today's enhanced activities with status detection.
/// Reads from Supabase (scheduled_activities) as single source of truth for My Day.
/// CRITICAL: NOT autoDispose to prevent API calls on hot reload
final todayActivitiesProvider = FutureProvider<List<EnhancedActivityData>>((ref) async {
  final activities = await ref.watch(scheduledActivitiesForTodayProvider.future);
  final activityManagerState = ref.watch(activityManagerProvider);
  final now = MoodyClock.now();
  final today = DateTime(now.year, now.month, now.day);

  final enhancedActivities = <EnhancedActivityData>[];

  for (final activity in activities) {
    try {
      final startTimeStr = activity['startTime'] as String?;
      if (startTimeStr == null) continue;

      final startTime = DateTime.parse(startTimeStr);
      final duration = activity['duration'] as int? ?? 60;
      final endTime = startTime.add(Duration(minutes: duration));

      // Only process activities for today
      if (startTime.year != today.year ||
          startTime.month != today.month ||
          startTime.day != today.day) {
        continue;
      }

      // Check if activity has been cancelled
      final activityId = activity['id'] as String? ?? activity['title'] as String? ?? '';
      final managerStatus = activityManagerState.statusUpdates[activityId];
      final snoozedUntil =
          activityManagerState.completionPromptSnoozes[activityId];
      
      if (managerStatus == ActivityStatus.cancelled) {
        // Add cancelled activity
        enhancedActivities.add(EnhancedActivityData(
          rawData: activity,
          status: ActivityStatus.cancelled,
          startTime: startTime,
          endTime: endTime,
          timeRemaining: null,
          timeSinceStart: null,
        ));
        continue;
      }
      
      // Determine activity status
      ActivityStatus status;
      Duration? timeRemaining;
      Duration? timeSinceStart;

      final isCompletionPromptSnoozed =
          snoozedUntil != null && now.isBefore(snoozedUntil);

      if (managerStatus == ActivityStatus.completed) {
        status = ActivityStatus.completed;
        timeSinceStart = now.difference(endTime);
      } else if (now.isAfter(endTime)) {
        if (isCompletionPromptSnoozed) {
          status = ActivityStatus.activeNow;
          timeRemaining = snoozedUntil.difference(now);
          timeSinceStart = now.difference(startTime);
        } else {
          status = ActivityStatus.awaitingCompletion;
          timeSinceStart = now.difference(endTime);
        }
      } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
        // Activity is happening now
        status = ActivityStatus.activeNow;
        timeRemaining = endTime.difference(now);
        timeSinceStart = now.difference(startTime);
      } else if (now.isBefore(startTime)) {
        // Activity is upcoming
        status = ActivityStatus.upcoming;
        timeRemaining = startTime.difference(now);
  } else {
        status = ActivityStatus.scheduled;
      }
      
      // Override with manager status if available
      if (managerStatus != null &&
          managerStatus != ActivityStatus.activeNow &&
          managerStatus != ActivityStatus.completed) {
        status = managerStatus;
      }
      
      enhancedActivities.add(EnhancedActivityData(
        rawData: activity,
        status: status,
        startTime: startTime,
        endTime: endTime,
        timeRemaining: timeRemaining,
        timeSinceStart: timeSinceStart,
      ));
      
    } catch (e) {
      debugPrint('❌ Error processing activity: $e');
      continue;
    }
  }
  
  // Sort by start time
  enhancedActivities.sort((a, b) => a.startTime.compareTo(b.startTime));
  
  return enhancedActivities;
});

/// Provider for current activity status (for the status card)
/// CRITICAL: NOT autoDispose to prevent API calls on hot reload
final currentActivityStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final todayActivities = await ref.watch(todayActivitiesProvider.future);
  final now = MoodyClock.now();
  final hour = now.hour;

  if (todayActivities.isEmpty) {
    return {
      'type': 'no_plan',
    };
  }
  
  // Find active activity
  final activeActivity = todayActivities.where((a) => a.status == ActivityStatus.activeNow).firstOrNull;
  if (activeActivity != null) {
    return {
      'type': 'active',
              'title': 'Right Now',
      'subtitle': activeActivity.rawData['title'],
      'description': 'Started ${_formatDuration(activeActivity.timeSinceStart!)} ago • Ends in ${_formatDuration(activeActivity.timeRemaining!)}',
      'activity': activeActivity.rawData,
      'enhancedActivity': activeActivity,
      'imageUrl': activeActivity.rawData['imageUrl'] ?? 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80',
    };
  }

  final awaitingCompletionActivity = todayActivities
      .where((a) => a.status == ActivityStatus.awaitingCompletion)
      .lastOrNull;
  if (awaitingCompletionActivity != null) {
    return {
      'type': 'awaiting_completion',
      'title': '⏱ CHECK IN',
      'subtitle': awaitingCompletionActivity.rawData['title'],
      'description':
          'Planned to finish ${_formatDuration(awaitingCompletionActivity.timeSinceStart!)} ago. Still there or done?',
      'activity': awaitingCompletionActivity.rawData,
      'enhancedActivity': awaitingCompletionActivity,
    };
  }
  
  // Find next upcoming activity
  final upcomingActivity = todayActivities
      .where((a) => a.status == ActivityStatus.upcoming)
      .firstOrNull;
  if (upcomingActivity != null) {
    return {
      'type': 'upcoming',
      'title': '⏳ COMING UP',
      'subtitle': upcomingActivity.rawData['title'],
      'description': 'Starts in ${_formatDuration(upcomingActivity.timeRemaining!)} (${_formatTime(upcomingActivity.startTime)})',
      'action2': 'Get Ready',
      'activity': upcomingActivity.rawData,
      'enhancedActivity': upcomingActivity,
    };
  }
  
  // Find recently completed activity  
  final recentlyCompleted = todayActivities
      .where((a) => a.status == ActivityStatus.completed && a.timeSinceStart!.inHours < 1)
      .lastOrNull;
  if (recentlyCompleted != null) {
    return {
      'type': 'completed',
      'title': '✅ COMPLETED',
      'subtitle': recentlyCompleted.rawData['title'],
      'description': 'Finished ${_formatDuration(recentlyCompleted.timeSinceStart!)} ago',
      'action1': 'Rate Experience',
      'action2': 'Share',
      'activity': recentlyCompleted.rawData,
      'enhancedActivity': recentlyCompleted,
    };
  }
  
  // Default free time status
  String timeOfDay;
  String suggestion;
  
  if (hour >= 6 && hour < 12) {
    timeOfDay = 'Morning';
    suggestion = 'Perfect time to start your day with energy';
  } else if (hour >= 12 && hour < 17) {
    timeOfDay = 'Afternoon';
    suggestion = 'Great time to explore and discover';
  } else {
    timeOfDay = 'Evening';
    suggestion = 'Wind down with something special';
  }
  
  return {
    'type': 'free_time',
    'title': '📅 FREE TIME',
    'subtitle': timeOfDay,
    'description': suggestion,
    'action1': 'Explore Nearby',
    'action2': 'Ask Moody',
  };
});

/// Provider for timeline categorized activities
/// CRITICAL: NOT autoDispose to prevent API calls on hot reload
final timelineCategorizedActivitiesProvider = FutureProvider<Map<String, List<EnhancedActivityData>>>((ref) async {
  final todayActivities = await ref.watch(todayActivitiesProvider.future);
  
  final Map<String, List<EnhancedActivityData>> categorized = {
    'morning': [],    // 6 AM - 12 PM
    'afternoon': [],  // 12 PM - 6 PM
    'evening': [],    // 6 PM - 12 AM
    'active': [],     // Currently happening
    'awaiting': [],   // Waiting for done / still here
    'upcoming': [],   // Next activities
    'completed': [],  // Finished activities
  };
  
  for (final activity in todayActivities) {
    final hour = activity.startTime.hour;
    
    // Categorize by status first
    switch (activity.status) {
      case ActivityStatus.activeNow:
        categorized['active']!.add(activity);
        break;
      case ActivityStatus.awaitingCompletion:
        categorized['awaiting']!.add(activity);
        break;
      case ActivityStatus.upcoming:
        categorized['upcoming']!.add(activity);
        break;
      case ActivityStatus.completed:
        categorized['completed']!.add(activity);
        break;
      default:
        break;
    }
    
    // Also categorize by time of day
    if (hour >= 6 && hour < 12) {
      categorized['morning']!.add(activity);
    } else if (hour >= 12 && hour < 18) {
      categorized['afternoon']!.add(activity);
    } else {
      categorized['evening']!.add(activity);
    }
  }
  
  return categorized;
});

/// Provider for categorized activities (legacy - for backwards compatibility)
final categorizedActivitiesProvider = FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
  final activities = await ref.watch(cachedActivitySuggestionsProvider.future);
  final currentHour = MoodyClock.now().hour;
  
  final Map<String, List<Map<String, dynamic>>> categorized = {
    'recommended': [],
    'rightNow': [],
    'later': [],
    'allTime': [],
  };
  
  for (final activity in activities) {
    final timeOfDay = activity['timeOfDay'] as String? ?? 'any';
    final isRecommended = activity['isRecommended'] as bool? ?? false;
    
    // Add to recommended if marked as such
    if (isRecommended) {
      categorized['recommended']!.add(activity);
    }
    
    // Categorize by time appropriateness
    if (timeOfDay == 'any' || _isTimeAppropriate(timeOfDay, currentHour)) {
      categorized['rightNow']!.add(activity);
    } else {
      categorized['later']!.add(activity);
    }
    
    // Add all to allTime
    categorized['allTime']!.add(activity);
  }
  
  return categorized;
});

/// Check if activity time matches current time
bool _isTimeAppropriate(String timeOfDay, int currentHour) {
  switch (timeOfDay) {
    case 'morning':
      return currentHour >= 6 && currentHour < 12;
    case 'afternoon':
      return currentHour >= 12 && currentHour < 17;
    case 'evening':
      return currentHour >= 17 || currentHour < 6;
    default:
      return true;
  }
}

/// Helper function to format duration
String _formatDuration(Duration duration) {
  if (duration.inHours > 0) {
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  } else {
    return '${duration.inMinutes}m';
  }
}

/// Helper function to format time
String _formatTime(DateTime time) {
  final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

/// Default activities as fallback
List<Map<String, dynamic>> _getDefaultActivities() {
  final hour = MoodyClock.now().hour;
  
  if (hour >= 6 && hour < 12) {
    return [
      {
        'id': 'default_morning_coffee',
        'title': 'Start with Great Coffee',
        'description': 'Find a cozy café nearby for your morning boost',
        'category': 'food',
        'timeOfDay': 'morning',
        'duration': 45,
        'mood': 'energetic',
        'imageUrl': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&q=80',
        'isRecommended': true,
      },
      {
        'id': 'default_morning_walk',
        'title': 'Morning Walk in Nature',
        'description': 'Get energized with a refreshing walk in nearby parks',
        'category': 'exercise',
        'timeOfDay': 'morning',
        'duration': 60,
        'mood': 'energetic',
        'imageUrl': 'https://images.unsplash.com/photo-1544920403-4c9d4c3e8e2e?w=400&q=80',
        'isRecommended': true,
      },
    ];
  } else if (hour >= 12 && hour < 17) {
    return [
      {
        'id': 'default_afternoon_museum',
        'title': 'Explore Local Museums',
        'description': 'Discover fascinating art and history nearby',
        'category': 'culture',
        'timeOfDay': 'afternoon',
        'duration': 120,
        'mood': 'curious',
        'imageUrl': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400&q=80',
        'isRecommended': true,
      },
      {
        'id': 'default_afternoon_lunch',
        'title': 'Delicious Local Lunch',
        'description': 'Try authentic local cuisine at nearby restaurants',
        'category': 'food',
        'timeOfDay': 'afternoon',
        'duration': 90,
        'mood': 'relaxed',
        'imageUrl': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80',
        'isRecommended': true,
      },
    ];
  } else {
    return [
      {
        'id': 'default_evening_dinner',
        'title': 'Perfect Dinner Spot',
        'description': 'End your day with a memorable dining experience',
        'category': 'food',
        'timeOfDay': 'evening',
        'duration': 120,
        'mood': 'relaxed',
        'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&q=80',
        'isRecommended': true,
      },
      {
        'id': 'default_evening_entertainment',
        'title': 'Evening Entertainment',
        'description': 'Enjoy live music, bars, or cultural events',
        'category': 'entertainment',
        'timeOfDay': 'evening',
        'duration': 180,
        'mood': 'social',
        'imageUrl': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&q=80',
        'isRecommended': true,
      },
    ];
  }
} 

// Extension to safely get first element
extension IterableExtensions<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
} 