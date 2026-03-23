import 'package:flutter/material.dart';

enum ActivityStatus {
  upcoming,      // starts in > 30 minutes
  startingSoon,  // starts in <= 30 minutes
  inProgress,    // currently happening
  overdue,       // should have ended but not marked done
  completed,     // marked as done by user
}

class ActivityStatusHelper {

  static ActivityStatus getStatus(
    DateTime startTime,
    int durationMinutes,
    bool isCompleted,
  ) {
    if (isCompleted) return ActivityStatus.completed;

    final now = DateTime.now();
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    final minutesUntilStart = startTime.difference(now).inMinutes;

    if (now.isAfter(endTime)) return ActivityStatus.overdue;
    if (now.isAfter(startTime)) return ActivityStatus.inProgress;
    if (minutesUntilStart <= 30) return ActivityStatus.startingSoon;
    return ActivityStatus.upcoming;
  }

  static String getStatusLabel(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.upcoming:     return 'GEPLAND';
      case ActivityStatus.startingSoon: return 'BEGINT SNEL';
      case ActivityStatus.inProgress:   return 'BEZIG';
      case ActivityStatus.overdue:      return 'VERLOPEN';
      case ActivityStatus.completed:    return 'KLAAR';
    }
  }

  static Color getStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.upcoming:     return const Color(0xFF8C8780); // wmStone
      case ActivityStatus.startingSoon: return const Color(0xFF2A6049); // wmForest
      case ActivityStatus.inProgress:   return const Color(0xFFE8784A); // wmSunset
      case ActivityStatus.overdue:      return const Color(0xFFE8784A); // wmSunset
      case ActivityStatus.completed:    return const Color(0xFF2A6049); // wmForest
    }
  }

  /// Returns the next activity to show in the hero card:
  /// the first non-completed activity sorted by start_time.
  static Map<String, dynamic>? getNextActivity(
    List<Map<String, dynamic>> activities,
  ) {
    final pending = activities
        .where((a) => a['is_confirmed'] != true)
        .toList();

    if (pending.isEmpty) return null;

    pending.sort((a, b) {
      final aTime = DateTime.parse(a['start_time'] as String);
      final bTime = DateTime.parse(b['start_time'] as String);
      return aTime.compareTo(bTime);
    });

    return pending.first;
  }

  /// Returns "HH:mm - HH:mm" formatted time range for an activity.
  static String formatActivityTimeRange(DateTime startTime, int durationMinutes) {
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    final startStr = _padTime(startTime.hour, startTime.minute);
    final endStr = _padTime(endTime.hour, endTime.minute);
    return '$startStr - $endStr';
  }

  /// Returns a human-readable duration label (e.g. "90m", "1u", "1u 30m").
  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '${hours}u';
    return '${hours}u ${remaining}m';
  }

  /// Returns the time-of-day section key from a start time.
  static String getTimeOfDay(DateTime startTime) {
    final hour = startTime.hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    return 'evening';
  }

  static String _padTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
