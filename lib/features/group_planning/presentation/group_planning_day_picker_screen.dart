import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_v2.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_plan_proposals.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Change 3 — Day picker screen.
/// OWNER picks the shared day; GUEST waits and then confirms.
class GroupPlanningDayPickerScreen extends ConsumerStatefulWidget {
  const GroupPlanningDayPickerScreen({super.key, required this.sessionId});

  final String sessionId;

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
  bool _isOwner = false;
  int? _selectedDayIndex; // 0=today, 1=+1, 2=+2, 3=+3
  String? _selectedSlot; // 'morning' | 'afternoon' | 'evening'
  bool _confirming = false;
  // Owner-side state after proposing: we stay on-screen and wait for the
  // guest to either accept or counter-propose. Navigation to the reveal
  // happens when the owner receives a `day_accepted` realtime event.
  bool _ownerWaitingConfirm = false;
  StreamSubscription<List<Map<String, dynamic>>>? _eventSub;
  /// Prevents stacking two guest confirm UIs (e.g. DB recovery + realtime).
  bool _guestDayProposalDialogActive = false;
  /// Same guard for the owner-side counter modal (recovery + realtime can
  /// both fire on the same frame on a cold start / push tap).
  bool _ownerCounterDialogActive = false;

  /// Latest `group_plans.plan_data` (for `dayProposal` ping-pong recovery).
  Map<String, dynamic>? _planData;
  /// Guest: ISO date of the owner's proposal being answered (for counter copy).
  String? _pendingOwnerProposalIso;

  late final AnimationController _pulse;

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
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final results = await Future.wait([
        repo.fetchSession(widget.sessionId),
        repo.fetchMembersWithProfiles(widget.sessionId),
        repo.fetchPlan(widget.sessionId),
      ]);
      final session = results[0] as GroupSessionRow;
      final members = results[1] as List<GroupMemberView>;
      final plan = results[2] as GroupPlanRow?;
      final uid = Supabase.instance.client.auth.currentUser?.id;
      final isOwner = session.createdBy == uid;
      Map<String, dynamic>? planData;
      if (plan != null) {
        planData = GroupPlanV2.normalizePlanData(
          Map<String, dynamic>.from(plan.planData),
        );
      }

      if (!mounted) return;
      var ownerWaiting = false;
      if (isOwner &&
          session.status == 'day_proposed' &&
          (session.plannedDate ?? '').trim().isNotEmpty) {
        ownerWaiting = true;
      }
      setState(() {
        _session = session;
        _members = members;
        _planData = planData;
        _isOwner = isOwner;
        _loading = false;
        if (ownerWaiting) {
          _ownerWaitingConfirm = true;
        }
      });

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
      if (mounted) setState(() => _loading = false);
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
    return DateFormat('EEEE d MMMM').format(dt);
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
      context.go('/group-planning/match-loading/${widget.sessionId}');
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
    final evType = row['event_type'] as String? ?? row['type'] as String?;
    if (evType != 'planUpdate') return null;
    final raw = row['event_data'] ?? row['data'];
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
        return null;
      } catch (_) {
        return null;
      }
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
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
      _eventSub = supabase
          .from('realtime_events')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid)
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
                context.go(
                    '/group-planning/match-loading/${widget.sessionId}');
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
      context.go('/group-planning/match-loading/${widget.sessionId}');
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
    final beforeAt = s.split('@').first.trim();
    final parts = beforeAt.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : '?';
  }

  GroupMemberView? _guestMember() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId != uid) return m;
    }
    return null;
  }

  GroupMemberView? _myMember() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId == uid) return m;
    }
    return null;
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
                      _DayPickerTeamHero(me: me, friend: guest),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 112,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _horizonDays,
                          itemBuilder: (context, i) {
                            final sel = tempDay == i;
                            final isToday = i == 0;
                            final day = _dayFromIndex(i);
                            final abbrev = isToday
                                ? l10n.moodMatchDayPickerToday
                                : DateFormat('EEE').format(day);
                            final dateNum = DateFormat('d').format(day);
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setSheet(() => tempDay = i);
                                },
                                child: AnimatedScale(
                                  scale: sel ? 1.06 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 76,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? GroupPlanningUi.forest
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: sel
                                            ? GroupPlanningUi.forest
                                            : GroupPlanningUi.cardBorder,
                                        width: sel ? 2.2 : 1,
                                      ),
                                      boxShadow: sel
                                          ? [
                                              BoxShadow(
                                                color: GroupPlanningUi.forest
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 16,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 6),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: GroupPlanningUi
                                                    .moodMatchShadow(0.06),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isToday)
                                          Text(
                                            l10n.moodMatchDayPickerToday,
                                            style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: sel
                                                  ? Colors.white
                                                      .withValues(alpha: 0.85)
                                                  : GroupPlanningUi.forest,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        Text(
                                          abbrev,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: sel
                                                ? Colors.white
                                                    .withValues(alpha: 0.8)
                                                : GroupPlanningUi.stone,
                                          ),
                                        ),
                                        Text(
                                          dateNum,
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: sel
                                                ? Colors.white
                                                : GroupPlanningUi.charcoal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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
                      const SizedBox(height: 14),
                      // "Whole day" lets the owner skip the slot picker so
                      // Moody plans morning + afternoon + evening together.
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheet(() => tempSlot = null);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: tempSlot == null
                                  ? GroupPlanningUi.forest
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: tempSlot == null
                                    ? GroupPlanningUi.forest
                                    : GroupPlanningUi.cardBorder,
                                width: tempSlot == null ? 2 : 1,
                              ),
                              boxShadow: tempSlot == null
                                  ? [
                                      BoxShadow(
                                        color: GroupPlanningUi.forest
                                            .withValues(alpha: 0.22),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                const Text('🗓️',
                                    style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.moodMatchDayPickerWholeDay,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: tempSlot == null
                                          ? Colors.white
                                          : GroupPlanningUi.charcoal,
                                    ),
                                  ),
                                ),
                                if (tempSlot == null)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(_slots.length, (i) {
                        final slot = _slots[i];
                        final sel = tempSlot == slot;
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: i < _slots.length - 1 ? 10 : 0),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setSheet(() => tempSlot = slot);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color:
                                    sel ? GroupPlanningUi.forest : Colors.white,
                                borderRadius: BorderRadius.circular(16),
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
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _slotEmojis[slot] ?? '🕐',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_slotLabel(l10n, slot)}  ${_slotRanges[slot]}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: sel
                                                ? Colors.white
                                                : GroupPlanningUi.charcoal,
                                          ),
                                        ),
                                        if (sel) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _slotNote(l10n, slot),
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                              fontStyle: FontStyle.italic,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (sel)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 22),
                      GroupPlanningUi.primaryCta(
                        label: l10n.moodMatchDayPickerSheetDone,
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
  }

  Future<void> _confirmDay() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedDayIndex == null) return;
    setState(() => _confirming = true);
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final iso = _isoDate(_selectedDayIndex!);
      // Slot is now OPTIONAL — when present, Moody plans only that part of
      // the day. When null, Moody plans the whole day (morning + afternoon
      // + evening).
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
    final l10n = AppLocalizations.of(context)!;
    final dt = DateTime.tryParse(isoDate);
    final dayLabel =
        dt != null ? DateFormat('EEEE d MMMM').format(dt) : isoDate;
    final timeLabel = '${_slotLabel(l10n, slot)} · ${_slotRanges[slot] ?? ''}';

    final choice = await _showMoodMatchBlockingSheet<String>(
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.moodMatchOwnerCounterTitle(guestName, dayLabel, timeLabel),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GroupPlanningUi.charcoal,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.moodMatchOwnerCounterBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: GroupPlanningUi.stone,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
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
      context.go('/group-planning/match-loading/${widget.sessionId}');
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
                  l10n.moodMatchGuestConfirmTitleWithTime(dayLabel, timeLabel),
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
                l10n.moodMatchGuestConfirmBody(ownerName, dayLabel, timeLabel),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GroupPlanningUi.charcoal,
                  height: 1.35,
                ),
              ),
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
        context.go('/group-planning/match-loading/${widget.sessionId}');
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

    final sent = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: const BoxDecoration(
              color: GroupPlanningUi.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _horizonDays,
                      itemBuilder: (context, i) {
                        final sel = dayIdx == i;
                        final isToday = i == 0;
                        final day = _dayFromIndex(i);
                        final abbrev = isToday
                            ? l10n.moodMatchDayPickerToday
                            : DateFormat('EEE').format(day);
                        final dateNum = DateFormat('d').format(day);
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setSheet(() => dayIdx = i);
                            },
                            child: AnimatedScale(
                              scale: sel ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 72,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? GroupPlanningUi.forest
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
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
                                                .withValues(alpha: 0.25),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isToday)
                                      Text(
                                        l10n.moodMatchDayPickerToday,
                                        style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: sel
                                              ? Colors.white
                                                  .withValues(alpha: 0.85)
                                              : GroupPlanningUi.forest,
                                        ),
                                      ),
                                    Text(
                                      abbrev,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: sel
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : GroupPlanningUi.stone,
                                      ),
                                    ),
                                    Text(
                                      dateNum,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: sel
                                            ? Colors.white
                                            : GroupPlanningUi.charcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Builder(
                    builder: (context) {
                      Widget partTile(String s) {
                        final sel = slot == s;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheet(() => slot = s);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  sel ? GroupPlanningUi.forest : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: sel
                                    ? GroupPlanningUi.forest
                                    : GroupPlanningUi.cardBorder,
                                width: sel ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _slotEmojis[s] ?? '🕐',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _slotLabel(l10n, s),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? Colors.white
                                        : GroupPlanningUi.charcoal,
                                  ),
                                ),
                                Text(
                                  _slotRanges[s] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: sel
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : GroupPlanningUi.stone,
                                  ),
                                ),
                                if (sel)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white.withValues(alpha: 0.95),
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: partTile('morning')),
                              const SizedBox(width: 10),
                              Expanded(child: partTile('afternoon')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: partTile('evening')),
                              const SizedBox(width: 10),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setSheet(() => slot = null);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: slot == null
                                    ? GroupPlanningUi.forest
                                    : const Color(0xFF2A6049)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: slot == null
                                      ? GroupPlanningUi.forest
                                      : GroupPlanningUi.forest
                                          .withValues(alpha: 0.35),
                                  width: slot == null ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text('🗓️',
                                      style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.moodMatchDayPickerWholeDay,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: slot == null
                                            ? Colors.white
                                            : GroupPlanningUi.charcoal,
                                      ),
                                    ),
                                  ),
                                  if (slot == null)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  GroupPlanningUi.primaryCta(
                    label: l10n.moodMatchGuestCounterSendCta,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

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
        },
      );
    } catch (_) {}

    if (!mounted) return;
    // Guest now waits on the day_accepted echo from owner before navigating.
    // We already own the realtime listener for that event.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final creamBody = _loading
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _creamSheetHandle(),
              const Expanded(
                child: Center(
                  child:
                      CircularProgressIndicator(color: GroupPlanningUi.forest),
                ),
              ),
            ],
          )
        : _isOwner
            ? (_ownerWaitingConfirm
                ? _buildOwnerWaitingBody(l10n)
                : _buildOwnerBody(l10n))
            : _buildGuestBody(l10n);

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
    final title = _isOwner
        ? l10n.moodMatchDayPickerStep
        : l10n.moodMatchDayPickerStepGuest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, topInset + 4, 8, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
                // Always exit to the Mood Match hub instead of popping back
                // into the lobby. The lobby auto-resumes any in-progress
                // session and would immediately bounce the user right back
                // here (the "pill flicker → stuck on the same screen" bug).
                onPressed: () => context.go('/group-planning'),
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

  Widget _buildOwnerWaitingBody(AppLocalizations l10n) {
    final guest = _guestMember();
    final guestName = guest != null
        ? _firstName(guest.displayName)
        : l10n.moodMatchFriendThey;
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
                      _DayPickerTeamHero(me: me, friend: guest),
                      const SizedBox(height: 24),
                      Text(
                        l10n.moodMatchOwnerWaitingConfirmTitle(guestName),
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
                        l10n.moodMatchOwnerWaitingConfirmSub,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: GroupPlanningUi.stone,
                          height: 1.45,
                        ),
                      ),
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
    final guest = _guestMember();
    final guestName = guest != null
        ? _firstName(guest.displayName)
        : l10n.moodMatchFriendThey;
    final me = _myMember();
    final myName = me != null ? _firstName(me.displayName) : 'You';
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
                    _DayPickerTeamHero(me: me, friend: guest),
                    const SizedBox(height: 18),
                    Text(
                      l10n.moodMatchDayPickerTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: GroupPlanningUi.charcoal,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.moodMatchDayPickerSubtitle(guestName),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: GroupPlanningUi.stone,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Material(
                      color: Colors.transparent,
                      elevation: _selectedDayIndex == null ? 10 : 4,
                      shadowColor: GroupPlanningUi.moodMatchShadow(0.12),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: _confirming
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _openOwnerDaySlotSheet(l10n);
                              },
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                GroupPlanningUi.cream,
                              ],
                            ),
                            border: Border.all(
                              color: _selectedDayIndex != null
                                  ? GroupPlanningUi.forest
                                      .withValues(alpha: 0.35)
                                  : GroupPlanningUi.cardBorder,
                              width: _selectedDayIndex != null ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: GroupPlanningUi.forest.withValues(
                                    alpha: _selectedDayIndex != null
                                        ? 0.12
                                        : 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 18),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: GroupPlanningUi.forestTint,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: GroupPlanningUi.forest,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedDayIndex == null
                                            ? l10n
                                                .moodMatchDayPickerOpenSheetCta
                                            : l10n
                                                .moodMatchDayPickerSheetChangeCta,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: GroupPlanningUi.charcoal,
                                          height: 1.25,
                                        ),
                                      ),
                                      if (_selectedDayIndex != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedSlot != null
                                              ? '${_dayLabel(l10n, _selectedDayIndex!)} · ${_slotLabel(l10n, _selectedSlot!)}'
                                              : '${_dayLabel(l10n, _selectedDayIndex!)} · ${l10n.moodMatchDayPickerWholeDay}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: GroupPlanningUi.forest,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: GroupPlanningUi.stone
                                      .withValues(alpha: 0.8),
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
                                    url: me?.avatarUrl,
                                    fallback: myName,
                                    ring: const Color(0xFFE8784A)),
                                Transform.translate(
                                  offset: const Offset(-8, 0),
                                  child: _NoteAvatar(
                                      url: guest?.avatarUrl,
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
                  ? l10n.moodMatchOwnerWaitingConfirmTitle(guestName)
                  : l10n.moodMatchDayPickerCta,
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

  Widget _buildGuestBody(AppLocalizations l10n) {
    final owner = _ownerMemberView();
    final me = _myMember();
    final ownerName = owner != null
        ? _firstName(owner.displayName)
        : l10n.moodMatchFriendThey;

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
                      _DayPickerTeamHero(me: me, friend: owner),
                      const SizedBox(height: 24),
                      Text(
                        l10n.moodMatchGuestWaitingDay(ownerName),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: GroupPlanningUi.charcoal,
                          height: 1.3,
                        ),
                      ),
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
}

/// Top-of-screen team hero: [me] — [Moody] — [match] reinforces the "we're in
/// this together" feel across every Mood Match step.
class _DayPickerTeamHero extends StatelessWidget {
  const _DayPickerTeamHero({this.me, this.friend});

  final GroupMemberView? me;
  final GroupMemberView? friend;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DayPickerAvatar(member: me, fallbackLabel: 'J'),
        const SizedBox(width: 10),
        const SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: MoodyCharacter(size: 32, mood: 'happy'),
          ),
        ),
        const SizedBox(width: 10),
        _DayPickerAvatar(member: friend, fallbackLabel: '?'),
      ],
    );
  }
}

class _DayPickerAvatar extends StatelessWidget {
  const _DayPickerAvatar({
    required this.member,
    required this.fallbackLabel,
  });

  final GroupMemberView? member;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final avatar = member?.avatarUrl;
    final name = member?.displayName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : fallbackLabel;

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
        child: avatar != null && avatar.isNotEmpty
            ? WmNetworkImage(
                avatar,
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
