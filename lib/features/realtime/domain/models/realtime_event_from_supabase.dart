import 'realtime_event.dart';

RealtimeEventType realtimeEventTypeFromDb(String? raw) {
  if (raw == null || raw.isEmpty) return RealtimeEventType.systemUpdate;
  for (final v in RealtimeEventType.values) {
    if (v.name == raw) return v;
  }
  return RealtimeEventType.systemUpdate;
}

/// Parses a PostgREST row into [RealtimeEvent].
///
/// Production schema for `public.realtime_events` is
/// `(id, sender_id, recipient_id, event_type, payload jsonb, read_at, created_at)`
/// where `payload = { title, message, data, priority, related_post_id }`.
/// Older code paths used a flat schema with `(user_id, type, title, message,
/// data, is_read, ...)` at the top level; we accept both shapes so this parser
/// works against either env without forcing a destructive migration.
RealtimeEvent realtimeEventFromSupabaseRow(Map<String, dynamic> row) {
  final payloadRaw = row['payload'];
  final payload = payloadRaw is Map
      ? Map<String, dynamic>.from(payloadRaw)
      : <String, dynamic>{};

  final dataRaw = payload['data'] ?? row['data'];
  final data = dataRaw is Map
      ? Map<String, dynamic>.from(dataRaw)
      : <String, dynamic>{};

  final tsRaw = row['created_at'] ?? row['timestamp'];
  final ts = tsRaw != null
      ? DateTime.tryParse(tsRaw.toString())?.toLocal() ?? DateTime.now()
      : DateTime.now();

  final readAtRaw = row['read_at'];
  final isRead = readAtRaw != null ||
      row['is_read'] == true ||
      row['isRead'] == true;

  final typeRaw = (row['event_type'] ?? row['type'])?.toString();

  return RealtimeEvent(
    id: row['id'].toString(),
    userId: (row['recipient_id'] ??
            row['user_id'] ??
            row['userId'] ??
            '')
        .toString(),
    type: realtimeEventTypeFromDb(typeRaw),
    title: (payload['title'] ?? row['title'] ?? '').toString(),
    message: (payload['message'] ?? row['message'] ?? '').toString(),
    data: data,
    timestamp: ts,
    isRead: isRead,
    imageUrl: payload['image_url']?.toString() ??
        row['image_url']?.toString() ??
        row['imageUrl']?.toString(),
    actionUrl: payload['action_url']?.toString() ??
        row['action_url']?.toString() ??
        row['actionUrl']?.toString(),
    relatedUserId: (payload['related_user_id'] ??
            row['sender_id'] ??
            row['related_user_id'] ??
            row['relatedUserId'])
        ?.toString(),
    relatedPostId: (payload['related_post_id'] ??
            row['related_post_id'] ??
            row['relatedPostId'])
        ?.toString(),
    priority: (payload['priority'] is num
            ? payload['priority'] as num
            : row['priority'] is num
                ? row['priority'] as num
                : null)
        ?.toInt(),
  );
}
