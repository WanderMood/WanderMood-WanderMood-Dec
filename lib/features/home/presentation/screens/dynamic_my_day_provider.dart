import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../plans/data/services/scheduled_activity_service.dart';
import '../../../plans/domain/models/activity.dart';

/// Selected My Day date (defaults to today).
final selectedMyDayDateProvider = StateProvider<DateTime>((ref) {
  final now = MoodyClock.now();
  return DateTime(now.year, now.month, now.day);
});

// Enum for activity status
enum ActivityStatus {
  upcoming,    // Added to the day plan, not yet checked in
  activeNow,   // User tapped "I'm Here" — currently at this activity
  completed,   // User tapped "Done"
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

  ActivityManagerState({
    required this.activities,
    required this.statusUpdates,
  });

  ActivityManagerState copyWith({
    List<Map<String, dynamic>>? activities,
    Map<String, ActivityStatus>? statusUpdates,
  }) {
    return ActivityManagerState(
      activities: activities ?? this.activities,
      statusUpdates: statusUpdates ?? this.statusUpdates,
    );
  }
}

class ActivityManagerNotifier extends StateNotifier<ActivityManagerState> {
  ActivityManagerNotifier()
      : super(
          ActivityManagerState(
            activities: [],
            statusUpdates: {},
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

  /// User tapped "I'm Here" — marks the activity as actively in progress.
  void checkInActivity(String activityId) {
    updateActivityStatus(activityId, ActivityStatus.activeNow);
  }

  /// User tapped "Done" — marks the activity as completed.
  void markActivityDone(String activityId) {
    updateActivityStatus(activityId, ActivityStatus.completed);
  }

  void cancelActivity(String activityId) {
    updateActivityStatus(activityId, ActivityStatus.cancelled);
  }

  /// After removing an activity from the backend, drop any local status for that id.
  void clearLocalStatusForActivity(String activityId) {
    if (activityId.isEmpty) return;
    final newStatus =
        Map<String, ActivityStatus>.from(state.statusUpdates)..remove(activityId);
    state = state.copyWith(statusUpdates: newStatus);
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
    'placeId': activity.placeId,
  };
}

/// Provider for today's scheduled activities from Supabase (single source of truth for My Day).
/// When invalidated (e.g. after plan save), My Day refreshes from the database.
final scheduledActivitiesForTodayProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(scheduledActivityServiceProvider);
  final selectedDate = ref.watch(selectedMyDayDateProvider);
  final activities = await service.getScheduledActivitiesForDate(selectedDate);
  final dateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

  final selectedDateMaps = <Map<String, dynamic>>[];
  for (final activity in activities) {
    final start = activity.startTime;
    if (start.year != dateOnly.year || start.month != dateOnly.month || start.day != dateOnly.day) {
      continue;
    }
    selectedDateMaps.add(_activityToRawData(activity));
  }
  return selectedDateMaps;
});

/// Agenda + onboarding cache: Supabase scheduled activities (source of truth) merged with
/// SharedPreferences suggestions (onboarding / booking fallback) so manual Explore adds appear on Agenda.
/// CRITICAL: NOT autoDispose to prevent API calls on hot reload
final cachedActivitySuggestionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(scheduledActivityServiceProvider);

  List<Map<String, dynamic>> fromDb = [];
  try {
    final dbActivities = await service.getAllScheduledActivitiesForUser();
    fromDb = dbActivities.map(_activityToRawData).toList();
  } catch (e) {
    debugPrint('cachedActivitySuggestionsProvider: DB load failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final activitiesJson = prefs.getStringList('cached_activity_suggestions') ?? [];

  final fromPrefs = activitiesJson.map((json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return <String, dynamic>{};
    }
  }).where((activity) => activity.isNotEmpty).toList();

  final seenIds = <String>{};
  for (final m in fromDb) {
    final id = m['id'] as String?;
    if (id != null && id.isNotEmpty) {
      seenIds.add(id);
    }
  }

  final merged = <Map<String, dynamic>>[...fromDb];
  for (final p in fromPrefs) {
    final id = p['id'] as String?;
    if (id != null && id.isNotEmpty) {
      if (seenIds.contains(id)) continue;
      seenIds.add(id);
    }
    merged.add(p);
  }

  merged.sort((a, b) {
    final sa = a['startTime'] as String?;
    final sb = b['startTime'] as String?;
    if (sa == null && sb == null) return 0;
    if (sa == null) return 1;
    if (sb == null) return -1;
    return sa.compareTo(sb);
  });

  return merged;
});

/// Provider for today's enhanced activities with status detection.
/// Status is entirely user-driven: "upcoming" until the user taps "I'm Here",
/// then "activeNow" until the user taps "Done". No clock-driven transitions.
/// CRITICAL: NOT autoDispose to prevent API calls on hot reload
final todayActivitiesProvider = FutureProvider<List<EnhancedActivityData>>((ref) async {
  final activities = await ref.watch(scheduledActivitiesForTodayProvider.future);
  final activityManagerState = ref.watch(activityManagerProvider);
  final selectedDate = ref.watch(selectedMyDayDateProvider);
  final dateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

  final enhancedActivities = <EnhancedActivityData>[];

  for (final activity in activities) {
    try {
      final startTimeStr = activity['startTime'] as String?;
      if (startTimeStr == null) continue;

      final startTime = DateTime.parse(startTimeStr);
      final duration = activity['duration'] as int? ?? 60;
      final endTime = startTime.add(Duration(minutes: duration));

      if (startTime.year != dateOnly.year ||
          startTime.month != dateOnly.month ||
          startTime.day != dateOnly.day) {
        continue;
      }

      final activityId = activity['id'] as String? ?? activity['title'] as String? ?? '';
      final managerStatus = activityManagerState.statusUpdates[activityId];

      // Status is purely user-driven — default is always "upcoming".
      final status = managerStatus ?? ActivityStatus.upcoming;

      enhancedActivities.add(EnhancedActivityData(
        rawData: activity,
        status: status,
        startTime: startTime,
        endTime: endTime,
      ));
    } catch (e) {
      debugPrint('❌ Error processing activity: $e');
      continue;
    }
  }

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
    return {'type': 'no_plan'};
  }

  // Active: user has checked in
  final activeActivity = todayActivities
      .where((a) => a.status == ActivityStatus.activeNow)
      .firstOrNull;
  if (activeActivity != null) {
    return {
      'type': 'active',
      'subtitle': activeActivity.rawData['title'],
      'activity': activeActivity.rawData,
      'enhancedActivity': activeActivity,
      'imageUrl': activeActivity.rawData['imageUrl'] ?? '',
    };
  }

  // Upcoming: first activity not yet checked in
  final upcomingActivity = todayActivities
      .where((a) => a.status == ActivityStatus.upcoming)
      .firstOrNull;
  if (upcomingActivity != null) {
    return {
      'type': 'upcoming',
      'subtitle': upcomingActivity.rawData['title'],
      'timePeriod': _timeSlotPeriod(upcomingActivity.startTime.hour),
      'activity': upcomingActivity.rawData,
      'enhancedActivity': upcomingActivity,
    };
  }

  // All completed
  final lastCompleted = todayActivities
      .where((a) => a.status == ActivityStatus.completed)
      .lastOrNull;
  if (lastCompleted != null) {
    return {
      'type': 'completed',
      'subtitle': lastCompleted.rawData['title'],
      'activity': lastCompleted.rawData,
      'enhancedActivity': lastCompleted,
    };
  }

  // Default free time — UI localizes titles/descriptions via [timePeriod] + type.
  final period = _timeSlotPeriod(hour);
  return {
    'type': 'free_time',
    'period': period,
    'action1': 'explore_nearby',
    'action2': 'ask_moody',
  };
});

/// `morning` | `afternoon` | `evening` for localization lookup.
String _timeSlotPeriod(int hour) {
  if (hour >= 6 && hour < 12) return 'morning';
  if (hour >= 12 && hour < 18) return 'afternoon';
  return 'evening';
}

/// Provider for timeline categorized activities
/// CRITICAL: NOT autoDispose to prevent API calls on hot reload
final timelineCategorizedActivitiesProvider = FutureProvider<Map<String, List<EnhancedActivityData>>>((ref) async {
  final todayActivities = await ref.watch(todayActivitiesProvider.future);
  
  final Map<String, List<EnhancedActivityData>> categorized = {
    'morning': [],    // 6 AM - 12 PM
    'afternoon': [],  // 12 PM - 6 PM
    'evening': [],    // 6 PM - 12 AM
    'active': [],     // User checked in
    'upcoming': [],   // Not yet checked in
    'completed': [],  // Finished activities
  };
  
  for (final activity in todayActivities) {
    final hour = activity.startTime.hour;
    
    switch (activity.status) {
      case ActivityStatus.activeNow:
        categorized['active']!.add(activity);
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