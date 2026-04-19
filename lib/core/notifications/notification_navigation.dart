import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:wandermood/core/providers/notification_provider.dart';
import 'package:wandermood/features/group_planning/data/mood_match_push_intent.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';

import 'notification_category.dart';

/// Deep link targets from FCM / in-app notification rows ([data] includes `event`, `session_id`, `post_id`, …).
void applyWmFcmDataNavigation(
  GoRouter router,
  WidgetRef ref,
  Map<String, dynamic> data,
) {
  final event = data['event']?.toString() ?? '';
  final sessionId = data['session_id']?.toString();
  final postId =
      data['post_id']?.toString() ?? data['related_post_id']?.toString();

  switch (event) {
    case 'mood_match_invite':
    case 'guest_joined':
    case 'mood_locked':
      if (sessionId != null && sessionId.isNotEmpty) {
        unawaited(_goMoodMatchLobbyFromPrefs(router, sessionId));
      }
      break;
    case 'plan_ready':
    case 'swap_accepted':
    case 'swap_declined':
      if (sessionId != null && sessionId.isNotEmpty) {
        router.go('/group-planning/result/$sessionId');
      }
      break;
    case 'swap_requested':
      if (sessionId != null && sessionId.isNotEmpty) {
        final slot = data['slot']?.toString().trim();
        MoodMatchPushIntent.setPendingSwapSlot(
          slot != null && slot.isNotEmpty ? slot : null,
        );
        final q = (slot != null && slot.isNotEmpty)
            ? '?wmSwapSlot=${Uri.encodeQueryComponent(slot)}'
            : '';
        router.go('/group-planning/result/$sessionId$q');
      }
      break;
    case 'swap_counter_proposed':
      if (sessionId != null && sessionId.isNotEmpty) {
        final slot = data['slot']?.toString().trim();
        MoodMatchPushIntent.setPendingSwapSlot(
          slot != null && slot.isNotEmpty ? slot : null,
        );
        final q = (slot != null && slot.isNotEmpty)
            ? '?wmSwapSlot=${Uri.encodeQueryComponent(slot)}'
            : '';
        router.go('/group-planning/result/$sessionId$q');
      }
      break;
    case 'day_proposed':
    case 'day_accepted':
    case 'day_counter_proposed':
    case 'day_guest_declined_original':
      // Day-picker is the only screen that owns the accept/counter modals.
      // Pre-fix this routed to /time-picker which silently skipped the modal
      // and dumped the user on the personal start-time screen instead.
      if (sessionId != null && sessionId.isNotEmpty) {
        router.go('/group-planning/day-picker/$sessionId');
      }
      break;
    case 'both_confirmed':
      if (sessionId != null && sessionId.isNotEmpty) {
        router.go('/group-planning/time-picker/$sessionId');
      }
      break;
    case 'leaving_soon':
      final lat = data['latitude'];
      final lng = data['longitude'];
      if (lat is num && lng is num) {
        // Caller can extend with map_launcher; centre stores coords when present.
      }
      router.go('/main?tab=0', extra: <String, dynamic>{'tab': 0});
      break;
    case 'rate_activity':
      router.go('/main?tab=0', extra: <String, dynamic>{'tab': 0});
      break;
    case 'post_reaction':
    case 'post_comment':
      if (postId != null && postId.isNotEmpty) {
        router.push('/social/post/$postId');
      }
      break;
    case 'new_follower':
      router.go('/main?tab=4', extra: <String, dynamic>{'tab': 4});
      break;
    case 'weekend_nudge':
    case 'morning_summary':
      ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
      router.go('/main?tab=0', extra: <String, dynamic>{'tab': 0});
      break;
    case 'milestone':
      router.go('/main?tab=4', extra: <String, dynamic>{'tab': 4});
      break;
    default:
      if (sessionId != null && sessionId.isNotEmpty) {
        unawaited(_goMoodMatchLobbyFromPrefs(router, sessionId));
      } else {
        router.push('/notifications');
      }
  }
}

Future<void> _goMoodMatchLobbyFromPrefs(
    GoRouter router, String sessionId) async {
  final r = await MoodMatchSessionPrefs.read();
  final code = (r.sessionId == sessionId &&
          r.joinCode != null &&
          r.joinCode!.trim().isNotEmpty)
      ? r.joinCode!.trim().toUpperCase()
      : null;
  if (code != null && code.isNotEmpty) {
    router.go(
      '/group-planning/lobby/$sessionId',
      extra: <String, dynamic>{'joinCode': code},
    );
  } else {
    router.go('/group-planning/lobby/$sessionId');
  }
}

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
      if (payload.startsWith('wm_nav_mm_lobby:')) {
        final sessionId = payload.substring('wm_nav_mm_lobby:'.length).trim();
        if (sessionId.isNotEmpty) {
          unawaited(_goMoodMatchLobbyFromPrefs(router, sessionId));
        }
        break;
      }
      if (kDebugMode) {
        debugPrint('Unknown notification payload: $payload');
      }
  }
}
