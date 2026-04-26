import 'package:flutter/material.dart';
import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';

enum NotificationCentreFilter { all, moodMatch, activities, social, moody }

/// Sub-keys from Mood Match / plan pings — also used when `event_type` was
/// stored in snake_case or fell through to [RealtimeEventType.systemUpdate]
/// but payload is clearly a shared-plan update.
const _moodMatchPayloadEventKeys = {
  'mood_match_invite',
  'plan_ready',
  'both_confirmed',
  'guest_joined',
  'mood_locked',
  'slot_confirmed',
  'swap_requested',
  'swap_accepted',
  'swap_declined',
  'day_proposed',
  'day_accepted',
  'day_counter_proposed',
  'day_guest_declined_original',
};

bool _isMoodMatchByPayload(RealtimeEvent e) {
  final sub = (e.data['event'] ?? e.data['kind'] ?? '').toString().trim();
  if (sub.isEmpty) return false;
  if (_moodMatchPayloadEventKeys.contains(sub)) return true;
  return false;
}

bool notificationCentrePasses(NotificationCentreFilter filter, RealtimeEvent e) {
  final t = e.type.name;
  final d = e.data;
  final sub = (d['event'] ?? d['kind'] ?? '').toString();
  switch (filter) {
    case NotificationCentreFilter.all:
      return true;
    case NotificationCentreFilter.moodMatch:
      if (t == 'groupTravelUpdate' || t == 'planUpdate') return true;
      if (sub == 'mood_match_invite') return true;
      if (_isMoodMatchByPayload(e)) return true;
      // Snake_case or legacy DB values that did not map to enum names.
      final raw = (t).replaceAll('_', '').toLowerCase();
      if (raw == 'grouptravelupdate' || raw == 'planupdate') return true;
      return false;
    case NotificationCentreFilter.activities:
      return t == 'activityReminder' || t == 'activityReview';
    case NotificationCentreFilter.social:
      return t == 'postReaction' ||
          t == 'postComment' ||
          t == 'postLike' ||
          t == 'newFollower' ||
          t == 'friendRequest';
    case NotificationCentreFilter.moody:
      return t == 'moodySuggestion' || t == 'milestone' || t == 'systemUpdate';
  }
}

String notificationCentrePillLabel(NotificationCentreFilter f, bool nl) {
  switch (f) {
    case NotificationCentreFilter.all:
      return nl ? 'Alles' : 'All';
    case NotificationCentreFilter.moodMatch:
      return 'Mood Match';
    case NotificationCentreFilter.activities:
      return nl ? 'Activiteiten' : 'Activities';
    case NotificationCentreFilter.social:
      return 'Social';
    case NotificationCentreFilter.moody:
      return 'Moody';
  }
}

Color notificationCentreIconBg(RealtimeEventType t, {Color sunset = const Color(0xFFE8784A), Color cream = const Color(0xFFF5F0E8)}) {
  switch (t) {
    case RealtimeEventType.groupTravelUpdate:
    case RealtimeEventType.planUpdate:
      return sunset.withValues(alpha: 0.14);
    case RealtimeEventType.activityReminder:
    case RealtimeEventType.activityReview:
      return const Color(0xFFA8C8DC).withValues(alpha: 0.10);
    case RealtimeEventType.postComment:
    case RealtimeEventType.postLike:
    case RealtimeEventType.postReaction:
    case RealtimeEventType.newFollower:
    case RealtimeEventType.friendRequest:
      return const Color(0xFFD4537E).withValues(alpha: 0.10);
    case RealtimeEventType.moodySuggestion:
    case RealtimeEventType.milestone:
      return const Color(0xFF2A6049).withValues(alpha: 0.18);
    default:
      return cream.withValues(alpha: 0.05);
  }
}

String notificationCentreCategoryLabel(RealtimeEventType t) {
  switch (t) {
    case RealtimeEventType.groupTravelUpdate:
    case RealtimeEventType.planUpdate:
      return 'Mood Match';
    case RealtimeEventType.activityReminder:
    case RealtimeEventType.activityReview:
      return 'Activities';
    case RealtimeEventType.postComment:
    case RealtimeEventType.postLike:
    case RealtimeEventType.postReaction:
    case RealtimeEventType.newFollower:
    case RealtimeEventType.friendRequest:
      return 'Social';
    case RealtimeEventType.moodySuggestion:
    case RealtimeEventType.milestone:
      return 'Moody';
    default:
      return 'Moody';
  }
}
