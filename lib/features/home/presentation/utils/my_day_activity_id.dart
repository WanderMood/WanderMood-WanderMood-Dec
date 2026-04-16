/// Same key used for status updates, ratings, and [activityRatingForActivityProvider].
String myDayStableActivityId(Map<String, dynamic> raw) {
  final id = raw['id']?.toString();
  if (id != null && id.trim().isNotEmpty) return id.trim();
  final title = raw['title']?.toString();
  if (title != null && title.trim().isNotEmpty) return title.trim();
  return '';
}
