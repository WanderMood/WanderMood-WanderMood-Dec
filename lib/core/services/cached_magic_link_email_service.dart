import 'package:shared_preferences/shared_preferences.dart';

/// Stores the last magic-link email so users rarely retype it.
///
/// Sliding window: each [remember] or session-based extension sets expiry to
/// [ttl] from now. Cleared on sign-out. Uninstall wipes app storage.
class CachedMagicLinkEmailService {
  CachedMagicLinkEmailService(this._prefs);

  final SharedPreferences _prefs;

  static const String _emailKey = 'wandermood_cached_magic_link_email';
  static const String _expiryKey = 'wandermood_cached_magic_link_email_expires_ms';

  /// How long the cached email remains valid (renewed on use / sign-in).
  static const Duration ttl = Duration(days: 180);

  /// Returns the cached email if still within TTL; otherwise `null`.
  String? getValidEmail() {
    final expiryMs = _prefs.getInt(_expiryKey);
    final email = _prefs.getString(_emailKey);
    if (email == null || email.isEmpty) return null;
    if (expiryMs == null) return null;
    if (DateTime.now().millisecondsSinceEpoch > expiryMs) return null;
    return email;
  }

  Future<void> remember(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;
    final expires = DateTime.now().add(ttl).millisecondsSinceEpoch;
    await _prefs.setString(_emailKey, trimmed);
    await _prefs.setInt(_expiryKey, expires);
  }

  Future<void> clear() async {
    await _prefs.remove(_emailKey);
    await _prefs.remove(_expiryKey);
  }
}
