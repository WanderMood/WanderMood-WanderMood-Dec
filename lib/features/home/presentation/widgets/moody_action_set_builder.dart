import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/home/presentation/providers/moody_hub_state_provider.dart';
import 'package:wandermood/features/home/presentation/screens/main_screen.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_action.dart';
import 'package:wandermood/features/home/presentation/widgets/mood_change_plan_bottom_sheet.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pure function: given hub state + l10n + a navigator handle, returns the
/// deterministic action list for the pill row.
///
/// Rules (source of truth — do not special-case in widgets):
///   * `empty_day`  → Plan / Find coffee / Get me active  + Mood Match*
///   * `active_day` → Change mood (primary card) / Mood Match / Find coffee /
///     Get me active (no duplicate Change mood chip; Replace removed here)
///   * Mood Match is suppressed when [MoodyMatchState.sharedReady] or
///     [MoodyMatchState.invite] — the pinned card owns that CTA.
///   * Mood Match label adapts to match state (none/available/sharedReady).
///
/// Chip onTap is always navigation. NEVER seeds the composer, NEVER injects
/// text into chat. This is the contract that lets the pill row stay stable
/// while the user chats freely.
List<MoodyAction> buildMoodyActions({
  required BuildContext context,
  required WidgetRef ref,
  required MoodyHubState state,
  required AppLocalizations l10n,
  void Function(String)? onChat,
}) {
  void goExplore() {
    ref.read(mainTabProvider.notifier).state = 1;
    context.go('/main?tab=1');
  }

  void openMoodyStandalone() => context.pushNamed('moody-standalone');

  void openChangeMoodBottomSheet() {
    unawaited(showMoodChangePlanBottomSheet(context, ref));
  }

  void openMoodMatch() => routeMoodMatch(context, state.match);

  final matchAction = MoodyAction(
    id: MoodyActionId.moodMatch,
    emoji: '🫶',
    label: switch (state.match.state) {
      MoodyMatchState.none => l10n.moodMatchHubCtaStart,
      MoodyMatchState.available => l10n.moodyHubMoodMatchViewMatches,
      MoodyMatchState.sharedReady => l10n.moodMatchHubCtaOpenShared,
      MoodyMatchState.invite => l10n.moodyHubMoodMatchInviteCta,
    },
    tone: MoodyActionTone.accent,
    onTap: openMoodMatch,
  );

  final bool moodMatchSuppressed = state.match.state == MoodyMatchState.sharedReady ||
      state.match.state == MoodyMatchState.invite;

  switch (state.day) {
    case MoodyDayState.empty:
      return [
        MoodyAction(
          id: MoodyActionId.planWholeDay,
          emoji: '✨',
          label: l10n.noPlanPlanMyWholeDay,
          tone: MoodyActionTone.primary,
          onTap: openMoodyStandalone,
        ),
        if (!moodMatchSuppressed) matchAction,
        MoodyAction(
          id: MoodyActionId.findCoffee,
          emoji: '☕',
          label: l10n.moodyHubActionFindCoffee,
          tone: MoodyActionTone.neutral,
          onTap: () {
            if (onChat != null) {
              onChat(l10n.moodyHubActionFindCoffee);
            } else {
              goExplore();
            }
          },
        ),
        MoodyAction(
          id: MoodyActionId.getMeActive,
          emoji: '🏃',
          label: l10n.moodyHubActionGetMeActive,
          tone: MoodyActionTone.neutral,
          onTap: () {
            if (onChat != null) {
              onChat(l10n.moodyHubActionGetMeActive);
            } else {
              goExplore();
            }
          },
        ),
      ];
    case MoodyDayState.active:
      return [
        MoodyAction(
          id: MoodyActionId.changeMood,
          emoji: '🎨',
          label: l10n.moodyHubChangeMood,
          tone: MoodyActionTone.primary,
          onTap: openChangeMoodBottomSheet,
        ),
        if (!moodMatchSuppressed) matchAction,
        MoodyAction(
          id: MoodyActionId.findCoffee,
          emoji: '☕',
          label: l10n.moodyHubActionFindCoffee,
          tone: MoodyActionTone.neutral,
          onTap: () {
            if (onChat != null) {
              onChat(l10n.moodyHubActionFindCoffee);
            } else {
              goExplore();
            }
          },
        ),
        MoodyAction(
          id: MoodyActionId.getMeActive,
          emoji: '🏃',
          label: l10n.moodyHubActionGetMeActive,
          tone: MoodyActionTone.neutral,
          onTap: () {
            if (onChat != null) {
              onChat(l10n.moodyHubActionGetMeActive);
            } else {
              goExplore();
            }
          },
        ),
      ];
  }
}

/// Shared router logic for the Mood Match slot — ported from
/// `_MoodMatchHubCardState._openMoodMatch` so the banner, the pill, and the
/// legacy card all route identically.
void routeMoodMatch(BuildContext context, MoodyMatchSnapshot snapshot) {
  if (snapshot.state == MoodyMatchState.invite) {
    context.go('/group-planning');
    return;
  }
  final GroupSessionRow? session = snapshot.session;
  if (session == null) {
    context.go('/group-planning');
    return;
  }
  if (session.completedAt != null || snapshot.hasPlan) {
    context.go('/group-planning/result/${session.id}');
    return;
  }
  if (session.status == 'day_proposed' ||
      session.status == 'day_counter_proposed') {
    context.go('/group-planning/day-picker/${session.id}');
    return;
  }
  if (session.status == 'generating' ||
      session.status == 'ready' ||
      session.status == 'day_confirmed') {
    context.go('/group-planning/match-loading/${session.id}');
    return;
  }
  context.go('/group-planning/lobby/${session.id}');
}
