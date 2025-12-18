import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../features/plans/data/services/scheduled_activity_service.dart';
import 'default_activities_provider.dart';

// Enum for activity status
enum ActivityStatus {
  upcoming,    // Scheduled for later today
  activeNow,   // Currently happening  
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
class ActivityManager extends StateNotifier<Map<String, ActivityStatus>> {
  ActivityManager() : super({});
  
  void updateActivityStatus(String activityId, ActivityStatus status) {
    state = {...state, activityId: status};
  }
  
  ActivityStatus? getActivityStatus(String activityId) {
    return state[activityId];
  }
}

final activityManagerProvider = StateNotifierProvider<ActivityManager, Map<String, ActivityStatus>>(
  (ref) => ActivityManager(),
);

/// Provider for cached activity suggestions
final cachedActivitySuggestionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final activitiesJson = prefs.getStringList('cached_activity_suggestions') ?? [];
  
  final cachedActivities = activitiesJson.map((json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return <String, dynamic>{};
    }
  }).where((activity) => activity.isNotEmpty).toList();
  
  // Get scheduled activities from the Moody flow
  final scheduledActivities = <Map<String, dynamic>>[];
  try {
    debugPrint('🔄 My Day Provider: Loading scheduled activities...');
    final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
    final activities = await scheduledActivityService.getScheduledActivities();
    
    debugPrint('🔄 My Day Provider: Found ${activities.length} scheduled activities');
    
    for (final activity in activities) {
      debugPrint('🔄 My Day Provider: Processing activity: ${activity.name}');
      scheduledActivities.add({
        'id': activity.id,
        'title': activity.name,
        'description': activity.description,
        'category': activity.tags.isNotEmpty ? activity.tags.first : 'general',
        'timeOfDay': activity.timeSlot,
        'duration': activity.duration,
        'mood': activity.tags.contains('energetic') ? 'energetic' : 'relaxed',
        'imageUrl': activity.imageUrl ?? 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&q=80',
        'isRecommended': true,
        'isScheduled': true,
        'startTime': activity.startTime.toIso8601String(),
        'paymentType': activity.paymentType.toString(),
      });
    }
    
    debugPrint('🔄 My Day Provider: Successfully processed ${scheduledActivities.length} scheduled activities');
  } catch (e) {
    debugPrint('❌ My Day Provider: Error loading scheduled activities: $e');
    debugPrint('❌ My Day Provider: Stack trace: ${StackTrace.current}');
  }
  
  // Combine scheduled activities with cached activities
  final allActivities = [...scheduledActivities, ...cachedActivities];
  
  // If no activities at all, get default activities
  if (allActivities.isEmpty) {
    return ref.watch(defaultActivitiesProvider).value ?? [];
  }
  
  return allActivities;
});

/// Provider for today's enhanced activities with status detection
final todayActivitiesProvider = FutureProvider.autoDispose<List<EnhancedActivityData>>((ref) async {
  final activities = await ref.watch(cachedActivitySuggestionsProvider.future);
  final activityManager = ref.watch(activityManagerProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  final enhancedActivities = <EnhancedActivityData>[];
  
  for (final activity in activities) {
    try {
      // Parse start time
      final startTime = activity['startTime'] != null 
        ? DateTime.parse(activity['startTime'])
        : _getDefaultStartTime(activity['timeOfDay'] as String? ?? 'any');
      
      // Calculate end time based on duration
      final duration = activity['duration'] as int? ?? 60;
      final endTime = startTime.add(Duration(minutes: duration));
      
      // Calculate time remaining and time since start
      final timeRemaining = endTime.isAfter(now) ? endTime.difference(now) : null;
      final timeSinceStart = now.isAfter(startTime) ? now.difference(startTime) : null;
      
      // Determine activity status
      ActivityStatus status;
      if (now.isBefore(startTime)) {
        status = ActivityStatus.upcoming;
      } else if (now.isAfter(endTime)) {
        status = ActivityStatus.completed;
      } else {
        status = ActivityStatus.activeNow;
      }
      
      // Check if status is overridden by activity manager
      final managerStatus = activityManager[activity['id']];
      if (managerStatus != null) {
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
final currentActivityStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final todayActivities = await ref.watch(todayActivitiesProvider.future);
  final now = DateTime.now();
  final hour = now.hour;
  
  // Find active activity
  final activeActivity = todayActivities.where((a) => a.status == ActivityStatus.activeNow).firstOrNull;
  if (activeActivity != null) {
    return {
      'type': 'active',
      'title': 'Right Now',
      'subtitle': activeActivity.rawData['title'],
      'description': 'Started ${_formatDuration(activeActivity.timeSinceStart!)} ago • Ends in ${_formatDuration(activeActivity.timeRemaining!)}',
      'activity': activeActivity.rawData,
      'imageUrl': activeActivity.rawData['imageUrl'] ?? 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80',
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
final timelineCategorizedActivitiesProvider = FutureProvider.autoDispose<Map<String, List<EnhancedActivityData>>>((ref) async {
  final todayActivities = await ref.watch(todayActivitiesProvider.future);
  
  final Map<String, List<EnhancedActivityData>> categorized = {
    'morning': [],    // 6 AM - 12 PM
    'afternoon': [],  // 12 PM - 6 PM
    'evening': [],    // 6 PM - 12 AM
    'active': [],     // Currently happening
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

/// Provider for time-based greeting message
final greetingMessageProvider = Provider<String>((ref) {
  final hour = DateTime.now().hour;
  
  if (hour < 12) {
    return 'Good morning! Let\'s make today amazing.';
  } else if (hour < 17) {
    return 'Good afternoon! Your day is looking great.';
  } else {
    return 'Good evening! Here\'s how your day went.';
  }
});

/// Provider for categorized activities (legacy - for backwards compatibility)
final categorizedActivitiesProvider = FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
  final activities = await ref.watch(cachedActivitySuggestionsProvider.future);
  final currentHour = DateTime.now().hour;
  
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

/// Helper function to get default start time based on time of day
DateTime _getDefaultStartTime(String timeOfDay) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  switch (timeOfDay.toLowerCase()) {
    case 'morning':
      return today.add(const Duration(hours: 9)); // 9 AM
    case 'afternoon':
      return today.add(const Duration(hours: 14)); // 2 PM
    case 'evening':
      return today.add(const Duration(hours: 19)); // 7 PM
    default:
      return now.add(const Duration(hours: 1)); // 1 hour from now
  }
} 