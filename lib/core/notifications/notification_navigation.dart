import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/providers/notification_provider.dart';
import 'package:wandermood/core/navigation/root_navigator_key.dart';
import 'package:wandermood/features/group_planning/data/mood_match_push_intent.dart';
import 'package:wandermood/features/wishlist/data/plan_met_vriend_service.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_met_vriend_navigation.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import 'notification_category.dart';

enum _MmNotifIntent { lobbyish, dayPicker, result }

void _moodMatchNotifToast(
  BuildContext ctx,
  String Function(AppLocalizations l10n) pick,
) {
  final l10n = AppLocalizations.of(ctx);
  if (l10n == null) return;
  showWanderMoodToast(ctx, message: pick(l10n));
}

bool _sessionExpiredLike(GroupSessionRow s) {
  return s.status == 'expired' ||
      s.status == 'error' ||
      !s.expiresAt.isAfter(DateTime.now());
}

/// Resolves lobby / day-picker / result / hub from live session + plan so stale
/// inbox rows do not send users through an outdated Mood Match step.
Future<void> _navigateMoodMatchFromNotificationData({
  required GoRouter router,
  required WidgetRef ref,
  required String sessionId,
  BuildContext? snackContext,
  required _MmNotifIntent intent,
  String resultExtraQuery = '',
}) async {
  final repo = ref.read(groupPlanningRepositoryProvider);
  late final GroupSessionRow session;
  try {
    session = await repo.fetchSession(sessionId);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[notifications] mood match fetch session: $e\n$st');
    }
    final c = snackContext;
    if (c != null && c.mounted) {
      _moodMatchNotifToast(c, (l) => l.moodMatchNotificationTapOpenFailed);
    }
    // Stale id, deleted session, or RLS (e.g. invitee not a member yet).
    router.go('/group-planning');
    return;
  }

  if (_sessionExpiredLike(session)) {
    final c = snackContext;
    if (c != null && c.mounted) {
      _moodMatchNotifToast(c, (l) => l.moodMatchNotificationTapSessionEnded);
    }
    router.go('/group-planning');
    return;
  }

  final plan = await repo.fetchPlan(sessionId);
  final hasPlan = plan != null;
  final doneSaved = session.completedAt != null;

  if (doneSaved || hasPlan) {
    if (doneSaved) {
      final c = snackContext;
      if (c != null && c.mounted) {
        _moodMatchNotifToast(c, (l) => l.moodMatchNotificationTapAlreadySaved);
      }
    }
    final q = intent == _MmNotifIntent.result &&
            !doneSaved &&
            resultExtraQuery.isNotEmpty
        ? resultExtraQuery
        : '';
    router.go('/group-planning/result/$sessionId$q');
    return;
  }

  switch (intent) {
    case _MmNotifIntent.result:
      final c = snackContext;
      if (c != null && c.mounted) {
        _moodMatchNotifToast(c, (l) => l.moodMatchNotificationTapStaleUpdate);
      }
      router.go('/group-planning');
      return;
    case _MmNotifIntent.dayPicker:
    case _MmNotifIntent.lobbyish:
      if (session.status == 'day_proposed' ||
          session.status == 'day_counter_proposed') {
        router.go('/group-planning/day-picker/$sessionId');
      } else if (session.status == 'generating' ||
          session.status == 'ready' ||
          session.status == 'day_confirmed') {
        router.go('/group-planning/match-loading/$sessionId');
      } else {
        await _goMoodMatchLobbyFromPrefs(router, sessionId);
      }
      return;
  }
}

/// Deep link targets from FCM / in-app notification rows ([data] includes `event`, `session_id`, `post_id`, …).
Future<void> applyWmFcmDataNavigation(
  GoRouter router,
  WidgetRef ref,
  Map<String, dynamic> data, {
  BuildContext? snackContext,
}) async {
  final event = data['event']?.toString() ?? '';
  final dataType = data['type']?.toString() ?? '';
  final sessionIdRaw = data['session_id']?.toString().trim();
  final sessionId =
      sessionIdRaw != null && sessionIdRaw.isNotEmpty ? sessionIdRaw : null;
  final inviteIdRaw = data['invite_id']?.toString().trim();
  final inviteId =
      inviteIdRaw != null && inviteIdRaw.isNotEmpty ? inviteIdRaw : null;

  if ((dataType == 'plan_met_vriend_invite_reply' ||
          event == 'plan_met_vriend_invite_reply') &&
      sessionId != null) {
    router.push('/wishlist/plan-met-vriend/pending/$sessionId');
    return;
  }

  if (dataType == 'plan_met_vriend_invite' ||
      event == 'plan_met_vriend_invite') {
    if (sessionId != null && inviteId != null) {
      try {
        await PlanMetVriendService(Supabase.instance.client)
            .joinInviteForDayPicker(
          sessionId: sessionId,
          inviteId: inviteId,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[notifications] pmv join invite: $e');
      }
      router.push('/wishlist/day-picker/$sessionId');
    }
    return;
  }

  if ((dataType == 'plan_met_vriend_match' ||
          event == 'plan_met_vriend_match') &&
      sessionId != null &&
      inviteId != null) {
    await _openPlanMetVriendMatchFromSession(
      router: router,
      ref: ref,
      sessionId: sessionId,
      inviteId: inviteId,
    );
    return;
  }

  final postId =
      data['post_id']?.toString() ?? data['related_post_id']?.toString();

  switch (event) {
    case 'mood_match_invite':
      // Invitee should always land on JOIN flow (never sender invite screen).
      final jc = data['join_code']?.toString().trim();
      if (jc != null && jc.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[notifications] mood_match_invite -> /group-planning/join '
            'session_id=${sessionId ?? "(none)"} code=${jc.toUpperCase()}',
          );
        }
        router.go('/group-planning/join?code=${Uri.encodeQueryComponent(jc.toUpperCase())}');
      } else {
        // Without code we cannot prefill join; open hub/inbox fallback.
        if (kDebugMode) {
          debugPrint(
            '[notifications] mood_match_invite missing join_code '
            'session_id=${sessionId ?? "(none)"} -> /group-planning',
          );
        }
        router.go('/group-planning');
      }
      break;
    case 'guest_joined':
    case 'mood_locked':
      if (sessionId != null) {
        await _navigateMoodMatchFromNotificationData(
          router: router,
          ref: ref,
          sessionId: sessionId,
          snackContext: snackContext,
          intent: _MmNotifIntent.lobbyish,
        );
      }
      break;
    case 'plan_ready':
    case 'swap_accepted':
    case 'swap_declined':
      if (sessionId != null && sessionId.isNotEmpty) {
        await _navigateMoodMatchFromNotificationData(
          router: router,
          ref: ref,
          sessionId: sessionId,
          snackContext: snackContext,
          intent: _MmNotifIntent.result,
        );
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
        await _navigateMoodMatchFromNotificationData(
          router: router,
          ref: ref,
          sessionId: sessionId,
          snackContext: snackContext,
          intent: _MmNotifIntent.result,
          resultExtraQuery: q,
        );
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
        await _navigateMoodMatchFromNotificationData(
          router: router,
          ref: ref,
          sessionId: sessionId,
          snackContext: snackContext,
          intent: _MmNotifIntent.result,
          resultExtraQuery: q,
        );
      }
      break;
    case 'day_proposed':
    case 'day_accepted':
    case 'day_counter_proposed':
    case 'day_guest_declined_original':
      if (sessionId != null && sessionId.isNotEmpty) {
        if (await _tryNavigatePlanMetVriendDayPicker(
          router,
          sessionId,
          inviteId: inviteId,
        )) {
          break;
        }
        await _navigateMoodMatchFromNotificationData(
          router: router,
          ref: ref,
          sessionId: sessionId,
          snackContext: snackContext,
          intent: _MmNotifIntent.dayPicker,
        );
      }
      break;
    case 'both_confirmed':
      if (sessionId != null && sessionId.isNotEmpty) {
        await _navigateMoodMatchFromNotificationData(
          router: router,
          ref: ref,
          sessionId: sessionId,
          snackContext: snackContext,
          intent: _MmNotifIntent.result,
        );
      }
      break;
    case 'guest_left_session':
    case 'host_ended_session':
      final c = snackContext;
      if (c != null && c.mounted) {
        _moodMatchNotifToast(c, (l) => l.moodMatchNotificationTapSessionEnded);
      }
      router.go('/group-planning');
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
    // OS/local notification mirror + Moody hub (see [NotificationService._mapLocalNotificationToRealtime]).
    case 'moody_chat_reminder':
      ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
      router.go('/main?tab=2', extra: <String, dynamic>{'tab': 2});
      break;
    case 'daily_mood_check_in':
    case 'companion_check_in':
    case 'mood_follow_up':
    case 'generate_my_day':
      ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
      router.go(
        '/main?tab=2&moodAction=moodCheckIn',
        extra: <String, dynamic>{'tab': 2, 'moodAction': 'moodCheckIn'},
      );
      break;
    case 'moody_holiday_greeting':
      // Seasonal copy is about the user's day — land on My Day, not the Moody tab.
      ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
      router.go('/main?tab=0', extra: <String, dynamic>{'tab': 0});
      break;
    case 'moody_nudge_check_in':
      ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
      router.go(
        '/main?tab=2&moodAction=moodCheckIn',
        extra: <String, dynamic>{'tab': 2, 'moodAction': 'moodCheckIn'},
      );
      break;
    case 'moody_nudge_plan_today':
      ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
      router.go('/main?tab=0', extra: <String, dynamic>{'tab': 0});
      break;
    case 'moody_post_trip_reflection':
      ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
      router.go(
        '/main?tab=2&moodAction=moodCheckIn',
        extra: <String, dynamic>{'tab': 2, 'moodAction': 'moodCheckIn'},
      );
      break;
    case 'moody_saved_place_interest':
      final savedPlaceId = data['place_id']?.toString().trim();
      if (savedPlaceId != null && savedPlaceId.isNotEmpty) {
        router.push('/place/$savedPlaceId');
      } else {
        ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
        router.go('/main?tab=0', extra: <String, dynamic>{'tab': 0});
      }
      break;
    // Future: server- or client-sent “Moody thinks you’ll like this place” (B2B can reuse with partner_id).
    case 'moody_place_pick':
    case 'place_suggestion':
    case 'placeRecommendation':
      final placeId = data['place_id']?.toString().trim();
      if (placeId != null && placeId.isNotEmpty) {
        router.push('/place/$placeId');
      } else {
        ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
        router.go('/main?tab=1', extra: <String, dynamic>{'tab': 1});
      }
      break;
    case 'activity_upcoming':
    case 'activity_reminder':
    case 'activityReminder':
      ref.read(suppressMoodyIdleOnceProvider.notifier).state = true;
      final dateStr = (data['scheduled_date'] ?? data['target_date'] ?? '')
          .toString()
          .trim();
      if (dateStr.isNotEmpty) {
        router.go(
          '/main?tab=0',
          extra: <String, dynamic>{'tab': 0, 'targetDate': dateStr},
        );
      } else {
        router.go('/main?tab=0', extra: <String, dynamic>{'tab': 0});
      }
      break;
    case 'milestone':
      router.go('/main?tab=4', extra: <String, dynamic>{'tab': 4});
      break;
    default:
      // SECURITY: do not treat arbitrary/unknown events as Mood Match just
      // because they carry a `session_id`. Previously any unrecognised event
      // with a session id silently routed the user into /group-planning/lobby,
      // which makes the routing layer a juicy injection target (push payloads
      // are server-signed but misconfigured callers could still create drift
      // between the notification copy and the destination). Whitelist only —
      // unknown events land on the inbox so the user picks intent explicitly.
      if (kDebugMode) {
        debugPrint(
          '[notifications] Unhandled FCM event="$event" '
          'session_id=${sessionId ?? "(none)"}',
        );
      }
      router.push('/notifications');
  }
}

Future<bool> _tryNavigatePlanMetVriendDayPicker(
  GoRouter router,
  String sessionId, {
  String? inviteId,
}) async {
  final service = PlanMetVriendService(Supabase.instance.client);
  final isPmv = await service.isPlanMetVriendSession(sessionId);
  final invite = inviteId != null && inviteId.isNotEmpty
      ? await service.fetchInvite(inviteId)
      : await service.fetchInviteBySession(sessionId);
  final looksLikePmvInvite = invite != null &&
      (invite['invitee_user_id'] != null || invite['inviter_user_id'] != null);
  if (!isPmv && !looksLikePmvInvite) return false;
  try {
    await service.ensureInviteeSessionAccess(sessionId, inviteId: inviteId);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[notifications] pmv ensureInviteeSessionAccess: $e');
    }
  }
  router.push('/wishlist/day-picker/$sessionId');
  return true;
}

Future<void> _openPlanMetVriendMatchFromSession({
  required GoRouter router,
  required WidgetRef ref,
  required String sessionId,
  required String inviteId,
}) async {
  final service = PlanMetVriendService(Supabase.instance.client);
  final session = await service.fetchSession(sessionId);
  final invite = await service.fetchInvite(inviteId);
  if (session == null || invite == null) {
    router.go('/wishlist');
    return;
  }
  final planned = session['planned_date']?.toString();
  final d = planned != null ? DateTime.tryParse(planned) : null;
  if (d == null) {
    router.go('/wishlist');
    return;
  }
  final inviterId = invite['inviter_user_id'] as String;
  final uid = Supabase.instance.client.auth.currentUser?.id;
  final friendId = uid == inviterId
      ? invite['invitee_user_id'] as String
      : inviterId;
  final profile = await service.fetchProfile(friendId);
  final args = PlanMetVriendMatchArgs(
    sessionId: sessionId,
    inviteId: inviteId,
    friend: PlanMetVriendFriend(
      userId: friendId,
      displayName: profile['displayName'] ?? 'Je vriend',
      username: profile['username'],
      avatarUrl: profile['avatarUrl'],
    ),
    place: PlanMetVriendPlace(
      placeId: invite['place_id'] as String,
      placeName: invite['place_name'] as String,
      placeData: Map<String, dynamic>.from(
        invite['place_data'] as Map? ?? {},
      ),
    ),
    matchedDate: DateTime(d.year, d.month, d.day),
  );
  final ctx = rootNavigatorKey.currentContext;
  if (ctx != null) {
    openMatchFound(ctx, args);
  } else {
    router.push('/wishlist/match-found', extra: args);
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
          // Same resume rules as Updates taps (no [BuildContext] for OS toast).
          unawaited(
            _navigateMoodMatchFromNotificationData(
              router: router,
              ref: ref,
              sessionId: sessionId,
              snackContext: null,
              intent: _MmNotifIntent.lobbyish,
            ),
          );
        }
        break;
      }
      if (kDebugMode) {
        debugPrint('Unknown notification payload: $payload');
      }
  }
}
