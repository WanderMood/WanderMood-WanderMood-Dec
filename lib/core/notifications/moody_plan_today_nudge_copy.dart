import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

/// Rotating Moody-style copy for empty-day in-app nudges (`moody_nudge_plan_today`).
class MoodyPlanTodayNudgeCopy {
  MoodyPlanTodayNudgeCopy._();

  static const _prefsKey = 'wm_moody_plan_today_nudge_idx_v1';
  static final _rng = Random();

  static const _nlTemplates = [
    'Wat staat er vandaag op het programma? 👀',
    'Je dag is nog leeg. Ik heb ideeën.',
    'Vandaag niets gepland? Dat kunnen we oplossen.',
    'Psst. Ik weet een goede plek voor vanavond.',
    'Je hebt me nog niet verteld wat je doet vandaag.',
    'Het is al [TIME]. Nog niets gepland?',
    'Vrijdag. Perfecte dag voor iets leuks.',
    'Zaterdag zonder plan is een gemiste kans. 🗓️',
    'Ik wacht al de hele dag op je. Bijna.',
    'Zeg het maar — ik regel de rest.',
    'Vandaag gewoon iets? Of toch avontuur?',
    'Je koffie is koud. Je dag is leeg. Fix één van de twee.',
    'Ik heb drie ideeën. Jij kiest.',
    'Geen plannen? Perfect. Laat mij even.',
    'Het weer is [WEATHER]. Ik weet wat daar bij past.',
  ];

  static const _enTemplates = [
    "What's the plan today? 👀",
    'Your day is wide open. I have thoughts.',
    'Nothing planned yet? We can fix that.',
    'Psst. I know a good spot for tonight.',
    "You haven't told me what you're doing today.",
    "It's already [TIME]. Still nothing planned?",
    'Friday. Perfect day for something fun.',
    'A Saturday with no plan is a wasted Saturday. 🗓️',
    "I've been waiting. Almost.",
    "Just say the word — I'll handle the rest.",
    'Something chill today? Or actual adventure?',
    "Your coffee's cold. Your day is empty. Fix one.",
    'I have three ideas. You pick.',
    'No plans? Perfect. Let me.',
    "It's [WEATHER] out. I know exactly what fits.",
  ];

  /// Picks the next message; never repeats the same pool index twice in a row.
  static Future<String> pick({
    required bool nl,
    String? weatherDescription,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = nl ? _nlTemplates : _enTemplates;
    final weather = weatherDescription?.trim();
    final hasWeather = weather != null && weather.isNotEmpty;

    final eligible = <int>[];
    for (var i = 0; i < templates.length; i++) {
      final t = templates[i];
      if (t.contains('[WEATHER]') && !hasWeather) continue;
      eligible.add(i);
    }

    if (eligible.isEmpty) {
      return nl
          ? 'Je dag is nog leeg. Ik heb ideeën.'
          : 'Your day is wide open. I have thoughts.';
    }

    final lastIdx = prefs.getInt(_prefsKey);
    final candidates = eligible.where((i) => i != lastIdx).toList();
    final pickFrom = candidates.isNotEmpty ? candidates : eligible;
    final chosen = pickFrom[_rng.nextInt(pickFrom.length)];

    await prefs.setInt(_prefsKey, chosen);
    return _resolve(templates[chosen], nl: nl, weather: weather);
  }

  static String _resolve(
    String template, {
    required bool nl,
    String? weather,
  }) {
    var out = template;
    if (out.contains('[TIME]')) {
      final now = MoodyClock.now();
      final h = now.hour.toString().padLeft(2, '0');
      final m = now.minute.toString().padLeft(2, '0');
      final timeStr = nl ? '$h:$m' : _enTimeLabel(now);
      out = out.replaceAll('[TIME]', timeStr);
    }
    if (out.contains('[WEATHER]') && weather != null && weather.isNotEmpty) {
      out = out.replaceAll('[WEATHER]', weather);
    }
    return out;
  }

  static String _enTimeLabel(DateTime t) {
    final h = t.hour;
    final m = t.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    if (m == 0) return '$hour12:00 $period';
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }
}
