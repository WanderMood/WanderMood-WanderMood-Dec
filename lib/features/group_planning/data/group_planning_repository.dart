import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/notifications/in_app_notification_copy.dart';
import 'package:wandermood/core/services/wandermood_ai_service.dart';
import 'package:wandermood/services/push_notify_edge.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_compatibility.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_v2.dart';
import 'package:wandermood/features/group_planning/data/profile_invite_search_row.dart';
import 'package:wandermood/features/group_planning/data/mood_match_invite_inbox_entry.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_in_app_invite_result.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';

/// Extracts Mood Match in-app invite fields from a `realtime_events` row.
/// Supports `data` (RPC / older schema) and `payload` / `payload.data` shapes.
Map<String, dynamic>? moodMatchInviteDataFromRealtimeRow(
    Map<String, dynamic> row) {
  Map<String, dynamic>? asStringKeyedMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  bool isInvite(Map<String, dynamic>? m) =>
      m != null && (m['kind'] as String?) == 'mood_match_invite';

  final payload = asStringKeyedMap(row['payload']);
  if (payload != null) {
    final nested = asStringKeyedMap(payload['data']);
    if (isInvite(nested)) return nested;
    if (isInvite(payload)) return payload;
  }

  final data = asStringKeyedMap(row['data']);
  if (isInvite(data)) return data;

  return null;
}

/// Supabase-backed group planning (create / join RPCs, moods, shared plan).
class GroupPlanningRepository {
  GroupPlanningRepository(this._client);

  final SupabaseClient _client;

  /// `scheduled_activities.scheduled_date` expects `YYYY-MM-DD`.
  /// Uses the **local** calendar day of the parsed instant so ISO strings with
  /// a `Z` offset (e.g. end-of-day UTC) do not shift the saved date vs. what
  /// the user picked in the Mood Match day picker.
  String _normalizeMoodMatchScheduledDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final d = DateTime.tryParse(t);
    if (d != null) {
      final l = d.toLocal();
      return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
    }
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t)) return t;
    return '';
  }

  /// Resolves `YYYY-MM-DD` for Mood Match saves: param first, then plan_data,
  /// then `group_sessions.planned_date`, then prefs — so we never silently
  /// fall back to "today" when one source still has the real day.
  Future<String> _resolveMoodMatchScheduledDateForSave({
    required String sessionId,
    required String plannedDateParam,
    required Map<String, dynamic> normalizedPlan,
  }) async {
    var dateOnly = _normalizeMoodMatchScheduledDate(plannedDateParam);
    if (dateOnly.isNotEmpty) return dateOnly;
    // Session + prefs beat plan_data: the plan snapshot may still carry an old
    // `planned_date` from generation time, while the day picker updates
    // `group_sessions.planned_date` (and prefs) as the source of truth.
    try {
      final session = await fetchSession(sessionId);
      final fromSession = session.plannedDate?.trim() ?? '';
      dateOnly = _normalizeMoodMatchScheduledDate(fromSession);
      if (dateOnly.isNotEmpty) return dateOnly;
    } catch (_) {}
    final fromPrefs = await MoodMatchSessionPrefs.readPlannedDate(sessionId);
    dateOnly = _normalizeMoodMatchScheduledDate(fromPrefs ?? '');
    if (dateOnly.isNotEmpty) return dateOnly;
    final fromPlan = normalizedPlan['planned_date']?.toString().trim() ?? '';
    return _normalizeMoodMatchScheduledDate(fromPlan);
  }

  /// Recomputes `guestReviewState` from guest slot confirmations (same rules as
  /// [setGuestSlotConfirmed]) so swap flows cannot leave it stuck on
  /// `swap_pending` after a decline or withdraw.
  void _syncGuestReviewStateFromGuestConfirmed(Map<String, dynamic> d) {
    if (d['sentToGuest'] != true) return;
    final normalized = GroupPlanV2.normalizePlanData(
      Map<String, dynamic>.from(d),
    );
    final gc = Map<String, dynamic>.from(
      d['guestConfirmed'] is Map ? d['guestConfirmed'] as Map : {},
    );
    for (final s in GroupPlanV2.slots) {
      gc.putIfAbsent(s, () => false);
    }
    final required = GroupPlanV2.slotsRequiringConfirmation(normalized);
    final allGuest =
        required.isNotEmpty && required.every((s) => gc[s] == true);
    if (allGuest) {
      d['guestReviewState'] = 'confirmed';
    } else {
      final any = required.any((s) => gc[s] == true);
      d['guestReviewState'] = any ? 'reviewing' : 'pending';
    }
  }

  /// After a swap is cancelled or declined, restore per-slot confirmations from
  /// the snapshot saved when the swap was opened (see [setSwapRequest]).
  void _restoreSlotConfirmationAfterSwapCancelled(
    Map<String, dynamic> d,
    String slot,
    Map<String, dynamic>? proposalSnapshot,
  ) {
    final oc = Map<String, dynamic>.from(
      d['ownerConfirmed'] is Map ? d['ownerConfirmed'] as Map : {},
    );
    final gc = Map<String, dynamic>.from(
      d['guestConfirmed'] is Map ? d['guestConfirmed'] as Map : {},
    );
    for (final s in GroupPlanV2.slots) {
      oc.putIfAbsent(s, () => false);
      gc.putIfAbsent(s, () => false);
    }
    if (proposalSnapshot != null &&
        proposalSnapshot.containsKey('priorOwnerConfirmed')) {
      oc[slot] = proposalSnapshot['priorOwnerConfirmed'] == true;
      gc[slot] = proposalSnapshot['priorGuestConfirmed'] == true;
    } else {
      // Legacy proposals without a snapshot: "keep current" puts the slot back
      // in a confirmable state so the guest row (`ownerOk && !guestOk`) shows
      // again instead of dead-ending with both flags false.
      oc[slot] = true;
      gc[slot] = true;
    }
    d['ownerConfirmed'] = oc;
    d['guestConfirmed'] = gc;
    _syncGuestReviewStateFromGuestConfirmed(d);
  }

  Future<({String sessionId, String joinCode})> createSession({
    String? title,
  }) async {
    final raw = await _client.rpc(
      'create_group_session',
      params: {'p_title': title},
    );
    final List<dynamic> rows;
    if (raw is List) {
      rows = raw;
    } else if (raw is Map) {
      rows = [raw];
    } else {
      throw Exception('create_group_session: unexpected response');
    }
    if (rows.isEmpty) {
      throw Exception('create_group_session returned no row');
    }
    final row = Map<String, dynamic>.from(rows.first as Map);
    return (
      sessionId: row['session_id'].toString(),
      joinCode: row['join_code'].toString(),
    );
  }

  Future<String> joinSession(String joinCode) async {
    final raw = await _client.rpc(
      'join_group_session',
      params: {'p_join_code': joinCode.trim()},
    );
    if (raw == null) {
      throw Exception('join_group_session: empty response');
    }
    final id = raw is String ? raw : raw.toString();
    if (id.isEmpty) {
      throw Exception('join_group_session: invalid session id');
    }
    return id;
  }

  Future<GroupSessionRow> fetchSession(String sessionId) async {
    final id = sessionId.trim();
    if (id.isEmpty) {
      throw Exception(
        'Mood Match session not found or you no longer have access.',
      );
    }
    // Avoid `.single()`: PostgREST PGRST116 when 0 rows (RLS, stale id, or
    // rare replication lag right after `create_group_session`).
    Map<String, dynamic>? map;
    for (var attempt = 0; attempt < 5; attempt++) {
      map = await _client
          .from('group_sessions')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (map != null) break;
      if (attempt < 4) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    if (map == null) {
      // Same access rules as RLS, but bypasses PostgREST table policies if the
      // remote DB is missing the creator SELECT branch (older deploy).
      try {
        final raw = await _client.rpc(
          'fetch_group_session_for_client',
          params: {'p_session_id': id},
        );
        if (raw is Map) {
          map = Map<String, dynamic>.from(raw);
        }
      } catch (e, st) {
        debugPrint('fetch_group_session_for_client: $e\n$st');
      }
    }
    if (map == null) {
      throw Exception(
        'Mood Match session not found or you no longer have access.',
      );
    }
    return GroupSessionRow.fromMap(Map<String, dynamic>.from(map));
  }

  /// Session with nested `group_session_members` (hub restore / lobby).
  Future<GroupSessionDetail?> fetchSessionWithMembers(String sessionId) async {
    try {
      final map = await _client
          .from('group_sessions')
          .select('*, group_session_members(*)')
          .eq('id', sessionId)
          .maybeSingle();
      if (map == null) return null;
      final m = Map<String, dynamic>.from(map);
      final nested = m['group_session_members'];
      final members = <GroupMemberRow>[];
      if (nested is List) {
        for (final e in nested) {
          members.add(
            GroupMemberRow.fromMap(Map<String, dynamic>.from(e as Map)),
          );
        }
      }
      m.remove('group_session_members');
      final session = GroupSessionRow.fromMap(m);
      return GroupSessionDetail(session: session, members: members);
    } catch (e, st) {
      debugPrint('fetchSessionWithMembers: $e\n$st');
      return null;
    }
  }

  /// Session ids where the current user already saved Mood Match rows into
  /// [scheduled_activities] (tapped Add to My Day). Used to split hub
  /// "active" vs "added to My Day" without a separate session status.
  Future<Set<String>> fetchMoodMatchSessionIdsSavedToMyDay(
    List<String> sessionIds,
  ) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || sessionIds.isEmpty) return const {};
    try {
      final rows = await _client
          .from('scheduled_activities')
          .select('group_session_id')
          .eq('user_id', uid)
          .inFilter('group_session_id', sessionIds);
      final out = <String>{};
      for (final r in (rows as List<dynamic>)) {
        final m = Map<String, dynamic>.from(r as Map);
        final sid = (m['group_session_id'] ?? '').toString();
        if (sid.isNotEmpty) out.add(sid);
      }
      return out;
    } catch (e, st) {
      debugPrint('fetchMoodMatchSessionIdsSavedToMyDay: $e\n$st');
      return const {};
    }
  }

  /// Every non-expired session the current user is a member of, ready for the
  /// Mood Match hub multi-card list. Each entry also reports whether a shared
  /// plan has already been generated so the card can render the right CTA.
  Future<
      List<
          ({
            GroupSessionRow session,
            bool hasPlan,
            Map<String, dynamic>? planData,
            bool savedToMyDay,
          })>> fetchActiveSessionsForUser() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    try {
      final memberRows = await _client
          .from('group_session_members')
          .select('session_id')
          .eq('user_id', uid);
      final ids = <String>{};
      for (final r in (memberRows as List<dynamic>)) {
        final m = Map<String, dynamic>.from(r as Map);
        final id = (m['session_id'] ?? '').toString();
        if (id.isNotEmpty) ids.add(id);
      }
      if (ids.isEmpty) return const [];

      final nowIso = MoodyClock.now().toUtc().toIso8601String();
      final sessionRows = await _client
          .from('group_sessions')
          .select()
          .inFilter('id', ids.toList())
          .gt('expires_at', nowIso)
          .inFilter('status', const [
        'waiting',
        'generating',
        'ready',
        'day_proposed',
        'day_confirmed',
      ]).order('updated_at', ascending: false);

      final sessions = <GroupSessionRow>[];
      for (final r in (sessionRows as List<dynamic>)) {
        sessions.add(
          GroupSessionRow.fromMap(Map<String, dynamic>.from(r as Map)),
        );
      }
      if (sessions.isEmpty) return const [];

      final sessionIds = sessions.map((s) => s.id).toList();
      final planIds = <String>{};
      final planDataBySession = <String, Map<String, dynamic>>{};
      try {
        final planRows = await _client
            .from('group_plans')
            .select('session_id, plan_data')
            .inFilter('session_id', sessionIds);
        for (final r in (planRows as List<dynamic>)) {
          final m = Map<String, dynamic>.from(r as Map);
          final sid = (m['session_id'] ?? '').toString();
          if (sid.isEmpty) continue;
          planIds.add(sid);
          final raw = m['plan_data'];
          if (raw is Map) {
            planDataBySession[sid] = GroupPlanV2.normalizePlanData(
              Map<String, dynamic>.from(raw),
            );
          }
        }
      } catch (e, st) {
        debugPrint('fetchActiveSessionsForUser plan lookup: $e\n$st');
      }

      final savedToMyDay =
          await fetchMoodMatchSessionIdsSavedToMyDay(sessionIds);

      return [
        for (final s in sessions)
          (
            session: s,
            hasPlan: planIds.contains(s.id),
            planData: planDataBySession[s.id],
            savedToMyDay: savedToMyDay.contains(s.id),
          ),
      ];
    } on PostgrestException catch (e, st) {
      debugPrint(
        'fetchActiveSessionsForUser PostgREST ${e.code}: ${e.message}\n$st',
      );
      return const [];
    } catch (e, st) {
      debugPrint('fetchActiveSessionsForUser: $e\n$st');
      return const [];
    }
  }

  /// Host-only: reuse an open waiting session instead of creating duplicates.
  Future<GroupSessionRow?> findMyActiveWaitingSession() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from('group_sessions')
          .select()
          .eq('created_by', uid)
          .eq('status', 'waiting')
          .gt('expires_at', MoodyClock.now().toUtc().toIso8601String())
          .maybeSingle();
      if (row == null) return null;
      return GroupSessionRow.fromMap(Map<String, dynamic>.from(row));
    } catch (e, st) {
      debugPrint('findMyActiveWaitingSession: $e\n$st');
      return null;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.from('group_sessions').delete().eq('id', sessionId);
  }

  Future<void> removeSelfFromSession(String sessionId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client
        .from('group_session_members')
        .delete()
        .match({'session_id': sessionId, 'user_id': uid});
  }

  Future<List<GroupMemberView>> fetchMembersWithProfiles(
      String sessionId) async {
    final rawMembers = await _client
        .from('group_session_members')
        .select()
        .eq('session_id', sessionId)
        .order('created_at');

    final list = (rawMembers as List<dynamic>)
        .map((e) => GroupMemberRow.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (list.isEmpty) return [];

    final ids = list.map((m) => m.userId).toList();
    final profiles = await _client
        .from('profiles')
        // Some environments don't have `avatar_url` in `profiles`; `image_url` is the
        // canonical column used elsewhere in the app.
        .select('id, username, full_name, image_url')
        .inFilter('id', ids);

    final profileById = <String, Map<String, dynamic>>{};
    for (final p in profiles as List<dynamic>) {
      final m = Map<String, dynamic>.from(p as Map);
      profileById[m['id'] as String] = m;
    }

    return list.map((m) {
      final p = profileById[m.userId];
      return GroupMemberView(
        member: m,
        username: p?['username'] as String?,
        fullName: p?['full_name'] as String?,
        avatarUrl: p?['image_url'] as String?,
      );
    }).toList();
  }

  Future<void> submitMood({
    required String sessionId,
    required String moodTag,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');

    await _client.from('group_session_members').update({
      'mood_tag': moodTag.trim(),
      'submitted_at': MoodyClock.now().toUtc().toIso8601String(),
    }).match({'session_id': sessionId, 'user_id': uid});

    try {
      final username = await fetchProfileDisplayUsername(_client, uid) ?? '';
      final members = await fetchMembersWithProfiles(sessionId);
      final nl = await wandermoodNotificationLangCode() == 'nl';
      final message = InAppNotificationCopy.planMessage(
        nl: nl,
        event: 'mood_locked',
        data: {'sender_username': username},
      );
      final title = InAppNotificationCopy.planTitle(nl);
      for (final m in members) {
        if (m.member.userId == uid) continue;
        await _client.rpc(
          'send_realtime_notification',
          params: {
            'target_user_id': m.member.userId,
            'event_type': 'groupTravelUpdate',
            'event_title': title,
            'event_message': message,
            'event_data': {
              'event': 'mood_locked',
              'session_id': sessionId,
              'sender_username': username,
            },
            'source_user_id': uid,
            'related_post_id': null,
            'priority_level': 3,
          },
        );
        schedulePushNotify(
          recipientId: m.member.userId,
          event: 'mood_locked',
          data: {
            'sender_username': username,
            'session_id': sessionId,
          },
        );
      }
    } catch (e, st) {
      debugPrint('submitMood notify: $e\n$st');
    }
  }

  Future<GroupPlanRow?> fetchPlan(String sessionId) async {
    final row = await _client
        .from('group_plans')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();
    if (row == null) return null;
    return GroupPlanRow.fromMap(Map<String, dynamic>.from(row));
  }

  /// When every member has [mood_tag], calls Moody explore once and stores [group_plans].
  /// Idempotent: if a plan row exists, returns it. Safe if two clients race (unique on session_id).
  Future<GroupPlanRow?> tryGeneratePlanIfComplete({
    required String sessionId,
    required double latitude,
    required double longitude,
    String? city,
    required String communicationStyle,
    required String languageCode,
    String? plannedDateFallback,
    String? timeSlot,
  }) async {
    final existing = await fetchPlan(sessionId);
    if (existing != null) return existing;

    final members = await fetchMembersWithProfiles(sessionId);
    if (members.length < 2) return null;
    if (!members.every((m) => m.member.hasSubmittedMood)) return null;

    final moods = members
        .map((m) => m.member.moodTag!.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (moods.isEmpty) return null;
    final session = await fetchSession(sessionId);
    final plannedDate = session.plannedDate ?? plannedDateFallback;
    // Date+slot ⇒ single-slot plan; date-only ⇒ full-day plan.
    final normalizedSlot = (timeSlot == 'morning' ||
            timeSlot == 'afternoon' ||
            timeSlot == 'evening')
        ? timeSlot
        : null;
    final participantNames = members.map((m) => m.displayName).toList();
    final rawCity = (city ?? '').trim();
    final locationForPlan =
        rawCity.isNotEmpty ? rawCity : 'Rotterdam';
    final mood1 = moods.isNotEmpty ? moods.first : '';
    final mood2 = moods.length > 1 ? moods[1] : mood1;

    DateTime? plannedDayLocal;
    final pd = plannedDate?.trim();
    if (pd != null && pd.isNotEmpty) {
      final parsed = DateTime.tryParse(pd);
      if (parsed != null) {
        final l = parsed.toLocal();
        plannedDayLocal = DateTime(l.year, l.month, l.day);
      }
    }

    try {
      await _client.from('group_sessions').update({
        'status': 'generating',
        'updated_at': MoodyClock.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint('group_sessions generating status: $e');
    }

    try {
      final ai = await WanderMoodAIService.getGroupMatchCreateDayPlan(
        moods: moods,
        location: locationForPlan,
        latitude: latitude,
        longitude: longitude,
        languageCode: languageCode,
        plannedDay: plannedDayLocal,
      );
      if (ai.recommendations.isEmpty) {
        throw Exception('Moody create_day_plan returned no activities');
      }

      final score = compatibilityScoreForMoodTags(moods);
      var moodyMessage = '';
      try {
        moodyMessage = await WanderMoodAIService.getGroupMatchMoodyMessage(
          moods: moods,
          compatibilityScore: score,
          languageCode: languageCode,
          communicationStyle: communicationStyle,
          plannedDate: plannedDate,
          mood1: mood1,
          mood2: mood2,
          name1: participantNames.isNotEmpty ? participantNames[0] : null,
          name2: participantNames.length > 1 ? participantNames[1] : null,
          location: locationForPlan,
        );
      } catch (e) {
        debugPrint('group moodyMessage skipped: $e');
      }

      final v2 = GroupPlanV2.buildPlanPayloadFromRecommendations(
        ai.recommendations,
        singleSlot: normalizedSlot,
      );
      final activitiesForPlan =
          List<dynamic>.from(v2['activities'] as List? ?? const <dynamic>[]);
      if (activitiesForPlan.isNotEmpty) {
        try {
          final slotNotes =
              await WanderMoodAIService.getGroupMatchActivityMoodyNotes(
            recommendations: ai.recommendations,
            languageCode: languageCode,
            communicationStyle: communicationStyle,
          );
          for (var i = 0; i < activitiesForPlan.length; i++) {
            final row = Map<String, dynamic>.from(
              activitiesForPlan[i] as Map<dynamic, dynamic>,
            );
            final slot = (row['slot'] ?? row['timeSlot'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
            final note = slotNotes[slot];
            if (note != null && note.trim().isNotEmpty) {
              row['moodyNote'] = note.trim();
            }
            activitiesForPlan[i] = row;
          }
          v2['activities'] = activitiesForPlan;
        } catch (e, st) {
          debugPrint('group_match_activity_notes skipped: $e\n$st');
        }
      }
      final planData = <String, dynamic>{
        'planVersion': 2,
        'version': 2,
        'moods': moods,
        'summary': ai.summary,
        'compatibilityScore': score,
        'generated_at': MoodyClock.now().toUtc().toIso8601String(),
        if (plannedDate != null && plannedDate.isNotEmpty)
          'planned_date': plannedDate,
        if (normalizedSlot != null) 'time_slot': normalizedSlot,
        if (participantNames.isNotEmpty) 'participants': participantNames,
        'location': locationForPlan,
        'recommendations': ai.recommendations.map((r) => r.toJson()).toList(),
        if (moodyMessage.isNotEmpty) 'moodyMessage': moodyMessage,
        'activities': v2['activities'],
        'swapPool': v2['swapPool'],
        'ownerConfirmed': v2['ownerConfirmed'],
        'guestConfirmed': v2['guestConfirmed'],
        'swapRequests': v2['swapRequests'],
        'swapProposals': v2['swapProposals'] ?? <String, dynamic>{},
        'sentToGuest': false,
      };

      try {
        await _client.from('group_plans').insert({
          'session_id': sessionId,
          'plan_data': planData,
        });
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          return fetchPlan(sessionId);
        }
        rethrow;
      }

      // Day was already agreed before generation; land in shared plan review.
      await _client.from('group_sessions').update({
        'status': 'ready',
        'updated_at': MoodyClock.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);

      return fetchPlan(sessionId);
    } catch (e, st) {
      debugPrint('Group plan generation failed: $e\n$st');
      try {
        await _client.from('group_sessions').update({
          'status': 'error',
          'updated_at': MoodyClock.now().toUtc().toIso8601String(),
        }).eq('id', sessionId);
      } catch (_) {}
      rethrow;
    }
  }

  /// Write the planned date (YYYY-MM-DD) chosen by the OWNER to group_sessions.
  /// Swallows PostgrestException if the column is missing on older schemas —
  /// callers should also persist the date locally (see MoodMatchSessionPrefs).
  Future<bool> writePlannedDate(String sessionId, String plannedDate) async {
    try {
      await _client.from('group_sessions').update({
        'planned_date': plannedDate,
        'updated_at': MoodyClock.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('writePlannedDate skipped: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('writePlannedDate failed: $e');
      return false;
    }
  }

  /// Write a status to group_sessions. Swallows CHECK / column errors on older
  /// schemas so the Mood Match flow still proceeds.
  Future<bool> writeSessionStatus(String sessionId, String status) async {
    try {
      await _client.from('group_sessions').update({
        'status': status,
        'updated_at': MoodyClock.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('writeSessionStatus($status) skipped: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('writeSessionStatus failed: $e');
      return false;
    }
  }

  /// Persist the latest Mood Match counter-proposal on the session row so the
  /// OWNER can recover the "accept this day?" modal on cold start / push tap.
  /// Swallows column errors on environments that haven't applied migration
  /// 20260420120000_group_sessions_counter_proposal.sql yet.
  Future<bool> writeProposedSlot({
    required String sessionId,
    required String slot,
    required String byUserId,
  }) async {
    try {
      await _client.from('group_sessions').update({
        'proposed_slot': slot,
        'proposed_by_user_id': byUserId,
        'updated_at': MoodyClock.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('writeProposedSlot skipped: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('writeProposedSlot failed: $e');
      return false;
    }
  }

  /// Clear the counter-proposal fields once both sides have agreed (or the
  /// owner kept the original). Swallows errors on older schemas.
  Future<bool> clearProposedSlot(String sessionId) async {
    try {
      await _client.from('group_sessions').update({
        'proposed_slot': null,
        'proposed_by_user_id': null,
        'updated_at': MoodyClock.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('clearProposedSlot skipped: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('clearProposedSlot failed: $e');
      return false;
    }
  }

  /// Send a realtime planUpdate event to another participant (used for day_proposed).
  Future<void> sendPlanUpdateEvent({
    required String targetUserId,
    required String sessionId,
    required Map<String, dynamic> payload,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final username = await fetchProfileDisplayUsername(_client, uid) ?? '';
      final merged = Map<String, dynamic>.from(payload);
      merged['sender_username'] = username;
      if ((merged['day'] ?? '').toString().trim().isEmpty &&
          merged['proposed_date'] != null) {
        merged['day'] = merged['proposed_date'].toString();
      }
      final pp = merged['proposed_place_name']?.toString().trim();
      if (pp != null &&
          pp.isNotEmpty &&
          (merged['place'] ?? '').toString().trim().isEmpty) {
        merged['place'] = pp;
      }
      final eventStr = (merged['event'] ?? '').toString();
      final nl = await wandermoodNotificationLangCode() == 'nl';
      final message = InAppNotificationCopy.planMessage(
        nl: nl,
        event: eventStr,
        data: merged,
      );
      final title = InAppNotificationCopy.planTitle(nl);
      await _client.rpc(
        'send_realtime_notification',
        params: {
          'target_user_id': targetUserId,
          'event_type': 'planUpdate',
          'event_title': title,
          'event_message': message,
          'event_data': {
            'session_id': sessionId,
            ...merged,
          },
          'source_user_id': uid,
          'related_post_id': null,
          'priority_level': 3,
        },
      );
      final pe = pushEventForPlanSideEffect(eventStr);
      if (pe != null) {
        schedulePushNotify(
          recipientId: targetUserId,
          event: pe,
          data: {
            'sender_username': username,
            'session_id': sessionId,
            if (merged['day'] != null) 'day': merged['day'].toString(),
            if (merged['slot'] != null) 'slot': merged['slot'].toString(),
            if (merged['place'] != null) 'place': merged['place'].toString(),
            if (merged['previous_day'] != null)
              'previous_day': merged['previous_day'].toString(),
            if (merged['new_day'] != null)
              'new_day': merged['new_day'].toString(),
            if (merged['proposed_date'] != null)
              'proposed_date': merged['proposed_date'].toString(),
            if (merged['proposed_slot'] != null)
              'proposed_slot': merged['proposed_slot'].toString(),
          },
        );
      }
    } catch (e) {
      debugPrint('sendPlanUpdateEvent: $e');
    }
  }

  /// Persists the ping-pong day proposal in [plan_data] (single source for UI).
  Future<void> upsertPendingDayProposal({
    required String sessionId,
    required String proposedByUserId,
    required String addressedToUserId,
    required String proposedDate,
    required String proposedSlot,
  }) async {
    await mergePlanData(sessionId, (d) {
      final prior = d['dayProposal'] is Map
          ? Map<String, dynamic>.from(d['dayProposal'] as Map)
          : <String, dynamic>{};
      final history = <dynamic>[
        ...(prior['history'] is List ? prior['history'] as List : const []),
      ];
      history.add({
        'by': proposedByUserId,
        'date': proposedDate,
        'slot': proposedSlot,
        'at': MoodyClock.now().toUtc().toIso8601String(),
      });
      d['dayProposal'] = {
        'status': 'pending',
        'proposedBy': proposedByUserId,
        'addressedTo': addressedToUserId,
        'proposedDate': proposedDate,
        'proposedSlot': proposedSlot,
        'proposedAt': MoodyClock.now().toUtc().toIso8601String(),
        'history': history,
      };
      return d;
    });
  }

  Future<void> markDayProposalAcceptedInPlan(String sessionId) async {
    await mergePlanData(sessionId, (d) {
      if (d['dayProposal'] is Map) {
        final m = Map<String, dynamic>.from(d['dayProposal'] as Map);
        m['status'] = 'accepted';
        d['dayProposal'] = m;
      }
      return d;
    });
  }

  bool _planHasAllSlotsConfirmed(Map<String, dynamic> d) {
    final oc = GroupPlanV2.boolSlotMap(d['ownerConfirmed']);
    final gc = GroupPlanV2.boolSlotMap(d['guestConfirmed']);
    for (final s in GroupPlanV2.slots) {
      if (oc[s] != true || gc[s] != true) return false;
    }
    return true;
  }

  Future<void> _maybeFireBothConfirmed(String sessionId) async {
    try {
      final planRow = await fetchPlan(sessionId);
      if (planRow == null) return;
      var d = GroupPlanV2.normalizePlanData(
        Map<String, dynamic>.from(planRow.planData),
      );
      if (d['sentToGuest'] != true) return;
      if (d['wm_both_confirmed_notified'] == true) return;
      if (!_planHasAllSlotsConfirmed(d)) return;

      await mergePlanData(sessionId, (x) {
        x['wm_both_confirmed_notified'] = true;
        return x;
      });

      final members = await fetchMembersWithProfiles(sessionId);
      final nl = await wandermoodNotificationLangCode() == 'nl';
      final message = InAppNotificationCopy.planMessage(
        nl: nl,
        event: 'both_confirmed',
        data: const {},
      );
      final title = InAppNotificationCopy.planTitle(nl);
      for (final m in members) {
        await _client.rpc(
          'send_realtime_notification',
          params: {
            'target_user_id': m.member.userId,
            'event_type': 'planUpdate',
            'event_title': title,
            'event_message': message,
            'event_data': {
              'session_id': sessionId,
              'event': 'both_confirmed',
            },
            'source_user_id': _client.auth.currentUser?.id,
            'related_post_id': null,
            'priority_level': 3,
          },
        );
        schedulePushNotify(
          recipientId: m.member.userId,
          event: 'both_confirmed',
          data: {'session_id': sessionId},
        );
      }
    } catch (e, st) {
      debugPrint('_maybeFireBothConfirmed: $e\n$st');
    }
  }

  /// Guest just joined — ping the session owner (in-app + push).
  Future<void> notifyOwnerGuestJoined(String sessionId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final session = await fetchSession(sessionId);
      final ownerId = session.createdBy;
      if (ownerId == uid) return;
      final username = await fetchProfileDisplayUsername(_client, uid) ?? '';
      final nl = await wandermoodNotificationLangCode() == 'nl';
      final message = InAppNotificationCopy.planMessage(
        nl: nl,
        event: 'guest_joined',
        data: {'sender_username': username},
      );
      final title = InAppNotificationCopy.planTitle(nl);
      await _client.rpc(
        'send_realtime_notification',
        params: {
          'target_user_id': ownerId,
          'event_type': 'groupTravelUpdate',
          'event_title': title,
          'event_message': message,
          'event_data': {
            'event': 'guest_joined',
            'session_id': sessionId,
            'sender_username': username,
          },
          'source_user_id': uid,
          'related_post_id': null,
          'priority_level': 3,
        },
      );
      schedulePushNotify(
        recipientId: ownerId,
        event: 'guest_joined',
        data: {
          'sender_username': username,
          'session_id': sessionId,
        },
      );
    } catch (e, st) {
      debugPrint('notifyOwnerGuestJoined: $e\n$st');
    }
  }

  /// Replace entire [plan_data] (e.g. legacy migration).
  Future<void> updatePlanDataReplace(
    String sessionId,
    Map<String, dynamic> planData,
  ) async {
    try {
      await _client
          .from('group_plans')
          .update({'plan_data': planData}).eq('session_id', sessionId);
    } catch (e) {
      debugPrint('updatePlanDataReplace: $e');
    }
  }

  /// Read-modify-write with an optimistic concurrency guard.
  ///
  /// Mood Match writes plan_data from both peers, so naive
  /// read-then-update lets a second writer clobber the first one's merge.
  /// We now:
  ///   1. Read `plan_data` + `plan_data_version`.
  ///   2. Run [updater] on a normalized copy.
  ///   3. Conditional UPDATE where `plan_data_version = <snapshot>`; bump the
  ///      version by 1 in the same statement.
  ///   4. If 0 rows were affected, someone else wrote in between — reload and
  ///      retry up to [maxRetries] times (exponential-ish backoff between
  ///      tries so the loser doesn't immediately refire into the same race).
  ///
  /// Throws [StateError] after exhausting retries so the caller can decide
  /// whether to surface an error to the user.
  Future<void> mergePlanData(
    String sessionId,
    Map<String, dynamic> Function(Map<String, dynamic> planData) updater, {
    int maxRetries = 4,
  }) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final plan = await fetchPlan(sessionId);
      if (plan == null) return;

      var data = Map<String, dynamic>.from(plan.planData);
      data = GroupPlanV2.normalizePlanData(data);
      data = updater(data);

      try {
        final result = await _client
            .from('group_plans')
            .update({
              'plan_data': data,
              'plan_data_version': plan.planDataVersion + 1,
            })
            .eq('session_id', sessionId)
            .eq('plan_data_version', plan.planDataVersion)
            .select('plan_data_version');

        final rows = (result as List<dynamic>?) ?? const [];
        if (rows.isNotEmpty) return;
      } on PostgrestException catch (e, st) {
        // If the server doesn't know about plan_data_version yet (e.g.
        // migration not applied in a local env), fall back to the legacy
        // replace so the client still works. Log loudly so we notice.
        final msg = e.message.toLowerCase();
        final legacyColumn = msg.contains('plan_data_version') &&
            (msg.contains('does not exist') ||
                msg.contains('unknown') ||
                msg.contains('column'));
        if (legacyColumn) {
          debugPrint(
            '[mergePlanData] plan_data_version column missing — '
            'falling back to legacy replace. Apply migration '
            '20260420210000_group_plans_plan_data_version.sql.',
          );
          await updatePlanDataReplace(sessionId, data);
          return;
        }
        debugPrint('mergePlanData PostgREST ${e.code}: ${e.message}\n$st');
        rethrow;
      }

      // Lost the race — back off and retry.
      if (attempt < maxRetries) {
        final waitMs = 40 * (1 << attempt); // 40, 80, 160, 320
        await Future<void>.delayed(Duration(milliseconds: waitMs));
      }
    }
    throw StateError(
      'mergePlanData: failed to apply update after $maxRetries retries '
      '(session=$sessionId). Too much contention on plan_data.',
    );
  }

  /// Owner reviewed all slots and shares the plan with the guest.
  Future<void> sendPlanToGuest({
    required String sessionId,
    required String guestUserId,
  }) async {
    await mergePlanData(sessionId, (d) {
      d['sentToGuest'] = true;
      d['guestReviewState'] = 'pending';
      return d;
    });
    await writeSessionStatus(sessionId, 'ready');
    await sendPlanUpdateEvent(
      targetUserId: guestUserId,
      sessionId: sessionId,
      payload: {
        'event': 'plan_ready',
        'session_id': sessionId,
      },
    );
  }

  Future<void> setOwnerSlotConfirmed(
    String sessionId,
    String slot,
    bool value,
  ) async {
    await mergePlanData(sessionId, (d) {
      final m = Map<String, dynamic>.from(
        d['ownerConfirmed'] is Map
            ? d['ownerConfirmed'] as Map
            : {for (final s in GroupPlanV2.slots) s: false},
      );
      for (final s in GroupPlanV2.slots) {
        m.putIfAbsent(s, () => false);
      }
      m[slot] = value;
      d['ownerConfirmed'] = m;
      return d;
    });
    if (value) {
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        try {
          final planRow = await fetchPlan(sessionId);
          if (planRow == null) return;
          final normalized = GroupPlanV2.normalizePlanData(
            Map<String, dynamic>.from(planRow.planData),
          );
          // Guest must not get slot pings while the owner is still drafting
          // (before "Send to guest").
          if (normalized['sentToGuest'] != true) return;

          final members = await fetchMembersWithProfiles(sessionId);
          for (final m in members) {
            if (m.member.userId == uid) continue;
            await sendPlanUpdateEvent(
              targetUserId: m.member.userId,
              sessionId: sessionId,
              payload: {
                'event': 'slot_confirmed',
                'session_id': sessionId,
                'slot': slot,
                'confirmed_by': 'owner',
              },
            );
          }
          await _maybeFireBothConfirmed(sessionId);
        } catch (e, st) {
          debugPrint('setOwnerSlotConfirmed notify: $e\n$st');
        }
      }
    }
  }

  Future<void> setGuestSlotConfirmed(
    String sessionId,
    String slot,
    bool value,
  ) async {
    await mergePlanData(sessionId, (d) {
      final m = Map<String, dynamic>.from(
        d['guestConfirmed'] is Map ? d['guestConfirmed'] as Map : {},
      );
      for (final s in GroupPlanV2.slots) {
        m.putIfAbsent(s, () => false);
      }
      m[slot] = value;
      d['guestConfirmed'] = m;
      // Keep guestReviewState in sync whenever guest toggles a slot (including
      // undo) — previously only `value == true` updated state, so undoing one
      // slot could leave guestReviewState stuck on "confirmed".
      if (d['sentToGuest'] == true) {
        final normalized = GroupPlanV2.normalizePlanData(
          Map<String, dynamic>.from(d),
        );
        final required =
            GroupPlanV2.slotsRequiringConfirmation(normalized);
        final allGuest = required.isNotEmpty &&
            required.every((s) => m[s] == true);
        if (allGuest) {
          d['guestReviewState'] = 'confirmed';
        } else {
          final any = required.any((s) => m[s] == true);
          d['guestReviewState'] = any ? 'reviewing' : 'pending';
        }
      }
      return d;
    });
    if (value) {
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        try {
          final members = await fetchMembersWithProfiles(sessionId);
          for (final m in members) {
            if (m.member.userId == uid) continue;
            await sendPlanUpdateEvent(
              targetUserId: m.member.userId,
              sessionId: sessionId,
              payload: {
                'event': 'slot_confirmed',
                'session_id': sessionId,
                'slot': slot,
                'confirmed_by': 'guest',
              },
            );
          }
          await _maybeFireBothConfirmed(sessionId);
        } catch (e, st) {
          debugPrint('setGuestSlotConfirmed notify: $e\n$st');
        }
      }
    }
  }

  Future<void> setSwapRequest({
    required String sessionId,
    required String slot,
    required Map<String, dynamic> proposedActivity,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final members = await fetchMembersWithProfiles(sessionId);
    String? addressedTo;
    for (final m in members) {
      if (m.member.userId != uid) addressedTo = m.member.userId;
    }
    if (addressedTo == null) return;
    await mergePlanData(sessionId, (d) {
      final reqs = Map<String, dynamic>.from(
        d['swapRequests'] is Map ? d['swapRequests'] as Map : {},
      );
      final copy = Map<String, dynamic>.from(proposedActivity);
      copy['slot'] = slot;
      reqs[slot] = {
        'requestedBy': uid,
        'proposedActivity': copy,
      };
      d['swapRequests'] = reqs;
      final currentAct = GroupPlanV2.activityForSlot(d, slot);
      final sp = Map<String, dynamic>.from(
        d['swapProposals'] is Map ? d['swapProposals'] as Map : {},
      );
      // Until the other person accepts or declines, this slot is not
      // "locked in" for either side.
      final oc = Map<String, dynamic>.from(
        d['ownerConfirmed'] is Map ? d['ownerConfirmed'] as Map : {},
      );
      final gc = Map<String, dynamic>.from(
        d['guestConfirmed'] is Map ? d['guestConfirmed'] as Map : {},
      );
      for (final s in GroupPlanV2.slots) {
        oc.putIfAbsent(s, () => false);
        gc.putIfAbsent(s, () => false);
      }
      final priorOwnerConfirmed = oc[slot] == true;
      final priorGuestConfirmed = gc[slot] == true;
      sp[slot] = {
        'status': 'pending',
        'proposedBy': uid,
        'addressedTo': addressedTo,
        'currentActivity': currentAct != null
            ? Map<String, dynamic>.from(currentAct)
            : <String, dynamic>{},
        'proposedActivity': Map<String, dynamic>.from(copy),
        'proposedAt': MoodyClock.now().toUtc().toIso8601String(),
        'priorOwnerConfirmed': priorOwnerConfirmed,
        'priorGuestConfirmed': priorGuestConfirmed,
      };
      d['swapProposals'] = sp;
      oc[slot] = false;
      gc[slot] = false;
      d['ownerConfirmed'] = oc;
      d['guestConfirmed'] = gc;
      if (d['sentToGuest'] == true) {
        d['guestReviewState'] = 'swap_pending';
      }
      return d;
    });
  }

  /// Owner-side draft edit before plan is shared:
  /// directly replace the slot activity instead of creating a swap request.
  Future<void> replaceActivityForSlot({
    required String sessionId,
    required String slot,
    required Map<String, dynamic> activity,
  }) async {
    await mergePlanData(sessionId, (d) {
      final sentToGuest = d['sentToGuest'] == true;
      if (sentToGuest) return d;

      final merged = Map<String, dynamic>.from(activity);
      merged['slot'] = slot;

      final activities = (d['activities'] as List<dynamic>?) ?? [];
      final next = <dynamic>[];
      for (final a in activities) {
        if (a is Map) {
          final am = Map<String, dynamic>.from(a);
          if (GroupPlanV2.slotFromActivity(am) == slot) {
            next.add(merged);
          } else {
            next.add(am);
          }
        }
      }
      d['activities'] = next;

      // Treat owner replacement as selecting this slot in the draft.
      final oc = Map<String, dynamic>.from(
        d['ownerConfirmed'] is Map ? d['ownerConfirmed'] as Map : {},
      );
      for (final s in GroupPlanV2.slots) {
        oc.putIfAbsent(s, () => false);
      }
      oc[slot] = true;
      d['ownerConfirmed'] = oc;

      // Clear any stale swap state for this slot while still in draft phase.
      final reqs = Map<String, dynamic>.from(
        d['swapRequests'] is Map ? d['swapRequests'] as Map : {},
      );
      reqs.remove(slot);
      d['swapRequests'] = reqs;
      final sp = Map<String, dynamic>.from(
        d['swapProposals'] is Map ? d['swapProposals'] as Map : {},
      );
      sp.remove(slot);
      d['swapProposals'] = sp;
      return d;
    });
  }

  Future<void> clearSwapRequest(String sessionId, String slot) async {
    await mergePlanData(sessionId, (d) {
      final sp = Map<String, dynamic>.from(
        d['swapProposals'] is Map ? d['swapProposals'] as Map : {},
      );
      final proposalSnap = sp[slot] is Map
          ? Map<String, dynamic>.from(sp[slot] as Map)
          : null;
      final reqs = Map<String, dynamic>.from(
        d['swapRequests'] is Map ? d['swapRequests'] as Map : {},
      );
      reqs.remove(slot);
      d['swapRequests'] = reqs;
      sp.remove(slot);
      d['swapProposals'] = sp;
      _restoreSlotConfirmationAfterSwapCancelled(d, slot, proposalSnap);
      return d;
    });
  }

  Future<void> ownerResolveSwap({
    required String sessionId,
    required String slot,
    required bool accept,
    required String guestUserId,
  }) async {
    final sessionRow = await fetchSession(sessionId);
    final ownerId = sessionRow.createdBy;

    final planBefore = await fetchPlan(sessionId);
    String? proposedPlaceName;
    if (planBefore != null) {
      final data = GroupPlanV2.normalizePlanData(
        Map<String, dynamic>.from(planBefore.planData),
      );
      final reqs = Map<String, dynamic>.from(
        data['swapRequests'] is Map ? data['swapRequests'] as Map : {},
      );
      final req = reqs[slot] is Map ? reqs[slot] as Map : null;
      final p = req?['proposedActivity'];
      if (p is Map) {
        proposedPlaceName = (p['name'] ?? p['title'] ?? '').toString().trim();
        if (proposedPlaceName.isEmpty) proposedPlaceName = null;
      }
    }

    await mergePlanData(sessionId, (d) {
      final reqs = Map<String, dynamic>.from(
        d['swapRequests'] is Map ? d['swapRequests'] as Map : {},
      );
      final req = reqs[slot] is Map
          ? Map<String, dynamic>.from(reqs[slot] as Map)
          : null;
      if (req == null) return d;

      // Guest-initiated swaps only — owner proposals are resolved by the guest.
      final by = GroupPlanV2.swapRequestedByUserId(req);
      if (by != null && by == ownerId) {
        return d;
      }

      final sp = Map<String, dynamic>.from(
        d['swapProposals'] is Map ? d['swapProposals'] as Map : {},
      );
      final proposalSnap = sp[slot] is Map
          ? Map<String, dynamic>.from(sp[slot] as Map)
          : null;

      if (accept) {
        final proposed = req['proposedActivity'];
        if (proposed is Map) {
          final merged = Map<String, dynamic>.from(proposed);
          merged['slot'] = slot;
          final activities = (d['activities'] as List<dynamic>?) ?? [];
          final next = <dynamic>[];
          for (final a in activities) {
            if (a is Map) {
              final am = Map<String, dynamic>.from(a);
              if (GroupPlanV2.slotFromActivity(am) == slot) {
                next.add(merged);
              } else {
                next.add(am);
              }
            }
          }
          d['activities'] = next;
          final oc = Map<String, dynamic>.from(
            d['ownerConfirmed'] is Map ? d['ownerConfirmed'] as Map : {},
          );
          for (final s in GroupPlanV2.slots) {
            oc.putIfAbsent(s, () => false);
          }
          oc[slot] = true;
          d['ownerConfirmed'] = oc;
          final gc = Map<String, dynamic>.from(
            d['guestConfirmed'] is Map ? d['guestConfirmed'] as Map : {},
          );
          for (final s in GroupPlanV2.slots) {
            gc.putIfAbsent(s, () => false);
          }
          gc[slot] = true;
          d['guestConfirmed'] = gc;
        }
      } else {
        _restoreSlotConfirmationAfterSwapCancelled(d, slot, proposalSnap);
      }
      reqs.remove(slot);
      d['swapRequests'] = reqs;
      sp.remove(slot);
      d['swapProposals'] = sp;
      if (d['sentToGuest'] == true) {
        _syncGuestReviewStateFromGuestConfirmed(d);
      }
      return d;
    });
    await sendPlanUpdateEvent(
      targetUserId: guestUserId,
      sessionId: sessionId,
      payload: {
        'event': accept ? 'swap_accepted' : 'swap_declined',
        'slot': slot,
        'session_id': sessionId,
        if (proposedPlaceName != null) 'proposed_place_name': proposedPlaceName,
      },
    );
  }

  /// Guest accepts or declines a swap **proposed by the owner** for [slot].
  Future<void> guestResolveSwap({
    required String sessionId,
    required String slot,
    required bool accept,
    required String ownerUserId,
  }) async {
    final sessionRow = await fetchSession(sessionId);
    final ownerId = sessionRow.createdBy;

    final planBefore = await fetchPlan(sessionId);
    String? proposedPlaceName;
    if (planBefore != null) {
      final data = GroupPlanV2.normalizePlanData(
        Map<String, dynamic>.from(planBefore.planData),
      );
      final reqs = Map<String, dynamic>.from(
        data['swapRequests'] is Map ? data['swapRequests'] as Map : {},
      );
      final req = reqs[slot] is Map ? reqs[slot] as Map : null;
      final p = req?['proposedActivity'];
      if (p is Map) {
        proposedPlaceName = (p['name'] ?? p['title'] ?? '').toString().trim();
        if (proposedPlaceName.isEmpty) proposedPlaceName = null;
      }
    }

    await mergePlanData(sessionId, (d) {
      final reqs = Map<String, dynamic>.from(
        d['swapRequests'] is Map ? d['swapRequests'] as Map : {},
      );
      final req = reqs[slot] is Map
          ? Map<String, dynamic>.from(reqs[slot] as Map)
          : null;
      if (req == null) return d;

      final by = GroupPlanV2.swapRequestedByUserId(req);
      if (by == null || by != ownerId) {
        return d;
      }

      final sp2 = Map<String, dynamic>.from(
        d['swapProposals'] is Map ? d['swapProposals'] as Map : {},
      );
      final proposalSnap = sp2[slot] is Map
          ? Map<String, dynamic>.from(sp2[slot] as Map)
          : null;

      if (accept) {
        final proposed = req['proposedActivity'];
        if (proposed is Map) {
          final merged = Map<String, dynamic>.from(proposed);
          merged['slot'] = slot;
          final activities = (d['activities'] as List<dynamic>?) ?? [];
          final next = <dynamic>[];
          for (final a in activities) {
            if (a is Map) {
              final am = Map<String, dynamic>.from(a);
              if (GroupPlanV2.slotFromActivity(am) == slot) {
                next.add(merged);
              } else {
                next.add(am);
              }
            }
          }
          d['activities'] = next;
          final oc = Map<String, dynamic>.from(
            d['ownerConfirmed'] is Map ? d['ownerConfirmed'] as Map : {},
          );
          final gc = Map<String, dynamic>.from(
            d['guestConfirmed'] is Map ? d['guestConfirmed'] as Map : {},
          );
          for (final s in GroupPlanV2.slots) {
            oc.putIfAbsent(s, () => false);
            gc.putIfAbsent(s, () => false);
          }
          oc[slot] = true;
          gc[slot] = true;
          d['ownerConfirmed'] = oc;
          d['guestConfirmed'] = gc;
        }
      } else {
        _restoreSlotConfirmationAfterSwapCancelled(d, slot, proposalSnap);
      }
      reqs.remove(slot);
      d['swapRequests'] = reqs;
      sp2.remove(slot);
      d['swapProposals'] = sp2;
      if (d['sentToGuest'] == true) {
        _syncGuestReviewStateFromGuestConfirmed(d);
      }
      return d;
    });
    await sendPlanUpdateEvent(
      targetUserId: ownerUserId,
      sessionId: sessionId,
      payload: {
        'event': accept ? 'swap_accepted' : 'swap_declined',
        'slot': slot,
        'session_id': sessionId,
        if (proposedPlaceName != null) 'proposed_place_name': proposedPlaceName,
      },
    );
  }

  /// Append alternatives to [swapPool] for one slot (e.g. sheet was empty).
  Future<void> appendSwapPoolForSlot({
    required String sessionId,
    required String slot,
    required List<Map<String, dynamic>> extras,
  }) async {
    if (extras.isEmpty) return;
    await mergePlanData(sessionId, (d) {
      final poolRaw = d['swapPool'];
      final pool = <String, List<dynamic>>{
        'morning': [],
        'afternoon': [],
        'evening': [],
      };
      if (poolRaw is Map) {
        for (final s in GroupPlanV2.slots) {
          final list = poolRaw[s] as List<dynamic>?;
          if (list != null) pool[s] = List<dynamic>.from(list);
        }
      }
      pool[slot] = [...pool[slot]!, ...extras];
      d['swapPool'] = pool;
      return d;
    });
  }

  /// Save scheduled activities for a group session (time picker save).
  /// Writes the same schedule for **every** session member so My Day stays in
  /// sync for owner and guest.
  Future<void> saveGroupScheduledActivities({
    required String sessionId,
    required String scheduledDate,
    required String timeSlot,
    required List<Map<String, dynamic>> activities,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    // RLS: each user may only insert rows for themselves. Owner and guest each
    // run this when they tap "My Day" — we persist one copy per caller, not
    // a single batch with other users' user_id (that always failed with RLS).
    final userIds = <String>[uid];

    // Calculate start times based on slot
    final slotHour = switch (timeSlot) {
      'morning' => 9,
      'afternoon' => 12,
      'evening' => 17,
      _ => 12,
    };

    var currentMinute = slotHour * 60;
    final dateParts = scheduledDate.split('-');
    if (dateParts.length != 3) {
      throw StateError('scheduledDate must be YYYY-MM-DD, got: $scheduledDate');
    }
    final schedYear = int.parse(dateParts[0]);
    final schedMonth = int.parse(dateParts[1]);
    final schedDay = int.parse(dateParts[2]);

    final template = <Map<String, dynamic>>[];
    for (var idx = 0; idx < activities.length; idx++) {
      final a = activities[idx];
      final durationMin = (a['duration_minutes'] as num?)?.toInt() ?? 60;
      final h = currentMinute ~/ 60;
      final m = currentMinute % 60;
      // Build wall-clock time on the **scheduled calendar day in local time**,
      // then convert to UTC ISO for `timestamptz`. Naive "YYYY-MM-DDTHH:mm:ss"
      // strings were interpreted as UTC on some stacks, which pushed rows onto
      // the wrong calendar day in My Day / My Plans.
      final localStart = DateTime(schedYear, schedMonth, schedDay, h, m);
      final startTimestamp = localStart.toUtc().toIso8601String();
      // `scheduled_activities.activity_id` is NOT NULL; synthesize a stable id
      // for Mood Match rows so the insert satisfies the constraint without
      // clashing with Explore-driven rows.
      final activityId =
          'groupplan_${sessionId}_${timeSlot}_${idx}_${a['place_id'] ?? a['name'] ?? idx}';
      template.add({
        'activity_id': activityId,
        'place_id': a['place_id']?.toString() ?? '',
        'place_name': a['name']?.toString() ?? '',
        'name': a['name']?.toString() ?? '',
        'image_url': GroupPlanV2.resolveActivityImageUrl(
          Map<String, dynamic>.from(a),
        ),
        'scheduled_date': scheduledDate,
        'start_time': startTimestamp,
        'duration': durationMin,
        'duration_minutes': durationMin,
        'group_session_id': sessionId,
        'time_slot': timeSlot,
      });
      currentMinute += durationMin + 30; // 30 min buffer between activities
    }

    if (template.isEmpty) return;

    final allRows = <Map<String, dynamic>>[];
    for (final userId in userIds) {
      for (final row in template) {
        allRows.add({...row, 'user_id': userId});
      }
    }

    Future<void> tryInsert(List<Map<String, dynamic>> rows) async {
      await _client.from('scheduled_activities').insert(rows);
    }

    // If this deployment has `start_time` as plain `time` (not `timestamptz`),
    // strip the date prefix so "HH:MM:SS" is sent instead of an ISO timestamp.
    List<Map<String, dynamic>> rowsWithBareTime(
      List<Map<String, dynamic>> rows,
    ) {
      return rows.map((r) {
        final copy = Map<String, dynamic>.from(r);
        final st = copy['start_time']?.toString() ?? '';
        final idx = st.indexOf('T');
        if (idx >= 0 && idx + 1 < st.length) {
          copy['start_time'] = st.substring(idx + 1);
        }
        return copy;
      }).toList();
    }

    // Retry strategy: some deployed schemas are missing newer optional columns.
    // When Postgrest reports a specific missing column (PGRST204), we drop that
    // key across all rows and retry so "Add to My Day" keeps working.
    const droppableColumns = <String>[
      'duration_minutes',
      'place_name',
      'name',
      'image_url',
      'group_session_id',
      'time_slot',
    ];

    final dropped = <String>{};
    var rows = allRows;
    var bareTimeRetryUsed = false;
    while (true) {
      try {
        await tryInsert(rows);
        return;
      } on PostgrestException catch (e) {
        if (e.code == '23505') return;
        final message = '${e.message} ${e.details ?? ''}'.toLowerCase();

        // Some schemas type `start_time` as plain `time` — retry with bare
        // "HH:MM:SS" once when Postgres rejects the ISO timestamp.
        final timestampMismatch = !bareTimeRetryUsed &&
            (e.code == '22007' || message.contains('22007')) &&
            message.contains('timestamp');
        if (timestampMismatch) {
          bareTimeRetryUsed = true;
          rows = rowsWithBareTime(rows);
          continue;
        }

        String? missing;
        if (e.code == 'PGRST204') {
          for (final col in droppableColumns) {
            if (!dropped.contains(col) && message.contains(col)) {
              missing = col;
              break;
            }
          }
        }
        if (missing == null) rethrow;
        dropped.add(missing);
        rows = rows.map((r) {
          final copy = Map<String, dynamic>.from(r);
          copy.remove(missing);
          return copy;
        }).toList();
      }
    }
  }

  /// Writes Mood Match plan activities into `scheduled_activities` for every
  /// session member. Uses per-activity `time_slot` when present; otherwise
  /// [overrideDefaultSlot] (time picker), then plan-level `time_slot`, pending
  /// prefs, then afternoon.
  Future<void> saveMoodMatchPlanToMyDayForAllMembers({
    required String sessionId,
    required String plannedDate,
    String? overrideDefaultSlot,
  }) async {
    final plan = await fetchPlan(sessionId);
    if (plan == null) {
      throw StateError('No group plan');
    }
    final normalized = GroupPlanV2.normalizePlanData(
      Map<String, dynamic>.from(plan.planData),
    );
    final dateOnly = await _resolveMoodMatchScheduledDateForSave(
      sessionId: sessionId,
      plannedDateParam: plannedDate,
      normalizedPlan: normalized,
    );
    if (dateOnly.isEmpty) {
      throw StateError('Invalid planned date');
    }
    // We still schedule rows whose `place_id` is missing (AI-only recs) so
    // Mood Match never dead-ends; My Day just shows the name without a
    // linkable place. A row must at least have a name.
    final rows = GroupPlanV2.schedulingActivityRows(normalized)
        .where((r) => (r['name']?.toString().trim().isNotEmpty ?? false))
        .toList();
    if (rows.isEmpty) {
      throw StateError('No activities to save');
    }

    var defaultSlot = 'afternoon';
    final over = overrideDefaultSlot;
    if (over == 'morning' || over == 'afternoon' || over == 'evening') {
      defaultSlot = over!;
    } else {
      final ts = normalized['time_slot']?.toString();
      if (ts == 'morning' || ts == 'afternoon' || ts == 'evening') {
        defaultSlot = ts!;
      } else {
        final pending = await MoodMatchSessionPrefs.readPendingTimeSlot(
          sessionId,
        );
        if (pending == 'morning' ||
            pending == 'afternoon' ||
            pending == 'evening') {
          defaultSlot = pending!;
        }
      }
    }

    final usePerSlot =
        rows.isNotEmpty && rows.any((a) => a['time_slot'] != null);
    // Forward image_url (and photos) so the timeline in My Day / My Plans
    // renders the real place photo instead of a gray placeholder. Previously
    // we stripped these keys and `resolveActivityImageUrl` returned empty.
    Map<String, dynamic> toScheduledActivity(Map<String, dynamic> row) {
      final out = <String, dynamic>{
        'name': row['name'],
        'place_id': row['place_id'],
        'duration_minutes': row['duration_minutes'],
      };
      final img = (row['image_url'] ?? row['imageUrl'] ?? row['photo_url'])
          ?.toString()
          .trim();
      if (img != null && img.isNotEmpty) out['image_url'] = img;
      final photos = row['photos'];
      if (photos is List && photos.isNotEmpty) out['photos'] = photos;
      return out;
    }

    if (usePerSlot) {
      for (final row in rows) {
        final slot = (row['time_slot'] as String?) ?? defaultSlot;
        await saveGroupScheduledActivities(
          sessionId: sessionId,
          scheduledDate: dateOnly,
          timeSlot: slot,
          activities: [toScheduledActivity(row)],
        );
      }
    } else {
      await saveGroupScheduledActivities(
        sessionId: sessionId,
        scheduledDate: dateOnly,
        timeSlot: defaultSlot,
        activities: rows.map(toScheduledActivity).toList(),
      );
    }

    await MoodMatchSessionPrefs.clearPendingTimeSlot(sessionId);

    // Persist locally so the hub state can detect "already on plan" even when
    // `scheduled_activities.group_session_id` or `group_sessions.completed_at`
    // columns are absent in older schema environments.
    unawaited(MoodMatchSessionPrefs.markSavedToMyDay(sessionId));

    // First-commit wins: stamp `completed_at` once so downstream analytics /
    // filters can identify sessions that actually shipped into someone's day.
    // We coalesce to protect against re-entry — a second member adding the
    // same plan should not overwrite the first-committed timestamp.
    unawaited(_stampSessionCompletedAtIfNull(sessionId));
  }

  /// One-shot update: sets `completed_at = now()` only if it's currently null.
  /// Swallows errors (including "column does not exist" for envs that haven't
  /// applied migration 20260420220000) so the Add-to-My-Day path never fails
  /// because of an analytics stamp.
  Future<void> _stampSessionCompletedAtIfNull(String sessionId) async {
    try {
      await _client
          .from('group_sessions')
          .update({'completed_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', sessionId)
          .isFilter('completed_at', null);
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('completed_at') &&
          (msg.contains('does not exist') ||
              msg.contains('column') ||
              msg.contains('unknown'))) {
        debugPrint(
          '[completed_at] column missing — skipping. '
          'Apply migration 20260420220000_group_sessions_completed_at.sql.',
        );
        return;
      }
      debugPrint('[completed_at] PostgREST ${e.code}: ${e.message}');
    } catch (e, st) {
      debugPrint('[completed_at] unexpected: $e\n$st');
    }
  }

  /// Optimistically save a single reaction into group_plans.plan_data['reactions'][uid][index].
  Future<void> updatePlanReaction({
    required String sessionId,
    required int activityIndex,
    required String reaction, // 'love' | 'skip' | 'swap'
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final plan = await fetchPlan(sessionId);
    if (plan == null) return;
    final planData = Map<String, dynamic>.from(plan.planData);
    final reactions = Map<String, dynamic>.from(
      planData['reactions'] is Map ? planData['reactions'] as Map : {},
    );
    final userReactions = Map<String, dynamic>.from(
      reactions[uid] is Map ? reactions[uid] as Map : {},
    );
    userReactions['$activityIndex'] = reaction;
    reactions[uid] = userReactions;
    planData['reactions'] = reactions;
    try {
      await _client
          .from('group_plans')
          .update({'plan_data': planData}).eq('session_id', sessionId);
    } catch (e) {
      debugPrint('updatePlanReaction: $e');
    }
  }

  Future<void> savePlanProposal({
    required String sessionId,
    required int activityIndex,
    required Map<String, dynamic> placeCard,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final plan = await fetchPlan(sessionId);
    if (plan == null) return;
    final planData = Map<String, dynamic>.from(plan.planData);
    final proposals = Map<String, dynamic>.from(
      planData['proposals'] is Map ? planData['proposals'] as Map : {},
    );
    proposals['$activityIndex'] = {
      'proposedBy': uid,
      'placeCard': placeCard,
      'updated_at': MoodyClock.now().toUtc().toIso8601String(),
    };
    planData['proposals'] = proposals;
    try {
      await _client
          .from('group_plans')
          .update({'plan_data': planData}).eq('session_id', sessionId);
    } catch (e) {
      debugPrint('savePlanProposal: $e');
    }
  }

  Future<void> resolvePlanProposal({
    required String sessionId,
    required int activityIndex,
    required bool acceptProposal,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final plan = await fetchPlan(sessionId);
    if (plan == null) return;
    final planData = Map<String, dynamic>.from(plan.planData);
    final proposals = Map<String, dynamic>.from(
      planData['proposals'] is Map ? planData['proposals'] as Map : {},
    );
    final key = '$activityIndex';
    final proposal = proposals[key] is Map
        ? Map<String, dynamic>.from(proposals[key] as Map)
        : null;
    if (proposal == null) return;

    if (acceptProposal) {
      final recs =
          (planData['recommendations'] as List<dynamic>?) ?? <dynamic>[];
      if (activityIndex >= 0 && activityIndex < recs.length) {
        final placeCard = proposal['placeCard'];
        if (placeCard is Map) {
          recs[activityIndex] = Map<String, dynamic>.from(placeCard);
          planData['recommendations'] = recs;
        }
      }
    }

    proposals.remove(key);
    planData['proposals'] = proposals;
    final decisions = Map<String, dynamic>.from(
      planData['decisions'] is Map ? planData['decisions'] as Map : {},
    );
    decisions[key] = {
      'decidedBy': uid,
      'accepted': acceptProposal,
      'updated_at': MoodyClock.now().toUtc().toIso8601String(),
    };
    planData['decisions'] = decisions;

    try {
      await _client
          .from('group_plans')
          .update({'plan_data': planData}).eq('session_id', sessionId);
    } catch (e) {
      debugPrint('resolvePlanProposal: $e');
    }
  }

  /// Username substring search for inviting someone already on WanderMood.
  Future<List<ProfileInviteSearchRow>> searchProfilesByUsernameForInvite(
    String query, {
    int limit = 20,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final q = query.trim();
    if (q.length < 2) return [];
    try {
      final rows = await _client
          .from('profiles')
          .select('id, username, full_name, image_url')
          .ilike('username', '%$q%')
          .neq('id', uid)
          .limit(limit);

      final list = rows as List<dynamic>;
      return list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return ProfileInviteSearchRow(
          id: m['id'] as String,
          username: m['username'] as String?,
          fullName: m['full_name'] as String?,
          imageUrl: m['image_url'] as String?,
        );
      }).toList();
    } catch (e, st) {
      debugPrint('searchProfilesByUsernameForInvite: $e\n$st');
      return [];
    }
  }

  /// In-app notification row for the target user (`realtime_events` via RPC).
  ///
  /// [joinLinkHttps] is stored in `event_data` for clients and echoed in [notificationMessage] by the UI.
  Future<MoodMatchInAppInviteResult> sendMoodMatchInAppInvite({
    required String targetUserId,
    required String sessionId,
    required String joinCode,
    required String joinLinkHttps,
    String? sessionTitleOverride,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return MoodMatchInAppInviteResult.error;
    if (uid == targetUserId) return MoodMatchInAppInviteResult.error;
    try {
      var sessionTitle = sessionTitleOverride?.trim();
      if (sessionTitle == null || sessionTitle.isEmpty) {
        sessionTitle = await MoodMatchSessionPrefs.readSessionDisplayTitle(
          sessionId,
        );
      }
      sessionTitle = sessionTitle?.trim();
      if (sessionTitle == null || sessionTitle.isEmpty) {
        try {
          final row = await _client
              .from('group_sessions')
              .select('title')
              .eq('id', sessionId)
              .maybeSingle();
          if (row != null) {
            final raw = row['title'];
            final t = raw?.toString().trim();
            if (t != null && t.isNotEmpty) sessionTitle = t;
          }
        } catch (_) {}
      }
      final ownerName = await fetchProfileDisplayUsername(_client, uid) ?? '';
      final nl = await wandermoodNotificationLangCode() == 'nl';
      final inviteMessage = InAppNotificationCopy.planMessage(
        nl: nl,
        event: 'mood_match_invite',
        data: {'sender_username': ownerName},
      );
      final inviteTitle = InAppNotificationCopy.planTitle(nl);
      final response = await _client.rpc(
        'send_realtime_notification',
        params: {
          'target_user_id': targetUserId,
          'event_type': 'groupTravelUpdate',
          'event_title': inviteTitle,
          'event_message': inviteMessage,
          'event_data': {
            'kind': 'mood_match_invite',
            'event': 'mood_match_invite',
            'session_id': sessionId,
            'join_code': joinCode.trim().toUpperCase(),
            'join_link': joinLinkHttps,
            'sender_username': ownerName,
            if (sessionTitle != null && sessionTitle.isNotEmpty)
              'session_title': sessionTitle,
          },
          'source_user_id': uid,
          'related_post_id': null,
          'priority_level': 3,
        },
      );
      if (response == null) {
        return MoodMatchInAppInviteResult.notDeliveredInApp;
      }
      if (response is Map) {
        final m = Map<String, dynamic>.from(response);
        final ok = m['success'];
        if (ok == false) return MoodMatchInAppInviteResult.notDeliveredInApp;
      }
      schedulePushNotify(
        recipientId: targetUserId,
        event: 'mood_match_invite',
        data: {
          'sender_username': ownerName,
          'session_id': sessionId,
        },
      );
      return MoodMatchInAppInviteResult.delivered;
    } on PostgrestException catch (e, st) {
      debugPrint(
        'sendMoodMatchInAppInvite PostgREST ${e.code}: ${e.message}\n$st',
      );
      return MoodMatchInAppInviteResult.error;
    } catch (e, st) {
      debugPrint('sendMoodMatchInAppInvite: $e\n$st');
      return MoodMatchInAppInviteResult.error;
    }
  }

  /// Fetches unread `mood_match_invite` events for the current user plus the
  /// sender's public profile so the hub can render a pending-invite card.
  Future<List<MoodMatchInviteInboxEntry>> fetchPendingMoodMatchInvites() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    try {
      List<dynamic> rows;
      try {
        rows = await _client
            .from('realtime_events')
            .select()
            .eq('recipient_id', uid)
            .eq('event_type', 'groupTravelUpdate')
            .filter('read_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(25);
      } on PostgrestException catch (_) {
        rows = await _client
            .from('realtime_events')
            .select()
            .eq('user_id', uid)
            .eq('type', 'groupTravelUpdate')
            .eq('is_read', false)
            .order('created_at', ascending: false)
            .limit(25);
      }

      final entries = <MoodMatchInviteInboxEntry>[];
      final senderIds = <String>{};
      for (final r in rows) {
        final row = Map<String, dynamic>.from(r as Map);
        final data = moodMatchInviteDataFromRealtimeRow(row);
        if (data == null) continue;
        final sessionId = (data['session_id'] ?? '').toString();
        final joinCode = (data['join_code'] ?? '').toString();
        final joinLink = (data['join_link'] ?? '').toString();
        final sessionTitleRaw = (data['session_title'] ?? '').toString().trim();
        if (sessionId.isEmpty || joinCode.isEmpty) continue;
        final senderId =
            (row['sender_id'] ?? row['related_user_id'] ?? '').toString();
        final createdAtRaw =
            row['created_at']?.toString() ?? row['timestamp']?.toString();
        final createdAt = createdAtRaw != null
            ? DateTime.tryParse(createdAtRaw)?.toLocal() ?? DateTime.now()
            : DateTime.now();
        if (senderId.isNotEmpty) senderIds.add(senderId);
        entries.add(MoodMatchInviteInboxEntry(
          eventId: (row['id'] ?? '').toString(),
          senderId: senderId,
          sessionId: sessionId,
          joinCode: joinCode,
          joinLink: joinLink,
          createdAt: createdAt,
          sessionTitle: sessionTitleRaw.isEmpty ? null : sessionTitleRaw,
        ));
      }

      if (entries.isEmpty) return const [];

      final Map<String, Map<String, dynamic>> profileById = {};
      if (senderIds.isNotEmpty) {
        try {
          final profiles = await _client
              .from('profiles')
              .select('id, username, full_name, image_url')
              .inFilter('id', senderIds.toList());
          for (final p in (profiles as List<dynamic>)) {
            final m = Map<String, dynamic>.from(p as Map);
            final id = (m['id'] ?? '').toString();
            if (id.isNotEmpty) profileById[id] = m;
          }
        } catch (e, st) {
          debugPrint('fetchPendingMoodMatchInvites profiles: $e\n$st');
        }
      }

      return entries.map((e) {
        final p = profileById[e.senderId];
        if (p == null) return e;
        return MoodMatchInviteInboxEntry(
          eventId: e.eventId,
          senderId: e.senderId,
          sessionId: e.sessionId,
          joinCode: e.joinCode,
          joinLink: e.joinLink,
          createdAt: e.createdAt,
          sessionTitle: e.sessionTitle,
          senderUsername: p['username'] as String?,
          senderFullName: p['full_name'] as String?,
          senderImageUrl: p['image_url'] as String?,
        );
      }).toList(growable: false);
    } on PostgrestException catch (e, st) {
      debugPrint(
        'fetchPendingMoodMatchInvites PostgREST ${e.code}: ${e.message}\n$st',
      );
      return const [];
    } catch (e, st) {
      debugPrint('fetchPendingMoodMatchInvites: $e\n$st');
      return const [];
    }
  }

  /// Marks [eventId] as read so it no longer appears in the invite inbox.
  Future<void> markMoodMatchInviteRead(String eventId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client
          .from('realtime_events')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', eventId)
          .eq('recipient_id', uid);
    } on PostgrestException catch (_) {
      try {
        await _client
            .from('realtime_events')
            .update({'is_read': true})
            .eq('id', eventId)
            .eq('user_id', uid);
      } catch (e, st) {
        debugPrint('markMoodMatchInviteRead fallback: $e\n$st');
      }
    } catch (e, st) {
      debugPrint('markMoodMatchInviteRead: $e\n$st');
    }
  }

  /// Realtime channel fires when a new `realtime_events` row is inserted for
  /// the current user — the hub listens so pending invites appear live.
  RealtimeChannel subscribeToIncomingRealtimeEvents({
    required void Function() onInsert,
  }) {
    final uid = _client.auth.currentUser?.id ?? '';
    final channel =
        _client.channel('mood_match_invite_inbox_$uid').onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'realtime_events',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'recipient_id',
                value: uid,
              ),
              callback: (_) {
                try {
                  onInsert();
                } catch (e, st) {
                  debugPrint('subscribeToIncomingRealtimeEvents cb: $e\n$st');
                }
              },
            );
    channel.subscribe();
    return channel;
  }
}
