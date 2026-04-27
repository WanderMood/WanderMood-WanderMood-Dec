import 'package:wandermood/core/utils/moody_clock.dart';

/// Fixed public moments for NL-focused in-app copy (not a full holiday API).
class NlEngagementPublicDay {
  const NlEngagementPublicDay({required this.id});

  /// Stable key for [InAppNotificationCopy.engagementHolidayBody].
  final String id;
}

/// Koningsdag: 27 April; if that is Sunday → Saturday 26 April.
DateTime _koningsdag(DateTime yearAnchor) {
  var d = DateTime(yearAnchor.year, 4, 27);
  if (d.weekday == DateTime.sunday) {
    d = d.subtract(const Duration(days: 1));
  }
  return DateTime(d.year, d.month, d.day);
}

/// Returns a public “Moody could greet” day when [local] matches (date only).
NlEngagementPublicDay? nlEngagementPublicDayOn(DateTime local) {
  final t = DateTime(local.year, local.month, local.day);
  final kd = _koningsdag(t);
  if (t.year == kd.year && t.month == kd.month && t.day == kd.day) {
    return const NlEngagementPublicDay(id: 'kings_day_nl');
  }
  if (t.month == 1 && t.day == 1) {
    return const NlEngagementPublicDay(id: 'new_year_nl');
  }
  if (t.month == 5 && t.day == 5) {
    return const NlEngagementPublicDay(id: 'liberation_day_nl');
  }
  return null;
}

/// Whether to run NL calendar nudges (locale and/or home base).
bool shouldOfferNlEngagementDays({
  required String languageCode,
  String? homeBaseLowercase,
}) {
  if (languageCode.toLowerCase().startsWith('nl')) return true;
  final h = homeBaseLowercase?.toLowerCase() ?? '';
  if (h.contains('nederland') ||
      h.contains('netherlands') ||
      h.contains('holland') ||
      h.contains('rotterdam') ||
      h.contains('amsterdam') ||
      h.contains('utrecht') ||
      h.contains('den haag') ||
      h.contains('eindhoven')) {
    return true;
  }
  return false;
}

/// “Afternoon” for no–mood-check nudge (local).
bool engagementPastNoMoodCutoffHour() => MoodyClock.now().hour >= 14;

/// “Late morning” for empty-plan nudge (local).
bool engagementPastEmptyPlanCutoffHour() => MoodyClock.now().hour >= 11;
