import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:wandermood/core/providers/notification_provider.dart';

import 'notification_category.dart';

/// Stable payload strings attached to local notifications for deep linking.
abstract class NotificationNavPayload {
  static const mainMyDay = 'wm_nav_main_0';
  static const mainExplore = 'wm_nav_main_1';
  static const mainMoody = 'wm_nav_main_2';
  /// Opens Moody tab and pushes standalone mood selection (`/moody`).
  static const mainMoodyMoodCheckIn = 'wm_nav_main_2_checkin';
  static const mainProfile = 'wm_nav_main_3';
  static const gamification = 'wm_nav_gamification';
  static const weather = 'wm_nav_weather';
  static const moodHistory = 'wm_nav_mood_history';
  static const messages = 'wm_nav_messages';
  static const agenda = 'wm_nav_agenda';

  static String? forCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.generateMyDay:
        return mainMoodyMoodCheckIn;
      case NotificationCategory.weekendPlanningNudge:
      case NotificationCategory.postTripReflection:
      case NotificationCategory.savedActivityReminder:
        return mainMyDay;
      case NotificationCategory.dailyMoodCheckIn:
      case NotificationCategory.companionCheckInMorning:
      case NotificationCategory.companionCheckInAfternoon:
      case NotificationCategory.companionCheckInEvening:
      case NotificationCategory.moodFollowUp:
      case NotificationCategory.reEngagement:
        return mainMoodyMoodCheckIn;
      case NotificationCategory.weeklyMoodRecap:
        return moodHistory;
      case NotificationCategory.streakMilestone:
      case NotificationCategory.achievementUnlocked:
        return gamification;
      case NotificationCategory.weatherNudge:
        return weather;
      case NotificationCategory.locationDiscovery:
      case NotificationCategory.trendingInYourCity:
      case NotificationCategory.festivalEvent:
        return mainExplore;
      case NotificationCategory.socialEngagement:
      case NotificationCategory.friendActivity:
        return messages;
    }
  }
}

/// Maps [NotificationNavPayload] values to [GoRouter] targets.
void applyNotificationNavigation(
  GoRouter router,
  String? payload,
  WidgetRef ref,
) {
  if (payload == null || payload.isEmpty) return;

  void openMoodCheckIn() {
    ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
    router.go(
      '/main?tab=2&moodAction=moodCheckIn',
      extra: <String, dynamic>{'tab': 2, 'moodAction': 'moodCheckIn'},
    );
  }

  switch (payload) {
    case NotificationNavPayload.mainMyDay:
      router.go('/main?tab=0', extra: <String, dynamic>{'tab': 0});
      break;
    case NotificationNavPayload.mainExplore:
      router.go('/main?tab=1', extra: <String, dynamic>{'tab': 1});
      break;
    case NotificationNavPayload.mainMoodyMoodCheckIn:
      openMoodCheckIn();
      break;
    case NotificationNavPayload.mainMoody:
      // Legacy scheduled notifications: same as check-in flow.
      openMoodCheckIn();
      break;
    case NotificationNavPayload.mainProfile:
      router.go('/main?tab=4', extra: <String, dynamic>{'tab': 4});
      break;
    case NotificationNavPayload.gamification:
      router.go('/gamification');
      break;
    case NotificationNavPayload.weather:
      router.go('/weather');
      break;
    case NotificationNavPayload.moodHistory:
      router.go('/moods/history');
      break;
    case NotificationNavPayload.messages:
      router.go('/social/messages');
      break;
    case NotificationNavPayload.agenda:
      router.go('/agenda');
      break;
    default:
      if (kDebugMode) {
        debugPrint('Unknown notification payload: $payload');
      }
  }
}
