/// Normalize handle for [profiles.username]: trim, lowercase, no leading @.
String? normalizeProfileUsername(String raw) {
  var s = raw.trim();
  if (s.startsWith('@')) {
    s = s.substring(1).trim();
  }
  if (s.isEmpty) return null;
  return s.toLowerCase();
}

/// 3–30 chars, ASCII letters, digits, underscores (stored lowercase).
bool isValidProfileUsernameFormat(String normalized) {
  return RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(normalized);
}
