import 'package:wandermood/l10n/app_localizations.dart';

/// Calendar day equality in local date components.
bool myDayIsSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Morning / afternoon / evening from scheduled hour (12–18 = afternoon, NL convention).
String myDayPeriodFromStartHour(AppLocalizations l10n, int hour) {
  if (hour >= 6 && hour < 12) return l10n.myDayPeriodMorning;
  if (hour >= 12 && hour < 18) return l10n.myDayPeriodAfternoon;
  return l10n.myDayPeriodEvening;
}

/// Chip / hero label: when it is already later in the day, avoid reading like “current afternoon”.
String myDayActivitySlotPeriodLabel(
  AppLocalizations l10n,
  DateTime activityStart,
  DateTime now,
) {
  if (!myDayIsSameCalendarDay(activityStart, now)) {
    return myDayPeriodFromStartHour(l10n, activityStart.hour);
  }
  final h = activityStart.hour;
  final nowH = now.hour;

  if (h >= 6 && h < 12) {
    if (nowH >= 12) return l10n.myDaySlotPlannedForMorning;
    return l10n.myDayPeriodMorning;
  }
  if (h >= 12 && h < 18) {
    if (nowH >= 18) return l10n.myDaySlotPlannedForAfternoon;
    return l10n.myDayPeriodAfternoon;
  }
  return l10n.myDayPeriodEvening;
}

/// Section header (with emoji): only adjusts when [viewDay] is “today” vs [now].
String myDayTimelineSectionTitle(
  AppLocalizations l10n, {
  required String period,
  required DateTime viewDay,
  required DateTime now,
}) {
  final view = DateTime(viewDay.year, viewDay.month, viewDay.day);
  final clock = DateTime(now.year, now.month, now.day);
  final isViewingToday = view == clock;

  switch (period) {
    case 'morning':
      if (isViewingToday && now.hour >= 12) {
        return l10n.myDayTimelineSectionMorningPastTitle;
      }
      return l10n.myDayTimelineSectionMorningTitle;
    case 'afternoon':
      if (isViewingToday && now.hour >= 18) {
        return l10n.myDayTimelineSectionAfternoonPastTitle;
      }
      return l10n.myDayTimelineSectionAfternoonTitle;
    case 'evening':
    default:
      return l10n.myDayTimelineSectionEveningTitle;
  }
}
