/// Deterministic compatibility score (68–94) from mood tags for Mood Match reveal.
int compatibilityScoreForMoodTags(List<String> moods) {
  final tags = moods
      .map((e) => e.toLowerCase().trim())
      .where((e) => e.isNotEmpty)
      .toList()
    ..sort();
  if (tags.isEmpty) return 78;
  var h = 0;
  for (final t in tags) {
    for (var i = 0; i < t.length; i++) {
      h = (h * 31 + t.codeUnitAt(i)) & 0x7fffffff;
    }
  }
  return 68 + (h % 27);
}
