import 'package:intl/intl.dart';
import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';

/// In-app + push copy (EN/NL). Placeholders: [name] [place] [day] [slot] …
class InAppNotificationCopy {
  InAppNotificationCopy._();

  /// Normalizes plan date fields in [data] to a short weekday date in [localeName].
  /// Handles ISO `yyyy-MM-dd` and legacy English strings like `Thu 23 Apr` stored at send time.
  static Map<String, dynamic> withLocaleFormattedIsoDates(
    Map<String, dynamic> data,
    String localeName,
  ) {
    final out = Map<String, dynamic>.from(data);
    const keys = <String>[
      'day',
      'proposed_date',
      'previous_day',
      'previous_date',
      'new_day',
    ];
    for (final key in keys) {
      final raw = out[key]?.toString().trim();
      if (raw == null || raw.isEmpty) continue;
      final dt = _parsePlanDateField(raw);
      if (dt == null) continue;
      out[key] = DateFormat('EEE d MMM', localeName).format(dt);
    }
    return out;
  }

  static DateTime? _parsePlanDateField(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t)) {
      return DateTime.tryParse(t);
    }
    const parseLocales = ['en_US', 'nl_NL', 'de_DE', 'fr_FR', 'es_ES'];
    const withYear = ['EEE d MMM y', 'EEE d MMMM y'];
    const noYear = ['EEE d MMM', 'EEE d MMMM'];
    for (final loc in parseLocales) {
      for (final p in withYear) {
        try {
          return DateFormat(p, loc).parseLoose(t);
        } catch (_) {}
      }
    }
    for (final loc in parseLocales) {
      for (final p in noYear) {
        try {
          var dt = DateFormat(p, loc).parseLoose(t);
          final now = DateTime.now();
          if (dt.year < 1980) {
            var candidate = DateTime(now.year, dt.month, dt.day);
            if (candidate.isBefore(now.subtract(const Duration(days: 400)))) {
              candidate = DateTime(now.year + 1, dt.month, dt.day);
            }
            dt = candidate;
          }
          return dt;
        } catch (_) {}
      }
    }
    return null;
  }

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

  /// Seasonal / public-day greetings (`kings_day_nl`, `new_year_nl`, …).
  static String engagementHolidayBody({required bool nl, required String holidayId}) {
    switch (holidayId) {
      case 'kings_day_nl':
        return nl
            ? 'Fijne Koningsdag! Zin om je dag samen wat kleur te geven?'
            : 'Happy King\'s Day! Want to add some color to your day together?';
      case 'new_year_nl':
        return nl
            ? 'Gelukkig nieuwjaar! Zullen we samen iets leuks plannen?'
            : 'Happy New Year! Want to plan something fun together?';
      case 'liberation_day_nl':
        return nl
            ? 'Fijne Bevrijdingsdag — rustig aan, of zin om samen iets te plannen?'
            : 'Happy Liberation Day — take it easy, or want to plan something together?';
      default:
        return nl
            ? 'Ik wens je een fijne dag.'
            : 'Wishing you a great day.';
    }
  }

  static String moodyMessage({
    required bool nl,
    required String event,
    required Map<String, dynamic> data,
  }) {
    if (event == 'moody_holiday_greeting') {
      final id = (data['holiday_id'] ?? '').toString();
      return engagementHolidayBody(nl: nl, holidayId: id);
    }
    if (event == 'moody_nudge_check_in') {
      return nl
          ? 'Je bent vandaag nog niet bij mij ingecheckt — hoe voel je je?'
          : 'You haven\'t checked in with me today — how are you feeling?';
    }
    if (event == 'moody_nudge_plan_today') {
      return nl
          ? 'Je hebt nog niks vandaag in je dag — zal ik helpen plannen?'
          : 'Nothing on your day yet — want help planning?';
    }
    if (event == 'moody_post_trip_reflection') {
      return nl
          ? 'Je dag zit erop — even samen reflecteren?'
          : 'Your day is wrapped — want a quick reflection together?';
    }
    if (event == 'moody_saved_place_interest') {
      final place =
          (data['place_name'] ?? data['place'] ?? '').toString().trim();
      if (place.isEmpty) {
        return nl
            ? 'Je hebt iets opgeslagen — wil je het aan je dag toevoegen?'
            : 'You saved a spot — want to add it to your day?';
      }
      return nl
          ? 'Ik zie dat je $place hebt opgeslagen — zin om het dit weekend (of vandaag) te plannen?'
          : 'I noticed you saved $place — want to add it to your day or this weekend?';
    }
    if (event == 'moody_chat_reminder') {
      final when = (data['when_label'] ?? '').toString().trim();
      if (when.isEmpty) {
        return nl
            ? 'Ik heb een herinnering voor je klaargezet.'
            : 'I set a reminder for you.';
      }
      return nl
          ? 'Herinnering gepland voor $when.'
          : 'Reminder set for $when.';
    }
    if (event == 'daily_mood_check_in') {
      return nl
          ? 'Hoe voel je je vandaag? Tik om in te checken.'
          : 'How are you feeling today? Tap to check in.';
    }
    if (event == 'companion_check_in') {
      return nl
          ? 'Hoe was je dag? Zin om even bij te praten?'
          : 'How was your day? Want to check in and chat?';
    }
    if (event == 'mood_follow_up') {
      return nl
          ? 'Even een snelle mood-check van mij.'
          : 'Quick mood check-in from me.';
    }
    if (event == 'generate_my_day') {
      return nl
          ? 'Zin om je dag samen te vullen?'
          : 'Want to fill in your day together?';
    }
    if (event == 'moody_place_pick' || event == 'place_suggestion') {
      final place =
          (data['place_name'] ?? data['place'] ?? '').toString().trim();
      if (place.isEmpty) {
        return nl
            ? 'Ik heb een plek uitgezocht die misschien bij je past.'
            : 'I picked a spot you might like.';
      }
      return nl
          ? 'Ik denk dat $place bij je past — even kijken?'
          : 'I think you might like $place — take a look?';
    }
    if (event == 'activity_upcoming' || event == 'activity_reminder') {
      final title = (data['activity_title'] ?? data['title'] ?? '')
          .toString()
          .trim();
      if (title.isEmpty) {
        return nl
            ? 'Je hebt straks iets gepland — even je dag bekijken?'
            : 'You have something coming up — peek at your day?';
      }
      return nl
          ? 'Straks: $title — klaar om te gaan?'
          : 'Coming up: $title — ready when you are?';
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
    return nl ? 'Ik heb een tip voor je.' : 'I have a nudge for you.';
  }
}
