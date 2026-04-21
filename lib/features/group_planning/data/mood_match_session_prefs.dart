import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/group_planning/data/mood_match_invited_profile.dart';

/// Persists the active Mood Match session so the hub and lobby can restore after navigation.
class MoodMatchSessionPrefs {
  MoodMatchSessionPrefs._();

  static const String sessionIdKey = 'active_mood_match_session_id';
  static const String joinCodeKey = 'active_mood_match_join_code';

  static String _kInvited(String sessionId) =>
      'mm_invited_profiles_v1_${sessionId.trim()}';
  static String _kRevealDone(String sessionId) =>
      'mm_reveal_done_v1_${sessionId.trim()}';
  static String _kPlannedDate(String sessionId) =>
      'mm_planned_date_v1_${sessionId.trim()}';
  static String _kPendingSlot(String sessionId) =>
      'mm_pending_slot_v1_${sessionId.trim()}';
  static String _kSessionTitle(String sessionId) =>
      'mm_session_title_v1_${sessionId.trim()}';

  static Future<void> save({
    required String sessionId,
    required String joinCode,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(sessionIdKey, sessionId.trim());
    await p.setString(joinCodeKey, joinCode.trim().toUpperCase());
  }

  static Future<({String? sessionId, String? joinCode})> read() async {
    final p = await SharedPreferences.getInstance();
    final sid = p.getString(sessionIdKey)?.trim();
    final code = p.getString(joinCodeKey)?.trim();
    if (sid == null || sid.isEmpty) {
      return (sessionId: null, joinCode: null);
    }
    return (
      sessionId: sid,
      joinCode: (code != null && code.isNotEmpty) ? code : null
    );
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(sessionIdKey);
    await p.remove(joinCodeKey);
  }

  static Future<List<MoodMatchInvitedProfile>> readInvitedProfiles(
    String sessionId,
  ) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kInvited(sessionId));
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (m) => MoodMatchInvitedProfile.fromJson(
              Map<String, dynamic>.from(m),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> clearInvitedProfiles(String sessionId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kInvited(sessionId));
  }

  static Future<void> upsertInvitedProfile({
    required String sessionId,
    required MoodMatchInvitedProfile profile,
  }) async {
    final p = await SharedPreferences.getInstance();
    final existing = await readInvitedProfiles(sessionId);
    final next = <MoodMatchInvitedProfile>[];
    var replaced = false;
    for (final item in existing) {
      if (item.id == profile.id) {
        next.add(profile);
        replaced = true;
      } else {
        next.add(item);
      }
    }
    if (!replaced) {
      next.add(profile);
    }
    final payload = jsonEncode(next.map((e) => e.toJson()).toList());
    await p.setString(_kInvited(sessionId), payload);
  }

  static Future<bool> readRevealCompleted(String sessionId) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRevealDone(sessionId)) ?? false;
  }

  static Future<void> markRevealCompleted(String sessionId) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRevealDone(sessionId), true);
  }

  static Future<void> savePlannedDate(String sessionId, String isoDate) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPlannedDate(sessionId), isoDate.trim());
  }

  static Future<String?> readPlannedDate(String sessionId) async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_kPlannedDate(sessionId))?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<void> savePendingTimeSlot(
    String sessionId,
    String slot,
  ) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPendingSlot(sessionId), slot.trim());
  }

  static Future<String?> readPendingTimeSlot(String sessionId) async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_kPendingSlot(sessionId))?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<void> clearPendingTimeSlot(String sessionId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPendingSlot(sessionId));
  }

  static Future<void> saveSessionDisplayTitle(
    String sessionId,
    String title,
  ) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSessionTitle(sessionId), title.trim());
  }

  static Future<String?> readSessionDisplayTitle(String sessionId) async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_kSessionTitle(sessionId))?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }
}
