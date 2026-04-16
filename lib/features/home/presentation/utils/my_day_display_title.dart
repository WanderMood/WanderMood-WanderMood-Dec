/// Shortens verbose Google-style / merchant titles for My Day UI surfaces.
/// Full strings in [rawData] are unchanged for maps, share, and APIs.
String myDayShortActivityTitle(String? raw, {int maxChars = 48}) {
  if (raw == null) return '';
  var t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return '';

  // Strip trailing parenthetical noise, e.g. "(VISIT BY APPOINTMENT ONLY)"
  final openParen = t.indexOf(' (');
  if (openParen >= 12) {
    t = t.substring(0, openParen).trim();
  }
  if (t.length <= maxChars) return t;

  for (final sep in [' — ', ' – ', ' - ', ' | ', ' · ']) {
    final i = t.indexOf(sep);
    if (i >= 14) {
      final head = t.substring(0, i).trim();
      if (head.length <= maxChars) return head;
      if (head.length < t.length) {
        t = head;
        break;
      }
    }
  }

  if (t.length <= maxChars) return t;

  var end = maxChars < t.length ? maxChars : t.length;
  while (end > 18) {
    final ch = t[end - 1];
    if (ch == ' ' || ch == ',' || ch == ';') break;
    end--;
  }
  if (end <= 18) end = maxChars > t.length ? t.length : maxChars;
  return '${t.substring(0, end).trim()}…';
}
