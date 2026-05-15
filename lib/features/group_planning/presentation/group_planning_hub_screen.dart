import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/group_planning/data/mood_match_invite_inbox_entry.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/group_planning_deep_link.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_v2.dart';
import 'package:wandermood/features/group_planning/domain/group_planning_mode.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/group_planning/presentation/share_sheet_origin.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

/// Rounded shape + accent hairline; shadow comes from [Material.elevation] for
/// smooth corners (avoids “pointy” box-shadow artifacts on large radii).
ShapeBorder _hubSessionMaterialShape({required bool planReady}) {
  const forest = GroupPlanningUi.forest;
  const orange = GroupPlanningUi.moodMatchTabActiveOrange;
  final accent = planReady ? orange : forest;
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(28),
    side: BorderSide(color: accent.withValues(alpha: 0.2), width: 1),
  );
}

/// Brown pill + white label + arrow — shared hub primary CTA (invite, resume,
/// see plan, open My Day).
///
/// [stretch] true: full-width bar (e.g. Join on invite). false: intrinsic width,
/// slightly smaller padding/type — pair with [Row] `end` alignment on cards.
class _HubPrimaryPillButton extends StatelessWidget {
  const _HubPrimaryPillButton({
    required this.label,
    required this.onPressed,
    this.showTrailingArrow = true,
    this.leading,
    this.stretch = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showTrailingArrow;
  final Widget? leading;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final showArrow = showTrailingArrow && onPressed != null && leading == null;
    final vPad = stretch ? 14.0 : 10.0;
    final hPad = stretch ? 20.0 : 16.0;
    final fontSize = stretch ? 14.0 : 13.0;
    final iconSize = stretch ? 18.0 : 16.0;

    final textStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      color: Colors.white,
    );

    final labelWidget = stretch
        ? Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          )
        : Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          );

    final row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: stretch ? 10 : 8),
        ],
        labelWidget,
        if (showArrow) ...[
          SizedBox(width: stretch ? 8 : 6),
          Icon(
            Icons.arrow_forward_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        ],
      ],
    );

    final pill = Material(
      color: GroupPlanningUi.forest,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
          child: row,
        ),
      ),
    );

    if (stretch) {
      return SizedBox(width: double.infinity, child: pill);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: IntrinsicWidth(child: pill),
    );
  }
}

/// Day handshake before shared plan generation (day picker owns both).
bool _hubSessionIsDayNegotiation(String status) =>
    status == 'day_proposed' || status == 'day_counter_proposed';

String _hubFriendFirstName(GroupMemberView? v, AppLocalizations l10n) {
  if (v == null) return l10n.moodMatchFriendThey;
  final n = v.displayName.trim();
  if (n.isEmpty) return l10n.moodMatchFriendThey;
  return n.split(RegExp(r'\s+')).first;
}

/// Badge + story + primary CTA for in-progress (non–plan-ready) hub cards.
({String badge, String body, String primaryCta, bool showNudge})
    _hubInProgressCardModel(
  AppLocalizations l10n,
  String uid,
  _HubSessionItem item,
) {
  final s = item.session;
  final owner = item.owner;
  final guest = item.guest;
  final GroupMemberView? me = owner?.member.userId == uid ? owner : guest;
  final GroupMemberView? friend = owner?.member.userId == uid ? guest : owner;
  final friendName = _hubFriendFirstName(friend, l10n);

  if (guest == null) {
    return (
      badge: l10n.moodMatchHubPendingWaiting,
      body: l10n.moodMatchHubStatusNeedGuest,
      primaryCta: l10n.moodMatchHubContinueSession,
      showNudge: true,
    );
  }

  if (_hubSessionIsDayNegotiation(s.status)) {
    final prop = s.proposedByUserId?.trim() ?? '';
    if (prop == uid) {
      return (
        badge: l10n.moodMatchHubPendingWaiting,
        body: l10n.moodMatchHubCardBodyDayWaitingOnThem(friendName),
        primaryCta: l10n.moodMatchHubCardCtaReviewDay,
        showNudge: false,
      );
    }
    return (
      badge: l10n.moodMatchHubCardInfoNextStep,
      body: l10n.moodMatchHubCardBodyDayTheirPick(friendName),
      primaryCta: l10n.moodMatchHubCardCtaReviewDay,
      showNudge: false,
    );
  }

  if (s.status == 'generating' ||
      s.status == 'ready' ||
      s.status == 'day_confirmed') {
    return (
      badge: l10n.moodMatchHubPendingBuilding,
      body: l10n.moodMatchHubStatusGenerating,
      primaryCta: l10n.moodMatchHubCardCtaCheckProgress,
      showNudge: false,
    );
  }

  if (s.status == 'waiting') {
    final meSubmitted = me?.member.hasSubmittedMood ?? false;
    final themSubmitted = friend?.member.hasSubmittedMood ?? false;
    if (!meSubmitted) {
      return (
        badge: l10n.moodMatchHubCardInfoPickingMood,
        body: l10n.moodMatchHubCardBodyPickYourMood,
        primaryCta: l10n.moodMatchHubContinueSession,
        showNudge: false,
      );
    }
    if (!themSubmitted) {
      return (
        badge: l10n.moodMatchHubCardBadgeWaitingFor(friendName),
        body: l10n.moodMatchHubStatusNeedMood,
        primaryCta: l10n.moodMatchHubContinueSession,
        showNudge: true,
      );
    }
    return (
      badge: l10n.moodMatchHubCardInfoNextStep,
      body: l10n.moodMatchHubStatusNeedDay,
      primaryCta: l10n.moodMatchHubContinueSession,
      showNudge: false,
    );
  }

  return (
    badge: l10n.moodMatchHubPendingTitle,
    body: l10n.moodMatchHubPendingResumeStory,
    primaryCta: l10n.moodMatchHubContinueSession,
    showNudge: true,
  );
}

GroupMemberView? _hubOtherMember(String uid, _HubSessionItem item) {
  final owner = item.owner;
  final guest = item.guest;
  if (owner?.member.userId == uid) return guest;
  return owner;
}

/// True when the hub should show the orange “ready / see the plan” card.
/// Requires a shared plan row **and** guest-side confirmations for every
/// filled slot — not merely `group_plans` existing (owner may still be
/// drafting or waiting on their friend after “send to guest”).
bool _hubShouldUseReadyResumeCard(_HubSessionItem item) {
  if (!item.hasPlan || item.planData == null) return false;
  if (_hubSessionIsDayNegotiation(item.session.status)) return false;
  final p =
      GroupPlanV2.normalizePlanData(Map<String, dynamic>.from(item.planData!));
  if (p['sentToGuest'] != true) return false;
  final need = GroupPlanV2.slotsRequiringConfirmation(p);
  final gc = GroupPlanV2.boolSlotMap(p['guestConfirmed']);
  for (final slot in need) {
    if (gc[slot] != true) return false;
  }
  return true;
}

({String badge, String body, String cta, bool showNudge})? _hubPlanPhaseCopy(
  AppLocalizations l10n,
  String uid,
  _HubSessionItem item,
) {
  if (!item.hasPlan || item.planData == null) return null;
  if (_hubSessionIsDayNegotiation(item.session.status)) return null;
  final p =
      GroupPlanV2.normalizePlanData(Map<String, dynamic>.from(item.planData!));
  final friendName = _hubFriendFirstName(_hubOtherMember(uid, item), l10n);
  if (p['sentToGuest'] != true) {
    return (
      badge: l10n.moodMatchHubPlanDraftingBadge,
      body: l10n.moodMatchHubPlanDraftingBody(friendName),
      cta: l10n.moodMatchHubOpenPlan,
      showNudge: false,
    );
  }
  final need = GroupPlanV2.slotsRequiringConfirmation(p);
  final gc = GroupPlanV2.boolSlotMap(p['guestConfirmed']);
  final allGuest = need.every((s) => gc[s] == true);
  if (allGuest) return null;
  final isOwner = item.session.createdBy == uid;
  if (isOwner) {
    return (
      badge: l10n.moodMatchHubCardBadgeWaitingFor(friendName),
      body: l10n.moodMatchHubOwnerWaitingGuestReviewBody(friendName),
      cta: l10n.moodMatchHubOpenPlan,
      showNudge: false,
    );
  }
  return (
    badge: l10n.moodMatchHubGuestReviewBadge,
    body: l10n.moodMatchHubGuestReviewBody(friendName),
    cta: l10n.moodMatchHubCtaReviewPlan,
    showNudge: false,
  );
}

/// Mood Match entry — forest header, cream body, staggered entry motion.
class GroupPlanningHubScreen extends ConsumerStatefulWidget {
  const GroupPlanningHubScreen({super.key});

  @override
  ConsumerState<GroupPlanningHubScreen> createState() =>
      _GroupPlanningHubScreenState();
}

class _HubSessionItem {
  const _HubSessionItem({
    required this.session,
    required this.hasPlan,
    this.planData,
    required this.savedToMyDay,
    this.owner,
    this.guest,
  });

  final GroupSessionRow session;
  final bool hasPlan;

  /// Normalized [GroupPlanV2] payload when a `group_plans` row exists.
  final Map<String, dynamic>? planData;

  /// This user already ran Add to My Day for this session.
  final bool savedToMyDay;
  final GroupMemberView? owner;
  final GroupMemberView? guest;
}

class _GroupPlanningHubScreenState extends ConsumerState<GroupPlanningHubScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  final GlobalKey _resumeShareKey = GlobalKey();

  bool _checkingActive = true;
  List<_HubSessionItem> _activeSessions = const [];
  List<MoodMatchInviteInboxEntry> _pendingInvites = const [];
  RealtimeChannel? _inviteChannel;
  String? _joiningInviteEventId;
  DateTime? _lastActiveCheckAt;

  /// 0 = Active (in progress), 1 = Completed (saved to My Day).
  int _hubSessionTab = 0;

  bool _pendingInvitesExpanded = true;
  late final PageController _invitePageController;
  int _inviteCarouselIndex = 0;

  // Fixed height for the PageView carousel — sized to the invite card's
  // natural content (avatar row + title/weekday + ~3-line body + CTA) so
  // there's no dead whitespace under the button when there are 2+ invites.
  // Extra 8px to give the layered drop-shadow room to breathe without
  // getting clipped by the PageView viewport.
  static const double _inviteCarouselHeight = 224;

  @override
  void initState() {
    super.initState();
    _invitePageController = PageController(viewportFraction: 0.94);
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) _entry.forward();
      await _checkActiveSession();
      _subscribeInvitesOnce();
    });
  }

  void _subscribeInvitesOnce() {
    if (_inviteChannel != null) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final repo = ref.read(groupPlanningRepositoryProvider);
    _inviteChannel = repo.subscribeToIncomingRealtimeEvents(
      onInsert: () {
        if (mounted) _checkActiveSession();
      },
    );
  }

  List<MoodMatchInviteInboxEntry> _dedupeInvites(
      List<MoodMatchInviteInboxEntry> raw) {
    final bySession = <String, MoodMatchInviteInboxEntry>{};
    for (final e in raw) {
      final existing = bySession[e.sessionId];
      if (existing == null || e.createdAt.isAfter(existing.createdAt)) {
        bySession[e.sessionId] = e;
      }
    }
    final out = bySession.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When returning from Lobby/Result via tab switch or navigator, the widget may
    // stay mounted. Re-check so we show the pending/ready card instead of the
    // default start/join buttons.
    final now = DateTime.now();
    final last = _lastActiveCheckAt;
    if (last == null ||
        now.difference(last) > const Duration(milliseconds: 800)) {
      _lastActiveCheckAt = now;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkActiveSession());
    }
  }

  @override
  void dispose() {
    final ch = _inviteChannel;
    if (ch != null) {
      Supabase.instance.client.removeChannel(ch);
      _inviteChannel = null;
    }
    _invitePageController.dispose();
    _entry.dispose();
    super.dispose();
  }

  Future<void> _checkActiveSession() async {
    if (!mounted) return;
    _lastActiveCheckAt = DateTime.now();
    setState(() => _checkingActive = true);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _checkingActive = false;
          _activeSessions = const [];
        });
      }
      return;
    }
    final repo = ref.read(groupPlanningRepositoryProvider);
    List<MoodMatchInviteInboxEntry> invites = const [];
    try {
      invites = await repo.fetchPendingMoodMatchInvites();
    } catch (e, st) {
      // Invites are a non-blocking enhancement, so we don't surface a SnackBar
      // — but keep developer visibility instead of a total silence.
      debugPrint('[Hub] fetchPendingMoodMatchInvites failed: $e\n$st');
    }
    invites = _dedupeInvites(invites);

    final rows = await () async {
      try {
        return await repo.fetchActiveSessionsForUser();
      } catch (e, st) {
        debugPrint('[Hub] fetchActiveSessionsForUser failed: $e\n$st');
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            GroupPlanningUi.showErrorSnack(
              context,
              l10n,
              e,
              onRetry: _checkActiveSession,
            );
          }
        }
        return null;
      }
    }();
    if (rows == null) {
      if (mounted) {
        setState(() {
          _checkingActive = false;
        });
      }
      return;
    }
    final items = <_HubSessionItem>[];
    for (final row in rows) {
      GroupMemberView? owner;
      GroupMemberView? guest;
      try {
        final members = await repo.fetchMembersWithProfiles(row.session.id);
        // Owner = session creator. Guest = any other member (Mood Match is 2-up).
        // Do NOT branch on `uid == m` for `owner ??= m` — when the viewer is the
        // guest and `members` is ordered [owner, guest], that branch skipped the
        // real `else { guest = m }` path and left `guest` null (second avatar "?").
        for (final m in members) {
          if (m.member.userId == row.session.createdBy) {
            owner = m;
          } else {
            guest ??= m;
          }
        }
      } catch (e, st) {
        debugPrint(
          '[Hub] fetchMembersWithProfiles(${row.session.id}) failed: $e\n$st',
        );
      }
      items.add(
        _HubSessionItem(
          session: row.session,
          hasPlan: row.hasPlan,
          planData: row.planData,
          savedToMyDay: row.savedToMyDay,
          owner: owner,
          guest: guest,
        ),
      );
    }
    if (!mounted) return;
    final activeSessionIds = items.map((e) => e.session.id).toSet();
    invites = invites
        .where((i) => !activeSessionIds.contains(i.sessionId))
        .toList(growable: false);

    final resumeItems = items.where((e) => !e.savedToMyDay).toList();
    if (resumeItems.isNotEmpty) {
      await MoodMatchSessionPrefs.save(
        sessionId: resumeItems.first.session.id,
        joinCode: resumeItems.first.session.joinCode,
      );
    } else {
      await MoodMatchSessionPrefs.clear();
    }
    setState(() {
      _checkingActive = false;
      _activeSessions = items;
      _pendingInvites = invites;
      _inviteCarouselIndex = 0;
      final activeCount = items.where((e) => !e.savedToMyDay).length;
      final completedCount = items.where((e) => e.savedToMyDay).length;
      if (activeCount == 0 && completedCount > 0) {
        _hubSessionTab = 1;
      } else if (completedCount == 0) {
        _hubSessionTab = 0;
      }
    });
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_invitePageController.hasClients) {
          _invitePageController.jumpToPage(0);
        }
      });
    }
  }

  Future<void> _confirmDismissInvite(MoodMatchInviteInboxEntry e) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.moodMatchHubConfirmDismissInviteTitle),
        content: Text(l10n.moodMatchHubConfirmDismissInviteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.moodMatchHubConfirmRemoveAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = ref.read(groupPlanningRepositoryProvider);
    await repo.markMoodMatchInviteRead(e.eventId);
    if (!mounted) return;
    setState(() {
      _pendingInvites =
          _pendingInvites.where((x) => x.eventId != e.eventId).toList();
    });
  }

  Future<void> _onJoinInvite(MoodMatchInviteInboxEntry e) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _joiningInviteEventId = e.eventId);
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final id = await repo.joinSession(e.joinCode);
      await repo.markMoodMatchInviteRead(e.eventId);
      await MoodMatchSessionPrefs.save(
        sessionId: id,
        joinCode: e.joinCode.trim().toUpperCase(),
      );
      if (!mounted) return;
      setState(() {
        _joiningInviteEventId = null;
        _pendingInvites =
            _pendingInvites.where((x) => x.eventId != e.eventId).toList();
      });
      await _checkActiveSession();
      if (!mounted) return;
      context.go(
        '/group-planning/lobby/$id',
        extra: {'joinCode': e.joinCode.trim().toUpperCase()},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _joiningInviteEventId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.moodMatchInviteInboxJoinError)),
      );
    }
  }

  Future<void> _confirmRemoveOngoingSession(GroupSessionRow s) async {
    final l10n = AppLocalizations.of(context)!;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final isHost = uid != null && s.createdBy == uid;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.moodMatchHubConfirmLeaveSessionTitle),
        content: Text(
          isHost
              ? l10n.moodMatchHubConfirmLeaveSessionBodyHost
              : l10n.moodMatchHubConfirmLeaveSessionBodyGuest,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.moodMatchHubConfirmRemoveAction),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _onCancelResume(l10n, s);
  }

  Future<void> _onCancelResume(AppLocalizations l10n, GroupSessionRow s) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final repo = ref.read(groupPlanningRepositoryProvider);
    try {
      if (s.createdBy == uid) {
        await repo.deleteSession(s.id);
      } else {
        await repo.removeSelfFromSession(s.id);
      }
      await MoodMatchSessionPrefs.clear();
      if (!mounted) return;
      await _checkActiveSession();
      if (mounted) {
        showWanderMoodToast(
          context,
          message: s.createdBy == uid
              ? l10n.moodMatchHubLeaveSuccessHostToast
              : l10n.moodMatchHubLeaveSuccessGuestToast,
        );
      }
    } catch (e) {
      if (mounted) {
        GroupPlanningUi.showErrorSnack(
          context,
          l10n,
          e,
          fallback: l10n.moodMatchHubCancelError(''),
        );
      }
    }
  }

  void _openSession(_HubSessionItem item) {
    final s = item.session;
    final isPlaceTogether = item.planData != null &&
        groupPlanningModeFromPlanData(item.planData!) ==
            GroupPlanningMode.placeTogether;
    // Explore "Plan together" seeds `group_plans` immediately; only Mood
    // Match should jump straight to result when a plan row exists.
    if (item.hasPlan && !isPlaceTogether) {
      context.go('/group-planning/result/${s.id}');
      return;
    }
    if (_hubSessionIsDayNegotiation(s.status)) {
      context.go('/group-planning/day-picker/${s.id}');
      return;
    }
    if (!isPlaceTogether &&
        (s.status == 'generating' ||
            s.status == 'ready' ||
            s.status == 'day_confirmed')) {
      context.go('/group-planning/match-loading/${s.id}');
      return;
    }
    if (isPlaceTogether &&
        (s.status == 'ready' || s.status == 'day_confirmed')) {
      context.go('/group-planning/result/${s.id}');
      return;
    }
    context.go(
      '/group-planning/lobby/${s.id}',
      extra: {'joinCode': s.joinCode},
    );
  }

  Future<void> _shareResume({
    required AppLocalizations l10n,
    required String joinCode,
    required bool isReminder,
  }) async {
    final codeUpper = joinCode.trim().toUpperCase();
    final joinLink = groupPlanningJoinShareLink(codeUpper).toString();
    final text = isReminder
        ? '👀 ${l10n.moodMatchInviteShare(codeUpper)}\n$joinLink'
        : '${l10n.moodMatchInviteShare(codeUpper)}\n$joinLink';

    final origin = sharePositionOriginForContext(
      _resumeShareKey.currentContext ?? context,
    );
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: l10n.groupPlanShareSubject,
          sharePositionOrigin: origin,
        ),
      );
    } catch (e, st) {
      // Most share failures here are user-initiated dismissals of the iOS/
      // Android share sheet — we don't surface a toast for those. We still
      // log so genuine platform errors are visible in development.
      debugPrint('[Hub] SharePlus invite failed: $e\n$st');
    }
  }

  String _sessionDisplayTitle(AppLocalizations l10n, GroupSessionRow s) {
    final t = s.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    return l10n.moodMatchHubUntitledSession;
  }

  Widget _pendingOngoingHubCard(
    AppLocalizations l10n,
    String uid,
    _HubSessionItem item, {
    String? statusBadge,
    String? statusBody,
    String? primaryCta,
    bool? showNudge,
  }) {
    final copy = _hubInProgressCardModel(l10n, uid, item);
    return _PendingResumeCard(
      l10n: l10n,
      sessionTitle: _sessionDisplayTitle(l10n, item.session),
      planReady: false,
      joinCode: item.session.joinCode,
      statusBadge: statusBadge ?? copy.badge,
      statusBody: statusBody ?? copy.body,
      primaryCta: primaryCta ?? copy.primaryCta,
      showNudge: showNudge ?? copy.showNudge,
      onContinue: () => _openSession(item),
      onNudgeFriend: () => _shareResume(
        l10n: l10n,
        joinCode: item.session.joinCode,
        isReminder: true,
      ),
      onCancel: () => _confirmRemoveOngoingSession(item.session),
      ownerAvatarUrl: item.owner?.avatarUrl,
      guestAvatarUrl: item.guest?.avatarUrl,
    );
  }

  Widget _ongoingActiveResumeCard(
    AppLocalizations l10n,
    String uid,
    _HubSessionItem item,
  ) {
    if (_hubShouldUseReadyResumeCard(item)) {
      return _ReadyResumeCard(
        l10n: l10n,
        sessionTitle: _sessionDisplayTitle(l10n, item.session),
        onSeePlan: () => _openSession(item),
        onRemove: () => _confirmRemoveOngoingSession(item.session),
        ownerAvatarUrl: item.owner?.avatarUrl,
        guestAvatarUrl: item.guest?.avatarUrl,
      );
    }
    final phase = _hubPlanPhaseCopy(l10n, uid, item);
    return _pendingOngoingHubCard(
      l10n,
      uid,
      item,
      statusBadge: phase?.badge,
      statusBody: phase?.body,
      primaryCta: phase?.cta,
      showNudge: phase?.showNudge,
    );
  }

  void _openMyDayForSession(GroupSessionRow s) {
    final raw = s.plannedDate?.trim();
    final extra = <String, dynamic>{};
    if (raw != null && raw.isNotEmpty && DateTime.tryParse(raw) != null) {
      extra['targetDate'] = raw;
    }
    context.go('/main?tab=0', extra: extra.isEmpty ? null : extra);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final charCurve = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.2, 0.5, curve: Curves.elasticOut),
    );
    final card1 = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.35, 0.72, curve: Curves.easeOutCubic),
    );
    final card2 = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.45, 0.82, curve: Curves.easeOutCubic),
    );

    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    final safeTop = MediaQuery.paddingOf(context).top;
    const sheetOverlap = 26.0;
    const sheetTopRadius = 28.0;
    final heroHeight = safeTop + 286.0;
    final hubActive =
        _activeSessions.where((e) => !e.savedToMyDay).toList(growable: false);
    final hubCompleted =
        _activeSessions.where((e) => e.savedToMyDay).toList(growable: false);

    return Scaffold(
      backgroundColor: GroupPlanningUi.moodMatchDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight + sheetOverlap,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GroupPlanningUi.moodMatchDeepSurface,
                    GroupPlanningUi.moodMatchDeep,
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, safeTop + 52, 16, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0, end: 1).animate(charCurve),
                      child: Container(
                        width: 86,
                        height: 86,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFBFD8FF)
                                  .withValues(alpha: 0.2),
                              blurRadius: 14,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const MoodyCharacter(
                          size: 56,
                          mood: 'happy',
                          glowOpacityScale: 0.42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.moodMatchTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        l10n.moodMatchHubMoodyHeroLine1,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        l10n.moodMatchHubMoodyHeroLine2,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.72),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: heroHeight - sheetOverlap,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(sheetTopRadius),
              ),
              child: Material(
                color: GroupPlanningUi.cream,
                elevation: 14,
                shadowColor:
                    GroupPlanningUi.moodMatchDeep.withValues(alpha: 0.22),
                surfaceTintColor: Colors.transparent,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color:
                                GroupPlanningUi.stone.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      FadeTransition(
                        opacity: card1,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ).animate(card1),
                          child: _ActionCard(
                            iconBg: const Color(0xFFEBF3EE),
                            emoji: '✨',
                            title: l10n.moodMatchStartBtn,
                            subtitle: l10n.moodMatchStartBtnSub,
                            onTap: () => context.push('/group-planning/create'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: card2,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ).animate(card2),
                          child: _ActionCard(
                            iconBg: const Color(0xFFFFF0E8),
                            emoji: '🔗',
                            title: l10n.moodMatchJoinBtn,
                            subtitle: l10n.moodMatchJoinBtnSub,
                            onTap: () => context.push('/group-planning/join'),
                          ),
                        ),
                      ),
                      if (!_checkingActive && _pendingInvites.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Material(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => setState(() {
                              _pendingInvitesExpanded =
                                  !_pendingInvitesExpanded;
                            }),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.moodMatchHubInvitesTitle,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.1,
                                            color: GroupPlanningUi.forest,
                                          ),
                                        ),
                                      ),
                                      if (_pendingInvites.length > 1)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 4),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: GroupPlanningUi.forest
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '${_pendingInvites.length}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: GroupPlanningUi.forest,
                                              ),
                                            ),
                                          ),
                                        ),
                                      AnimatedRotation(
                                        turns:
                                            _pendingInvitesExpanded ? 0.5 : 0,
                                        duration:
                                            const Duration(milliseconds: 220),
                                        curve: Curves.easeOutCubic,
                                        child: Icon(
                                          Icons.expand_more_rounded,
                                          size: 28,
                                          color: GroupPlanningUi.charcoal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!_pendingInvitesExpanded) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.moodMatchHubInvitesCollapsedHint(
                                        _pendingInvites.length,
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        height: 1.4,
                                        color: GroupPlanningUi.charcoal,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _pendingInvitesExpanded
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 10),
                                    if (_pendingInvites.length == 1)
                                      _HubMoodMatchInviteCard(
                                        l10n: l10n,
                                        entry: _pendingInvites.single,
                                        joining: _joiningInviteEventId ==
                                            _pendingInvites.single.eventId,
                                        onDismiss: () => _confirmDismissInvite(
                                          _pendingInvites.single,
                                        ),
                                        onJoin: () => _onJoinInvite(
                                          _pendingInvites.single,
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: _inviteCarouselHeight,
                                        child: PageView.builder(
                                          controller: _invitePageController,
                                          itemCount: _pendingInvites.length,
                                          padEnds: true,
                                          // Let the card's soft drop-shadow
                                          // bleed past the viewport edges so
                                          // the "floating" look isn't sheared.
                                          clipBehavior: Clip.none,
                                          onPageChanged: (i) {
                                            setState(
                                              () => _inviteCarouselIndex = i,
                                            );
                                          },
                                          itemBuilder: (context, i) {
                                            final inv = _pendingInvites[i];
                                            return Padding(
                                              // Symmetric gutters so every
                                              // card appears centered in its
                                              // viewport slot; horizontal +
                                              // vertical padding also gives
                                              // the floating drop shadow room
                                              // to render cleanly without
                                              // being clipped.
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 3,
                                                vertical: 4,
                                              ),
                                              child: _HubMoodMatchInviteCard(
                                                l10n: l10n,
                                                entry: inv,
                                                joining:
                                                    _joiningInviteEventId ==
                                                        inv.eventId,
                                                onDismiss: () =>
                                                    _confirmDismissInvite(inv),
                                                onJoin: () =>
                                                    _onJoinInvite(inv),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    if (_pendingInvites.length > 1) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          for (var i = 0;
                                              i < _pendingInvites.length;
                                              i++)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 3,
                                              ),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                width: i == _inviteCarouselIndex
                                                    ? 9
                                                    : 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    999,
                                                  ),
                                                  color: i ==
                                                          _inviteCarouselIndex
                                                      ? GroupPlanningUi.forest
                                                      : GroupPlanningUi.stone
                                                          .withValues(
                                                          alpha: 0.28,
                                                        ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                      if (_checkingActive)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: GroupPlanningUi.forest,
                              ),
                            ),
                          ),
                        )
                      else if (hubActive.isNotEmpty ||
                          hubCompleted.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _MoodMatchHubSessionsToggle(
                          l10n: l10n,
                          selectedIndex: _hubSessionTab,
                          onSelected: (i) => setState(() => _hubSessionTab = i),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            _hubSessionTab == 0
                                ? l10n.moodMatchHubTabActiveHint
                                : l10n.moodMatchHubTabCompletedHint,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: GroupPlanningUi.charcoal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_hubSessionTab == 0) ...[
                          if (hubActive.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 22,
                              ),
                              child: Center(
                                child: Text(
                                  l10n.moodMatchHubTabActiveEmpty,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: GroupPlanningUi.stone,
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            for (final item in hubActive)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _ongoingActiveResumeCard(
                                  l10n,
                                  uid,
                                  item,
                                ),
                              ),
                          ],
                        ] else ...[
                          if (hubCompleted.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 22,
                              ),
                              child: Center(
                                child: Text(
                                  l10n.moodMatchHubTabCompletedEmpty,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: GroupPlanningUi.stone,
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            for (final item in hubCompleted)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _CompletedResumeCard(
                                  l10n: l10n,
                                  sessionTitle: _sessionDisplayTitle(
                                    l10n,
                                    item.session,
                                  ),
                                  onOpenMyDay: () =>
                                      _openMyDayForSession(item.session),
                                  onRemove: () => _confirmRemoveOngoingSession(
                                    item.session,
                                  ),
                                  ownerAvatarUrl: item.owner?.avatarUrl,
                                  guestAvatarUrl: item.guest?.avatarUrl,
                                ),
                              ),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: safeTop + 4,
            left: 4,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/main');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill switcher: Active vs Completed (matches My Day slot toggle look).
class _MoodMatchHubSessionsToggle extends StatelessWidget {
  const _MoodMatchHubSessionsToggle({
    required this.l10n,
    required this.selectedIndex,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GroupPlanningUi.stone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _segment(
                emoji: '⚡️',
                label: l10n.moodMatchHubTabActive,
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            Expanded(
              child: _segment(
                emoji: '✔️',
                label: l10n.moodMatchHubTabCompleted,
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment({
    required String emoji,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final textStyle = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
      color: selected ? GroupPlanningUi.charcoal : GroupPlanningUi.stone,
    );

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      // Hide the decorative emoji from the screen reader — the label already
      // conveys the tab meaning and the emoji is redundant noise.
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: GroupPlanningUi.moodMatchDeep
                            .withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: textStyle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 15, height: 1.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// In-app Mood Match invite — matches notification copy; join + dismiss.
class _HubMoodMatchInviteCard extends StatelessWidget {
  const _HubMoodMatchInviteCard({
    required this.l10n,
    required this.entry,
    required this.joining,
    required this.onDismiss,
    required this.onJoin,
  });

  final AppLocalizations l10n;
  final MoodMatchInviteInboxEntry entry;
  final bool joining;
  final VoidCallback onDismiss;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final weekday = DateFormat.EEEE(locale).format(entry.createdAt.toLocal());
    final nameForBody = entry.senderFirstName;
    final title = entry.sessionTitle?.trim();
    final hasTitle = title != null && title.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: GroupPlanningUi.forest.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          // Ambient — keeps the card visually grounded at its edges.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          // Soft key light — the main "floating" lift.
          BoxShadow(
            color: GroupPlanningUi.moodMatchDeep.withValues(alpha: 0.10),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
          // Wide diffuse halo — premium, dreamy depth.
          BoxShadow(
            color: GroupPlanningUi.moodMatchDeep.withValues(alpha: 0.05),
            blurRadius: 56,
            spreadRadius: -12,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 44, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top block: avatar/badge row + title + body
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: GroupPlanningUi.cream,
                          backgroundImage: (entry.senderImageUrl != null &&
                                  entry.senderImageUrl!.trim().isNotEmpty)
                              ? wmCachedNetworkImageProvider(
                                  entry.senderImageUrl!.trim(),
                                )
                              : null,
                          child: (entry.senderImageUrl == null ||
                                  entry.senderImageUrl!.trim().isEmpty)
                              ? Text(
                                  entry.senderDisplayLabel.isNotEmpty
                                      ? entry.senderDisplayLabel[0]
                                          .toUpperCase()
                                      : '?',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: GroupPlanningUi.forest,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: GroupPlanningUi.forestTint,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.moodMatchInviteInboxTag,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: GroupPlanningUi.forest,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.senderDisplayLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: GroupPlanningUi.stone,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasTitle ? title : weekday,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: GroupPlanningUi.charcoal,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.moodMatchInviteInboxBody(nameForBody),
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        height: 1.35,
                        color: GroupPlanningUi.charcoal,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                // Bottom block: CTA, anchored to the card's bottom edge so
                // there's no dead whitespace below.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _HubPrimaryPillButton(
                      label: joining
                          ? l10n.moodMatchInviteInboxJoining
                          : l10n.moodMatchInviteInboxJoin,
                      onPressed: joining ? null : onJoin,
                      showTrailingArrow: !joining,
                      leading: joining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : null,
                      stretch: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: joining ? null : onDismiss,
              icon: Icon(
                Icons.close,
                color: GroupPlanningUi.stone.withValues(alpha: 0.55),
                size: 20,
              ),
              tooltip: l10n.moodMatchInviteInboxDismiss,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _PendingResumeCard extends StatelessWidget {
  const _PendingResumeCard({
    required this.l10n,
    required this.sessionTitle,
    required this.planReady,
    required this.joinCode,
    required this.statusBadge,
    required this.statusBody,
    required this.primaryCta,
    required this.showNudge,
    required this.onContinue,
    required this.onNudgeFriend,
    required this.onCancel,
    this.ownerAvatarUrl,
    this.guestAvatarUrl,
  });

  final AppLocalizations l10n;
  final String sessionTitle;
  final bool planReady;
  final String joinCode;
  final String statusBadge;
  final String statusBody;
  final String primaryCta;
  final bool showNudge;
  final VoidCallback onContinue;
  final VoidCallback onNudgeFriend;
  final VoidCallback onCancel;
  final String? ownerAvatarUrl;
  final String? guestAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: GroupPlanningUi.moodMatchDeep.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      shape: _hubSessionMaterialShape(planReady: planReady),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle background decoration
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    GroupPlanningUi.moodMatchTabActiveOrange
                        .withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: GroupPlanningUi.moodMatchTabActiveOrange
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusBadge,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: GroupPlanningUi.moodMatchTabActiveOrange,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _PairAvatarPill(
                      ownerAvatarUrl: ownerAvatarUrl,
                      guestAvatarUrl: guestAvatarUrl,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onCancel,
                      icon: Icon(Icons.close,
                          color: GroupPlanningUi.stone.withValues(alpha: 0.5),
                          size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  sessionTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GroupPlanningUi.charcoal,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusBody,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.4,
                    color: GroupPlanningUi.charcoal,
                  ),
                ),
                const SizedBox(height: 20),
                if (showNudge)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onNudgeFriend,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: GroupPlanningUi.forest,
                            side: BorderSide(
                              color: GroupPlanningUi.forest
                                  .withValues(alpha: 0.35),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            l10n.moodMatchHubNudgeFriend,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _HubPrimaryPillButton(
                        label: primaryCta,
                        onPressed: onContinue,
                        stretch: false,
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _HubPrimaryPillButton(
                        label: primaryCta,
                        onPressed: onContinue,
                        stretch: false,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyResumeCard extends StatelessWidget {
  const _ReadyResumeCard({
    required this.l10n,
    required this.sessionTitle,
    required this.onSeePlan,
    required this.onRemove,
    this.ownerAvatarUrl,
    this.guestAvatarUrl,
  });

  final AppLocalizations l10n;
  final String sessionTitle;
  final VoidCallback onSeePlan;
  final VoidCallback onRemove;
  final String? ownerAvatarUrl;
  final String? guestAvatarUrl;

  static const Color _stateOrange = Color(0xFFE07A3F);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: GroupPlanningUi.moodMatchDeep.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      shape: _hubSessionMaterialShape(planReady: true),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _stateOrange.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.moodMatchHubReadyTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _stateOrange,
                        ),
                      ),
                    ),
                    _PairAvatarPill(
                      ownerAvatarUrl: ownerAvatarUrl,
                      guestAvatarUrl: guestAvatarUrl,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: GroupPlanningUi.stone.withValues(alpha: 0.5),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: const ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  sessionTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GroupPlanningUi.charcoal,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.moodMatchHubReadySubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.4,
                    color: GroupPlanningUi.charcoal,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _HubPrimaryPillButton(
                      label: l10n.moodMatchHubSeePlanCta,
                      onPressed: onSeePlan,
                      stretch: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Session the user already saved to My Day — kept separate from active work.
class _CompletedResumeCard extends StatelessWidget {
  const _CompletedResumeCard({
    required this.l10n,
    required this.sessionTitle,
    required this.onOpenMyDay,
    required this.onRemove,
    this.ownerAvatarUrl,
    this.guestAvatarUrl,
  });

  final AppLocalizations l10n;
  final String sessionTitle;
  final VoidCallback onOpenMyDay;
  final VoidCallback onRemove;
  final String? ownerAvatarUrl;
  final String? guestAvatarUrl;

  static const Color _forest = GroupPlanningUi.forest;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: GroupPlanningUi.moodMatchDeep.withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      shape: _hubSessionMaterialShape(planReady: false),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: GroupPlanningUi.forestTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.moodMatchHubCompletedBadge,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _forest,
                      height: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                _PairAvatarPill(
                  ownerAvatarUrl: ownerAvatarUrl,
                  guestAvatarUrl: guestAvatarUrl,
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: GroupPlanningUi.stone.withValues(alpha: 0.5),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sessionTitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GroupPlanningUi.charcoal,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.moodMatchHubCompletedBody,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.4,
                color: GroupPlanningUi.charcoal,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _HubPrimaryPillButton(
                  label: l10n.moodMatchHubCompletedCta,
                  onPressed: onOpenMyDay,
                  stretch: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PairAvatarPill extends StatelessWidget {
  const _PairAvatarPill({
    this.ownerAvatarUrl,
    this.guestAvatarUrl,
  });

  final String? ownerAvatarUrl;
  final String? guestAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: GroupPlanningUi.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GroupPlanningUi.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniAvatar(ownerAvatarUrl, 'Y'),
          const SizedBox(width: 6),
          _miniAvatar(guestAvatarUrl, '?'),
        ],
      ),
    );
  }

  Widget _miniAvatar(String? url, String fallback) {
    final u = url?.trim();
    return CircleAvatar(
      radius: 12,
      backgroundColor: GroupPlanningUi.forestTint,
      child: u != null && u.isNotEmpty
          ? ClipOval(
              child: WmNetworkImage(
                u,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            )
          : Text(
              fallback,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: GroupPlanningUi.forest,
              ),
            ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.iconBg,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color iconBg;
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $subtitle',
      button: true,
      // The decorative emoji icon is already covered by the title — don't
      // leak a second announcement for screen readers.
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        elevation: 14,
        shadowColor: GroupPlanningUi.moodMatchDeep.withValues(alpha: 0.14),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: GroupPlanningUi.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: GroupPlanningUi.moodMatchDeep
                            .withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: GroupPlanningUi.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.35,
                          color: GroupPlanningUi.stone,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: GroupPlanningUi.forest.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
