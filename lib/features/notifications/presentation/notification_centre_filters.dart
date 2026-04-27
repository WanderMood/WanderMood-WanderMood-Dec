import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/notifications/in_app_notification_copy.dart';
import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';
import 'package:wandermood/l10n/app_localizations.dart';

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

String notificationCentrePillLabel(NotificationCentreFilter f, AppLocalizations l10n) {
  switch (f) {
    case NotificationCentreFilter.all:
      return l10n.notificationCentreAllFilter;
    case NotificationCentreFilter.moodMatch:
      return l10n.notificationCentreCategoryMoodMatch;
    case NotificationCentreFilter.activities:
      return l10n.notificationCentreActivitiesLabel;
    case NotificationCentreFilter.social:
      return l10n.notificationCentreSocialLabel;
    case NotificationCentreFilter.moody:
      return l10n.notificationCentreMoodyLabel;
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

String notificationCentreCategoryLabel(RealtimeEventType t, AppLocalizations l10n) {
  switch (t) {
    case RealtimeEventType.groupTravelUpdate:
    case RealtimeEventType.planUpdate:
      return l10n.notificationCentreCategoryMoodMatch;
    case RealtimeEventType.activityReminder:
    case RealtimeEventType.activityReview:
      return l10n.notificationCentreActivitiesLabel;
    case RealtimeEventType.postComment:
    case RealtimeEventType.postLike:
    case RealtimeEventType.postReaction:
    case RealtimeEventType.newFollower:
    case RealtimeEventType.friendRequest:
      return l10n.notificationCentreSocialLabel;
    case RealtimeEventType.moodySuggestion:
    case RealtimeEventType.milestone:
      return l10n.notificationCentreMoodyLabel;
    default:
      return l10n.notificationCentreMoodyLabel;
  }
}

/// Relative time for the notification list (uses app [l10n], not hardcoded English).
String notificationCentreTimeAgo(RealtimeEvent e, AppLocalizations l10n) {
  final now = DateTime.now();
  final difference = now.difference(e.timestamp);
  if (difference.inMinutes < 1) {
    return l10n.activeSessionsTimeJustNow;
  }
  if (difference.inMinutes < 60) {
    return l10n.notificationCentreRelativeMinutesAgo(difference.inMinutes);
  }
  if (difference.inHours < 24) {
    return l10n.savedPlacesTimeHoursAgo(difference.inHours);
  }
  if (difference.inDays < 7) {
    return l10n.savedPlacesTimeDaysAgo(difference.inDays);
  }
  final weeks = (difference.inDays / 7).floor();
  return l10n.activeSessionsTimeWeeksAgo(weeks);
}

/// Body line: recomputes Mood Match / Moody / social copy from payload + current locale
/// so inbox matches the user’s language even if the row was stored with another language.
String notificationCentreDisplayBody(RealtimeEvent e, AppLocalizations l10n) {
  final nl = l10n.localeName.toLowerCase().startsWith('nl');
  final locale = l10n.localeName;
  final t = e.type;
  final sub =
      (e.data['event'] ?? e.data['kind'] ?? '').toString().trim();

  if (t == RealtimeEventType.groupTravelUpdate ||
      t == RealtimeEventType.planUpdate ||
      _isMoodMatchByPayload(e)) {
    final d = InAppNotificationCopy.withLocaleFormattedIsoDates(e.data, locale);
    return InAppNotificationCopy.planMessage(
      nl: nl,
      event: sub.isNotEmpty ? sub : '_',
      data: d,
    );
  }

  if (t == RealtimeEventType.activityReminder) {
    final ev = sub.isNotEmpty ? sub : 'activity_reminder';
    final d = InAppNotificationCopy.withLocaleFormattedIsoDates(e.data, locale);
    return InAppNotificationCopy.moodyMessage(nl: nl, event: ev, data: d);
  }
  if (t == RealtimeEventType.activityReview) {
    final ev = sub.isNotEmpty ? sub : 'rate_activity';
    final d = InAppNotificationCopy.withLocaleFormattedIsoDates(e.data, locale);
    return InAppNotificationCopy.planMessage(nl: nl, event: ev, data: d);
  }
  if (t == RealtimeEventType.placeRecommendation) {
    final ev = sub.isNotEmpty ? sub : 'moody_place_pick';
    return InAppNotificationCopy.moodyMessage(nl: nl, event: ev, data: e.data);
  }

  if (t == RealtimeEventType.systemUpdate ||
      t == RealtimeEventType.moodySuggestion ||
      t == RealtimeEventType.milestone) {
    final ev = (e.data['event'] ?? '').toString().trim();
    if (ev.isNotEmpty) {
      final d = Map<String, dynamic>.from(e.data);
      if (ev == 'moody_chat_reminder') {
        final iso = d['fire_at']?.toString();
        final dt = iso != null ? DateTime.tryParse(iso) : null;
        if (dt != null) {
          d['when_label'] =
              DateFormat.yMMMd(locale).add_jm().format(dt.toLocal());
        }
      }
      return InAppNotificationCopy.moodyMessage(nl: nl, event: ev, data: d);
    }
  }

  switch (t) {
    case RealtimeEventType.postReaction:
    case RealtimeEventType.postLike:
    case RealtimeEventType.postComment:
    case RealtimeEventType.newFollower:
      return InAppNotificationCopy.socialMessage(
        nl: nl,
        type: t,
        data: e.data,
      );
    default:
      return e.message;
  }
}
