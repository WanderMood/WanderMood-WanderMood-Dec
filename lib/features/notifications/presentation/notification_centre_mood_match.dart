import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';

/// Visual tier for Mood Match rows in the notification centre (not used for other filters).
enum MoodMatchNotificationTier {
  /// Low emphasis: confirmations, joins, declines without a required tap.
  status,
  /// User should open: proposals, swaps, counter-days.
  action,
  /// Milestone: plan ready, day locked in, invite, both confirmed.
  highlight,
}

/// Row context for spacing / light grouping in the Mood Match timeline.
class NotificationCentreRowContext {
  const NotificationCentreRowContext({
    this.previous,
    this.index = 0,
    this.tightenTop = false,
  });

  final RealtimeEvent? previous;
  final int index;
  /// Pull this row closer to the previous when same session + related day flow.
  final bool tightenTop;
}

String _eventKey(RealtimeEvent e) {
  return (e.data['event'] ?? e.data['kind'] ?? '').toString().trim();
}

String? _sessionId(RealtimeEvent e) {
  final v = e.data['session_id']?.toString().trim();
  return v != null && v.isNotEmpty ? v : null;
}

bool _isDayFlowEvent(String key) {
  return key == 'day_proposed' ||
      key == 'day_counter_proposed' ||
      key == 'day_accepted' ||
      key == 'day_guest_declined_original';
}

/// Tight vertical grouping when several day-negotiation updates stack for one session.
bool moodMatchTightenTopSpacing(RealtimeEvent current, RealtimeEvent? previous) {
  if (previous == null) return false;
  final sid = _sessionId(current);
  final prevSid = _sessionId(previous);
  if (sid == null || sid != prevSid) return false;
  final a = _eventKey(current);
  final b = _eventKey(previous);
  return _isDayFlowEvent(a) && _isDayFlowEvent(b);
}

MoodMatchNotificationTier moodMatchTierFor(RealtimeEvent e) {
  final key = _eventKey(e);
  final t = e.type.name;

  if (t == 'groupTravelUpdate' && key == 'mood_match_invite') {
    return MoodMatchNotificationTier.highlight;
  }

  switch (key) {
    case 'plan_ready':
    case 'both_confirmed':
    case 'day_accepted':
    case 'swap_accepted':
      return MoodMatchNotificationTier.highlight;
    case 'day_proposed':
    case 'day_counter_proposed':
    case 'swap_requested':
      return MoodMatchNotificationTier.action;
    case 'mood_match_invite':
      return MoodMatchNotificationTier.highlight;
    default:
      return MoodMatchNotificationTier.status;
  }
}
