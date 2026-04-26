import 'dart:async';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/notifications/in_app_notification_copy.dart';
import 'package:wandermood/core/services/push_notify_edge.dart';

/// Inserts a `realtime_events` row for the signed-in user so My Day bell /
/// notification centre stay aligned with a locally scheduled Moody Hub reminder.
///
/// [push-notify] cannot target `recipient_id == auth.uid` (self-push guard),
/// so this uses [send_realtime_notification] directly — fire-and-forget.
void mirrorMoodyChatReminderToInAppNotification({
  required DateTime fireAt,
  required int localNotificationId,
}) {
  unawaited(() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final nl =
          (await wandermoodNotificationLangCode()).toLowerCase().startsWith('nl');
      final whenLabel = DateFormat.yMMMd().add_jm().format(fireAt.toLocal());
      const title = 'Moody';
      final message = InAppNotificationCopy.moodyMessage(
        nl: nl,
        event: 'moody_chat_reminder',
        data: {'when_label': whenLabel},
      );

      await client.rpc(
        'send_realtime_notification',
        params: {
          'target_user_id': user.id,
          'event_type': 'systemUpdate',
          'event_title': title,
          'event_message': message,
          'event_data': {
            'event': 'moody_chat_reminder',
            'fire_at': fireAt.toIso8601String(),
            'local_notification_id': localNotificationId,
            'when_label': whenLabel,
          },
          'source_user_id': user.id,
          'related_post_id': null,
          'priority_level': 3,
        },
      );
    } catch (_) {}
  }());
}
