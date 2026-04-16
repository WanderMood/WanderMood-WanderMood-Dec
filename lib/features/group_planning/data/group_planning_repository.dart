import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/services/wandermood_ai_service.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_compatibility.dart';
import 'package:wandermood/features/group_planning/data/profile_invite_search_row.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_in_app_invite_result.dart';

/// Supabase-backed group planning (create / join RPCs, moods, shared plan).
class GroupPlanningRepository {
  GroupPlanningRepository(this._client);

  final SupabaseClient _client;

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
    final map = await _client
        .from('group_sessions')
        .select()
        .eq('id', sessionId)
        .single();
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

    try {
      await _client.from('group_sessions').update({
        'status': 'generating',
        'updated_at': MoodyClock.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint('group_sessions generating status: $e');
    }

    try {
      final ai = await WanderMoodAIService.getRecommendations(
        moods: moods,
        latitude: latitude,
        longitude: longitude,
        city: city,
      );

      final score = compatibilityScoreForMoodTags(moods);
      var moodyMessage = '';
      try {
        moodyMessage = await WanderMoodAIService.getGroupMatchMoodyMessage(
          moods: moods,
          compatibilityScore: score,
          languageCode: languageCode,
          communicationStyle: communicationStyle,
        );
      } catch (e) {
        debugPrint('group moodyMessage skipped: $e');
      }

      final planData = <String, dynamic>{
        'version': 1,
        'moods': moods,
        'summary': ai.summary,
        'compatibilityScore': score,
        'generated_at': MoodyClock.now().toUtc().toIso8601String(),
        'recommendations': ai.recommendations.map((r) => r.toJson()).toList(),
        if (moodyMessage.isNotEmpty) 'moodyMessage': moodyMessage,
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
    required String notificationTitle,
    required String notificationMessage,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return MoodMatchInAppInviteResult.error;
    if (uid == targetUserId) return MoodMatchInAppInviteResult.error;
    try {
      final response = await _client.rpc(
        'send_realtime_notification',
        params: {
          'target_user_id': targetUserId,
          'event_type': 'groupTravelUpdate',
          'event_title': notificationTitle,
          'event_message': notificationMessage,
          'event_data': {
            'kind': 'mood_match_invite',
            'session_id': sessionId,
            'join_code': joinCode.trim().toUpperCase(),
            'join_link': joinLinkHttps,
          },
          'source_user_id': uid,
          'related_post_id': null,
          'priority_level': 3,
        },
      );
      if (response == null) {
        return MoodMatchInAppInviteResult.notDeliveredInApp;
      }
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
}
