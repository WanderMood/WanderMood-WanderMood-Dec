import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';

/// Prefer `data['sender_id']` (FCM / plan pings), else DB `sender_id` mapped to [RealtimeEvent.relatedUserId].
String? notificationSenderUserId(RealtimeEvent e) {
  final fromData = e.data['sender_id']?.toString().trim();
  if (fromData != null && fromData.isNotEmpty) return fromData;
  final ru = e.relatedUserId?.trim();
  if (ru != null && ru.isNotEmpty) return ru;
  return null;
}

/// First letter for avatar fallback: payload usernames first, then nothing.
String notificationSenderInitialFromPayload(RealtimeEvent e) {
  for (final key in [
    'proposed_by_username',
    'sender_username',
    'name',
  ]) {
    final v = e.data[key]?.toString().trim();
    if (v != null && v.isNotEmpty) {
      final ch = v.split(RegExp(r'\s+')).first;
      if (ch.isNotEmpty) return ch[0].toUpperCase();
    }
  }
  return '?';
}
