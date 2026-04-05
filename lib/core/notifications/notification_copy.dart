/// A single push notification's display text.
class NotificationCopy {
  final String title;
  final String body;

  /// Passed to the OS; used on tap to navigate (see [NotificationNavigation]).
  final String? payload;

  const NotificationCopy({
    required this.title,
    required this.body,
    this.payload,
  });

  NotificationCopy withPayload(String? payload) {
    return NotificationCopy(title: title, body: body, payload: payload);
  }

  /// Replace `{key}` placeholders in both title and body.
  ///
  /// Example:
  /// ```dart
  /// copy.substitute({'days': '7', 'mood': 'adventurous'})
  /// ```
  NotificationCopy substitute(Map<String, String> params) {
    var t = title;
    var b = body;
    for (final entry in params.entries) {
      t = t.replaceAll('{${entry.key}}', entry.value);
      b = b.replaceAll('{${entry.key}}', entry.value);
    }
    return NotificationCopy(title: t, body: b, payload: payload);
  }
}
