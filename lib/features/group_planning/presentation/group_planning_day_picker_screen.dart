import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/group_planning/data/mood_match_realtime_event_adapter.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_v2.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_copy.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_plan_proposals.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/features/wishlist/data/plan_met_vriend_service.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/features/profile/domain/providers/current_user_profile_provider.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_met_vriend_navigation.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/plan_invite_note_strip.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Change 3 — Day picker screen.
/// OWNER picks the shared day; GUEST waits and then confirms.
class GroupPlanningDayPickerScreen extends ConsumerStatefulWidget {
  const GroupPlanningDayPickerScreen({
    super.key,
    required this.sessionId,
    this.planMetVriendMode = false,
  });

  final String sessionId;

  /// Plan met vriend: date-only ping-pong (no moods, no time slots, no AI plan).
  final bool planMetVriendMode;

  @override
  ConsumerState<GroupPlanningDayPickerScreen> createState() =>
      _GroupPlanningDayPickerScreenState();
}

class _GroupPlanningDayPickerScreenState
    extends ConsumerState<GroupPlanningDayPickerScreen>
    with TickerProviderStateMixin {
  List<GroupMemberView> _members = [];
  GroupSessionRow? _session;
  bool _loading = true;
  /// User-safe error message when the initial `_load()` fails, so the screen
  /// can render a retry state instead of a blank/partial UI.
  String? _loadError;
  bool _isOwner = false;
  int? _selectedDayIndex; // 0=today, 1=+1, 2=+2, 3=+3
  String? _selectedSlot; // 'morning' | 'afternoon' | 'evening'
  bool _confirming = false;
  // Owner-side state after proposing: we stay on-screen and wait for the
  // guest to either accept or counter-propose. Navigation to the reveal
  // happens when the owner receives a `day_accepted` realtime event.
  bool _ownerWaitingConfirm = false;
  StreamSubscription<List<Map<String, dynamic>>>? _eventSub;
  StreamSubscription<List<Map<String, dynamic>>>? _sessionSub;
  /// Prevents stacking two guest confirm UIs (e.g. DB recovery + realtime).
  bool _guestDayProposalDialogActive = false;
  /// Same guard for the owner-side counter modal (recovery + realtime can
  /// both fire on the same frame on a cold start / push tap).
  bool _ownerCounterDialogActive = false;

  /// Latest `group_plans.plan_data` (for `dayProposal` ping-pong recovery).
  Map<String, dynamic>? _planData;
  late bool _planMetVriend;
  Map<String, dynamic>? _pmvSessionMeta;
  /// Other participant avatar when [GroupMemberView.avatarUrl] is empty.
  String? _otherMemberAvatarUrl;
  /// Invite peer (often not in [group_session_members] until they open the link).
  String? _invitePeerUserId;
  String? _invitePeerFullName;
  String? _invitePeerUsername;
  String? _invitePeerAvatarUrl;
  String? _pmvInviteId;
  String? _pmvInviteeId;
  String? _pmvInviterMessage;
  String? _pmvInviteeReply;
  /// Guest: ISO date of the owner's proposal being answered (for counter copy).
  String? _pendingOwnerProposalIso;

  late final AnimationController _pulse;
  late final FixedExtentScrollController _ownerDayWheelController;

  /// Horizontally scrollable day range (today + next N−1 days).
  static const _horizonDays = 21;

  static const _slots = ['morning', 'afternoon', 'evening'];
  static const _slotEmojis = {
    'morning': '🌅',
    'afternoon': '☀️',
    'evening': '🌆'
  };
  static const _slotRanges = {
    'morning': '9–12',
    'afternoon': '12–17',
    'evening': '17–22',
  };

  @override
  void initState() {
    super.initState();
    _planMetVriend = widget.planMetVriendMode;
    _ownerDayWheelController = FixedExtentScrollController(initialItem: 0);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _ownerDayWheelController.dispose();
    _pulse.dispose();
    _eventSub?.cancel();
    _sessionSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted && _loadError != null) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final pmvService = PlanMetVriendService(Supabase.instance.client);
      if (widget.planMetVriendMode) {
        try {
          await pmvService.ensureInviteeSessionAccess(widget.sessionId);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[DayPicker] pmv ensureInviteeSessionAccess: $e');
          }
        }
      }
      final results = await Future.wait([
        repo.fetchSession(widget.sessionId),
        repo.fetchMembersWithProfiles(widget.sessionId),
        repo.fetchPlan(widget.sessionId),
      ]);
      final session = results[0] as GroupSessionRow;
      final members = results[1] as List<GroupMemberView>;
      final plan = results[2] as GroupPlanRow?;
      if (!widget.planMetVriendMode) {
        final isPmv = await pmvService.isPlanMetVriendSession(widget.sessionId);
        if (isPmv) _planMetVriend = true;
      }
      if (_planMetVriend) {
        _pmvSessionMeta =
            await pmvService.fetchSessionMeta(widget.sessionId);
        final invite =
            await pmvService.fetchInviteBySession(widget.sessionId);
        if (invite != null) {
          _pmvInviteId = invite['id']?.toString();
          _pmvInviteeId = invite['invitee_user_id']?.toString();
          _pmvInviterMessage = PlanMetVriendService.inviteNoteText(invite);
          _pmvInviteeReply =
              PlanMetVriendService.inviteNoteText(invite, reply: true);
        }
      }
      final uid = Supabase.instance.client.auth.currentUser?.id;
      final isOwner = session.createdBy == uid;
      Map<String, dynamic>? planData;
      if (plan != null) {
        planData = GroupPlanV2.normalizePlanData(
          Map<String, dynamic>.from(plan.planData),
        );
      }
      final peer = await _resolveInvitePeerProfile(
        uid: uid,
        members: members,
        planData: planData,
        pmvService: pmvService,
      );

      if (!mounted) return;
      var ownerWaiting = false;
      if (isOwner &&
          session.status == 'day_proposed' &&
          (session.plannedDate ?? '').trim().isNotEmpty) {
        ownerWaiting = true;
      }
      var nextSelectedDay = _selectedDayIndex;
      var nextSelectedSlot = _selectedSlot;
      if (isOwner && !ownerWaiting) {
        nextSelectedDay ??= _indexFromIso(session.plannedDate) ?? 0;
        final rawSlot = session.proposedSlot?.trim();
        if (rawSlot != null && rawSlot.isNotEmpty && rawSlot != 'whole_day') {
          nextSelectedSlot ??= rawSlot;
        }
      }
      setState(() {
        _session = session;
        _members = members;
        _planData = planData;
        _isOwner = isOwner;
        _otherMemberAvatarUrl = peer.avatarUrl;
        _invitePeerUserId = peer.userId;
        _invitePeerFullName = peer.fullName;
        _invitePeerUsername = peer.username;
        _invitePeerAvatarUrl = peer.avatarUrl;
        _loading = false;
        _selectedDayIndex = nextSelectedDay;
        _selectedSlot = nextSelectedSlot;
        if (ownerWaiting) {
          _ownerWaitingConfirm = true;
        }
      });
      if (isOwner && !ownerWaiting && nextSelectedDay != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _ownerDayWheelController.jumpToItem(nextSelectedDay!);
        });
      }

      // Both sides subscribe to events — guest listens for the day_proposed
      // ping from the owner; owner listens for day_accepted / counter_proposed
      // so the ping-pong flow stays fully in this screen.
      _subscribeToPlanEvents();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _recoverDayProposalIfNeeded();
        if (!mounted) return;
        if (!isOwner) {
          _scheduleGuestRecoveryFromSession(session);
        } else {
          _scheduleOwnerRecoveryFromSession(session);
        }
      });
    } catch (e) {
      debugPrint('[DayPicker] _load failed: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _loading = false;
        _loadError = l10n == null
            ? null
            : GroupPlanningUi.classifyError(l10n, e);
      });
    }
  }

  GroupMemberView? _memberByUserId(String id) {
    for (final m in _members) {
      if (m.member.userId == id) return m;
    }
    return null;
  }

  String _fmtDayIso(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('EEE d MMM').format(dt);
  }

  void _goAfterDayConfirmed() {
    if (!mounted) return;
    if (_planMetVriend) {
      unawaited(_openPlanMetVriendMatchFound());
    } else {
      _goAfterDayConfirmed();
    }
  }

  Future<void> _openPlanMetVriendMatchFound() async {
    final meta = _pmvSessionMeta;
    final planned = (meta?['planned_date'] ?? _session?.plannedDate ?? '')
        .toString()
        .trim();
    final d = DateTime.tryParse(planned);
    if (d == null || !mounted) return;

    final service = PlanMetVriendService(Supabase.instance.client);
    final invite = await service.fetchInviteBySession(widget.sessionId);
    if (invite == null || !mounted) return;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    final inviterId = invite['inviter_user_id'] as String;
    final inviteeId = invite['invitee_user_id'] as String;
    final friendId = uid == inviterId ? inviteeId : inviterId;
    final profile = await service.fetchProfile(friendId);

    final place = PlanMetVriendPlace(
      placeId: (meta?['anchor_place_id'] ?? invite['place_id']).toString(),
      placeName: (meta?['anchor_place_name'] ?? invite['place_name']).toString(),
      placeData: Map<String, dynamic>.from(
        meta?['anchor_place_data'] as Map? ??
            invite['place_data'] as Map? ??
            {},
      ),
    );

    if (!mounted) return;
    openMatchFound(
      context,
      PlanMetVriendMatchArgs(
        sessionId: widget.sessionId,
        inviteId: invite['id'] as String,
        friend: PlanMetVriendFriend(
          userId: friendId,
          displayName: profile['displayName'] ?? 'Je vriend',
          username: profile['username'],
          avatarUrl: profile['avatarUrl'],
        ),
        place: place,
        matchedDate: DateTime(d.year, d.month, d.day),
      ),
    );
  }

  Future<void> _recoverDayProposalIfNeeded() async {
    if (!mounted) return;
    final plan = _planData;
    final session = _session;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final l10n = AppLocalizations.of(context);
    if (uid == null || session == null || l10n == null) return;
    final ownerId = session.createdBy;
    if (plan != null) {
      final dp = MoodMatchPlanProposals.dayProposalMap(plan);
      if (dp != null &&
          (dp['status'] ?? '').toString() == 'pending' &&
          (dp['addressedTo'] ?? '').toString() == uid) {
        final proposedBy = (dp['proposedBy'] ?? '').toString();
        final date = (dp['proposedDate'] ?? '').toString();
        final slot = (dp['proposedSlot'] ?? 'whole_day').toString();
        if (date.isEmpty) return;
        final proposer = _memberByUserId(proposedBy);
        final name = proposer != null
            ? _firstName(proposer.displayName)
            : l10n.moodMatchFriendThey;
        if (_isOwner) {
          if (proposedBy.isNotEmpty && proposedBy != ownerId) {
            await _showOwnerCounterDialog(date, slot, name);
          }
        } else {
          if (proposedBy == ownerId) {
            await _showGuestDayConfirmDialog(date, slot, name);
          }
        }
        return;
      }
    }
  }

  Future<T?> _showMoodMatchBlockingSheet<T>({required Widget child}) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: GroupPlanningUi.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }

  /// Mirror of `_scheduleGuestRecoveryFromSession` for the OWNER. If the guest
  /// already inserted `day_counter_proposed` (with `planned_date` +
  /// `proposed_slot` + `proposed_by_user_id` on `group_sessions`) before we
  /// subscribed, the realtime stream won't replay it — recover from the row
  /// after load so the modal still fires.
  void _scheduleOwnerRecoveryFromSession(GroupSessionRow session) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isOwner) return;
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (_planData != null &&
          uid != null &&
          MoodMatchPlanProposals.dayProposalPendingForUser(_planData!, uid)) {
        return;
      }
      unawaited(_applyOwnerRecoveryFromSession(session));
    });
  }

  Future<void> _applyOwnerRecoveryFromSession(GroupSessionRow session) async {
    if (!mounted || !_isOwner) return;
    final date = session.plannedDate?.trim();
    if (date == null || date.isEmpty) return;

    final status = session.status;
    if (status == 'day_confirmed' || status == 'generating') {
      if (!mounted) return;
      _goAfterDayConfirmed();
      return;
    }
    if (status != 'day_counter_proposed') return;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    final byUserId = session.proposedByUserId;
    // Belt-and-braces: never re-show the owner their own proposal.
    if (byUserId != null && uid != null && byUserId == uid) return;

    final l10n = AppLocalizations.of(context)!;
    final guest = _guestMember();
    final guestName =
        guest != null ? _firstName(guest.displayName) : l10n.moodMatchFriendThey;
    final slot = (session.proposedSlot ?? 'whole_day').trim().isEmpty
        ? 'whole_day'
        : session.proposedSlot!;
    await _showOwnerCounterDialog(date, slot, guestName);
  }

  Map<String, dynamic>? _planUpdateDataFromRow(Map<String, dynamic> row) {
    final evType = MoodMatchRealtimeEventAdapter.eventTypeFromRow(row);
    if (evType != 'planUpdate') return null;
    return MoodMatchRealtimeEventAdapter.eventDataFromRow(row);
  }

  Future<void> _notifyOwnerGuestDeclinedOriginal({
    required String proposedDate,
    required String proposedSlot,
  }) async {
    final owner = _ownerMemberView();
    if (owner == null) return;
    final me = _myMember();
    final myName = me != null ? _firstName(me.displayName) : 'your match';
    try {
      await ref.read(groupPlanningRepositoryProvider).sendPlanUpdateEvent(
            targetUserId: owner.member.userId,
            sessionId: widget.sessionId,
            payload: {
              'event': 'day_guest_declined_original',
              'proposed_date': proposedDate,
              'proposed_slot': proposedSlot,
              'proposed_by_username': myName,
            },
          );
    } catch (_) {}
  }

  void _subscribeToPlanEvents() {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final supabase = Supabase.instance.client;
      _eventSub?.cancel();
      _sessionSub?.cancel();
      _eventSub = supabase
          .from('realtime_events')
          .stream(primaryKey: ['id'])
          .eq('recipient_id', uid)
          .listen((rows) {
            final l10n = AppLocalizations.of(context);
            if (l10n == null || !mounted) return;
            for (final row in rows) {
              final data =
                  _planUpdateDataFromRow(Map<String, dynamic>.from(row));
              if (data == null) continue;
              final sid = data['session_id']?.toString();
              if (sid != null && sid != widget.sessionId) continue;

              final event = data['event'] as String?;
              final date = data['proposed_date'] as String?;
              final slot = data['proposed_slot'] as String?;
              final byName = data['proposed_by_username'] as String?;
              if (!mounted) return;
              if (event == 'day_guest_declined_original' && _isOwner) {
                final guestLabel = (byName != null && byName.isNotEmpty)
                    ? _firstName(byName)
                    : l10n.moodMatchFriendThey;
                showWanderMoodToast(
                  context,
                  message: l10n.moodMatchToastGuestDeclinedOriginalDay(
                    guestLabel,
                  ),
                );
                return;
              }
              if (event == 'day_proposed' && date != null && !_isOwner) {
                _showGuestDayConfirmDialog(
                  date,
                  slot ?? 'whole_day',
                  byName ?? 'your match',
                );
                return;
              }
              if (event == 'day_accepted') {
                _goAfterDayConfirmed();
                return;
              }
              if (event == 'plan_ready' &&
                  sid != null &&
                  sid == widget.sessionId) {
                context.go('/group-planning/result/${widget.sessionId}');
                return;
              }
              if (event == 'day_counter_proposed' && date != null && _isOwner) {
                final guestLabel = (byName != null && byName.isNotEmpty)
                    ? _firstName(byName)
                    : l10n.moodMatchFriendThey;
                _showOwnerCounterDialog(
                  date,
                  slot ?? 'whole_day',
                  guestLabel,
                );
                return;
              }
            }
          });

      // Keep waiting UIs hot even when a direct event ping was missed while
      // this screen stayed open (e.g. both users active simultaneously).
      _sessionSub = supabase
          .from('group_sessions')
          .stream(primaryKey: ['id'])
          .eq('id', widget.sessionId)
          .listen((rows) async {
            if (!mounted || rows.isEmpty) return;
            final row = Map<String, dynamic>.from(rows.last);
            final nextSession = GroupSessionRow.fromMap(row);
            final isOwner = _isOwner;
            final l10n = AppLocalizations.of(context);
            if (l10n == null) return;

            if (mounted) {
              final ownerWaiting = isOwner &&
                  nextSession.status == 'day_proposed' &&
                  (nextSession.plannedDate ?? '').trim().isNotEmpty;
              setState(() {
                _session = nextSession;
                _ownerWaitingConfirm = ownerWaiting;
              });
            }

            if (nextSession.status == 'day_confirmed' ||
                nextSession.status == 'generating') {
              if (!mounted) return;
              _goAfterDayConfirmed();
              return;
            }

            if (!isOwner &&
                nextSession.status == 'day_proposed' &&
                (nextSession.plannedDate ?? '').trim().isNotEmpty) {
              final owner = _ownerMemberView();
              final ownerName = owner != null
                  ? _firstName(owner.displayName)
                  : l10n.moodMatchFriendThey;
              await _showGuestDayConfirmDialog(
                nextSession.plannedDate!,
                'whole_day',
                ownerName,
              );
              return;
            }

            if (isOwner &&
                nextSession.status == 'day_counter_proposed' &&
                (nextSession.plannedDate ?? '').trim().isNotEmpty) {
              final proposer = _memberByUserId(nextSession.proposedByUserId ?? '');
              final guestName = proposer != null
                  ? _firstName(proposer.displayName)
                  : l10n.moodMatchFriendThey;
              await _showOwnerCounterDialog(
                nextSession.plannedDate!,
                (nextSession.proposedSlot ?? 'whole_day').trim().isEmpty
                    ? 'whole_day'
                    : nextSession.proposedSlot!,
                guestName,
              );
            }
          });
    } catch (_) {}
  }

  /// If the owner already wrote `day_proposed` + `planned_date` before this
  /// screen subscribed to `realtime_events`, the insert is easy to miss — recover
  /// from `group_sessions` after load.
  void _scheduleGuestRecoveryFromSession(GroupSessionRow session) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isOwner) return;
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (_planData != null &&
          uid != null &&
          MoodMatchPlanProposals.dayProposalPendingForUser(_planData!, uid)) {
        return;
      }
      unawaited(_applyGuestRecoveryFromSession(session));
    });
  }

  Future<void> _applyGuestRecoveryFromSession(GroupSessionRow session) async {
    if (!mounted || _isOwner) return;
    final date = session.plannedDate?.trim();
    if (date == null || date.isEmpty) return;

    final status = session.status;
    if (status == 'day_confirmed' || status == 'generating') {
      if (!mounted) return;
      _goAfterDayConfirmed();
      return;
    }
    if (status != 'day_proposed') return;

    final l10n = AppLocalizations.of(context)!;
    final owner = _ownerMemberView();
    final ownerName =
        owner != null ? _firstName(owner.displayName) : l10n.moodMatchFriendThey;
    // `proposed_slot` is not persisted on `group_sessions`; the realtime
    // handler treats a missing slot as "whole day" so we do the same here
    // when recovering from the persisted session row.
    await _showGuestDayConfirmDialog(date, 'whole_day', ownerName);
  }

  /// Session owner profile, or the other member if `created_by` is missing
  /// from the loaded list (older race / partial fetch).
  GroupMemberView? _ownerMemberView() {
    final session = _session;
    if (session == null) return null;
    for (final m in _members) {
      if (m.member.userId == session.createdBy) return m;
    }
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId != uid) return m;
    }
    return null;
  }

  String _firstName(String displayName) {
    final s = displayName.trim();
    if (s.isEmpty) return '?';
    // `GroupMemberView.displayName` returns `@username` when the profile only
    // has a handle. `split('@').first` on that returns an empty string, which
    // makes downstream copy read " is picking the day..." with a missing
    // subject. Strip the leading `@` first.
    if (s.startsWith('@')) {
      final u = s.substring(1).trim();
      if (u.isNotEmpty) {
        final parts = u.split(RegExp(r'\s+'));
        if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first;
      }
    }
    final beforeAt = s.split('@').first.trim();
    final parts = beforeAt.split(RegExp(r'\s+'));
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '?';
  }

  GroupMemberView? _guestMember() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId != uid) return m;
    }
    return null;
  }

  /// Session member or invite peer — invitee is often not a member until they open the link.
  GroupMemberView? _otherParticipantView() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      for (final m in _members) {
        if (m.member.userId != uid) return m;
      }
    }
    final peerId = _invitePeerUserId?.trim();
    if (peerId == null || peerId.isEmpty) return null;
    return GroupMemberView(
      member: GroupMemberRow(
        id: 'invite-peer',
        sessionId: widget.sessionId,
        userId: peerId,
      ),
      fullName: _invitePeerFullName,
      username: _invitePeerUsername,
      avatarUrl: _invitePeerAvatarUrl,
    );
  }

  String _otherParticipantFirstName(AppLocalizations l10n) {
    final other = _otherParticipantView();
    if (other != null) {
      final name = _firstName(other.displayName);
      if (name != '?') return name;
    }
    return l10n.moodMatchFriendThey;
  }

  Future<({
    String? userId,
    String? fullName,
    String? username,
    String? avatarUrl,
  })> _resolveInvitePeerProfile({
    required String? uid,
    required List<GroupMemberView> members,
    required Map<String, dynamic>? planData,
    required PlanMetVriendService pmvService,
  }) async {
    if (uid == null) {
      return (userId: null, fullName: null, username: null, avatarUrl: null);
    }

    for (final m in members) {
      if (m.member.userId == uid) continue;
      final fromMember = m.avatarUrl?.trim();
      if (fromMember != null && fromMember.isNotEmpty) {
        return (
          userId: m.member.userId,
          fullName: m.fullName,
          username: m.username,
          avatarUrl: fromMember,
        );
      }
    }

    Map<String, dynamic>? invite;
    final rawInvite = planData?['planMetVriendInvite'];
    if (rawInvite is Map) {
      invite = Map<String, dynamic>.from(rawInvite);
    } else {
      invite = await pmvService.fetchInviteBySession(widget.sessionId);
    }

    if (invite != null) {
      final inviterId = invite['inviter_user_id']?.toString();
      final inviteeId = invite['invitee_user_id']?.toString();
      final isInviter = uid == inviterId;
      final otherId = isInviter ? inviteeId : inviterId;
      if (otherId != null && otherId.isNotEmpty) {
        var avatar = isInviter
            ? (invite['invitee_avatar_url'] as String?)?.trim()
            : null;
        var fullName = isInviter
            ? (invite['invitee_display_name'] as String?)?.trim()
            : null;
        var username = isInviter
            ? (invite['invitee_username'] as String?)?.trim()
            : null;

        if (avatar == null || avatar.isEmpty ||
            fullName == null || fullName.isEmpty) {
          final profile = await pmvService.fetchProfile(otherId);
          avatar ??= profile['avatarUrl']?.trim();
          fullName ??= profile['displayName']?.trim();
          username ??= profile['username']?.trim();
        }

        for (final m in members) {
          if (m.member.userId == otherId) {
            avatar ??= m.avatarUrl?.trim();
            fullName ??= m.fullName?.trim();
            username ??= m.username?.trim();
            break;
          }
        }

        return (
          userId: otherId,
          fullName: fullName,
          username: username,
          avatarUrl: avatar,
        );
      }
    }

    for (final m in members) {
      if (m.member.userId == uid) continue;
      final profile = await pmvService.fetchProfile(m.member.userId);
      final avatar = profile['avatarUrl']?.trim();
      return (
        userId: m.member.userId,
        fullName: m.fullName ?? profile['displayName']?.trim(),
        username: m.username ?? profile['username']?.trim(),
        avatarUrl: avatar,
      );
    }

    return (userId: null, fullName: null, username: null, avatarUrl: null);
  }

  GroupMemberView? _myMember() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId == uid) return m;
    }
    return null;
  }

  String? _resolvedMeAvatarUrl() {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final fromProfile = profile?.avatarUrl?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return _myMember()?.avatarUrl?.trim();
  }

  String _resolvedMeFallbackLabel() {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final name = profile?.fullName?.trim();
    if (name != null && name.isNotEmpty) return name[0].toUpperCase();
    final user = profile?.username?.trim();
    if (user != null && user.isNotEmpty) {
      final u = user.startsWith('@') ? user.substring(1) : user;
      if (u.isNotEmpty) return u[0].toUpperCase();
    }
    final me = _myMember();
    if (me != null) return _firstName(me.displayName).substring(0, 1);
    return 'J';
  }

  String? _resolvedFriendAvatarUrl(GroupMemberView? friend) {
    final fromMember = friend?.avatarUrl?.trim();
    if (fromMember != null && fromMember.isNotEmpty) return fromMember;
    final cached = _otherMemberAvatarUrl?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return _invitePeerAvatarUrl?.trim();
  }

  String _resolvedFriendFallbackLabel(GroupMemberView? friend) {
    if (friend != null) {
      final initial = _firstName(friend.displayName);
      if (initial != '?' && initial.isNotEmpty) {
        return initial.substring(0, 1).toUpperCase();
      }
    }
    final peerName = _invitePeerFullName?.trim();
    if (peerName != null && peerName.isNotEmpty) {
      return peerName[0].toUpperCase();
    }
    final peerUser = _invitePeerUsername?.trim();
    if (peerUser != null && peerUser.isNotEmpty) {
      final u = peerUser.startsWith('@') ? peerUser.substring(1) : peerUser;
      if (u.isNotEmpty) return u[0].toUpperCase();
    }
    return '?';
  }

  Future<void> _reloadPmvInvite() async {
    final invite = await PlanMetVriendService(Supabase.instance.client)
        .fetchInviteBySession(widget.sessionId);
    if (!mounted || invite == null) return;
    setState(() {
      _pmvInviteId = invite['id']?.toString();
      _pmvInviterMessage = PlanMetVriendService.inviteNoteText(invite);
      _pmvInviteeReply =
          PlanMetVriendService.inviteNoteText(invite, reply: true);
    });
  }

  Widget _buildPmvInviteNotes(
    AppLocalizations l10n, {
    bool compact = false,
    bool allowReply = false,
  }) {
    if (!_planMetVriend) return const SizedBox.shrink();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final isInvitee = uid != null && uid == _pmvInviteeId;
    final hasInviterNote = _pmvInviterMessage?.trim().isNotEmpty ?? false;
    final hasReply = _pmvInviteeReply?.trim().isNotEmpty ?? false;
    if (!hasInviterNote && !hasReply && !isInvitee) {
      return const SizedBox.shrink();
    }

    final owner = _ownerMemberView();
    final guest = _guestMember();
    final inviterName = _isOwner
        ? (ref.watch(currentUserProfileProvider).valueOrNull?.fullName?.trim() ??
            owner?.fullName?.trim() ??
            _firstName(owner?.displayName ?? ''))
        : (owner != null
            ? _firstName(owner.displayName)
            : _otherParticipantFirstName(l10n));
    final inviterAvatar = _isOwner
        ? _resolvedMeAvatarUrl()
        : _resolvedFriendAvatarUrl(owner);
    final currentProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final me = _myMember();
    final inviteeDisplayName = isInvitee
        ? 'jou'
        : (guest != null
            ? _firstName(guest.displayName)
            : (currentProfile?.fullName?.trim().isNotEmpty == true
                ? _firstName(currentProfile!.fullName!)
                : _firstName(me?.displayName ?? _otherParticipantFirstName(l10n))));

    final inviteId = _pmvInviteId;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 14),
      child: PlanInviteNoteStrip(
        inviterName: inviterName,
        inviterAvatarUrl: inviterAvatar,
        inviterMessage: _pmvInviterMessage,
        inviteeName: inviteeDisplayName,
        inviteeReply: _pmvInviteeReply,
        compact: compact,
        canReply: allowReply && isInvitee && inviteId != null,
        onSaveReply: allowReply && isInvitee && inviteId != null
            ? (text) async {
                await PlanMetVriendService(Supabase.instance.client)
                    .saveInviteReply(
                  inviteId: inviteId,
                  sessionId: widget.sessionId,
                  reply: text,
                );
                await _reloadPmvInvite();
              }
            : null,
      ),
    );
  }

  Widget _teamHero({
    GroupMemberView? me,
    GroupMemberView? friend,
  }) {
    final resolvedMe = me ?? _myMember();
    final resolvedFriend = friend ?? _otherParticipantView();
    return _DayPickerTeamHero(
      me: resolvedMe,
      friend: resolvedFriend,
      meAvatarUrl: _resolvedMeAvatarUrl(),
      friendAvatarUrl: _resolvedFriendAvatarUrl(resolvedFriend),
      meFallbackLabel: _resolvedMeFallbackLabel(),
      friendFallbackLabel: _resolvedFriendFallbackLabel(resolvedFriend),
    );
  }

  DateTime _dayFromIndex(int i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: i));
  }

  String _dayLabel(AppLocalizations l10n, int i) {
    if (i == 0) return l10n.moodMatchDayPickerToday;
    final d = _dayFromIndex(i);
    return DateFormat('EEE d').format(d);
  }

  String _isoDate(int index) {
    final d = _dayFromIndex(index);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  int? _indexFromIso(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final start =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final picked = DateTime(dt.year, dt.month, dt.day);
    final diff = picked.difference(start).inDays;
    if (diff < 0 || diff >= _horizonDays) return null;
    return diff;
  }

  Future<void> _openOwnerDaySlotSheet(AppLocalizations l10n) async {
    final guest = _guestMember();
    final guestName = guest != null
        ? _firstName(guest.displayName)
        : l10n.moodMatchFriendThey;
    final me = _myMember();
    var tempDay = _selectedDayIndex ?? 0;
    if (tempDay < 0 || tempDay >= _horizonDays) tempDay = 0;
    // null = "whole day" (Moody plans morning + afternoon + evening).
    String? tempSlot = _selectedSlot;
    final dayWheelController = FixedExtentScrollController(initialItem: tempDay);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: GroupPlanningUi.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 28,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                GroupPlanningUi.stone.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.moodMatchDayPickerSheetTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: GroupPlanningUi.charcoal,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.moodMatchDayPickerSheetMoodyLine(guestName),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: GroupPlanningUi.forest,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _teamHero(me: me, friend: guest),
                      const SizedBox(height: 18),
                      Container(
                        height: 188,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: GroupPlanningUi.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: GroupPlanningUi.moodMatchShadow(0.09),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                height: 44,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: GroupPlanningUi.forestTint
                                      .withValues(alpha: 0.55),
                                  border: Border.all(
                                    color: GroupPlanningUi.forest
                                        .withValues(alpha: 0.28),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            ListWheelScrollView.useDelegate(
                              controller: dayWheelController,
                              itemExtent: 44,
                              physics: const FixedExtentScrollPhysics(),
                              diameterRatio: 2.2,
                              perspective: 0.0025,
                              squeeze: 1.08,
                              onSelectedItemChanged: (i) {
                                HapticFeedback.selectionClick();
                                setSheet(() => tempDay = i);
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: _horizonDays,
                                builder: (context, i) {
                                  final day = _dayFromIndex(i);
                                  final isToday = i == 0;
                                  final sel = tempDay == i;
                                  final label = isToday
                                      ? '${l10n.moodMatchDayPickerToday} · ${DateFormat('EEE d MMM').format(day)}'
                                      : DateFormat('EEE d MMM').format(day);
                                  return Center(
                                    child: Text(
                                      label,
                                      style: GoogleFonts.poppins(
                                        fontSize: sel ? 16 : 14,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: sel
                                            ? GroupPlanningUi.charcoal
                                            : GroupPlanningUi.stone
                                                .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l10n.moodMatchTimePickerTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: GroupPlanningUi.charcoal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.moodMatchDayPickerTimeHint,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: GroupPlanningUi.stone,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildWholeDayAndSlotPickers(
                        l10n: l10n,
                        selectedSlot: tempSlot,
                        onSlotChanged: (next) =>
                            setSheet(() => tempSlot = next),
                      ),
                      const SizedBox(height: 22),
                      GroupPlanningUi.primaryCta(
                        label: l10n.moodMatchPlanV2SendToGuest(guestName),
                        onPressed: () =>
                            Navigator.of(sheetCtx).pop(<String, dynamic>{
                          'day': tempDay,
                          // null = "whole day" — Moody plans all 3 slots.
                          'slot': tempSlot,
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedDayIndex = result['day'] as int?;
        _selectedSlot = result['slot'] as String?;
      });
    }
    dayWheelController.dispose();
  }

  Future<void> _confirmDay() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedDayIndex == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _confirming = true);
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final iso = _isoDate(_selectedDayIndex!);
      final slot = _selectedSlot;

      // Persist locally first so the flow continues even when the DB write
      // fails (older schema without `planned_date` / extended status enum).
      await MoodMatchSessionPrefs.savePlannedDate(widget.sessionId, iso);
      // Persist a sentinel `'whole_day'` when the owner picked the whole
      // day. Clearing here would let downstream code default to `afternoon`
      // and produce a single-slot plan instead of morning+afternoon+evening.
      await MoodMatchSessionPrefs.savePendingTimeSlot(
        widget.sessionId,
        slot ?? 'whole_day',
      );

      // These may fail silently on older schemas — intentional, we don't block.
      await repo.writePlannedDate(widget.sessionId, iso);
      await repo.writeSessionStatus(widget.sessionId, 'day_proposed');

      final guest = _guestMember();
      final me = _myMember();
      final myName = me != null ? _firstName(me.displayName) : 'Owner';
      if (guest != null) {
        final meUid = me?.member.userId;
        if (meUid != null) {
          await repo.upsertPendingDayProposal(
            sessionId: widget.sessionId,
            proposedByUserId: meUid,
            addressedToUserId: guest.member.userId,
            proposedDate: iso,
            proposedSlot: slot ?? 'whole_day',
          );
        }
        final dayLabel = _dayLabel(l10n, _selectedDayIndex!);
        try {
          await repo.sendPlanUpdateEvent(
            targetUserId: guest.member.userId,
            sessionId: widget.sessionId,
            payload: {
              'event': 'day_proposed',
              'proposed_date': iso,
              'proposed_day_label': dayLabel,
              // Always include a `proposed_slot`. The guest used to default
              // a missing slot to `'afternoon'`, which silently turned a
              // whole-day plan into a single-slot one.
              'proposed_slot': slot ?? 'whole_day',
              'proposed_by_username': myName,
            },
          ).timeout(const Duration(seconds: 12));
        } catch (_) {
          if (mounted) {
            showWanderMoodToast(
              context,
              message: l10n.moodMatchDayNotifyMaybeFailed,
            );
          }
        }
      }

      // Owner stays on this screen in a "waiting for confirm" state until
      // the guest accepts. We do not navigate here — the day_accepted event
      // (see _subscribeToPlanEvents) routes both sides to /match-loading.
      if (mounted) {
        setState(() {
          _confirming = false;
          _ownerWaitingConfirm = true;
        });
        try {
          final p = await repo.fetchPlan(widget.sessionId);
          if (mounted && p != null) {
            setState(() {
              _planData = GroupPlanV2.normalizePlanData(
                Map<String, dynamic>.from(p.planData),
              );
            });
          }
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() => _confirming = false);
        showWanderMoodToast(
          context,
          message: l10n.signupErrorGeneric,
        );
      }
    }
  }

  /// Owner receives this when the guest countered with a different day / slot.
  Future<void> _showOwnerCounterDialog(
      String isoDate, String slot, String guestName) async {
    if (!mounted || _ownerCounterDialogActive) return;
    _ownerCounterDialogActive = true;
    try {
      await _showOwnerCounterDialogInner(isoDate, slot, guestName);
    } finally {
      _ownerCounterDialogActive = false;
    }
  }

  Future<void> _showOwnerCounterDialogInner(
      String isoDate, String slot, String guestName) async {
    if (!mounted) return;
    if (_planMetVriend) {
      await _reloadPmvInvite();
      if (!mounted) return;
    }
    final l10n = AppLocalizations.of(context)!;
    final dt = DateTime.tryParse(isoDate);
    final dayLabel =
        dt != null ? DateFormat('EEEE d MMMM').format(dt) : isoDate;
    final timeLabel = '${_slotLabel(l10n, slot)} · ${_slotRanges[slot] ?? ''}';

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: GroupPlanningUi.cream,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: GroupPlanningUi.stone.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$guestName suggested $dayLabel · $timeLabel',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: GroupPlanningUi.charcoal,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Looks fun? Accept it, or toss back another time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: GroupPlanningUi.stone,
                  height: 1.35,
                ),
              ),
              if (_planMetVriend) ...[
                const SizedBox(height: 14),
                _buildPmvInviteNotes(l10n, compact: true),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: GroupPlanningUi.primaryCta(
                  label: l10n.moodMatchPlanV2WorksForMe,
                  onPressed: () => Navigator.of(ctx).pop('accept'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GroupPlanningUi.secondaryCta(
                  label: l10n.moodMatchOwnerCounterSuggestAnother,
                  onPressed: () => Navigator.of(ctx).pop('counter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == 'accept' && mounted) {
      // Owner accepts the counter — adopt the guest's date/slot, bounce back
      // a `day_accepted` event and head to the reveal together.
      await MoodMatchSessionPrefs.savePlannedDate(widget.sessionId, isoDate);
      await MoodMatchSessionPrefs.savePendingTimeSlot(widget.sessionId, slot);
      try {
        final repo = ref.read(groupPlanningRepositoryProvider);
        final guest = _guestMember();
        final me = _myMember();
        final myName = me != null ? _firstName(me.displayName) : 'Owner';
        if (guest != null) {
          await repo.sendPlanUpdateEvent(
            targetUserId: guest.member.userId,
            sessionId: widget.sessionId,
            payload: {
              'event': 'day_accepted',
              'proposed_date': isoDate,
              'proposed_slot': slot,
              'proposed_by_username': myName,
            },
          );
        }
        await repo.writePlannedDate(widget.sessionId, isoDate);
        await repo.writeSessionStatus(widget.sessionId, 'day_confirmed');
        await repo.markDayProposalAcceptedInPlan(widget.sessionId);
        // Counter resolved — wipe the recovery fields so re-entry doesn't
        // re-pop this dialog forever.
        await repo.clearProposedSlot(widget.sessionId);
      } catch (_) {}
      if (!mounted) return;
      _goAfterDayConfirmed();
    } else if (choice == 'counter' && mounted) {
      await _openOwnerDaySlotSheet(l10n);
      if (mounted && _selectedDayIndex != null) {
        await _confirmDay();
      }
    }
  }

  String _slotNote(AppLocalizations l10n, String slot) {
    switch (slot) {
      case 'morning':
        return l10n.moodMatchTimePickerMorningNote;
      case 'afternoon':
        return l10n.moodMatchTimePickerAfternoonNote;
      case 'evening':
        return l10n.moodMatchTimePickerEveningNote;
      default:
        return '';
    }
  }

  String _slotLabel(AppLocalizations l10n, String slot) {
    switch (slot) {
      case 'morning':
        return l10n.moodMatchTimePickerMorning;
      case 'afternoon':
        return l10n.moodMatchTimePickerAfternoon;
      case 'evening':
        return l10n.moodMatchTimePickerEvening;
      case 'whole_day':
        return l10n.moodMatchDayPickerWholeDay;
      default:
        return slot;
    }
  }

  /// Whole-day row first, then compact slot rows — shared by the owner sheet
  /// and the guest counter sheet so both flows use the same smaller layout.
  Widget _buildWholeDayAndSlotPickers({
    required AppLocalizations l10n,
    required String? selectedSlot,
    required void Function(String? next) onSlotChanged,
  }) {
    const rowPad = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    const emojiSize = 18.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSlotChanged(null);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: rowPad,
              decoration: BoxDecoration(
                color: selectedSlot == null
                    ? GroupPlanningUi.forest
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedSlot == null
                      ? GroupPlanningUi.forest
                      : GroupPlanningUi.cardBorder,
                  width: selectedSlot == null ? 2 : 1,
                ),
                boxShadow: selectedSlot == null
                    ? [
                        BoxShadow(
                          color: GroupPlanningUi.forest
                              .withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  const Text('🗓️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.moodMatchDayPickerWholeDay,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedSlot == null
                            ? Colors.white
                            : GroupPlanningUi.charcoal,
                      ),
                    ),
                  ),
                  if (selectedSlot == null)
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
        ...List.generate(_slots.length, (i) {
          final slot = _slots[i];
          final sel = selectedSlot == slot;
          return Padding(
            padding: EdgeInsets.only(bottom: i < _slots.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSlotChanged(slot);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: rowPad,
                decoration: BoxDecoration(
                  color: sel ? GroupPlanningUi.forest : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel
                        ? GroupPlanningUi.forest
                        : GroupPlanningUi.cardBorder,
                    width: sel ? 2 : 1,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: GroupPlanningUi.forest
                                .withValues(alpha: 0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(
                      _slotEmojis[slot] ?? '🕐',
                      style: const TextStyle(fontSize: emojiSize),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_slotLabel(l10n, slot)}  ${_slotRanges[slot]}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : GroupPlanningUi.charcoal,
                            ),
                          ),
                          if (sel) ...[
                            const SizedBox(height: 2),
                            Text(
                              _slotNote(l10n, slot),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (sel)
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _ownerDateTitleByStyle(
    AppLocalizations l10n,
    String communicationStyle,
  ) {
    switch (moodMatchNormalizeCommunicationStyle(communicationStyle)) {
      case 'energetic':
        return 'Pick the vibe day for both of you';
      case 'direct':
        return 'Pick your shared day';
      case 'professional':
        return l10n.moodMatchDayPickerTitle;
      default:
        return 'Pick a day that feels right for both of you';
    }
  }

  String _ownerDateSubtitleByStyle(String guestName, String communicationStyle) {
    switch (moodMatchNormalizeCommunicationStyle(communicationStyle)) {
      case 'energetic':
        return 'You choose first, then $guestName confirms. Keep it fun.';
      case 'direct':
        return 'You choose. $guestName confirms.';
      case 'professional':
        return '$guestName will review and confirm your pick.';
      default:
        return 'You choose first, then $guestName can say yes or suggest another vibe.';
    }
  }

  String _ownerWaitingTitleByStyle(String guestName, String communicationStyle) {
    switch (moodMatchNormalizeCommunicationStyle(communicationStyle)) {
      case 'energetic':
        return 'Proposal sent to $guestName';
      case 'direct':
        return 'Waiting for $guestName';
      case 'professional':
        return 'Awaiting confirmation from $guestName';
      default:
        return '$guestName is checking your plan now';
    }
  }

  String _ownerWaitingSubtitleByStyle(
    String guestName,
    String communicationStyle,
  ) {
    switch (moodMatchNormalizeCommunicationStyle(communicationStyle)) {
      case 'energetic':
        return 'They just got the invite. If it clicks, you are both in.';
      case 'direct':
        return 'Sent. Waiting for their answer.';
      case 'professional':
        return 'A confirmation request has been sent to $guestName.';
      default:
        return 'We sent it to $guestName. As soon as they answer, you both jump into your shared plan.';
    }
  }

  String _guestWaitingHeadlineByStyle(
    String ownerName,
    String communicationStyle,
  ) {
    switch (moodMatchNormalizeCommunicationStyle(communicationStyle)) {
      case 'energetic':
        return '$ownerName is picking the day for both of you';
      case 'direct':
        return 'Waiting for $ownerName to pick a day';
      case 'professional':
        return '$ownerName is selecting a day for both participants';
      default:
        return '$ownerName is choosing a day for both of you';
    }
  }

  bool get _guestHasSentCounterProposal {
    if (_isOwner) return false;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return _session?.status == 'day_counter_proposed' &&
        uid != null &&
        _session?.proposedByUserId == uid;
  }

  Future<void> _showGuestDayConfirmDialog(
      String isoDate, String slot, String ownerName) async {
    if (!mounted || _guestDayProposalDialogActive) return;
    _guestDayProposalDialogActive = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      final dt = DateTime.tryParse(isoDate);
      final dayLabel =
          dt != null ? DateFormat('EEEE d MMMM').format(dt) : isoDate;
      final timeLabel = '${_slotLabel(l10n, slot)} ${_slotRanges[slot] ?? ''}';

      _pendingOwnerProposalIso = isoDate;
      final confirmed = await _showMoodMatchBlockingSheet<bool>(
        child: Builder(
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: GroupPlanningUi.forestTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _planMetVriend
                      ? dayLabel
                      : l10n.moodMatchGuestConfirmTitleWithTime(
                          dayLabel,
                          timeLabel,
                        ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GroupPlanningUi.forest,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _planMetVriend
                    ? '$ownerName stelt $dayLabel voor. Past dit voor jullie?'
                    : l10n.moodMatchGuestConfirmBody(
                        ownerName,
                        dayLabel,
                        timeLabel,
                      ),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GroupPlanningUi.charcoal,
                  height: 1.35,
                ),
              ),
              if (_planMetVriend) ...[
                const SizedBox(height: 14),
                _buildPmvInviteNotes(l10n, compact: true),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GroupPlanningUi.primaryCta(
                  label: l10n.moodMatchGuestConfirmYes,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GroupPlanningUi.secondaryCta(
                  label: l10n.moodMatchGuestCounterCta,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;
      if (confirmed == true) {
        // Guest accepts — notify owner + both move on.
        await MoodMatchSessionPrefs.savePlannedDate(widget.sessionId, isoDate);
        await MoodMatchSessionPrefs.savePendingTimeSlot(widget.sessionId, slot);
        try {
          final repo = ref.read(groupPlanningRepositoryProvider);
          await repo.writeSessionStatus(widget.sessionId, 'day_confirmed');
          await repo.markDayProposalAcceptedInPlan(widget.sessionId);
          // Wipe any prior counter so the owner doesn't re-recover the modal.
          await repo.clearProposedSlot(widget.sessionId);
          final owner = _ownerMemberView();
          if (owner == null) {
            if (mounted) {
              showWanderMoodToast(
                context,
                message: l10n.signupErrorGeneric,
              );
            }
            return;
          }
          final me = _myMember();
          final myName = me != null ? _firstName(me.displayName) : 'your match';
          await repo.sendPlanUpdateEvent(
            targetUserId: owner.member.userId,
            sessionId: widget.sessionId,
            payload: {
              'event': 'day_accepted',
              'proposed_date': isoDate,
              'proposed_slot': slot,
              'proposed_by_username': myName,
            },
          );
        } catch (_) {}
        if (!mounted) return;
        _goAfterDayConfirmed();
      } else if (confirmed == false) {
        await _notifyOwnerGuestDeclinedOriginal(
          proposedDate: isoDate,
          proposedSlot: slot,
        );
        if (!mounted) return;
        await _openGuestCounterPicker(ownerName);
      } else {
        // Dialog dismissed without choosing — still tell the owner.
        await _notifyOwnerGuestDeclinedOriginal(
          proposedDate: isoDate,
          proposedSlot: slot,
        );
      }
    } finally {
      _guestDayProposalDialogActive = false;
    }
  }

  /// Guest-side counter-proposal flow: pick a different day + slot, send it
  /// back to the owner, then wait for their accept.
  Future<void> _openGuestCounterPicker(String ownerName) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    int dayIdx = 1;
    // null = "whole day" — matches the owner-side day/slot sheet so the guest
    // can counter with the same options the owner had. Pre-fix this defaulted
    // to `'afternoon'` and only offered the three regular slots.
    String? slot;
    var counterMessage = '';
    final dayWheelController = FixedExtentScrollController(initialItem: dayIdx);

    final sent = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheet) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.9,
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: const BoxDecoration(
                color: GroupPlanningUi.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                GroupPlanningUi.stone.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.moodMatchGuestCounterTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: GroupPlanningUi.charcoal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.moodMatchGuestCounterSub(ownerName),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: GroupPlanningUi.stone,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 188,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border:
                              Border.all(color: GroupPlanningUi.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: GroupPlanningUi.moodMatchShadow(0.09),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                height: 44,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: GroupPlanningUi.forestTint
                                      .withValues(alpha: 0.55),
                                  border: Border.all(
                                    color: GroupPlanningUi.forest
                                        .withValues(alpha: 0.28),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            ListWheelScrollView.useDelegate(
                              controller: dayWheelController,
                              itemExtent: 44,
                              physics: const FixedExtentScrollPhysics(),
                              diameterRatio: 2.2,
                              perspective: 0.0025,
                              squeeze: 1.08,
                              onSelectedItemChanged: (i) {
                                HapticFeedback.selectionClick();
                                setSheet(() => dayIdx = i);
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: _horizonDays,
                                builder: (context, i) {
                                  final day = _dayFromIndex(i);
                                  final isToday = i == 0;
                                  final sel = dayIdx == i;
                                  final label = isToday
                                      ? '${l10n.moodMatchDayPickerToday} · ${DateFormat('EEE d MMM').format(day)}'
                                      : DateFormat('EEE d MMM').format(day);
                                  return Center(
                                    child: Text(
                                      label,
                                      style: GoogleFonts.poppins(
                                        fontSize: sel ? 16 : 14,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: sel
                                            ? GroupPlanningUi.charcoal
                                            : GroupPlanningUi.stone
                                                .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.moodMatchTimePickerTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: GroupPlanningUi.charcoal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.moodMatchDayPickerTimeHint,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: GroupPlanningUi.stone,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildWholeDayAndSlotPickers(
                        l10n: l10n,
                        selectedSlot: slot,
                        onSlotChanged: (next) => setSheet(() => slot = next),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Bericht aan $ownerName (optioneel)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: GroupPlanningUi.stone,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        maxLength: 100,
                        maxLines: 2,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        onChanged: (value) => counterMessage = value.trim(),
                        onSubmitted: (_) => FocusScope.of(ctx).unfocus(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: GroupPlanningUi.charcoal,
                          height: 1.35,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Bijv. Ik kan dan wel, lukt dat voor jou?',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: GroupPlanningUi.cardBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: GroupPlanningUi.cardBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: GroupPlanningUi.forest,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      GroupPlanningUi.primaryCta(
                        label: l10n.moodMatchGuestCounterSendCta,
                        onPressed: () {
                          FocusScope.of(ctx).unfocus();
                          Navigator.of(ctx).pop(true);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    dayWheelController.dispose();
    if (sent != true || !mounted) return;

    final iso = _isoDate(dayIdx);
    final slotForPayload = slot ?? 'whole_day';
    await MoodMatchSessionPrefs.savePlannedDate(widget.sessionId, iso);
    await MoodMatchSessionPrefs.savePendingTimeSlot(
      widget.sessionId,
      slotForPayload,
    );
    final me = _myMember();
    final myName = me != null ? _firstName(me.displayName) : 'your match';
    final myUserId = me?.member.userId;
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      // Persist on the session row so the OWNER can recover the
      // "accept this counter?" modal on cold start / push tap. The realtime
      // stream only delivers NEW inserts after subscribe, so without DB
      // persistence the owner silently misses counter proposals.
      await repo.writePlannedDate(widget.sessionId, iso);
      if (myUserId != null) {
        await repo.writeProposedSlot(
          sessionId: widget.sessionId,
          slot: slotForPayload,
          byUserId: myUserId,
        );
      }
      await repo.writeSessionStatus(
        widget.sessionId,
        'day_counter_proposed',
      );

      final owner = _members.firstWhere(
        (m) => _session != null && m.member.userId == _session!.createdBy,
        orElse: () => _members.first,
      );
      if (myUserId != null) {
        await repo.upsertPendingDayProposal(
          sessionId: widget.sessionId,
          proposedByUserId: myUserId,
          addressedToUserId: owner.member.userId,
          proposedDate: iso,
          proposedSlot: slotForPayload,
        );
      }
      final prevIso = (_pendingOwnerProposalIso ?? _session?.plannedDate ?? '')
          .trim();
      final prevDayLabel =
          prevIso.isNotEmpty ? _fmtDayIso(prevIso) : prevIso;
      final newDayLabel = _fmtDayIso(iso);
      if (_pmvInviteId != null && counterMessage.isNotEmpty) {
        try {
          await PlanMetVriendService(Supabase.instance.client).saveInviteReply(
            inviteId: _pmvInviteId!,
            sessionId: widget.sessionId,
            reply: counterMessage,
          );
          await _reloadPmvInvite();
        } catch (e) {
          if (kDebugMode) debugPrint('pmv counter reply: $e');
        }
      }
      await repo.sendPlanUpdateEvent(
        targetUserId: owner.member.userId,
        sessionId: widget.sessionId,
        payload: {
          'event': 'day_counter_proposed',
          'proposed_date': iso,
          'proposed_slot': slotForPayload,
          'proposed_by_username': myName,
          if (prevIso.isNotEmpty) 'previous_date': prevIso,
          'previous_day': prevDayLabel,
          'new_day': newDayLabel,
          'day': newDayLabel,
          if (counterMessage.isNotEmpty) 'counter_message': counterMessage,
        },
      );
    } catch (_) {}

    if (!mounted) return;
    // Guest now waits on the day_accepted echo from owner before navigating.
    // We already own the realtime listener for that event.
    final current = _session;
    if (current != null) {
      setState(() {
        _session = GroupSessionRow(
          id: current.id,
          createdBy: current.createdBy,
          title: current.title,
          joinCode: current.joinCode,
          status: 'day_counter_proposed',
          maxMembers: current.maxMembers,
          expiresAt: current.expiresAt,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          plannedDate: iso,
          proposedByUserId: myUserId,
          proposedSlot: slotForPayload,
          completedAt: current.completedAt,
        );
      });
    }
    showWanderMoodToast(
      context,
      message: 'Voorstel verstuurd naar $ownerName.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final communicationStyle = ref.watch(preferencesProvider).communicationStyle;

    final Widget creamBody;
    if (_loading) {
      creamBody = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _creamSheetHandle(),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: GroupPlanningUi.forest),
            ),
          ),
        ],
      );
    } else if (_loadError != null) {
      creamBody = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _creamSheetHandle(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('😕', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.4,
                        color: GroupPlanningUi.charcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.planLoadingTryAgain),
                      style: FilledButton.styleFrom(
                        backgroundColor: GroupPlanningUi.forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        if (_planMetVriend) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/group-planning');
                        }
                      },
                      child: Text(
                        _planMetVriend ? 'Sluiten' : l10n.moodMatchTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: GroupPlanningUi.stone,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      creamBody = _isOwner
          ? (_ownerWaitingConfirm
              ? _buildOwnerWaitingBody(l10n, communicationStyle)
              : _buildOwnerBody(l10n))
          : _buildGuestBody(l10n, communicationStyle);
    }

    return Scaffold(
      backgroundColor: GroupPlanningUi.moodMatchDeep,
      body: _dayPickerShell(context, l10n, creamBody),
    );
  }

  /// Same Mood Match chrome as lobby / result: dark strip + rounded cream sheet.
  Widget _dayPickerShell(
    BuildContext context,
    AppLocalizations l10n,
    Widget creamBody,
  ) {
    final topInset = MediaQuery.paddingOf(context).top;
    final title = _planMetVriend
        ? 'Jullie datum'
        : l10n.moodMatchDayPickerStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, topInset + 4, 8, 12),
          child: Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
                onPressed: () {
                  if (_planMetVriend) {
                    Navigator.of(context).pop();
                  } else {
                    // Mood Match: hub avoids lobby bounce ("pill flicker").
                    context.go('/group-planning');
                  }
                },
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: Material(
            color: GroupPlanningUi.cream,
            elevation: 8,
            shadowColor: GroupPlanningUi.moodMatchShadow(0.35),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.antiAlias,
            child: creamBody,
          ),
        ),
      ],
    );
  }

  /// Drag handle + spacing, aligned with [GroupPlanningLobbyScreen] cream body.
  Widget _creamSheetHandle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: GroupPlanningUi.stone.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildOwnerWaitingBody(AppLocalizations l10n, String communicationStyle) {
    final guest = _otherParticipantView();
    final guestName = _otherParticipantFirstName(l10n);
    final me = _myMember();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _creamSheetHandle(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _teamHero(me: me, friend: guest),
                      _buildPmvInviteNotes(l10n),
                      const SizedBox(height: 24),
                      Text(
                        _ownerWaitingTitleByStyle(guestName, communicationStyle),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: GroupPlanningUi.charcoal,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _ownerWaitingSubtitleByStyle(guestName, communicationStyle),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: GroupPlanningUi.stone,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _pendingProposalCard(l10n),
                      const SizedBox(height: 24),
                      _BouncingDots(pulse: _pulse),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerBody(AppLocalizations l10n) {
    final guest = _otherParticipantView();
    final guestName = _otherParticipantFirstName(l10n);
    final me = _myMember();
    final myName = me != null ? _firstName(me.displayName) : 'You';
    final communicationStyle = ref.watch(preferencesProvider).communicationStyle;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final waitingOnGuest = _planData != null &&
        uid != null &&
        MoodMatchPlanProposals.dayProposalWaitingOnOther(_planData!, uid);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _creamSheetHandle(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _teamHero(me: me, friend: guest),
                    _buildPmvInviteNotes(l10n),
                    const SizedBox(height: 18),
                    Text(
                      _planMetVriend
                          ? 'Kies jullie datum'
                          : _ownerDateTitleByStyle(l10n, communicationStyle),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: GroupPlanningUi.charcoal,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _planMetVriend
                          ? 'Jij stelt een dag voor — $guestName kan bevestigen of een ander voorstel doen.'
                          : _ownerDateSubtitleByStyle(
                              guestName,
                              communicationStyle,
                            ),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: GroupPlanningUi.stone,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildOwnerDayWheel(l10n),
                    const SizedBox(height: 14),
                    _buildOwnerSlotPicker(l10n),
                    if (_selectedDayIndex != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: GroupPlanningUi.softCardDecoration(
                          background: GroupPlanningUi.forestTint,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _NoteAvatar(
                                    url: _resolvedMeAvatarUrl(),
                                    fallback: myName,
                                    ring: const Color(0xFFE8784A)),
                                Transform.translate(
                                  offset: const Offset(-8, 0),
                                  child: _NoteAvatar(
                                      url: _resolvedFriendAvatarUrl(guest),
                                      fallback: guestName,
                                      ring: GroupPlanningUi.forest),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    l10n.moodMatchDayPickerNote(guestName),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: GroupPlanningUi.forest,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                l10n.moodMatchDayPickerPreview(
                                  myName,
                                  _dayLabel(l10n, _selectedDayIndex!),
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: GroupPlanningUi.charcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GroupPlanningUi.primaryCta(
              label: waitingOnGuest
                  ? _ownerWaitingTitleByStyle(guestName, communicationStyle)
                  : l10n.moodMatchPlanV2SendToGuest(guestName),
              onPressed: _selectedDayIndex != null &&
                      !_confirming &&
                      !waitingOnGuest
                  ? _confirmDay
                  : null,
              busy: _confirming,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerDayWheel(AppLocalizations l10n) {
    final selected = _selectedDayIndex ?? 0;
    return Container(
      height: 188,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GroupPlanningUi.cardBorder),
        boxShadow: [
          BoxShadow(
            color: GroupPlanningUi.moodMatchShadow(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: GroupPlanningUi.forestTint.withValues(alpha: 0.55),
                border: Border.all(
                  color: GroupPlanningUi.forest.withValues(alpha: 0.28),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _ownerDayWheelController,
            itemExtent: 44,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 2.2,
            perspective: 0.0025,
            squeeze: 1.08,
            onSelectedItemChanged: (idx) {
              HapticFeedback.selectionClick();
              if (!mounted) return;
              setState(() => _selectedDayIndex = idx);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _horizonDays,
              builder: (context, i) {
                final day = _dayFromIndex(i);
                final isToday = i == 0;
                final isSel = i == selected;
                final label = isToday
                    ? '${l10n.moodMatchDayPickerToday} · ${DateFormat('EEE d MMM').format(day)}'
                    : DateFormat('EEE d MMM').format(day);
                return Center(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: isSel ? 16 : 14,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel
                          ? GroupPlanningUi.charcoal
                          : GroupPlanningUi.stone.withValues(alpha: 0.8),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSlotPicker(AppLocalizations l10n) {
    final slotLabel = _selectedSlot == null
        ? l10n.moodMatchDayPickerWholeDay
        : _slotLabel(l10n, _selectedSlot!);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GroupPlanningUi.cardBorder),
        boxShadow: [
          BoxShadow(
            color: GroupPlanningUi.moodMatchShadow(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.moodMatchTimePickerTitle,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: GroupPlanningUi.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$slotLabel ${_selectedSlot != null ? '· ${_slotRanges[_selectedSlot!]}' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: GroupPlanningUi.stone,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ownerSlotChip(
                label: l10n.moodMatchDayPickerWholeDay,
                emoji: '🗓️',
                selected: _selectedSlot == null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedSlot = null);
                },
              ),
              for (final slot in _slots)
                _ownerSlotChip(
                  label: '${_slotLabel(l10n, slot)} ${_slotRanges[slot]}',
                  emoji: _slotEmojis[slot] ?? '🕐',
                  selected: _selectedSlot == slot,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedSlot = slot);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ownerSlotChip({
    required String label,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? GroupPlanningUi.forest : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? GroupPlanningUi.forest : GroupPlanningUi.cardBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: GroupPlanningUi.forest.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : GroupPlanningUi.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestBody(AppLocalizations l10n, String communicationStyle) {
    final owner = _ownerMemberView();
    final me = _myMember();
    final ownerName = owner != null
        ? _firstName(owner.displayName)
        : l10n.moodMatchFriendThey;
    final sentCounter = _guestHasSentCounterProposal;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _creamSheetHandle(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _teamHero(me: me, friend: owner),
                      _buildPmvInviteNotes(l10n),
                      const SizedBox(height: 24),
                      Text(
                        sentCounter
                            ? 'Voorstel verstuurd'
                            : _guestWaitingHeadlineByStyle(
                                ownerName,
                                communicationStyle,
                              ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: GroupPlanningUi.charcoal,
                          height: 1.3,
                        ),
                      ),
                      if (sentCounter) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Je voorstel ligt bij $ownerName. Zodra die akkoord gaat, staat jullie datum vast.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: GroupPlanningUi.stone,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _pendingProposalCard(l10n),
                      const SizedBox(height: 16),
                      _BouncingDots(pulse: _pulse),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingProposalCard(AppLocalizations l10n) {
    final date = _session?.plannedDate?.trim();
    final rawSlot = _session?.proposedSlot?.trim();
    final slot = (rawSlot == null || rawSlot.isEmpty) ? 'whole_day' : rawSlot;
    final dayLabel = (date == null || date.isEmpty) ? null : _fmtDayIso(date);
    final line = dayLabel == null ? null : '$dayLabel · ${_slotLabel(l10n, slot)}';
    if (line == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GroupPlanningUi.forestTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GroupPlanningUi.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: GroupPlanningUi.forest,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              line,
              textAlign: TextAlign.left,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GroupPlanningUi.forest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top-of-screen team hero: [me] — [Moody] — [match] reinforces the "we're in
/// this together" feel across every Mood Match step.
class _DayPickerTeamHero extends StatelessWidget {
  const _DayPickerTeamHero({
    this.me,
    this.friend,
    this.meAvatarUrl,
    this.friendAvatarUrl,
    this.meFallbackLabel = 'J',
    this.friendFallbackLabel = '?',
  });

  final GroupMemberView? me;
  final GroupMemberView? friend;
  final String? meAvatarUrl;
  final String? friendAvatarUrl;
  final String meFallbackLabel;
  final String friendFallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DayPickerAvatar(
          member: me,
          avatarUrl: meAvatarUrl,
          fallbackLabel: meFallbackLabel,
        ),
        const SizedBox(width: 10),
        const SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: MoodyCharacter(size: 32, mood: 'happy'),
          ),
        ),
        const SizedBox(width: 10),
        _DayPickerAvatar(
          member: friend,
          avatarUrl: friendAvatarUrl,
          fallbackLabel: friendFallbackLabel,
        ),
      ],
    );
  }
}

class _DayPickerAvatar extends StatelessWidget {
  const _DayPickerAvatar({
    required this.member,
    required this.fallbackLabel,
    this.avatarUrl,
  });

  final GroupMemberView? member;
  final String? avatarUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = avatarUrl?.trim();
    final fromMember = member?.avatarUrl?.trim();
    final url = (resolved != null && resolved.isNotEmpty)
        ? resolved
        : fromMember;
    final name = member?.displayName ?? '';
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : fallbackLabel;

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GroupPlanningUi.forestTint,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: GroupPlanningUi.moodMatchShadow(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? WmNetworkImage(
                url,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _DayPickerAvatarInitial(label: initial),
              )
            : _DayPickerAvatarInitial(label: initial),
      ),
    );
  }
}

class _DayPickerAvatarInitial extends StatelessWidget {
  const _DayPickerAvatarInitial({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GroupPlanningUi.forestTint,
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: GroupPlanningUi.forest,
        ),
      ),
    );
  }
}

/// Small round avatar (with a colored ring) used inside the "owner suggests"
/// note card. Falls back to initials when no avatar URL is present.
class _NoteAvatar extends StatelessWidget {
  const _NoteAvatar({
    required this.url,
    required this.fallback,
    required this.ring,
  });

  final String? url;
  final String fallback;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final initial = fallback.isNotEmpty ? fallback[0].toUpperCase() : '?';
    final u = url?.trim();
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring,
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (u != null && u.isNotEmpty)
          ? WmNetworkImage(
              u,
              width: 30,
              height: 30,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                initial,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : Text(
              initial,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }
}

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.pulse});

  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        double dotScale(int i) {
          final phase = (pulse.value + i * 0.18) % 1.0;
          return 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
        }

        Widget dot(int i) => Transform.scale(
              scale: dotScale(i),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: GroupPlanningUi.forest,
                  shape: BoxShape.circle,
                ),
              ),
            );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(0),
            const SizedBox(width: 8),
            dot(1),
            const SizedBox(width: 8),
            dot(2),
          ],
        );
      },
    );
  }
}
