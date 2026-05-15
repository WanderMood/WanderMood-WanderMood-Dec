import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/group_planning/data/group_planning_repository.dart';
import 'package:wandermood/core/services/push_notify_edge.dart'
    show fetchProfileDisplayUsername, schedulePushNotify;
import 'package:wandermood/core/services/google_places_service.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_plan_proposals.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';

final planMetVriendServiceProvider = Provider<PlanMetVriendService>((ref) {
  return PlanMetVriendService(Supabase.instance.client);
});

class PlanMetVriendService {
  PlanMetVriendService(this._client);

  final SupabaseClient _client;

  static List<String> datesToIso(List<DateTime> dates) {
    return dates
        .map(
          (d) =>
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        )
        .toSet()
        .toList()
      ..sort();
  }

  static List<DateTime> parseDateList(dynamic raw) {
    if (raw is! List) return [];
    final out = <DateTime>[];
    for (final e in raw) {
      final s = e?.toString();
      if (s == null || s.isEmpty) continue;
      final d = DateTime.tryParse(s);
      if (d != null) out.add(DateTime(d.year, d.month, d.day));
    }
    return out;
  }

  /// Parses PGRST204 / unknown-column errors, e.g. `Could not find the 'city' column`.
  String? _schemaErrorColumn(PostgrestException e, Iterable<String> dataKeys) {
    final msg = '${e.message} ${e.details ?? ''}'.toLowerCase();
    final quoted = RegExp(r"'([^']+)'\s+column").firstMatch(msg);
    if (quoted != null) return quoted.group(1);
    for (final k in dataKeys) {
      if (msg.contains(k.toLowerCase())) return k;
    }
    return null;
  }

  bool _shouldDropColumn(
    String key,
    Set<String>? allowDrop,
    Set<String> alreadyRemoved,
  ) {
    if (alreadyRemoved.contains(key)) return false;
    if (allowDrop != null && !allowDrop.contains(key)) return false;
    return alreadyRemoved.add(key);
  }

  Future<Map<String, dynamic>> _insertRowResilient(
    String table,
    Map<String, dynamic> row, {
    List<String> droppableKeys = const [],
  }) async {
    var data = Map<String, dynamic>.from(row);
    final allowDrop = droppableKeys.isEmpty ? null : droppableKeys.toSet();
    final removed = <String>{};
    while (true) {
      try {
        final res = await _client.from(table).insert(data).select().single();
        return Map<String, dynamic>.from(res);
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          rethrow;
        }
        if (e.code == 'PGRST204' || e.code == '42703') {
          final key = _schemaErrorColumn(e, data.keys);
          if (key != null && _shouldDropColumn(key, allowDrop, removed)) {
            data.remove(key);
            continue;
          }
        }
        rethrow;
      }
    }
  }

  Future<void> _updateRowResilient(
    String table,
    Map<String, dynamic> patch,
    Map<String, dynamic> match, {
    List<String> droppableKeys = const [],
  }) async {
    var data = Map<String, dynamic>.from(patch);
    final allowDrop = droppableKeys.isEmpty ? null : droppableKeys.toSet();
    final removed = <String>{};
    while (true) {
      try {
        var q = _client.from(table).update(data);
        match.forEach((k, v) => q = q.eq(k, v));
        await q;
        return;
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST204' || e.code == '42703') {
          final key = _schemaErrorColumn(e, data.keys);
          if (key != null && _shouldDropColumn(key, allowDrop, removed)) {
            data.remove(key);
            if (data.isEmpty) return;
            continue;
          }
        }
        rethrow;
      }
    }
  }

  Future<({String sessionId, String joinCode})> _createSessionViaRpc(
    String title,
  ) async {
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

  bool _isMissingRelation(PostgrestException e, String table) {
    final msg = '${e.message} ${e.details ?? ''}'.toLowerCase();
    return e.code == '42P01' ||
        e.code == 'PGRST205' ||
        msg.contains(table) ||
        msg.contains('does not exist');
  }

  bool _isRpcNotFound(PostgrestException e, String fn) {
    final msg = '${e.message} ${e.details ?? ''}'.toLowerCase();
    return e.code == 'PGRST202' ||
        e.code == '42883' ||
        msg.contains(fn.toLowerCase());
  }

  /// Adds current user to [group_session_members] when invited (bypasses RLS).
  Future<void> _joinGroupSessionAsInvitee(
    String sessionId, {
    String? inviteId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final existing = await fetchMember(sessionId: sessionId, userId: uid);
    if (existing != null) return;

    final params = <String, dynamic>{'p_session_id': sessionId};
    final trimmedInvite = inviteId?.trim();
    if (trimmedInvite != null && trimmedInvite.isNotEmpty) {
      params['p_invite_id'] = trimmedInvite;
    }

    try {
      await _client.rpc('join_group_session_for_invitee', params: params);
      return;
    } on PostgrestException catch (e) {
      if (!_isRpcNotFound(e, 'join_group_session_for_invitee')) rethrow;
      if (kDebugMode) {
        debugPrint(
          'join_group_session_for_invitee missing — apply Supabase migration '
          '20260516000000_join_group_session_for_invitee.sql',
        );
      }
    }

    await _client.from('group_session_members').upsert({
      'session_id': sessionId,
      'user_id': uid,
    }, onConflict: 'session_id,user_id');
  }

  Future<void> _storeInviteInPlanData({
    required String sessionId,
    required String inviteId,
    required String inviterId,
    required PlanMetVriendFriend friend,
    required PlanMetVriendPlace place,
    String? message,
    required String expiresAt,
  }) async {
    final existing = await _client
        .from('group_plans')
        .select('plan_data')
        .eq('session_id', sessionId)
        .maybeSingle();
    final data = existing?['plan_data'] is Map
        ? Map<String, dynamic>.from(existing!['plan_data'] as Map)
        : <String, dynamic>{};
    final priorInvite = data['planMetVriendInvite'];
    final priorReply = priorInvite is Map
        ? priorInvite['reply_message']?.toString().trim()
        : null;
    data['planMetVriendInvite'] = {
      'id': inviteId,
      'inviter_user_id': inviterId,
      'invitee_user_id': friend.userId,
      'invitee_display_name': friend.displayName,
      if (friend.username != null && friend.username!.trim().isNotEmpty)
        'invitee_username': friend.username!.trim(),
      if (friend.avatarUrl != null && friend.avatarUrl!.trim().isNotEmpty)
        'invitee_avatar_url': friend.avatarUrl!.trim(),
      'place_id': place.placeId,
      'place_name': place.placeName,
      'place_data': place.placeData,
      'group_session_id': sessionId,
      'status': 'pending',
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      if (priorReply != null && priorReply.isNotEmpty) 'reply_message': priorReply,
      'expires_at': expiresAt,
    };
    data['anchor_place_data'] = place.placeData;
    await _client.from('group_plans').update({
      'plan_data': data,
    }).eq('session_id', sessionId);
  }

  Future<String> _persistInviteRecord({
    required String sessionId,
    required String inviterId,
    required PlanMetVriendFriend friend,
    required PlanMetVriendPlace place,
    String? message,
    required String expiresAt,
  }) async {
    try {
      final res = await _insertRowResilient(
        'wishlist_place_invites',
        {
          'inviter_user_id': inviterId,
          'invitee_user_id': friend.userId,
          'place_id': place.placeId,
          'place_name': place.placeName,
          'place_data': place.placeData,
          'group_session_id': sessionId,
          'status': 'pending',
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
          'expires_at': expiresAt,
        },
        droppableKeys: const [
          'place_data',
          'message',
          'reply_message',
          'group_session_id',
        ],
      );
      return res['id'] as String;
    } on PostgrestException catch (e) {
      if (!_isMissingRelation(e, 'wishlist_place_invites')) rethrow;
      if (kDebugMode) {
        debugPrint(
          'wishlist_place_invites missing — storing invite in group_plans',
        );
      }
    }
    final syntheticId = sessionId;
    await _storeInviteInPlanData(
      sessionId: sessionId,
      inviteId: syntheticId,
      inviterId: inviterId,
      friend: friend,
      place: place,
      message: message,
      expiresAt: expiresAt,
    );
    return syntheticId;
  }

  Future<void> _mergePlanDataCity(String sessionId, String city) async {
    if (city.trim().isEmpty) return;
    try {
      final existing = await _client
          .from('group_plans')
          .select('plan_data')
          .eq('session_id', sessionId)
          .maybeSingle();
      final data = existing?['plan_data'] is Map
          ? Map<String, dynamic>.from(existing!['plan_data'] as Map)
          : <String, dynamic>{};
      data['city'] = city.trim();
      await _client.from('group_plans').update({
        'plan_data': data,
      }).eq('session_id', sessionId);
    } catch (e) {
      if (kDebugMode) debugPrint('pmv plan_data city: $e');
    }
  }

  Future<void> _ensurePlanRow(String sessionId) async {
    try {
      await _client.from('group_plans').insert({
        'session_id': sessionId,
        'plan_data': {
          'planVersion': 2,
          'planning_mode': 'plan_met_vriend',
          'activities': <dynamic>[],
        },
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
    }
  }

  static List<DateTime> intersectDates(List<DateTime> a, List<DateTime> b) {
    final setB = b.map((d) => datesToIso([d]).first).toSet();
    final out = <DateTime>[];
    for (final d in a) {
      final key = datesToIso([d]).first;
      if (setB.contains(key)) out.add(DateTime(d.year, d.month, d.day));
    }
    out.sort((x, y) => x.compareTo(y));
    return out;
  }

  Future<({String sessionId, String inviteId})> sendInvite({
    required PlanMetVriendFriend friend,
    required PlanMetVriendPlace place,
    required List<DateTime> selectedDates,
    required String city,
    String? message,
    required String inviterDisplayName,
    String? proposedSlot,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final dates = datesToIso(selectedDates);
    final now = DateTime.now().toUtc();
    final expires = now.add(const Duration(days: 7));
    final expiresIso = expires.toIso8601String();

    final title = place.placeName.length > 120
        ? '${place.placeName.substring(0, 120)}…'
        : place.placeName;
    final created = await _createSessionViaRpc(title);
    final sessionId = created.sessionId;

    await _ensurePlanRow(sessionId);

    await _updateRowResilient(
      'group_sessions',
      {
        'status': 'waiting',
        'expires_at': expiresIso,
        'session_type': 'plan_met_vriend',
        'anchor_place_id': place.placeId,
        'anchor_place_name': place.placeName,
        'anchor_place_data': place.placeData,
        'city': city,
        'max_members': 2,
        'updated_at': now.toIso8601String(),
      },
      {'id': sessionId},
      droppableKeys: const [
        'session_type',
        'anchor_place_id',
        'anchor_place_name',
        'anchor_place_data',
        'city',
        'max_members',
        'expires_at',
        'updated_at',
      ],
    );

    await _mergePlanDataCity(sessionId, city);

    // RPC already inserted creator membership — update only (no second insert).
    await _updateRowResilient(
      'group_session_members',
      {
        'availability_dates': dates,
        'availability_submitted_at': now.toIso8601String(),
      },
      {'session_id': sessionId, 'user_id': uid},
      droppableKeys: const [
        'availability_dates',
        'availability_submitted_at',
      ],
    );

    final inviteId = await _persistInviteRecord(
      sessionId: sessionId,
      inviterId: uid,
      friend: friend,
      place: place,
      message: message,
      expiresAt: expiresIso,
    );

    // Always mirror invite + photos into group_plans (wishlist row may omit place_data).
    await _storeInviteInPlanData(
      sessionId: sessionId,
      inviteId: inviteId,
      inviterId: uid,
      friend: friend,
      place: place,
      message: message,
      expiresAt: expiresIso,
    );

    await _notifyInvite(
      recipientId: friend.userId,
      inviterName: inviterDisplayName,
      placeName: place.placeName,
      sessionId: sessionId,
      inviteId: inviteId,
      inviteMessage: message?.trim(),
    );

    return (sessionId: sessionId, inviteId: inviteId);
  }

  /// After [sendInvite], propose day + notify (best-effort; won't block invite).
  Future<void> proposeInitialDay({
    required GroupPlanningRepository repo,
    required String sessionId,
    required String inviteId,
    required String friendUserId,
    required String inviterUserId,
    required String inviterDisplayName,
    required String proposedDateIso,
    required String proposedSlot,
    required String dayLabel,
    required String placeName,
  }) async {
    await _ensurePlanRow(sessionId);
    try {
      await repo.writePlannedDate(sessionId, proposedDateIso);
    } catch (_) {}
    try {
      await repo.writeProposedSlot(
        sessionId: sessionId,
        slot: proposedSlot,
        byUserId: inviterUserId,
      );
    } catch (_) {}
    try {
      await repo.writeSessionStatus(sessionId, 'day_proposed');
    } catch (_) {}
    try {
      await repo.upsertPendingDayProposal(
        sessionId: sessionId,
        proposedByUserId: inviterUserId,
        addressedToUserId: friendUserId,
        proposedDate: proposedDateIso,
        proposedSlot: proposedSlot,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('pmv upsertPendingDayProposal: $e');
    }
    try {
      await repo.sendPlanUpdateEvent(
        targetUserId: friendUserId,
        sessionId: sessionId,
        payload: {
          'event': 'day_proposed',
          'type': 'plan_met_vriend_invite',
          'session_id': sessionId,
          'invite_id': inviteId,
          'proposed_date': proposedDateIso,
          'proposed_day_label': dayLabel,
          'proposed_slot': proposedSlot,
          'proposed_by_username': inviterDisplayName.split(' ').first,
          'place_name': placeName,
        },
      );
    } catch (_) {}
  }

  /// Non-empty invite note from [wishlist_place_invites] or plan_data mirror.
  static String? inviteNoteText(Map<String, dynamic>? invite, {bool reply = false}) {
    if (invite == null) return null;
    final key = reply ? 'reply_message' : 'message';
    final raw = invite[key]?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<void> saveInviteReply({
    required String inviteId,
    required String sessionId,
    required String reply,
  }) async {
    final trimmed = reply.trim();
    if (trimmed.isEmpty) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final invite = await fetchInvite(inviteId);
    if (invite == null) throw Exception('Invite not found');
    final inviteeId = invite['invitee_user_id']?.toString();
    if (inviteeId != uid) {
      throw Exception('Only the invitee can reply');
    }

    final inviterId = invite['inviter_user_id']?.toString() ?? '';
    final placeName = invite['place_name']?.toString() ?? 'een plek';

    try {
      await _client.from('wishlist_place_invites').update({
        'reply_message': trimmed,
      }).eq('id', inviteId);
    } on PostgrestException catch (e) {
      if (!_isMissingRelation(e, 'wishlist_place_invites') &&
          e.code != 'PGRST204' &&
          e.code != '42703') {
        rethrow;
      }
    }

    final plan = await _client
        .from('group_plans')
        .select('plan_data')
        .eq('session_id', sessionId)
        .maybeSingle();
    final raw = plan?['plan_data'];
    if (raw is Map) {
      final data = Map<String, dynamic>.from(raw);
      final mirror = Map<String, dynamic>.from(
        data['planMetVriendInvite'] as Map? ?? {},
      );
      if (mirror.isNotEmpty) {
        mirror['reply_message'] = trimmed;
        data['planMetVriendInvite'] = mirror;
        await _client.from('group_plans').update({
          'plan_data': data,
        }).eq('session_id', sessionId);
      }
    }

    if (inviterId.isNotEmpty) {
      final inviteeName = await fetchProfileDisplayName(uid) ?? 'Je vriend';
      final body = trimmed.length > 80 ? '${trimmed.substring(0, 77)}…' : trimmed;
      final title = '$inviteeName reageerde op je uitnodiging';
      try {
        await _client.rpc(
          'send_realtime_notification',
          params: {
            'target_user_id': inviterId,
            'event_type': 'systemUpdate',
            'event_title': title,
            'event_message': body,
            'event_data': {
              'type': 'plan_met_vriend_invite_reply',
              'session_id': sessionId,
              'invite_id': inviteId,
              'place_name': placeName,
            },
            'source_user_id': uid,
            'related_post_id': null,
            'priority_level': 3,
          },
        );
      } catch (e) {
        if (kDebugMode) debugPrint('plan_met_vriend reply notify: $e');
      }
      schedulePushNotify(
        recipientId: inviterId,
        event: 'plan_met_vriend_invite_reply',
        data: {
          'type': 'plan_met_vriend_invite_reply',
          'session_id': sessionId,
          'invite_id': inviteId,
          'place_name': placeName,
          'title': title,
          'body': body,
        },
      );
    }
  }

  Future<void> _notifyInvite({
    required String recipientId,
    required String inviterName,
    required String placeName,
    required String sessionId,
    required String inviteId,
    String? inviteMessage,
  }) async {
    final title = '$inviterName wil $placeName bezoeken';
    final note = inviteMessage?.trim();
    final body = (note != null && note.isNotEmpty)
        ? '$note · Tik om de datum samen af te stemmen.'
        : 'Tik om de datum samen af te stemmen.';
    try {
      await _client.rpc(
        'send_realtime_notification',
        params: {
          'target_user_id': recipientId,
          'event_type': 'systemUpdate',
          'event_title': title,
          'event_message': body,
          'event_data': {
            'type': 'plan_met_vriend_invite',
            'session_id': sessionId,
            'invite_id': inviteId,
            'place_name': placeName,
          },
          'source_user_id': _client.auth.currentUser?.id,
          'related_post_id': null,
          'priority_level': 3,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('plan_met_vriend realtime notify: $e');
    }
    schedulePushNotify(
      recipientId: recipientId,
      event: 'plan_met_vriend_invite',
      data: {
        'type': 'plan_met_vriend_invite',
        'session_id': sessionId,
        'invite_id': inviteId,
        'place_name': placeName,
        'title': title,
        'body': body,
      },
    );
  }

  Future<void> resendInviteReminder({
    required String friendUserId,
    required String inviterName,
    required String placeName,
    required String sessionId,
    required String inviteId,
  }) async {
    await _notifyInvite(
      recipientId: friendUserId,
      inviterName: inviterName,
      placeName: placeName,
      sessionId: sessionId,
      inviteId: inviteId,
    );
  }

  Future<bool> isPlanMetVriendSession(String sessionId) async {
    final row = await _client
        .from('group_sessions')
        .select('session_type')
        .eq('id', sessionId)
        .maybeSingle();
    return row?['session_type']?.toString() == 'plan_met_vriend';
  }

  Future<Map<String, dynamic>?> fetchSessionMeta(String sessionId) async {
    final row = await _client
        .from('group_sessions')
        .select(
          'session_type, anchor_place_id, anchor_place_name, anchor_place_data, planned_date',
        )
        .eq('id', sessionId)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>?> _inviteFromPlanData(String sessionId) async {
    final plan = await _client
        .from('group_plans')
        .select('plan_data')
        .eq('session_id', sessionId)
        .maybeSingle();
    final raw = plan?['plan_data'];
    if (raw is! Map) return null;
    final invite = raw['planMetVriendInvite'];
    if (invite is! Map) return null;
    return Map<String, dynamic>.from(invite);
  }

  Future<Map<String, dynamic>?> fetchInviteBySession(String sessionId) async {
    final fromPlan = await _inviteFromPlanData(sessionId);
    try {
      final row = await _client
          .from('wishlist_place_invites')
          .select()
          .eq('group_session_id', sessionId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row != null) {
        final table = Map<String, dynamic>.from(row);
        if (fromPlan == null) return table;
        return {
          ...fromPlan,
          ...table,
          'message': table['message'] ?? fromPlan['message'],
          'reply_message': table['reply_message'] ?? fromPlan['reply_message'],
          'invitee_display_name': table['invitee_display_name'] ??
              fromPlan['invitee_display_name'],
          'invitee_avatar_url': table['invitee_avatar_url'] ??
              fromPlan['invitee_avatar_url'],
          'invitee_username': table['invitee_username'] ??
              fromPlan['invitee_username'],
        };
      }
    } on PostgrestException catch (e) {
      if (!_isMissingRelation(e, 'wishlist_place_invites')) rethrow;
    }
    return fromPlan;
  }

  static bool isPlanMetVriendNotificationData(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim() ?? '';
    if (type == 'plan_met_vriend_invite' ||
        type == 'plan_met_vriend_match' ||
        type == 'plan_met_vriend_no_overlap') {
      return true;
    }
    final event = data['event']?.toString().trim() ?? '';
    return event == 'plan_met_vriend_invite';
  }

  /// Plan-met-vriend session ids from in-app notifications (invitee can read these).
  Future<Map<String, String?>> planMetVriendHintsFromInbox(String uid) async {
    final hints = <String, String?>{};
    List<dynamic> rows = const [];
    try {
      rows = await _client
          .from('realtime_events')
          .select('data')
          .eq('recipient_id', uid)
          .order('created_at', ascending: false)
          .limit(120);
    } on PostgrestException {
      try {
        rows = await _client
            .from('realtime_events')
            .select('data')
            .eq('user_id', uid)
            .order('timestamp', ascending: false)
            .limit(120);
      } catch (e) {
        if (kDebugMode) debugPrint('pmv inbox hints: $e');
      }
    }

    for (final raw in rows) {
      if (raw is! Map) continue;
      final dataRaw = raw['data'];
      if (dataRaw is! Map) continue;
      final data = Map<String, dynamic>.from(dataRaw);
      if (!isPlanMetVriendNotificationData(data)) continue;
      final sid = data['session_id']?.toString().trim();
      if (sid == null || sid.isEmpty) continue;
      final inviteId = data['invite_id']?.toString().trim();
      hints.putIfAbsent(sid, () => inviteId);
    }
    return hints;
  }

  /// Join session when invite row is only on the host plan (RLS blocked read).
  Future<void> joinSessionAsInviteeFromHint({
    required String sessionId,
    String? inviteId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _joinGroupSessionAsInvitee(sessionId, inviteId: inviteId);

    final resolvedInviteId = inviteId?.trim();
    if (resolvedInviteId != null && resolvedInviteId.isNotEmpty) {
      try {
        await _markInviteStatus(
          inviteId: resolvedInviteId,
          sessionId: sessionId,
          status: 'accepted',
        );
      } catch (e) {
        if (kDebugMode) debugPrint('pmv mark invite from hint: $e');
      }
    }
  }

  /// Adds invitee to [group_session_members] without changing invite status.
  Future<void> ensureInviteeMembershipOnly(String sessionId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final existing = await fetchMember(sessionId: sessionId, userId: uid);
    if (existing != null) return;

    final invite = await fetchInviteBySession(sessionId);
    if (invite == null) {
      final hints = await planMetVriendHintsFromInbox(uid);
      final inviteId = hints[sessionId];
      if (inviteId != null || hints.containsKey(sessionId)) {
        await joinSessionAsInviteeFromHint(
          sessionId: sessionId,
          inviteId: inviteId,
        );
      }
      return;
    }
    if (invite['invitee_user_id']?.toString() != uid) return;

    await _joinGroupSessionAsInvitee(
      sessionId,
      inviteId: invite['id']?.toString(),
    );
  }

  /// Ensures the current user can read the session (invitee not yet in members).
  Future<void> ensureInviteeSessionAccess(
    String sessionId, {
    String? inviteId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final existing = await fetchMember(sessionId: sessionId, userId: uid);
    if (existing != null) return;

    Map<String, dynamic>? invite;
    if (inviteId != null && inviteId.trim().isNotEmpty) {
      invite = await fetchInvite(inviteId.trim());
    }
    invite ??= await fetchInviteBySession(sessionId);
    if (invite == null) {
      final hintId = inviteId?.trim();
      if (hintId != null && hintId.isNotEmpty) {
        await joinSessionAsInviteeFromHint(
          sessionId: sessionId,
          inviteId: hintId,
        );
      }
      return;
    }

    final inviteeId = invite['invitee_user_id']?.toString();
    if (inviteeId != uid) return;

    final resolvedInviteId =
        invite['id']?.toString() ?? inviteId?.trim() ?? sessionId;
    if (resolvedInviteId.isEmpty) return;

    await joinInviteForDayPicker(
      sessionId: sessionId,
      inviteId: resolvedInviteId,
    );
  }

  Future<void> _ensureInviteeCanLoadPlans(
    String uid,
    Set<String> sessionIds,
    Set<String> memberSessionIds,
    Map<String, String?> inboxHints,
  ) async {
    for (final sid in sessionIds) {
      if (memberSessionIds.contains(sid)) continue;
      try {
        final inviteId = inboxHints[sid];
        if (inviteId != null && inviteId.isNotEmpty) {
          await joinSessionAsInviteeFromHint(
            sessionId: sid,
            inviteId: inviteId,
          );
        } else {
          await ensureInviteeMembershipOnly(sid);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('pmv ensure invitee load plans ($sid): $e');
      }
    }
  }

  /// Friend opens invite — join session, then Mood Match–style day ping-pong.
  Future<void> joinInviteForDayPicker({
    required String sessionId,
    required String inviteId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    await _joinGroupSessionAsInvitee(sessionId, inviteId: inviteId);

    await _markInviteStatus(
      inviteId: inviteId,
      sessionId: sessionId,
      status: 'accepted',
    );
  }

  Future<void> _markInviteStatus({
    required String inviteId,
    required String sessionId,
    required String status,
  }) async {
    final respondedAt = DateTime.now().toUtc().toIso8601String();
    try {
      await _client.from('wishlist_place_invites').update({
        'status': status,
        'responded_at': respondedAt,
      }).eq('id', inviteId);
      return;
    } on PostgrestException catch (e) {
      if (!_isMissingRelation(e, 'wishlist_place_invites')) rethrow;
    }
    final plan = await _client
        .from('group_plans')
        .select('plan_data')
        .eq('session_id', sessionId)
        .maybeSingle();
    final raw = plan?['plan_data'];
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    final invite = Map<String, dynamic>.from(
      data['planMetVriendInvite'] as Map? ?? {},
    );
    if (invite.isEmpty) return;
    invite['status'] = status;
    invite['responded_at'] = respondedAt;
    data['planMetVriendInvite'] = invite;
    await _client.from('group_plans').update({
      'plan_data': data,
    }).eq('session_id', sessionId);
  }

  Future<Map<String, dynamic>?> fetchInvite(String inviteId) async {
    try {
      final row = await _client
          .from('wishlist_place_invites')
          .select()
          .eq('id', inviteId)
          .maybeSingle();
      if (row != null) return Map<String, dynamic>.from(row);
    } on PostgrestException catch (e) {
      if (!_isMissingRelation(e, 'wishlist_place_invites')) rethrow;
    }
    return _inviteFromPlanData(inviteId);
  }

  Future<Map<String, dynamic>?> fetchMember({
    required String sessionId,
    required String userId,
  }) async {
    final row = await _client
        .from('group_session_members')
        .select()
        .eq('session_id', sessionId)
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<List<DateTime>> fetchMemberDates({
    required String sessionId,
    required String userId,
  }) async {
    final m = await fetchMember(sessionId: sessionId, userId: userId);
    if (m == null) return [];
    return parseDateList(m['availability_dates']);
  }

  Future<({List<DateTime> overlap, String inviterId})> acceptInviteAndMatch({
    required String sessionId,
    required String inviteId,
    required List<DateTime> friendDates,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final now = DateTime.now().toUtc();
    final dates = datesToIso(friendDates);

    await _joinGroupSessionAsInvitee(sessionId, inviteId: inviteId);
    await _updateRowResilient(
      'group_session_members',
      {
        'availability_dates': dates,
        'availability_submitted_at': now.toIso8601String(),
      },
      {'session_id': sessionId, 'user_id': uid},
      droppableKeys: const [
        'availability_dates',
        'availability_submitted_at',
      ],
    );

    await _markInviteStatus(
      inviteId: inviteId,
      sessionId: sessionId,
      status: 'accepted',
    );

    final invite = await fetchInvite(inviteId);
    final inviterId = invite?['inviter_user_id'] as String? ?? '';

    final inviterDates = inviterId.isNotEmpty
        ? await fetchMemberDates(sessionId: sessionId, userId: inviterId)
        : <DateTime>[];

    final overlap = intersectDates(inviterDates, friendDates);

    if (overlap.isNotEmpty) {
      final planned = datesToIso([overlap.first]).first;
      await _client.from('group_sessions').update({
        'status': 'match_found',
        'planned_date': planned,
      }).eq('id', sessionId);

      if (inviterId.isNotEmpty) {
        final friendName = await fetchProfileDisplayName(uid) ?? 'Je vriend';
        schedulePushNotify(
          recipientId: inviterId,
          event: 'plan_met_vriend_match',
          data: {
            'type': 'plan_met_vriend_match',
            'session_id': sessionId,
            'invite_id': inviteId,
            'friend_name': friendName,
          },
        );
      }
    } else {
      await _client.from('group_sessions').update({
        'status': 'no_overlap',
      }).eq('id', sessionId);

      if (inviterId.isNotEmpty) {
        schedulePushNotify(
          recipientId: inviterId,
          event: 'plan_met_vriend_no_overlap',
          data: {
            'session_id': sessionId,
            'invite_id': inviteId,
          },
        );
      }
    }

    return (overlap: overlap, inviterId: inviterId);
  }

  Future<void> declineInvite({
    required String inviteId,
    required String sessionId,
  }) async {
    await _markInviteStatus(
      inviteId: inviteId,
      sessionId: sessionId,
      status: 'declined',
    );
  }

  Future<void> markCalendarSynced({
    required String sessionId,
    required String userId,
  }) async {
    try {
      await _client.from('group_session_members').update({
        'calendar_synced': true,
      }).match({'session_id': sessionId, 'user_id': userId});
    } catch (e) {
      if (kDebugMode) debugPrint('calendar_synced member: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchSession(String sessionId) async {
    final row = await _client
        .from('group_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<String?> fetchProfileDisplayName(String userId) async {
    return fetchProfileDisplayUsername(_client, userId);
  }

  /// Seeds a single-venue [group_plans] row so Mood Match result UI can show the anchor.
  Future<void> seedAnchorPlanForSession({
    required String sessionId,
    required PlanMetVriendPlace place,
    required DateTime plannedDate,
  }) async {
    final data = place.placeData;
    final lat = (data['lat'] as num?)?.toDouble() ??
        (data['latitude'] as num?)?.toDouble() ??
        0.0;
    final lng = (data['lng'] as num?)?.toDouble() ??
        (data['longitude'] as num?)?.toDouble() ??
        0.0;
    final image = place.photoUrl ?? '';
    final act = <String, dynamic>{
      'name': place.placeName,
      'type': data['type'] ?? data['primary_type'] ?? 'restaurant',
      'rating': data['rating'],
      'timeSlot': 'evening',
      'moodMatch': true,
      'place_id': place.placeId,
      'imageUrl': image,
      'location': {'lat': lat, 'lng': lng},
      'description': data['description'] ?? data['editorial_summary'] ?? '',
      'duration': '2h',
    };
    final planData = <String, dynamic>{
      'planVersion': 2,
      'version': 2,
      'planning_mode': 'plan_met_vriend',
      'planned_date': PlanMetVriendService.datesToIso([plannedDate]).first,
      'time_slot': 'evening',
      'activities': [act],
      'ownerConfirmed': {'evening': true},
      'guestConfirmed': {'evening': true},
      'sentToGuest': true,
    };
    try {
      await _client.from('group_plans').upsert({
        'session_id': sessionId,
        'plan_data': planData,
      }, onConflict: 'session_id');
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
    }
    await _client.from('group_sessions').update({
      'status': 'ready',
    }).eq('id', sessionId);
  }

  Future<void> saveAnchorDateToMyDay({
    required String sessionId,
    required PlanMetVriendPlace place,
    required DateTime date,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final dateStr = datesToIso([date]).first;
    final localStart = DateTime(date.year, date.month, date.day, 19, 0);
    final image = place.photoUrl ?? '';
    final row = <String, dynamic>{
      'user_id': uid,
      'activity_id': 'pmv_${sessionId}_${place.placeId}',
      'place_id': place.placeId,
      'place_name': place.placeName,
      'name': place.placeName,
      'image_url': image,
      'scheduled_date': dateStr,
      'start_time': localStart.toUtc().toIso8601String(),
      'duration': 120,
      'duration_minutes': 120,
      'group_session_id': sessionId,
      'time_slot': 'evening',
    };
    try {
      await _client.from('scheduled_activities').insert(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      rethrow;
    }
  }

  Future<Map<String, String?>> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('full_name, username, image_url')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) {
      return {'displayName': null, 'avatarUrl': null, 'username': null};
    }
    final full = row['full_name'] as String?;
    final user = row['username'] as String?;
    return {
      'displayName': (full != null && full.trim().isNotEmpty)
          ? full.trim()
          : user,
      'avatarUrl': row['image_url'] as String?,
      'username': user,
    };
  }

  bool _isPlanMetVriendPlanData(Map<String, dynamic> data) {
    if (data['planning_mode'] == 'plan_met_vriend') return true;
    if (data['planMetVriendInvite'] != null) return true;
    final acts = data['activities'];
    if (acts is List &&
        acts.isNotEmpty &&
        acts.first is Map &&
        (acts.first as Map)['moodMatch'] != true) {
      final first = acts.first as Map;
      if (first['place_id'] != null) return true;
    }
    return false;
  }

  static PlanMetVriendPlanCardKind _resolvePlanCardKind({
    required String status,
    required String userId,
    required Map<String, dynamic>? planData,
    required String? proposedByUserId,
  }) {
    if (status == 'match_found' || status == 'day_confirmed') {
      return PlanMetVriendPlanCardKind.confirmed;
    }
    if (MoodMatchPlanProposals.dayProposalPendingForUser(planData, userId)) {
      return PlanMetVriendPlanCardKind.needsReply;
    }
    if (status == 'day_proposed' &&
        proposedByUserId != null &&
        proposedByUserId.isNotEmpty &&
        proposedByUserId != userId) {
      return PlanMetVriendPlanCardKind.needsReply;
    }
    return PlanMetVriendPlanCardKind.waiting;
  }

  static String? _locationLabelFromPlaceData(Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    for (final key in const [
      'vicinity',
      'neighborhood',
      'district',
      'city',
    ]) {
      final v = data[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    final address = data['address'] ?? data['formatted_address'];
    if (address is String && address.trim().isNotEmpty) {
      final parts = address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts[parts.length - 2]}, ${parts.last}';
      }
      return address.trim();
    }
    return null;
  }

  static String? _firstPhotoUrlFromPlaceBlob(Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);

    for (final key in const [
      'photo_url',
      'photoUrl',
      'image_url',
      'imageUrl',
    ]) {
      final v = data[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }

    final photos = data['photos'];
    if (photos is List && photos.isNotEmpty) {
      for (final item in photos) {
        if (item is String) {
          final s = item.trim();
          if (s.isNotEmpty) return s;
        }
        if (item is Map) {
          for (final key in const ['url', 'photo_url', 'photoUrl', 'uri']) {
            final v = item[key]?.toString().trim();
            if (v != null && v.isNotEmpty) return v;
          }
        }
      }
    }

    final ref = data['photo_reference']?.toString().trim();
    if (ref != null && ref.isNotEmpty) {
      final placeId = data['id']?.toString() ?? data['place_id']?.toString();
      return GooglePlacesService.getPhotoUrl(ref, 400, 400, placeId);
    }

    final refs = data['photo_references'];
    if (refs is List && refs.isNotEmpty) {
      final ref0 = refs.first?.toString().trim();
      if (ref0 != null && ref0.isNotEmpty) {
        final placeId = data['id']?.toString() ?? data['place_id']?.toString();
        return GooglePlacesService.getPhotoUrl(ref0, 400, 400, placeId);
      }
    }

    return null;
  }

  static String? _photoUrlFromSources({
    Map<String, dynamic>? planData,
    Object? inviteRaw,
    Object? sessionAnchorPlaceData,
    Object? wishlistPlaceData,
  }) {
    if (inviteRaw is Map) {
      final invite = Map<String, dynamic>.from(inviteRaw);
      final fromInvite = _firstPhotoUrlFromPlaceBlob(invite['place_data']);
      if (fromInvite != null) return fromInvite;
    }

    final fromWishlist = _firstPhotoUrlFromPlaceBlob(wishlistPlaceData);
    if (fromWishlist != null) return fromWishlist;

    final fromSessionAnchor = _firstPhotoUrlFromPlaceBlob(sessionAnchorPlaceData);
    if (fromSessionAnchor != null) return fromSessionAnchor;

    final pd = planData;
    if (pd != null) {
      final fromPlanAnchor = _firstPhotoUrlFromPlaceBlob(pd['anchor_place_data']);
      if (fromPlanAnchor != null) return fromPlanAnchor;

      final acts = pd['activities'];
      if (acts is List && acts.isNotEmpty && acts.first is Map) {
        final fromAct = _firstPhotoUrlFromPlaceBlob(acts.first);
        if (fromAct != null) return fromAct;
      }
    }
    return null;
  }

  Future<Set<String>> _sessionIdsSavedToMyDay(List<String> sessionIds) async {
    if (sessionIds.isEmpty) return {};
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    try {
      final rows = await _client
          .from('scheduled_activities')
          .select('group_session_id')
          .eq('user_id', uid)
          .inFilter('group_session_id', sessionIds);
      final out = <String>{};
      for (final row in rows as List) {
        final sid = row['group_session_id']?.toString();
        if (sid != null && sid.isNotEmpty) out.add(sid);
      }
      return out;
    } catch (e) {
      if (kDebugMode) debugPrint('pmv savedToMyDay lookup: $e');
      return {};
    }
  }

  Future<Map<String, String>> _photoUrlsFromPlacesCache(
    List<String> placeIds,
  ) async {
    if (placeIds.isEmpty) return {};
    try {
      final rows = await _client
          .from('places_cache')
          .select('place_id, photo_reference, photo_references')
          .inFilter('place_id', placeIds);
      final out = <String, String>{};
      for (final row in rows as List) {
        final pid = row['place_id']?.toString();
        if (pid == null || pid.isEmpty) continue;
        final url = _firstPhotoUrlFromPlaceBlob(row);
        if (url != null) out[pid] = url;
      }
      return out;
    } catch (e) {
      if (kDebugMode) debugPrint('pmv places_cache photos: $e');
      return {};
    }
  }

  /// Plans the current user is part of (plan-met-vriend mode).
  Future<List<PlanMetVriendPlanListItem>> listMyFriendPlans() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final memberships = await _client
          .from('group_session_members')
          .select('session_id')
          .eq('user_id', uid);
      final sessionIdSet = (memberships as List)
          .map((r) => r['session_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      try {
        final inviteRows = await _client
            .from('wishlist_place_invites')
            .select('group_session_id, status')
            .eq('invitee_user_id', uid);
        for (final row in inviteRows as List) {
          final sid = row['group_session_id']?.toString();
          if (sid == null || sid.isEmpty) continue;
          final status = row['status']?.toString().toLowerCase() ?? '';
          if (status == 'declined' || status == 'cancelled') continue;
          sessionIdSet.add(sid);
        }
      } on PostgrestException catch (e) {
        if (!_isMissingRelation(e, 'wishlist_place_invites') && kDebugMode) {
          debugPrint('pmv list invites for invitee: $e');
        }
      }

      final inboxHints = await planMetVriendHintsFromInbox(uid);
      sessionIdSet.addAll(inboxHints.keys);

      final memberOnlyIds = (memberships as List)
          .map((r) => r['session_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      await _ensureInviteeCanLoadPlans(
        uid,
        sessionIdSet,
        memberOnlyIds,
        inboxHints,
      );

      final sessionIds = sessionIdSet.toList();
      if (sessionIds.isEmpty) return [];

      final plans = await _client
          .from('group_plans')
          .select('session_id, plan_data')
          .inFilter('session_id', sessionIds);

      final pmvSessionIds = <String>[];
      final planDataBySession = <String, Map<String, dynamic>>{};
      for (final row in plans as List) {
        final sid = row['session_id']?.toString();
        if (sid == null || sid.isEmpty) continue;
        final pd = row['plan_data'];
        if (pd is! Map) continue;
        final data = Map<String, dynamic>.from(pd);
        if (_isPlanMetVriendPlanData(data)) {
          pmvSessionIds.add(sid);
          planDataBySession[sid] = data;
        }
      }
      if (pmvSessionIds.isEmpty) return [];

      List<dynamic> sessions;
      try {
        sessions = await _client
            .from('group_sessions')
            .select(
              'id, status, planned_date, title, created_at, created_by, '
              'proposed_slot, proposed_by_user_id, anchor_place_id, '
              'anchor_place_data, completed_at',
            )
            .inFilter('id', pmvSessionIds);
      } on PostgrestException {
        try {
          sessions = await _client
              .from('group_sessions')
              .select(
                'id, status, planned_date, title, created_at, created_by, '
                'anchor_place_id, anchor_place_data, completed_at',
              )
              .inFilter('id', pmvSessionIds);
        } on PostgrestException {
          try {
            sessions = await _client
                .from('group_sessions')
                .select(
                  'id, status, planned_date, title, created_at, created_by',
                )
                .inFilter('id', pmvSessionIds);
          } on PostgrestException {
            sessions = await _client
                .from('group_sessions')
                .select('id, status, created_at')
                .inFilter('id', pmvSessionIds);
          }
        }
      }

      final wishlistPlaceDataBySession = <String, Map<String, dynamic>>{};
      final inviteIdBySession = <String, String>{};
      try {
        final inviteRows = await _client
            .from('wishlist_place_invites')
            .select('id, group_session_id, place_id, place_data')
            .inFilter('group_session_id', pmvSessionIds);
        for (final row in inviteRows as List) {
          final sid = row['group_session_id']?.toString();
          final pd = row['place_data'];
          if (sid == null || sid.isEmpty) continue;
          final rowId = row['id']?.toString();
          if (rowId != null && rowId.isNotEmpty) {
            inviteIdBySession[sid] = rowId;
          }
          if (pd is! Map) continue;
          wishlistPlaceDataBySession[sid] =
              Map<String, dynamic>.from(pd);
        }
      } on PostgrestException catch (e) {
        if (!_isMissingRelation(e, 'wishlist_place_invites') && kDebugMode) {
          debugPrint('pmv wishlist_place_invites photos: $e');
        }
      }

      final memberRows = await _client
          .from('group_session_members')
          .select('session_id, user_id')
          .inFilter('session_id', pmvSessionIds);
      final otherUserBySession = <String, String>{};
      for (final m in memberRows as List) {
        final sid = m['session_id']?.toString();
        final memberId = m['user_id']?.toString();
        if (sid == null || memberId == null || memberId == uid) continue;
        otherUserBySession.putIfAbsent(sid, () => memberId);
      }

      final profileIds = otherUserBySession.values.toSet().toList();
      final profilesById = <String, Map<String, String?>>{};
      if (profileIds.isNotEmpty) {
        List<dynamic> profiles;
        try {
          profiles = await _client
              .from('profiles')
              .select('id, full_name, username, image_url')
              .inFilter('id', profileIds);
        } on PostgrestException {
          profiles = await _client
              .from('profiles')
              .select('id, full_name, username')
              .inFilter('id', profileIds);
        }
        for (final p in profiles) {
          final id = p['id']?.toString();
          if (id == null) continue;
          profilesById[id] = {
            'displayName': (p['full_name'] as String?)?.trim().isNotEmpty == true
                ? p['full_name'] as String
                : p['username'] as String?,
            'username': p['username'] as String?,
            'avatarUrl': p['image_url'] as String?,
          };
        }
      }

      final savedToMyDayIds = await _sessionIdsSavedToMyDay(pmvSessionIds);

      final out = <PlanMetVriendPlanListItem>[];
      for (final row in sessions) {
        final sid = row['id']?.toString();
        if (sid == null) continue;
        final pd = planDataBySession[sid];
        final invite = pd?['planMetVriendInvite'];
        String placeName = (row['title'] as String?)?.trim() ?? '';
        if (placeName.isEmpty && invite is Map) {
          placeName = (invite['place_name'] as String?)?.trim() ?? '';
        }
        if (placeName.isEmpty) {
          final acts = pd?['activities'];
          if (acts is List && acts.isNotEmpty && acts.first is Map) {
            placeName = ((acts.first as Map)['name'] as String?)?.trim() ?? '';
          }
        }
        if (placeName.isEmpty) placeName = 'Place';

        DateTime? planned;
        final plannedRaw = row['planned_date'] ?? pd?['planned_date'];
        if (plannedRaw != null) {
          planned = DateTime.tryParse(plannedRaw.toString());
        }

        var updated = DateTime.now();
        final createdRaw = row['created_at'];
        if (createdRaw != null) {
          updated = DateTime.tryParse(createdRaw.toString()) ?? updated;
        }

        final createdBy = row['created_by']?.toString();
        final isHost = createdBy == uid ||
            (invite is Map && invite['inviter_user_id']?.toString() == uid);

        String? friendLabel;
        String? friendAvatarUrl;
        String? otherId;
        if (invite is Map) {
          otherId = invite['inviter_user_id'] == uid
              ? invite['invitee_user_id']?.toString()
              : invite['inviter_user_id']?.toString();
          if (isHost) {
            final inviteeName =
                (invite['invitee_display_name'] as String?)?.trim();
            if (inviteeName != null && inviteeName.isNotEmpty) {
              friendLabel = inviteeName;
            }
            final inviteeAvatar =
                (invite['invitee_avatar_url'] as String?)?.trim();
            if (inviteeAvatar != null && inviteeAvatar.isNotEmpty) {
              friendAvatarUrl = inviteeAvatar;
            }
          }
        }
        otherId ??= otherUserBySession[sid];
        if (otherId != null && otherId.isNotEmpty) {
          final profile = profilesById[otherId];
          friendLabel ??= profile?['displayName'] ?? profile?['username'];
          friendAvatarUrl ??= profile?['avatarUrl'];
        }

        final sessionStatus = row['status']?.toString() ?? 'waiting';
        final proposedBy = row['proposed_by_user_id']?.toString();
        var timeSlot = row['proposed_slot']?.toString();
        final dayProposal = MoodMatchPlanProposals.dayProposalMap(pd);
        if (dayProposal != null) {
          final slotFromProposal = dayProposal['proposedSlot']?.toString();
          if (slotFromProposal != null && slotFromProposal.isNotEmpty) {
            timeSlot = slotFromProposal;
          }
        }
        if ((timeSlot == null || timeSlot.isEmpty) && pd != null) {
          timeSlot = pd['time_slot']?.toString();
        }

        final cardKind = _resolvePlanCardKind(
          status: sessionStatus,
          userId: uid,
          planData: pd,
          proposedByUserId: proposedBy ?? dayProposal?['proposedBy']?.toString(),
        );

        final completedRaw = row['completed_at'];
        final isCompleted = savedToMyDayIds.contains(sid) ||
            (completedRaw != null && completedRaw.toString().trim().isNotEmpty);

        String? placeId;
        if (invite is Map) {
          placeId = invite['place_id']?.toString();
        }
        placeId ??= row['anchor_place_id']?.toString();

        var photoUrl = _photoUrlFromSources(
          planData: pd,
          inviteRaw: invite,
          sessionAnchorPlaceData: row['anchor_place_data'],
          wishlistPlaceData: wishlistPlaceDataBySession[sid],
        );

        String? inviteId = inviteIdBySession[sid];
        if (inviteId == null && invite is Map) {
          inviteId = invite['invite_id']?.toString() ?? invite['id']?.toString();
        }
        final locationLabel = _locationLabelFromPlaceData(
          invite is Map ? invite['place_data'] : null,
        ) ??
            _locationLabelFromPlaceData(row['anchor_place_data']) ??
            _locationLabelFromPlaceData(wishlistPlaceDataBySession[sid]);

        out.add(
          PlanMetVriendPlanListItem(
            sessionId: sid,
            placeName: placeName,
            status: sessionStatus,
            isHost: isHost,
            cardKind: cardKind,
            isCompleted: isCompleted,
            plannedDate: planned,
            friendLabel: friendLabel,
            friendAvatarUrl: friendAvatarUrl,
            photoUrl: photoUrl,
            placeId: placeId,
            timeSlot: timeSlot,
            proposedByUserId:
                proposedBy ?? dayProposal?['proposedBy']?.toString(),
            inviteId: inviteId,
            friendUserId: otherId,
            locationLabel: locationLabel,
            updatedAt: updated,
          ),
        );
      }

      var missingPlaceIds = out
          .where((p) => (p.photoUrl == null || p.photoUrl!.isEmpty) && p.placeId != null)
          .map((p) => p.placeId!)
          .toSet()
          .toList();

      if (missingPlaceIds.isNotEmpty) {
        final savedPhotos = <String, String>{};
        try {
          final savedRows = await _client
              .from('user_saved_places')
              .select('place_id, place_data')
              .eq('user_id', uid)
              .inFilter('place_id', missingPlaceIds);
          for (final row in savedRows as List) {
            final pid = row['place_id']?.toString();
            if (pid == null) continue;
            final url = _firstPhotoUrlFromPlaceBlob(row['place_data']);
            if (url != null) savedPhotos[pid] = url;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('pmv user_saved_places photos: $e');
        }
        if (savedPhotos.isNotEmpty) {
          for (var i = 0; i < out.length; i++) {
            final item = out[i];
            if (item.photoUrl != null && item.photoUrl!.isNotEmpty) continue;
            final cached = savedPhotos[item.placeId];
            if (cached == null) continue;
            out[i] = PlanMetVriendPlanListItem(
              sessionId: item.sessionId,
              placeName: item.placeName,
              status: item.status,
              isHost: item.isHost,
              cardKind: item.cardKind,
              isCompleted: item.isCompleted,
              plannedDate: item.plannedDate,
              friendLabel: item.friendLabel,
              friendAvatarUrl: item.friendAvatarUrl,
              photoUrl: cached,
              placeId: item.placeId,
              timeSlot: item.timeSlot,
              proposedByUserId: item.proposedByUserId,
              inviteId: item.inviteId,
              friendUserId: item.friendUserId,
              locationLabel: item.locationLabel,
              updatedAt: item.updatedAt,
            );
          }
        }
      }

      missingPlaceIds = out
          .where((p) => (p.photoUrl == null || p.photoUrl!.isEmpty) && p.placeId != null)
          .map((p) => p.placeId!)
          .toSet()
          .toList();
      if (missingPlaceIds.isNotEmpty) {
        final cachePhotos = await _photoUrlsFromPlacesCache(missingPlaceIds);
        if (cachePhotos.isNotEmpty) {
          for (var i = 0; i < out.length; i++) {
            final item = out[i];
            if (item.photoUrl != null && item.photoUrl!.isNotEmpty) continue;
            final pid = item.placeId;
            if (pid == null) continue;
            final cached = cachePhotos[pid];
            if (cached != null) {
              out[i] = PlanMetVriendPlanListItem(
                sessionId: item.sessionId,
                placeName: item.placeName,
                status: item.status,
                isHost: item.isHost,
                cardKind: item.cardKind,
                isCompleted: item.isCompleted,
                plannedDate: item.plannedDate,
                friendLabel: item.friendLabel,
                friendAvatarUrl: item.friendAvatarUrl,
                photoUrl: cached,
                placeId: item.placeId,
                timeSlot: item.timeSlot,
                proposedByUserId: item.proposedByUserId,
                inviteId: item.inviteId,
                friendUserId: item.friendUserId,
                locationLabel: item.locationLabel,
                updatedAt: item.updatedAt,
              );
            }
          }
        }
      }

      out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return out;
    } catch (e, st) {
      if (kDebugMode) debugPrint('listMyFriendPlans: $e\n$st');
      rethrow;
    }
  }

  /// Removes this plan from your list (host deletes session; guest leaves).
  Future<void> cancelFriendPlan({
    required String sessionId,
    required bool isHost,
    required GroupPlanningRepository groupRepo,
  }) async {
    await _markInviteCancelledInPlanData(sessionId);
    try {
      await _client.from('wishlist_place_invites').update({
        'status': 'cancelled',
        'responded_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('group_session_id', sessionId);
    } on PostgrestException catch (e) {
      if (!_isMissingRelation(e, 'wishlist_place_invites')) {
        if (kDebugMode) debugPrint('cancelFriendPlan invite row: $e');
      }
    }
    if (isHost) {
      await groupRepo.deleteSession(sessionId);
    } else {
      await groupRepo.removeSelfFromSession(sessionId);
    }
  }

  Future<void> _markInviteCancelledInPlanData(String sessionId) async {
    final existing = await _client
        .from('group_plans')
        .select('plan_data')
        .eq('session_id', sessionId)
        .maybeSingle();
    final raw = existing?['plan_data'];
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    final invite = data['planMetVriendInvite'];
    if (invite is Map) {
      final copy = Map<String, dynamic>.from(invite);
      copy['status'] = 'cancelled';
      data['planMetVriendInvite'] = copy;
      await _client.from('group_plans').update({
        'plan_data': data,
      }).eq('session_id', sessionId);
    }
  }
}
