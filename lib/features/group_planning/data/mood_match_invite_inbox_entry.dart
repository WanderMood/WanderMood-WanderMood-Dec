/// Pending Mood Match invite delivered through `realtime_events`.
class MoodMatchInviteInboxEntry {
  const MoodMatchInviteInboxEntry({
    required this.eventId,
    required this.senderId,
    required this.sessionId,
    required this.joinCode,
    required this.joinLink,
    required this.createdAt,
    this.sessionTitle,
    this.senderUsername,
    this.senderFullName,
    this.senderImageUrl,
  });

  final String eventId;
  final String senderId;
  final String sessionId;
  final String joinCode;
  final String joinLink;
  final DateTime createdAt;
  /// Host-chosen name for the match (from `group_sessions.title`), if any.
  final String? sessionTitle;
  final String? senderUsername;
  final String? senderFullName;
  final String? senderImageUrl;

  String get senderDisplayLabel {
    final u = senderUsername?.trim();
    if (u != null && u.isNotEmpty) return '@$u';
    final f = senderFullName?.trim();
    if (f != null && f.isNotEmpty) return f;
    return 'WanderMood';
  }

  String get senderFirstName {
    final f = senderFullName?.trim();
    if (f != null && f.isNotEmpty) {
      final first = f.split(RegExp(r'\s+')).firstOrNull;
      if (first != null && first.isNotEmpty) return first;
    }
    final u = senderUsername?.trim();
    if (u != null && u.isNotEmpty) return u;
    return 'WanderMood';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
