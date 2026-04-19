import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/services/wandermood_ai_service.dart';
import 'package:wandermood/features/group_planning/data/mood_match_push_intent.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_plan_proposals.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_place_mapper.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_v2.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_labels.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart'
    show GroupMemberView, GroupPlanRow, GroupSessionRow;
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/mood_match_swap_proposal_sheet.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_copy.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/utils/place_type_formatter.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_activity_note.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Mood Match shared plan: 3 slots (owner confirms → send → guest responds).
class GroupPlanningResultScreen extends ConsumerStatefulWidget {
  const GroupPlanningResultScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<GroupPlanningResultScreen> createState() =>
      _GroupPlanningResultScreenState();
}

// Dark header strip matches lobby; cream body matches [GroupPlanningLobbyScreen].
const _wmForest = GroupPlanningUi.forest;
const _wmSunset = Color(0xFFE8784A);
/// Light ink on dark bars (header, loading, bottom CTA strip).
const _textPrimary = Color(0xFFF5F0E8);
const _mint = Color(0xFF5DCAA5);
/// Same as lobby Mood Match body: titles and copy on [GroupPlanningUi.cream].
const _creamInk = GroupPlanningUi.charcoal;
const _creamInkSoft = GroupPlanningUi.stone;

class _GroupPlanningResultScreenState extends ConsumerState<GroupPlanningResultScreen> {
  Map<String, dynamic>? _planData;
  List<GroupMemberView> _members = [];
  GroupSessionRow? _session;
  bool _loading = true;
  String? _error;
  bool _saving = false;
  StreamSubscription<List<Map<String, dynamic>>>? _planSub;
  StreamSubscription<List<Map<String, dynamic>>>? _planUpdateEventsSub;
  final Set<String> _seenPlanUpdateEventIds = {};
  final Set<String> _swapDecisionSheetsShown = {};
  final Set<String> _ownerSlotDraft = {};
  bool _ownerBatchSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
      _startPlanRealtime();
    });
  }

  @override
  void dispose() {
    _planSub?.cancel();
    _planUpdateEventsSub?.cancel();
    super.dispose();
  }

  void _startPlanRealtime() {
    try {
      final supabase = Supabase.instance.client;
      _planSub = supabase
          .from('group_plans')
          .stream(primaryKey: ['id'])
          .eq('session_id', widget.sessionId)
          .listen((rows) {
            if (!mounted || rows.isEmpty) return;
            final latest = Map<String, dynamic>.from(rows.last);
            final rawPlanData = latest['plan_data'];
            if (rawPlanData is! Map) return;
            setState(() {
              _planData = GroupPlanV2.normalizePlanData(
                Map<String, dynamic>.from(rawPlanData),
              );
              if (_isOwner && !_ownerBatchSaving) {
                final oc = _oc(_planData);
                _ownerSlotDraft
                  ..clear()
                  ..addAll({
                    for (final s in GroupPlanV2.slots)
                      if (oc[s] == true) s,
                  });
              }
            });
            _maybePresentSwapDecisionSheet();
          });
    } catch (_) {}
  }

  void _ensurePlanUpdateEventSubscription() {
    if (_planUpdateEventsSub != null) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final supabase = Supabase.instance.client;
      _planUpdateEventsSub = supabase
          .from('realtime_events')
          .stream(primaryKey: ['id'])
          // DB column is `user_id` (see send_realtime_notification); not recipient_id.
          .eq('user_id', uid)
          .listen(
            (rows) {
              if (!mounted) return;
              for (final row in rows) {
                final id = (row['id'] ?? '').toString();
                if (id.isEmpty || _seenPlanUpdateEventIds.contains(id)) {
                  continue;
                }
                _seenPlanUpdateEventIds.add(id);
                _handlePlanUpdateRealtimeRow(Map<String, dynamic>.from(row));
              }
            },
            onError: (_) {},
          );
    } catch (_) {}
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

  String _actorFirstNameFromRow(
    Map<String, dynamic> row,
    AppLocalizations l10n,
  ) {
    final sid = row['related_user_id']?.toString();
    if (sid != null && sid.isNotEmpty) {
      for (final m in _members) {
        if (m.member.userId == sid) return _firstName(m, l10n);
      }
    }
    return l10n.moodMatchFriendThey;
  }

  String _firstNameFromPayloadUsername(
    dynamic raw,
    AppLocalizations l10n,
  ) {
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty) return l10n.moodMatchFriendThey;
    final beforeAt = s.split('@').first.trim();
    final parts = beforeAt.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : l10n.moodMatchFriendThey;
  }

  String _slotLabelForToast(AppLocalizations l10n, String slot) {
    switch (slot) {
      case 'morning':
        return l10n.moodMatchTimePickerMorning;
      case 'afternoon':
        return l10n.moodMatchTimePickerAfternoon;
      case 'evening':
        return l10n.moodMatchTimePickerEvening;
      default:
        return slot;
    }
  }

  bool _isRecentPlanUpdateRow(Map<String, dynamic> row) {
    final tsStr = row['created_at']?.toString() ?? row['timestamp']?.toString();
    if (tsStr == null) return true;
    final t = DateTime.tryParse(tsStr)?.toUtc();
    if (t == null) return true;
    return DateTime.now().toUtc().difference(t) <= const Duration(seconds: 120);
  }

  void _handlePlanUpdateRealtimeRow(Map<String, dynamic> row) {
    final data = _planUpdateDataFromRow(row);
    if (data == null) return;
    final sid = data['session_id']?.toString();
    if (sid != null && sid != widget.sessionId) return;
    if (!_isRecentPlanUpdateRow(row)) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final event = data['event'] as String?;
    final actorName = (event == 'day_guest_declined_original' ||
            event == 'day_counter_proposed')
        ? _firstNameFromPayloadUsername(data['proposed_by_username'], l10n)
        : _actorFirstNameFromRow(row, l10n);

    switch (event) {
      case 'day_guest_declined_original':
        if (_isOwner) {
          showWanderMoodToast(
            context,
            message: l10n.moodMatchToastGuestDeclinedOriginalDay(actorName),
          );
        }
        return;
      case 'day_counter_proposed':
        if (_isOwner) {
          showWanderMoodToast(
            context,
            message: l10n.moodMatchToastGuestProposedNewDay(actorName),
          );
        }
        return;
      case 'plan_ready':
        showWanderMoodToast(
          context,
          message: l10n.moodMatchToastPlanShared(actorName),
        );
        return;
      case 'swap_requested':
        final place = (data['proposed_place_name'] ?? '').toString().trim();
        showWanderMoodToast(
          context,
          message: l10n.moodMatchToastSwapRequested(
            actorName,
            place.isEmpty ? l10n.moodMatchPlanV2PickThis : place,
          ),
        );
        return;
      case 'swap_accepted':
        showWanderMoodToast(
          context,
          message: l10n.moodMatchToastSwapAccepted(actorName),
        );
        return;
      case 'swap_declined':
        final slotRaw = (data['slot'] ?? '').toString();
        showWanderMoodToast(
          context,
          message: l10n.moodMatchToastSwapDeclined(
            actorName,
            _slotLabelForToast(l10n, slotRaw.isEmpty ? 'afternoon' : slotRaw),
          ),
        );
        return;
      case 'slot_confirmed':
        final by = data['confirmed_by'] as String?;
        final slotRaw = (data['slot'] ?? '').toString();
        final slotLabel =
            _slotLabelForToast(l10n, slotRaw.isEmpty ? 'afternoon' : slotRaw);
        final actor = by == 'owner'
            ? _firstName(_ownerMember(), l10n)
            : by == 'guest'
                ? _firstName(_guestMember(), l10n)
                : actorName;
        showWanderMoodToast(
          context,
          message: l10n.moodMatchToastPartnerConfirmedSlot(actor, slotLabel),
        );
        return;
      default:
        return;
    }
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final results = await Future.wait([
        repo.fetchPlan(widget.sessionId),
        repo.fetchMembersWithProfiles(widget.sessionId),
        repo.fetchSession(widget.sessionId),
      ]).timeout(const Duration(seconds: 15));
      final plan = results[0] as GroupPlanRow?;
      final members = results[1] as List<GroupMemberView>;
      final session = results[2] as GroupSessionRow;
      if (!mounted) return;
      if (plan == null) {
        setState(() {
          _loading = false;
          _members = members;
          _session = session;
          _error = l10n.groupPlanResultNoPlan;
        });
        return;
      }
      await MoodMatchSessionPrefs.clear();
      if (!mounted) return;

      var planData = Map<String, dynamic>.from(plan.planData);
      final sessionDate = session.plannedDate?.trim();
      if (sessionDate != null && sessionDate.isNotEmpty) {
        planData['planned_date'] = sessionDate;
      }

      final hadV2Activities = planData['activities'] is List &&
          (planData['activities'] as List).isNotEmpty;
      if (!hadV2Activities) {
        planData = GroupPlanV2.normalizePlanData(planData);
        await repo.updatePlanDataReplace(widget.sessionId, planData);
      } else {
        planData = GroupPlanV2.normalizePlanData(planData);
      }

      setState(() {
        _planData = planData;
        _members = members;
        _session = session;
        _loading = false;
        if (_isOwner && !_ownerBatchSaving) {
          final oc = _oc(planData);
          _ownerSlotDraft
            ..clear()
            ..addAll({
              for (final s in GroupPlanV2.slots) if (oc[s] == true) s,
            });
        }
      });
      _ensurePlanUpdateEventSubscription();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybePresentSwapDecisionSheet();
      });
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.planLoadingErrorNetwork;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _maybePresentSwapDecisionSheet() {
    if (!mounted || _loading || _planData == null || _session == null) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final ownerId = _session!.createdBy;
    final guestId = _guestMember()?.member.userId;

    final fromPush = MoodMatchPushIntent.takePendingSwapSlot();
    String? routeSlot;
    try {
      routeSlot = GoRouterState.of(context).uri.queryParameters['wmSwapSlot'];
    } catch (_) {
      routeSlot = null;
    }
    final targetSlot = (fromPush != null && fromPush.isNotEmpty)
        ? fromPush
        : (routeSlot != null && routeSlot.isNotEmpty ? routeSlot : null);

    String? slot = MoodMatchPlanProposals.pendingSwapSlotForResponder(
      _planData,
      uid,
      ownerId,
      guestId,
    );
    if (targetSlot != null) {
      final req = GroupPlanV2.swapRequestForSlot(_planData, targetSlot);
      if (req != null) {
        final by = GroupPlanV2.swapRequestedByUserId(req);
        final addressedTo = by == ownerId ? guestId : ownerId;
        if (addressedTo == uid) slot = targetSlot;
      }
    }
    if (slot == null) return;
    final key = '${widget.sessionId}|$slot';
    if (_swapDecisionSheetsShown.contains(key)) return;

    final req = GroupPlanV2.swapRequestForSlot(_planData, slot);
    if (req == null) return;
    final swapBy = GroupPlanV2.swapRequestedByUserId(req);
    if (swapBy == null) return;
    final guestIsResponder = swapBy == ownerId;
    final ownerIsResponder = swapBy != ownerId;
    _swapDecisionSheetsShown.add(key);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showMoodMatchSwapDecisionSheet(
        context: context,
        ref: ref,
        sessionId: widget.sessionId,
        slot: slot!,
        planData: _planData!,
        ownerUserId: ownerId,
        guestUserId: guestId,
        guestIsResponder: guestIsResponder,
        ownerIsResponder: ownerIsResponder,
      );
      if (mounted) {
        _swapDecisionSheetsShown.remove(key);
        await _load();
      }
    });
  }

  /// First name or @handle for copy. [GroupMemberView.displayName] is often
  /// `@username` only — `split('@').first` would be empty without this.
  String _firstName(GroupMemberView? m, AppLocalizations l10n) {
    if (m == null) return l10n.moodMatchFriendThey;
    final raw = m.displayName.trim();
    if (raw.isEmpty) return l10n.moodMatchFriendThey;

    String candidate;
    if (raw.startsWith('@')) {
      candidate = raw.substring(1).split(RegExp(r'\s+')).first.trim();
    } else {
      final beforeAt = raw.split('@').first.trim();
      final parts = beforeAt.split(RegExp(r'\s+'));
      candidate = parts.isNotEmpty ? parts.first.trim() : '';
    }
    if (candidate.isEmpty) return l10n.moodMatchFriendThey;
    return candidate;
  }

  GroupMemberView? _ownerMember() {
    final oid = _session?.createdBy;
    if (oid == null) return null;
    for (final m in _members) {
      if (m.member.userId == oid) return m;
    }
    return null;
  }

  GroupMemberView? _guestMember() {
    final oid = _session?.createdBy;
    for (final m in _members) {
      if (m.member.userId != oid) return m;
    }
    return null;
  }

  bool get _isOwner {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid != null && uid == _session?.createdBy;
  }

  bool _sentToGuest(Map<String, dynamic>? data) =>
      data?['sentToGuest'] == true;

  Map<String, bool> _oc(Map? p) =>
      GroupPlanV2.boolSlotMap(p?['ownerConfirmed']);

  Map<String, bool> _gc(Map? p) =>
      GroupPlanV2.boolSlotMap(p?['guestConfirmed']);

  bool _allOwnerConfirmed(Map<String, dynamic>? p) {
    if (p == null) return false;
    final m = _oc(p);
    final need = GroupPlanV2.slotsRequiringConfirmation(p);
    return need.every((s) => m[s] == true);
  }

  bool _allGuestConfirmed(Map<String, dynamic>? p) {
    if (p == null) return false;
    final m = _gc(p);
    final need = GroupPlanV2.slotsRequiringConfirmation(p);
    return need.every((s) => m[s] == true);
  }

  bool _hasPendingSwap(Map<String, dynamic>? p) {
    if (p == null) return false;
    final r = p['swapRequests'];
    if (r is! Map || r.isEmpty) return false;
    return r.values.any((v) => v is Map);
  }

  /// True when the **owner** proposed at least one swap — guest must respond
  /// on the cards (not only wait on the owner).
  bool _swapAwaitingGuestResponse(Map<String, dynamic>? plan) {
    final ownerId = _session?.createdBy;
    if (ownerId == null || plan == null) return false;
    final reqs = plan['swapRequests'];
    if (reqs is! Map) return false;
    for (final v in reqs.values) {
      if (v is! Map) continue;
      final by = GroupPlanV2.swapRequestedByUserId(
        Map<String, dynamic>.from(v),
      );
      if (by == ownerId) return true;
    }
    return false;
  }

  /// Open the standard place detail screen for an activity, just like the
  /// Explorer screen does. Uses the activity's place_id (Moody attaches one
  /// for every Google Places result).
  void _openPlaceDetail(Map<String, dynamic> activity) {
    final raw = (activity['place_id'] ??
            activity['placeId'] ??
            (activity['location'] is Map
                ? (activity['location'] as Map)['placeId'] ??
                    (activity['location'] as Map)['place_id']
                : null))
        ?.toString()
        .trim();
    if (raw == null || raw.isEmpty) return;
    context.push('/place/${Uri.encodeComponent(raw)}');
  }

  Future<String?> _resolvePlannedDateString() async {
    var date = _planData?['planned_date'] as String?;
    if (date == null || date.isEmpty) {
      date = _session?.plannedDate;
    }
    if (date == null || date.isEmpty) {
      date = await MoodMatchSessionPrefs.readPlannedDate(widget.sessionId);
    }
    final trimmed = date?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  void _goToMyDayHome(
    String? plannedDate, {
    bool showMoodMatchSuccessToast = false,
  }) {
    final extra = <String, dynamic>{};
    if (plannedDate != null &&
        plannedDate.isNotEmpty &&
        DateTime.tryParse(plannedDate) != null) {
      extra['targetDate'] = plannedDate;
    }
    if (showMoodMatchSuccessToast) {
      extra['moodMatchMyDayToast'] = true;
      extra['moodMatchToastNonce'] = DateTime.now().microsecondsSinceEpoch;
    }
    context.go('/main?tab=0', extra: extra.isEmpty ? null : extra);
  }

  Future<void> _finishNavigateToMyDay(String? plannedDate) async {
    if (!mounted) return;
    _goToMyDayHome(plannedDate, showMoodMatchSuccessToast: true);
  }

  Future<void> _openMyDayAfterPlanSent() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final date = await _resolvePlannedDateString();
    if (!mounted) return;
    if (date == null) {
      // No date locked in — fall back to the day picker so the owner can pick
      // one. Without a date we cannot persist scheduled activities.
      context.go('/group-planning/day-picker/${widget.sessionId}');
      return;
    }
    setState(() => _saving = true);
    try {
      // Persist the agreed plan into scheduled_activities for every member
      // (owner + guest) before opening My Day. Previously this step was
      // missing on the owner path, which is why "Add to My Day" appeared to
      // do nothing for the owner.
      await ref
          .read(groupPlanningRepositoryProvider)
          .saveMoodMatchPlanToMyDayForAllMembers(
            sessionId: widget.sessionId,
            plannedDate: date,
          );
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.moodMatchSaveMyDayFailed(
            kDebugMode ? '$e' : l10n.signupErrorGeneric,
          ),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    await _finishNavigateToMyDay(date);
  }

  /// Guest: both sides confirmed — add stops to My Day for everyone, then open My Day.
  Future<void> _finalizeGuestPlanToMyDay(AppLocalizations l10n) async {
    if (_saving) return;
    final date = await _resolvePlannedDateString();
    if (!mounted) return;
    if (date == null) {
      context.go('/group-planning/day-picker/${widget.sessionId}');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(groupPlanningRepositoryProvider)
          .saveMoodMatchPlanToMyDayForAllMembers(
            sessionId: widget.sessionId,
            plannedDate: date,
          );
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.moodMatchSaveMyDayFailed(
            kDebugMode ? '$e' : l10n.signupErrorGeneric,
          ),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    await _finishNavigateToMyDay(date);
  }

  String _slotTitle(AppLocalizations l10n, String slot) {
    switch (slot) {
      case 'morning':
        return l10n.moodMatchTimePickerMorning;
      case 'afternoon':
        return l10n.moodMatchTimePickerAfternoon;
      case 'evening':
        return l10n.moodMatchTimePickerEvening;
      default:
        return slot;
    }
  }

  LinearGradient _slotGradient(String slot) {
    switch (slot) {
      case 'morning':
        return LinearGradient(
          colors: [
            _wmForest,
            _wmForest.withValues(alpha: 0.6),
          ],
        );
      case 'afternoon':
        return LinearGradient(
          colors: [
            const Color(0xFF8B6914),
            const Color(0xFFC4A35A),
          ],
        );
      case 'evening':
        return LinearGradient(
          colors: [
            const Color(0xFF3D2A5C),
            const Color(0xFF5C3D7A),
          ],
        );
      default:
        return LinearGradient(
          colors: [
            GroupPlanningUi.forestTint,
            GroupPlanningUi.forestTint.withValues(alpha: 0.5),
          ],
        );
    }
  }

  bool _ownerLocksPlanWhileGuestReviews(Map<String, dynamic>? p) {
    if (p == null || !_isOwner || !_sentToGuest(p)) return false;
    return !_allGuestConfirmed(p);
  }

  void _toggleOwnerSlotDraft(String slot) {
    if (!_isOwner || _planData == null) return;
    if (_ownerLocksPlanWhileGuestReviews(_planData)) return;
    if (_ownerBatchSaving || _saving) return;
    setState(() {
      if (_ownerSlotDraft.contains(slot)) {
        _ownerSlotDraft.remove(slot);
      } else {
        _ownerSlotDraft.add(slot);
      }
    });
  }

  Future<void> _commitOwnerSlotDraft(AppLocalizations l10n) async {
    if (_ownerBatchSaving || !_isOwner || _planData == null) return;
    if (_ownerSlotDraft.length != GroupPlanV2.slots.length) return;
    setState(() => _ownerBatchSaving = true);
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      for (final s in GroupPlanV2.slots) {
        final want = _ownerSlotDraft.contains(s);
        final have = _oc(_planData)[s] == true;
        if (want != have) {
          await repo.setOwnerSlotConfirmed(widget.sessionId, s, want);
        }
      }
      await _load();
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(context, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _ownerBatchSaving = false);
    }
  }

  Future<void> _onSendToGuest(AppLocalizations l10n) async {
    final guest = _guestMember();
    if (guest == null || !_allOwnerConfirmed(_planData)) return;
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(groupPlanningRepositoryProvider).sendPlanToGuest(
            sessionId: widget.sessionId,
            guestUserId: guest.member.userId,
          );
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.moodMatchPlanV2SentToGuest(_firstName(guest, l10n)),
        );
      }
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onGuestConfirmSlot(String slot) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(groupPlanningRepositoryProvider)
          .setGuestSlotConfirmed(widget.sessionId, slot, true);
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickSwapAlternative(
    String slot,
    Map<String, dynamic> activity,
  ) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(groupPlanningRepositoryProvider).setSwapRequest(
            sessionId: widget.sessionId,
            slot: slot,
            proposedActivity: activity,
          );
      final owner = _ownerMember();
      final guest = _guestMember();
      final uid = Supabase.instance.client.auth.currentUser?.id;
      final String? notifyUserId = uid != null && owner != null &&
              uid == owner.member.userId
          ? guest?.member.userId
          : owner?.member.userId;
      final sent = _sentToGuest(_planData);
      // Draft phase: owner refines before "Send to guest" — no swap ping to guest.
      if (notifyUserId != null && sent) {
        try {
          await ref.read(groupPlanningRepositoryProvider).sendPlanUpdateEvent(
                targetUserId: notifyUserId,
                sessionId: widget.sessionId,
                payload: {
                  'event': 'swap_requested',
                  'slot': slot,
                  'session_id': widget.sessionId,
                  'proposed_place_name':
                      (activity['name'] ?? activity['title'] ?? '').toString(),
                },
              );
        } catch (_) {}
      }
      if (mounted) Navigator.of(context).pop();
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _ensureSwapPool(String slot) async {
    final pools = GroupPlanV2.swapPools(_planData);
    if (pools[slot]!.length >= 3) return;
    final moods = (_planData!['moods'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList() ??
        ['relaxed'];
    final pos = await ref.read(userLocationProvider.future);
    final lat = pos?.latitude ?? 52.3676;
    final lng = pos?.longitude ?? 4.9041;
    final ai = await WanderMoodAIService.getRecommendations(
      moods: moods,
      latitude: lat,
      longitude: lng,
      plannedDate: _planData!['planned_date'] as String?,
      groupMatch: true,
    );
    final extras = ai.recommendations
        .map(GroupPlanV2.aiRecommendationToActivityMap)
        .toList();
    if (extras.isEmpty) return;
    await ref.read(groupPlanningRepositoryProvider).appendSwapPoolForSlot(
          sessionId: widget.sessionId,
          slot: slot,
          extras: extras.take(8).toList(),
        );
    await _load();
  }

  Future<void> _openSwapSheet(String slot, AppLocalizations l10n) async {
    await _ensureSwapPool(slot);
    if (!mounted) return;
    final pools = GroupPlanV2.swapPools(_planData);
    var options = List<Map<String, dynamic>>.from(pools[slot] ?? []);
    if (options.isEmpty) {
      await _ensureSwapPool(slot);
      await _load();
      if (!mounted) return;
      options = List<Map<String, dynamic>>.from(
        GroupPlanV2.swapPools(_planData)[slot] ?? [],
      );
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: GroupPlanningUi.moodMatchDeepSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.moodMatchPlanV2SwapSheetTitle(_slotTitle(l10n, slot)),
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.moodMatchPlanV2SwapSheetMoody,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: _textPrimary.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length.clamp(0, 5),
                    itemBuilder: (_, i) {
                      final o = options[i];
                      final name =
                          (o['name'] ?? o['title'] ?? 'Place').toString();
                      final rating = (o['rating'] as num?)?.toDouble() ?? 0;
                      final url = (o['imageUrl'] ?? '').toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: GroupPlanningUi.moodMatchDeep,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _saving
                                ? null
                                : () => _pickSwapAlternative(slot, o),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: url.isNotEmpty
                                          ? WmPlacePhotoNetworkImage(
                                              url,
                                              fit: BoxFit.cover,
                                            )
                                          : ColoredBox(color: _wmForest),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '★ ${rating.toStringAsFixed(1)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: _textPrimary.withValues(
                                                alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    l10n.moodMatchPlanV2PickThis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _mint,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _ownerResolveSwap(
    String slot,
    bool accept,
    AppLocalizations l10n,
  ) async {
    final guest = _guestMember();
    if (guest == null) return;
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(groupPlanningRepositoryProvider).ownerResolveSwap(
            sessionId: widget.sessionId,
            slot: slot,
            accept: accept,
            guestUserId: guest.member.userId,
          );
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _guestCancelSwap(String slot) async {
    final owner = _ownerMember();
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(groupPlanningRepositoryProvider)
          .clearSwapRequest(widget.sessionId, slot);
      if (owner != null) {
        try {
          await ref.read(groupPlanningRepositoryProvider).sendPlanUpdateEvent(
                targetUserId: owner.member.userId,
                sessionId: widget.sessionId,
                payload: {
                  'event': 'swap_declined',
                  'slot': slot,
                  'session_id': widget.sessionId,
                },
              );
        } catch (_) {}
      }
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Owner withdraws their own pending swap suggestion before the guest acts.
  Future<void> _ownerWithdrawSwap(String slot) async {
    final guest = _guestMember();
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(groupPlanningRepositoryProvider)
          .clearSwapRequest(widget.sessionId, slot);
      if (guest != null && _sentToGuest(_planData)) {
        try {
          await ref.read(groupPlanningRepositoryProvider).sendPlanUpdateEvent(
                targetUserId: guest.member.userId,
                sessionId: widget.sessionId,
                payload: {
                  'event': 'swap_declined',
                  'slot': slot,
                  'session_id': widget.sessionId,
                },
              );
        } catch (_) {}
      }
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _guestResolveSwap(
    String slot,
    bool accept,
    AppLocalizations l10n,
  ) async {
    final owner = _ownerMember();
    if (owner == null) return;
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(groupPlanningRepositoryProvider).guestResolveSwap(
            sessionId: widget.sessionId,
            slot: slot,
            accept: accept,
            ownerUserId: owner.member.userId,
          );
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        backgroundColor: GroupPlanningUi.moodMatchDeep,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MoodyCharacter(size: 100, mood: 'thinking'),
              const SizedBox(height: 16),
              Text(
                l10n.groupPlanLoadingCompactHeadline,
                style: GoogleFonts.poppins(
                  color: _textPrimary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: GroupPlanningUi.moodMatchDeep,
        appBar: AppBar(
          backgroundColor: GroupPlanningUi.moodMatchDeep,
          foregroundColor: _textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.go('/group-planning'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: _textPrimary.withValues(alpha: 0.7)),
            ),
          ),
        ),
      );
    }

    final plan = _planData!;
    final owner = _ownerMember();
    final guest = _guestMember();
    final ownerName = _firstName(owner, l10n);
    final guestName = _firstName(guest, l10n);
    // Result-screen Moody line: do NOT reuse the reveal paragraph (that one
    // recaps "matching vibes" — repeating it here makes Moody sound robotic).
    // Pick a result-specific line from a small rotating set, keyed off the
    // session id so it stays stable across rebuilds for the same plan.
    // Hero shows a short teaser only (score lives on reveal).
    final commStyle = ref.watch(preferencesProvider).communicationStyle;
    final moodyLineFull = _isOwner
        ? moodMatchPlanResultMoodyLine(
            l10n,
            sessionId: widget.sessionId,
            guestName: guestName,
            commStyle: commStyle,
            backendOverride: plan['moodyMessageResult'] as String?,
          )
        : l10n.moodMatchPlanV2GuestMoody(ownerName);
    final moodyLineHero = moodMatchResultHeroMoodyTeaser(moodyLineFull);

    final dateStr = plan['planned_date'] as String? ??
        _session?.plannedDate ??
        '';
    String dayPretty = dateStr;
    final dt = DateTime.tryParse(dateStr);
    if (dt != null) {
      dayPretty = DateFormat('EEEE d MMMM').format(dt);
    }

    final sent = _sentToGuest(plan);
    final guestWaiting = !_isOwner && !sent;
    final activeSlots =
        GroupPlanV2.slotsRequiringConfirmation(plan).toList();

    return Scaffold(
      backgroundColor: GroupPlanningUi.moodMatchDeep,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Colors.white70,
                    ),
                    onPressed: () => context.go('/group-planning'),
                  ),
                  Expanded(
                    child: Text(
                      l10n.moodMatchTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 23,
                        height: 1.1,
                        letterSpacing: -0.4,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    onPressed: _load,
                  ),
                ],
              ),
            ),
            if (_isOwner &&
                _sentToGuest(plan) &&
                !_allGuestConfirmed(plan)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      l10n.moodMatchPlanSentToGuestBanner(guestName),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Expanded(
              child: guestWaiting
                  ? Material(
                      color: GroupPlanningUi.cream,
                      elevation: 8,
                      shadowColor: GroupPlanningUi.moodMatchShadow(0.35),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _guestWaitingBody(l10n, ownerName),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: GroupPlanningUi.moodMatchDeepSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      GroupPlanningUi.moodMatchShadow(0.4),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _headerAvatars(
                                    owner,
                                    guest,
                                    ownerName,
                                    guestName,
                                  ),
                                  const SizedBox(height: 10),
                                  _moodyHeroLine(
                                    moodyLineHero,
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Material(
                            color: GroupPlanningUi.cream,
                            elevation: 8,
                            shadowColor:
                                GroupPlanningUi.moodMatchShadow(0.35),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(28),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                120,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 42,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: GroupPlanningUi.stone
                                            .withValues(alpha: 0.25),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (dateStr.isNotEmpty) ...[
                                    _contextPill(
                                      l10n.moodMatchPlanV2ContextPlannedDay(
                                        dayPretty,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ] else
                                    const SizedBox(height: 6),
                                  _planMoodsSummary(l10n, plan),
                                  if (_isOwner)
                                    _ownerSwapBanners(l10n, guestName),
                                  for (final slot in activeSlots)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: _slotCard(
                                        slot,
                                        l10n,
                                        ownerName,
                                        guestName,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            if (!guestWaiting) _bottomBar(l10n, ownerName, guestName),
          ],
        ),
      ),
    );
  }

  Widget _guestWaitingBody(AppLocalizations l10n, String ownerName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MoodyCharacter(size: 88, mood: 'waiting'),
            const SizedBox(height: 20),
            Text(
              l10n.moodMatchPlanV2GuestWaitingShare(ownerName),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _creamInk,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerAvatars(
    GroupMemberView? owner,
    GroupMemberView? guest,
    String ownerName,
    String guestName, {
    bool forLightBackground = false,
  }) {
    final nameColor = forLightBackground
        ? _creamInk.withValues(alpha: 0.88)
        : _textPrimary.withValues(alpha: 0.88);
    final plusColor = forLightBackground
        ? _creamInkSoft.withValues(alpha: 0.45)
        : _textPrimary.withValues(alpha: 0.35);

    Widget av(GroupMemberView? m, String label) {
      final url = m?.avatarUrl?.trim();
      return Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _wmForest,
            backgroundImage:
                url != null && url.isNotEmpty ? NetworkImage(url) : null,
            child: url == null || url.isEmpty
                ? Text(
                    label.isNotEmpty ? label[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: nameColor,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        av(owner, ownerName),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '+',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: plusColor,
            ),
          ),
        ),
        av(guest, guestName),
      ],
    );
  }

  /// Moody as part of the hero — no “boxed” callout; matches reveal energy.
  Widget _moodyHeroLine(
    String text, {
    bool forLightBackground = false,
    int? maxLines,
  }) {
    final textColor = forLightBackground
        ? _creamInk.withValues(alpha: 0.88)
        : _textPrimary.withValues(alpha: 0.88);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MoodyCharacter(size: 50, mood: 'happy'),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              maxLines: maxLines,
              overflow:
                  maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.45,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _planMoodsSummary(AppLocalizations l10n, Map<String, dynamic> plan) {
    final raw = plan['moods'];
    final tags = <String>[];
    if (raw is List<dynamic>) {
      for (final e in raw) {
        final s = e.toString().trim().toLowerCase();
        if (s.isNotEmpty && !tags.contains(s)) tags.add(s);
      }
    }
    if (tags.isEmpty) return const SizedBox.shrink();
    final labels =
        tags.map((t) => groupPlanLocalizedMoodTag(l10n, t)).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: Text(
          l10n.moodMatchPlanV2BasedOnMoods(labels),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _creamInkSoft,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _contextPill(String text) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: GroupPlanningUi.forest.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: GroupPlanningUi.charcoal.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: GroupPlanningUi.forest,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: _creamInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ownerSwapBanners(AppLocalizations l10n, String guestName) {
    if (!_isOwner) return const SizedBox.shrink();
    final reqs = _planData?['swapRequests'];
    if (reqs is! Map || reqs.isEmpty) return const SizedBox.shrink();
    final widgets = <Widget>[];
    final ownerId = _session?.createdBy;
    for (final slot in GroupPlanV2.slots) {
      final r = reqs[slot];
      if (r is! Map) continue;
      final by = GroupPlanV2.swapRequestedByUserId(
        Map<String, dynamic>.from(r),
      );
      // Guest-initiated only — owner proposals are handled on the guest's card.
      if (by != null && ownerId != null && by == ownerId) continue;
      final proposed = r['proposedActivity'];
      if (proposed is! Map) continue;
      final propName =
          (proposed['name'] ?? proposed['title'] ?? '').toString();
      final act = GroupPlanV2.activityForSlot(_planData, slot);
      final origName =
          (act?['name'] ?? act?['title'] ?? '').toString();
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _wmSunset.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: _wmSunset, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.moodMatchPlanV2SwapBannerTitle(
                        guestName,
                        _slotTitle(l10n, slot),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _creamInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.moodMatchPlanV2SwapBannerSubtitle(propName, origName),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _creamInkSoft,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => _ownerResolveSwap(slot, false, l10n),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _wmForest,
                        side: BorderSide(
                          color: _wmForest.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        l10n.moodMatchPlanV2KeepOriginal(origName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () => _ownerResolveSwap(slot, true, l10n),
                      style: FilledButton.styleFrom(
                        backgroundColor: _wmForest,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        l10n.moodMatchPlanV2AcceptSwap(propName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: widgets);
  }

  Widget _slotCard(
    String slot,
    AppLocalizations l10n,
    String ownerName,
    String guestName,
  ) {
    final act = GroupPlanV2.activityForSlot(_planData, slot);
    if (act == null) {
      return Text(
        slot,
        style: const TextStyle(color: _creamInk),
      );
    }
    final idx = GroupPlanV2.slotIndex(slot);
    final place = placeFromGroupPlanRecommendation(
      act,
      sessionId: widget.sessionId,
      index: idx,
    );
    final oc = _oc(_planData);
    final gc = _gc(_planData);
    final ownerOk = oc[slot] == true;
    final guestOk = gc[slot] == true;
    final swapReq = GroupPlanV2.swapRequestForSlot(_planData, slot);
    final pendingSwap = swapReq != null;
    final swapBy =
        swapReq != null ? GroupPlanV2.swapRequestedByUserId(swapReq) : null;
    final ownerId = _session?.createdBy;
    final guestUserId = _guestMember()?.member.userId;

    final dur = GroupPlanV2.durationMinutes(act) ?? 60;
    final timeBadge = '$dur min';

    final moodRaw = (act['moodMatch'] ?? '').toString().trim();
    final moodLabel = moodRaw.isNotEmpty
        ? groupPlanLocalizedMoodTag(l10n, moodRaw.toLowerCase())
        : null;

    final titleUpper = _slotTitle(l10n, slot).toUpperCase();

    final sent = _sentToGuest(_planData);
    final draftSelected = _isOwner && !sent && _ownerSlotDraft.contains(slot);

    final lang = ref.read(preferencesProvider).languagePreference;
    final typeLabel = formatPlaceType(
      (place.primaryType ?? act['type'] ?? '').toString(),
      languageCode: lang,
    );
    final rawNote = (act['moodyNote'] ?? '').toString().trim();
    final moodyNote = rawNote.isNotEmpty
        ? rawNote
        : moodMatchActivityNoteLine(
            lang,
            (place.primaryType ?? act['type'] ?? '').toString(),
            moodRaw.isNotEmpty ? moodRaw.toLowerCase() : null,
          );

    String? statusBadge;
    Color statusColor = const Color(0xFF5DCAA5);
    if (guestOk && ownerOk) {
      statusBadge = l10n.moodMatchPlanV2BothIn;
      statusColor = const Color(0xFF5DCAA5);
    } else if (!_isOwner &&
        pendingSwap &&
        ownerId != null &&
        swapBy == ownerId) {
      statusBadge = l10n.moodMatchPlanV2YourTurn;
      statusColor = _wmSunset;
    } else if (!_isOwner &&
        pendingSwap &&
        guestUserId != null &&
        swapBy == guestUserId) {
      statusBadge = l10n.moodMatchPlanV2SwapRequested;
      statusColor = _wmSunset;
    } else if (!_isOwner && ownerOk && !guestOk && !pendingSwap) {
      statusBadge = l10n.moodMatchPlanV2YourTurn;
      statusColor = _wmSunset;
    }

    // Participant line is only shown when both are in (a real "with X"
    // signal), or when there is a meaningful nudge for the guest. Avoids
    // repeating "Confirm before sending" / "Waiting for you" on every card.
    String? participantLine;
    if (guestOk && ownerOk) {
      participantLine = l10n.moodMatchPlanV2YouBothIn(ownerName);
    } else if (!_isOwner && ownerOk && !guestOk && !pendingSwap) {
      participantLine = l10n.moodMatchPlanV2OwnerInYourCall(ownerName);
    }

    final url = (act['imageUrl'] ?? '').toString();
    final ownerM = _ownerMember();
    final guestM = _guestMember();
    final ownerLocks = _ownerLocksPlanWhileGuestReviews(_planData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              switch (slot) {
                'morning' => '🌅',
                'afternoon' => '☀️',
                'evening' => '🌆',
                _ => '',
              },
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              titleUpper,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: _creamInkSoft.withValues(alpha: 0.85),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  height: 1,
                  color: _creamInk.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          elevation: pendingSwap ? 8 : 4,
          shadowColor: GroupPlanningUi.moodMatchShadow(0.12),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: pendingSwap
                ? BorderSide(
                    color: _wmSunset.withValues(alpha: 0.45),
                    width: 1,
                  )
                : draftSelected
                    ? const BorderSide(color: _wmForest, width: 2)
                    : BorderSide(color: GroupPlanningUi.cardBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              if (_isOwner &&
                  !sent &&
                  !pendingSwap &&
                  !ownerLocks) {
                _toggleOwnerSlotDraft(slot);
              } else {
                _openPlaceDetail(act);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 90,
                      width: double.infinity,
                      child: url.isNotEmpty
                          ? WmPlacePhotoNetworkImage(url, fit: BoxFit.cover)
                          : Container(
                              decoration: BoxDecoration(
                                gradient: _slotGradient(slot),
                              ),
                            ),
                    ),
                    if (_isOwner && !sent && !pendingSwap && !ownerLocks)
                      Positioned(
                        left: 2,
                        top: 2,
                        child: Material(
                          color: Colors.black45,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _openPlaceDetail(act),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (draftSelected && statusBadge == null)
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF2A6049),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: GroupPlanningUi.moodMatchShadow(0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timeBadge,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
                        decoration: BoxDecoration(
                          color: GroupPlanningUi.moodMatchShadow(0.55),
                          borderRadius: BorderRadius.circular(999),
                          border: guestOk && ownerOk
                              ? Border.all(
                                  color: const Color(0xFF2A6049)
                                      .withValues(alpha: 0.45),
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _microAvatar(ownerM, ownerOk),
                            Transform.translate(
                              offset: const Offset(-8, 0),
                              child: _microAvatar(guestM, guestOk),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (statusBadge != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2825),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statusBadge,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      place.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _creamInk,
                      ),
                    ),
                    if (moodLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.moodMatchPlanV2ActivityMood(moodLabel),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _wmForest.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '★ ${place.rating.toStringAsFixed(1)} · ${act['cost'] ?? '€€'} · $typeLabel',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _creamInkSoft,
                      ),
                    ),
                    if (moodyNote.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '✨ $moodyNote',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: const Color(0xFFF5F0E8).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (participantLine != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _tinyAvatar(ownerName, true),
                          const SizedBox(width: 6),
                          _tinyAvatar(guestName, true),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              participantLine,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _creamInkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_isOwner) ...[
                      const SizedBox(height: 10),
                      if (pendingSwap &&
                          ownerId != null &&
                          swapBy == ownerId) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _wmSunset.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _wmSunset.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.moodMatchPlanV2WaitingGuestApproveSwap(
                                  guestName,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _creamInk,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => _ownerWithdrawSwap(slot),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _wmForest,
                                  side: BorderSide(
                                    color: _wmForest.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(l10n.moodMatchPlanV2WithdrawSwap),
                              ),
                            ],
                          ),
                        ),
                      ] else if (pendingSwap &&
                          guestUserId != null &&
                          swapBy == guestUserId) ...[
                        Text(
                          l10n.moodMatchPlanV2RespondSwapsOnCards,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _creamInkSoft,
                            fontStyle: FontStyle.italic,
                            height: 1.35,
                          ),
                        ),
                      ] else if (!ownerLocks) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _saving || pendingSwap
                                ? null
                                : () => _openSwapSheet(slot, l10n),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _wmForest,
                              side: BorderSide(
                                color: _wmForest.withValues(alpha: 0.35),
                              ),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              l10n.moodMatchPlanV2SuggestDifferentPlace,
                            ),
                          ),
                        ),
                      ],
                    ],
                    if (!_isOwner &&
                        _sentToGuest(_planData) &&
                        ownerOk &&
                        !guestOk &&
                        !pendingSwap) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _saving
                                  ? null
                                  : () => _onGuestConfirmSlot(slot),
                              style: FilledButton.styleFrom(
                                backgroundColor: _wmForest,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                              ),
                              child: Text(l10n.moodMatchPlanV2WorksForMe),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving || pendingSwap
                                  ? null
                                  : () => _openSwapSheet(slot, l10n),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _wmForest,
                                side: BorderSide(
                                  color: _wmForest.withValues(alpha: 0.35),
                                ),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                              ),
                              child: Text(l10n.moodMatchPlanV2NotForMe),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!_isOwner && pendingSwap) ...[
                      const SizedBox(height: 10),
                      if (ownerId != null && swapBy == ownerId) ...[
                        Text(
                          l10n.moodMatchPlanV2OwnerSuggestedDifferentPlace(
                            ownerName,
                            (swapReq['proposedActivity'] is Map
                                    ? (swapReq['proposedActivity'] as Map)['name'] ??
                                        ''
                                    : '')
                                .toString(),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _wmSunset,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () =>
                                        _guestResolveSwap(slot, false, l10n),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _wmForest,
                                  side: BorderSide(
                                    color: _wmForest.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  l10n.moodMatchPlanV2KeepCurrentPlace,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: _saving
                                    ? null
                                    : () =>
                                        _guestResolveSwap(slot, true, l10n),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _wmForest,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(l10n.moodMatchPlanV2UseOwnersPick),
                              ),
                            ),
                          ],
                        ),
                      ] else if (guestUserId != null &&
                          swapBy == guestUserId) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _wmSunset.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.moodMatchPlanV2YourSwapPendingOwner(
                                  (swapReq['proposedActivity'] is Map
                                          ? (swapReq['proposedActivity']
                                                  as Map)['name'] ??
                                              ''
                                          : '')
                                      .toString(),
                                  ownerName,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _wmSunset,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => _guestCancelSwap(slot),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _wmForest,
                                  side: BorderSide(
                                    color: _wmForest.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(l10n.moodMatchPlanV2WithdrawSwap),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tinyAvatar(String name, bool filled) {
    return CircleAvatar(
      radius: 14,
      backgroundColor:
          filled ? _wmForest : GroupPlanningUi.forestTint,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : _wmForest.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _microAvatar(GroupMemberView? m, bool on) {
    final url = m?.avatarUrl?.trim();
    final raw = (m?.displayName ?? '').trim();
    final letter = raw.isNotEmpty ? raw[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 11,
      backgroundColor: on
          ? const Color(0xFF2A6049).withValues(alpha: 0.2)
          : Colors.white24,
      backgroundImage:
          url != null && url.isNotEmpty ? NetworkImage(url) : null,
      child: url == null || url.isEmpty
          ? Text(
              letter,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: on ? _wmForest : _creamInkSoft,
              ),
            )
          : null,
    );
  }

  Widget _bottomBar(
    AppLocalizations l10n,
    String ownerName,
    String guestName,
  ) {
    final plan = _planData!;
    // Counter (e.g. "2/3") is now part of the CTA label instead of three
    // round checkmarks below it. The user found the dots confusing.
    final needSlots = GroupPlanV2.slotsRequiringConfirmation(plan);
    final guestCount = needSlots.where((s) => _gc(plan)[s] == true).length;
    final total = needSlots.length;

    String ctaLabel;
    VoidCallback? onCta;
    if (_isOwner) {
      if (_sentToGuest(plan)) {
        if (!_allGuestConfirmed(plan) || _hasPendingSwap(plan)) {
          ctaLabel = l10n.moodMatchWaitingGuestReviewPlan(guestName);
          onCta = null;
        } else {
          ctaLabel = l10n.moodMatchPlanV2OpenMyDay;
          onCta = () {
            unawaited(_openMyDayAfterPlanSent());
          };
        }
      } else if (_allOwnerConfirmed(plan)) {
        ctaLabel = l10n.moodMatchPlanV2SendToGuest(guestName);
        onCta = _saving ? null : () => _onSendToGuest(l10n);
      } else {
        final allDraft =
            GroupPlanV2.slots.every(_ownerSlotDraft.contains);
        if (!allDraft) {
          ctaLabel = l10n.moodMatchPlanV2SelectAllThreeToContinue;
          onCta = null;
        } else {
          ctaLabel = l10n.moodMatchPlanV2ImIn;
          onCta = _ownerBatchSaving
              ? null
              : () {
                  unawaited(_commitOwnerSlotDraft(l10n));
                };
        }
      }
    } else {
      if (_hasPendingSwap(plan)) {
        ctaLabel = _swapAwaitingGuestResponse(plan)
            ? l10n.moodMatchPlanV2RespondSwapsOnCards
            : l10n.moodMatchPlanV2WaitingOwnerSwap(ownerName);
        onCta = null;
      } else if (_allGuestConfirmed(plan) && _allOwnerConfirmed(plan)) {
        ctaLabel = l10n.moodMatchPlanV2OpenMyDay;
        onCta = _saving
            ? null
            : () {
                unawaited(_finalizeGuestPlanToMyDay(l10n));
              };
      } else {
        ctaLabel =
            '${l10n.moodMatchPlanV2ConfirmAllGuest(total)} · $guestCount/$total';
        onCta = null;
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: GroupPlanningUi.cream,
        border: Border(
          top: BorderSide(
            color: GroupPlanningUi.charcoal.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: GroupPlanningUi.primaryCta(
        label: ctaLabel,
        onPressed: onCta,
        busy: _ownerBatchSaving || (_saving && onCta != null),
        busyLabel: _ownerBatchSaving ? l10n.moodMatchSaving : null,
      ),
    );
  }
}
