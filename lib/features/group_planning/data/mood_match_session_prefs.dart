import 'package:shared_preferences/shared_preferences.dart';

/// Persists the active Mood Match session so the hub and lobby can restore after navigation.
class MoodMatchSessionPrefs {
  MoodMatchSessionPrefs._();

  static const String sessionIdKey = 'active_mood_match_session_id';
  static const String joinCodeKey = 'active_mood_match_join_code';

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
}
