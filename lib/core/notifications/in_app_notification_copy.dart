import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';

/// In-app + push copy (EN/NL). Placeholders: [name] [place] [day] [slot] …
class InAppNotificationCopy {
  InAppNotificationCopy._();

  static String sub(String tpl, Map<String, String> v) {
    var s = tpl;
    v.forEach((k, val) => s = s.replaceAll('[$k]', val));
    return s;
  }

  static String planTitle(bool nl) => nl ? 'Mood Match' : 'Mood Match';

  static String planMessage({
    required bool nl,
    required String event,
    required Map<String, dynamic> data,
  }) {
    final name = (data['sender_username'] ?? data['proposed_by_username'] ?? '')
        .toString()
        .trim();
    final place = (data['place'] ??
            data['proposed_place_name'] ??
            data['proposedPlaceName'] ??
            '')
        .toString()
        .trim();
    final day = (data['day'] ?? data['proposed_date'] ?? '').toString().trim();
    final slot = (data['slot'] ?? '').toString().trim();
    final n = (data['n'] ?? '').toString().trim();
    final minutes = (data['minutes'] ?? '').toString().trim();
    final time = (data['time'] ?? '').toString().trim();
    final firstActivity =
        (data['firstActivity'] ?? '').toString().trim();
    final city = (data['city'] ?? '').toString().trim();

    switch (event) {
      case 'mood_match_invite':
        return sub(
          nl
              ? '[name] wil een dag plannen met je 👀 Doe je mee?'
              : '[name] wants to plan a day with you 👀 You in?',
          {'name': name},
        );
      case 'guest_joined':
        return sub(
          nl
              ? '[name] is erbij. Jullie kiezen allebei een vibe — jij eerst.'
              : '[name] joined. You both pick a mood — go first.',
          {'name': name},
        );
      case 'mood_locked':
        return sub(
          nl
              ? '[name] heeft gekozen. Jouw beurt — wat is jouw vibe?'
              : '[name] locked in their mood. Your turn — what\'s yours?',
          {'name': name},
        );
      case 'plan_ready':
        return sub(
          nl
              ? 'Jullie dag staat klaar. [name] heeft 3 plekken gekozen — kijk maar.'
              : 'Your day is ready. [name] picked 3 spots — take a look.',
          {'name': name},
        );
      case 'day_proposed':
        return sub(
          nl
              ? '[name] stelt [day] voor. Komt dat uit?'
              : '[name] suggested [day] for your day out. Works for you?',
          {'name': name, 'day': day},
        );
      case 'day_accepted':
        return sub(
          nl
              ? '[name] bevestigde [day]. Kies nu jouw starttijd.'
              : '[name] confirmed [day]. Now pick your start time.',
          {'name': name, 'day': day},
        );
      case 'day_counter_proposed':
        final pd = (data['previous_day'] ?? data['previous_date'] ?? '').toString().trim();
        final nd = (data['new_day'] ?? data['proposed_date'] ?? day).toString().trim();
        return sub(
          nl ? '[name] kan niet op [previous_day]. Ze stellen [new_day] voor — komt dat uit?' : '[name] can\'t do [previous_day]. They suggested [new_day] instead — works for you?',
          {'name': name, 'previous_day': pd, 'new_day': nd},
        );
      case 'swap_counter_proposed':
        return sub(
          nl ? '[name] heeft een ander idee voor de [slot]. Kijk maar — jij beslist.' : '[name] suggested a different activity for the [slot]. Take a look — your call.',
          {'name': name, 'slot': slot},
        );
      case 'swap_requested':
        return sub(
          nl
              ? '[name] wil de [slot] omwisselen. Ze hebben een idee — jij beslist.'
              : '[name] wants to swap the [slot]. They have an idea — your call.',
          {'name': name, 'slot': slot},
        );
      case 'swap_accepted':
        return sub(nl ? '[name] accepteerde jouw wissel. [slot] is geregeld ✓' : '[name] said yes to your swap. [slot] is sorted ✓', {'name': name, 'slot': slot});
      case 'swap_declined':
        return sub(nl ? '[name] hield de originele keuze voor de [slot]. Prima.' : '[name] kept the original for the [slot]. Fair enough.', {'name': name, 'slot': slot});
      case 'both_confirmed':
        return nl ? 'Jullie dag is bevestigd. Kies je starttijd en je bent klaar 🗓️' : 'Your day is locked. Pick your start time and you\'re ready 🗓️';
      case 'guest_left_session':
        return sub(
          nl ? '[name] heeft de Mood Match verlaten.' : '[name] left this Mood Match.',
          {'name': name},
        );
      case 'host_ended_session':
        return sub(
          nl ? '[name] heeft deze Mood Match geannuleerd.' : '[name] ended this Mood Match.',
          {'name': name},
        );
      case 'leaving_soon':
        return sub(
          nl
              ? '[place] is [minutes] minuten rijden. Het kan slim zijn om nu te gaan.'
              : '[place] is [minutes] minutes away. Might be worth leaving now.',
          {'place': place, 'minutes': minutes},
        );
      case 'confirm_tonight':
        return sub(
          nl
              ? '[place] om [time] — ga je nog?'
              : '[place] at [time] — still on for tonight?',
          {'place': place, 'time': time},
        );
      case 'rate_activity':
        return sub(
          nl
              ? 'Hoe was [place]? Een snelle beoordeling helpt me beter plannen.'
              : 'How was [place]? Quick rating helps me plan better for you.',
          {'place': place},
        );
      default:
        return nl ? 'Er is een update voor je Mood Match.' : 'There\'s a Mood Match update.';
    }
  }

  static String socialMessage({
    required bool nl,
    required RealtimeEventType type,
    required Map<String, dynamic> data,
  }) {
    final name = (data['sender_username'] ?? '').toString().trim();
    switch (type) {
      case RealtimeEventType.postReaction:
      case RealtimeEventType.postLike:
        return sub(
          nl ? '[name] reageerde op je post.' : '[name] reacted to your post.',
          {'name': name},
        );
      case RealtimeEventType.postComment:
        return sub(
          nl ? '[name] reageerde op je bericht.' : '[name] commented on your post.',
          {'name': name},
        );
      case RealtimeEventType.newFollower:
        return sub(
          nl ? '[name] volgt je nu.' : '[name] started following you.',
          {'name': name},
        );
      default:
        return nl ? 'Je hebt een melding.' : 'You have an update.';
    }
  }

  static String moodyMessage({
    required bool nl,
    required String event,
    required Map<String, dynamic> data,
  }) {
    if (event == 'moody_chat_reminder') {
      final when = (data['when_label'] ?? '').toString().trim();
      if (when.isEmpty) {
        return nl
            ? 'Moody heeft een herinnering voor je klaargezet.'
            : 'Moody set a reminder for you.';
      }
      return nl
          ? 'Herinnering gepland voor $when.'
          : 'Reminder set for $when.';
    }
    if (event == 'morning_summary') {
      return sub(
        nl
            ? 'Goedemorgen. [n] dingen gepland vandaag. Eerst [firstActivity].'
            : 'Good morning. [n] things planned today. [firstActivity] first.',
        {
          'n': (data['n'] ?? '').toString(),
          'firstActivity': (data['firstActivity'] ?? '').toString(),
        },
      );
    }
    if (event == 'weekend_nudge') {
      return sub(
        nl
            ? 'Nog niks gepland voor het weekend. [day] is nog vrij — zal ik iets zoeken?'
            : 'Nothing planned for the weekend yet. [day]\'s wide open — want me to find something?',
        {'day': (data['day'] ?? '').toString()},
      );
    }
    if (event == 'milestone') {
      return nl
          ? (data['message_nl'] ?? data['message'] ?? '').toString()
          : (data['message_en'] ?? data['message'] ?? '').toString();
    }
    return nl ? 'Moody heeft een tip voor je.' : 'Moody has a nudge for you.';
  }
}
