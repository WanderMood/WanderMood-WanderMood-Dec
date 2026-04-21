import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';

/// Day-planning axis: does the user currently have any live activities?
enum MoodyDayState { empty, active }

/// Mood Match axis: what is the most actionable shared-planning state?
///
/// `pending` (invitation sent, not yet accepted) is reserved for a future
/// iteration; the backend currently doesn't distinguish invited-but-not-joined
/// separately enough to surface it as its own UI state.
enum MoodyMatchState {
  none,
  available,
  /// Shared plan exists and the user has not added it to My Day yet — "Open shared plan".
  sharedReady,
  /// Last match is on the user's plan or the session is done — hub shows invite copy, not "open plan".
  invite,
}

/// Snapshot passed to the action builder + pinned banner. Carries enough of
/// the underlying session so navigation callbacks can route to the correct
/// group-planning subroute without re-fetching.
class MoodyMatchSnapshot {
  const MoodyMatchSnapshot({
    required this.state,
    this.session,
    this.hasPlan = false,
    this.partnerFirstName,
    this.totalActive = 0,
  });

  const MoodyMatchSnapshot.none()
      : state = MoodyMatchState.none,
        session = null,
        hasPlan = false,
        partnerFirstName = null,
        totalActive = 0;

  final MoodyMatchState state;
  final GroupSessionRow? session;
  final bool hasPlan;
  final String? partnerFirstName;
  final int totalActive;
}

/// Composed hub state consumed by the pill row, the pinned Mood Match banner,
/// and the intro hero. Independent of anything in the chat thread — the whole
/// point of the refactor is that this provider never reads chat messages.
class MoodyHubState {
  const MoodyHubState({
    required this.day,
    required this.match,
  });

  const MoodyHubState.empty()
      : day = MoodyDayState.empty,
        match = const MoodyMatchSnapshot.none();

  final MoodyDayState day;
  final MoodyMatchSnapshot match;
}

/// Primary axis — derived from `todayActivitiesProvider`. Any non-cancelled
/// activity flips this to `active`.
final moodyDayStateProvider = Provider.autoDispose<AsyncValue<MoodyDayState>>(
  (ref) {
    final activities = ref.watch(todayActivitiesProvider);
    return activities.whenData((list) {
      final hasAny = list.any((a) => a.status != ActivityStatus.cancelled);
      return hasAny ? MoodyDayState.active : MoodyDayState.empty;
    });
  },
);

/// Secondary axis — derived from the same repo `MoodMatchHubCard` uses. The
/// priority ordering matches that card so the banner/pill surface the same
/// session as the legacy widget.
final moodyMatchSnapshotProvider =
    FutureProvider.autoDispose<MoodyMatchSnapshot>((ref) async {
  final repo = ref.watch(groupPlanningRepositoryProvider);
  final rows = await repo.fetchActiveSessionsForUser();
  if (rows.isEmpty) return const MoodyMatchSnapshot.none();

  // Third-layer "saved" check: local SharedPreferences flag written immediately
  // after a successful insert. Reliable even when DB columns are absent.
  final sessionIds = rows.map((r) => r.session.id).toList();
  final locallySaved = await MoodMatchSessionPrefs.savedToMyDayIds(sessionIds);

  int priority(
    ({
      GroupSessionRow session,
      bool hasPlan,
      Map<String, dynamic>? planData,
      bool savedToMyDay,
    }) r,
  ) {
    final s = r.session.status;
    if (s == 'day_proposed' || s == 'day_counter_proposed') return 5;
    if (r.hasPlan && r.session.completedAt == null) return 4;
    if (s == 'generating' || s == 'ready' || s == 'day_confirmed') return 3;
    if (s == 'waiting') return 2;
    return 1;
  }

  final sorted = [...rows]..sort((a, b) {
      final cmp = priority(b).compareTo(priority(a));
      if (cmp != 0) return cmp;
      return b.session.updatedAt.compareTo(a.session.updatedAt);
    });

  bool isSaved(({
    GroupSessionRow session,
    bool hasPlan,
    Map<String, dynamic>? planData,
    bool savedToMyDay,
  }) r) =>
      r.savedToMyDay ||
      r.session.completedAt != null ||
      locallySaved.contains(r.session.id);

  // 1) Actionable shared plan — not yet saved to My Day.
  ({
    GroupSessionRow session,
    bool hasPlan,
    Map<String, dynamic>? planData,
    bool savedToMyDay,
  })? sharedReadyRow;
  for (final r in sorted) {
    if (r.hasPlan && !isSaved(r)) {
      sharedReadyRow = r;
      break;
    }
  }

  // 2) In-flight session (lobby / generating / …) without a completed add-to-day flow.
  ({
    GroupSessionRow session,
    bool hasPlan,
    Map<String, dynamic>? planData,
    bool savedToMyDay,
  })? availableRow;
  for (final r in sorted) {
    if (!isSaved(r)) {
      availableRow = r;
      break;
    }
  }

  // 3) Everything in the list is already on My Day or closed — invite a new Mood Match.
  final top = sorted.first;

  final MoodyMatchState state;
  if (sharedReadyRow != null) {
    state = MoodyMatchState.sharedReady;
  } else if (availableRow != null) {
    state = MoodyMatchState.available;
  } else {
    state = MoodyMatchState.invite;
  }

  final pick = sharedReadyRow ?? availableRow ?? top;

  // Best-effort partner name — matches `MoodMatchHubCard` behaviour. Swallow
  // errors so a flaky profile fetch never blocks the hub from rendering.
  String? partnerFirstName;
  try {
    final me = Supabase.instance.client.auth.currentUser?.id;
    final members = await repo.fetchMembersWithProfiles(pick.session.id);
    if (members.isNotEmpty) {
      final other = members.firstWhere(
        (GroupMemberView m) => me == null || m.member.userId != me,
        orElse: () => members.first,
      );
      partnerFirstName = _firstName(other.displayName);
    }
  } catch (_) {
    // Fall back to nameless copy.
  }

  return MoodyMatchSnapshot(
    state: state,
    session: pick.session,
    hasPlan: pick.hasPlan,
    partnerFirstName: partnerFirstName,
    totalActive: rows.length,
  );
});

/// Composed state consumed by widgets. Emits `AsyncValue.data` as soon as the
/// day axis is ready — the match axis falls back to `none` while loading so
/// the hub can render immediately and upgrade when the snapshot resolves.
final moodyHubStateProvider = Provider.autoDispose<AsyncValue<MoodyHubState>>(
  (ref) {
    final day = ref.watch(moodyDayStateProvider);
    final match = ref.watch(moodyMatchSnapshotProvider);

    return day.when(
      loading: () => const AsyncValue.loading(),
      error: AsyncValue.error,
      data: (dayState) {
        final matchSnapshot = match.maybeWhen(
          data: (s) => s,
          orElse: () => const MoodyMatchSnapshot.none(),
        );
        return AsyncValue.data(
          MoodyHubState(day: dayState, match: matchSnapshot),
        );
      },
    );
  },
);

String? _firstName(String displayName) {
  final t = displayName.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('@')) return t;
  final parts = t.split(RegExp(r'\s+'));
  return parts.isNotEmpty ? parts.first : t;
}
