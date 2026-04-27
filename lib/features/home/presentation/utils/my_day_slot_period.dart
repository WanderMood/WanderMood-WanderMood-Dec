import 'package:wandermood/l10n/app_localizations.dart';

/// Calendar day equality in local date components.
bool myDayIsSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whether the quick-add slot (0 = morning, 1 = afternoon, 2 = evening) should
/// appear when planning **[selectedDay]** at local time **[now]**.
///
/// For **today** only, matches [myDayTimelineSectionTitle] cutoffs: morning is
/// hidden from noon onward, afternoon from 18:00 onward. **Evening** stays
/// available all day so users can still add something “tonight” late.
bool myDayQuickAddSlotOfferedForDay({
  required int slotIndex,
  required DateTime selectedDay,
  required DateTime now,
}) {
  assert(slotIndex >= 0 && slotIndex < 3);
  if (!myDayIsSameCalendarDay(selectedDay, now)) return true;
  final h = now.hour;
  return switch (slotIndex) {
    0 => h < 12,
    1 => h < 18,
    _ => true,
  };
}

/// First offered slot index for that day, or `null` if none (should not happen
/// for calendar days that are not “today”, or today while evening is offered).
int? myDayQuickAddFirstOfferedSlotIndex({
  required DateTime selectedDay,
  required DateTime now,
}) {
  for (var i = 0; i < 3; i++) {
    if (myDayQuickAddSlotOfferedForDay(
        slotIndex: i, selectedDay: selectedDay, now: now)) {
      return i;
    }
  }
  return null;
}

/// Morning / afternoon / evening from scheduled hour (12–18 = afternoon, NL convention).
String myDayPeriodFromStartHour(AppLocalizations l10n, int hour) {
  if (hour >= 6 && hour < 12) return l10n.myDayPeriodMorning;
  if (hour >= 12 && hour < 18) return l10n.myDayPeriodAfternoon;
  return l10n.myDayPeriodEvening;
}

/// True when [activityStart] is the same calendar day as [now] and the nominal
/// morning/afternoon window for that start time has already ended. Used so the
/// hero “up next” line does not read as “soon” (e.g. Dutch Straks) for a slot that
/// is already in the past.
bool myDayActivityStartSlotPeriodHasElapsedForToday({
  required DateTime activityStart,
  required DateTime now,
}) {
  if (!myDayIsSameCalendarDay(activityStart, now)) return false;
  final h = activityStart.hour;
  final nowH = now.hour;
  if (h >= 6 && h < 12) return nowH >= 12;
  if (h >= 12 && h < 18) return nowH >= 18;
  return false;
}

/// Chip / hero label: **focus** copy (“This morning”) while that part of the day
/// is still current; **neutral** (“Morning”) after that window has passed (same day).
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
    if (nowH >= 12) return l10n.myDayPeriodMorning;
    return l10n.myDaySlotPlannedForMorning;
  }
  if (h >= 12 && h < 18) {
    if (nowH >= 18) return l10n.myDayPeriodAfternoon;
    return l10n.myDaySlotPlannedForAfternoon;
  }
  // Evening (18–24): “this evening” same day; late-night hours (0–5) stay neutral.
  if (h < 6) {
    return l10n.myDayPeriodEvening;
  }
  return l10n.myDaySlotThisEvening;
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
      if (isViewingToday && now.hour < 12) {
        return l10n.myDayTimelineSectionMorningFocusTitle;
      }
      return l10n.myDayTimelineSectionMorningTitle;
    case 'afternoon':
      if (isViewingToday && now.hour >= 18) {
        return l10n.myDayTimelineSectionAfternoonPastTitle;
      }
      if (isViewingToday && now.hour < 18) {
        return l10n.myDayTimelineSectionAfternoonFocusTitle;
      }
      return l10n.myDayTimelineSectionAfternoonTitle;
    case 'evening':
    default:
      // “This evening” all day when the list is for **today** (incl. afternoon
      // before 18:00) so the avond block doesn’t read as a generic “Evening”.
      if (isViewingToday) {
        return l10n.myDayTimelineSectionEveningFocusTitle;
      }
      return l10n.myDayTimelineSectionEveningTitle;
  }
}

/// Section subline: when viewing **today** and a period is already over, use a
/// neutral “earlier today” line instead of peppy future-facing copy.
String myDayTimelineSectionSubtitle(
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
        return l10n.myDayTimelineSectionEarlierTodaySubtitle;
      }
      return l10n.myDayTimelineSectionMorningSubtitle;
    case 'afternoon':
      if (isViewingToday && now.hour >= 18) {
        return l10n.myDayTimelineSectionEarlierTodaySubtitle;
      }
      return l10n.myDayTimelineSectionAfternoonSubtitle;
    case 'evening':
    default:
      return l10n.myDayTimelineSectionEveningSubtitle;
  }
}
