import 'package:wandermood/l10n/app_localizations.dart';

/// Localized title for [currentActivityStatusProvider] maps (`type` field).
String myDayStatusTitleForType(AppLocalizations l10n, String? type) {
  switch (type) {
    case 'active':
      return l10n.myDayStatusTitleRightNow;
    case 'upcoming':
      return l10n.myDayStatusTitleUpNext;
    case 'completed':
      return l10n.myDayStatusTitleAllDone;
    case 'free_time':
      return l10n.myDayStatusTitleFreeTime;
    default:
      return '';
  }
}

/// Localized description line for status cards (not the activity name subtitle).
String myDayStatusDescriptionForMap(AppLocalizations l10n, Map<String, dynamic> status) {
  final type = status['type'] as String?;
  switch (type) {
    case 'active':
      return l10n.myDayStatusDescActive;
    case 'upcoming':
      final period = status['timePeriod'] as String? ?? 'evening';
      switch (period) {
        case 'morning':
          return l10n.myDayStatusDescUpcomingMorning;
        case 'afternoon':
          return l10n.myDayStatusDescUpcomingAfternoon;
        default:
          return l10n.myDayStatusDescUpcomingEvening;
      }
    case 'completed':
      return l10n.myDayStatusDescCompleted;
    case 'free_time':
      final period = status['period'] as String? ?? 'evening';
      switch (period) {
        case 'morning':
          return l10n.myDayFreeTimeSuggestionMorning;
        case 'afternoon':
          return l10n.myDayFreeTimeSuggestionAfternoon;
        default:
          return l10n.myDayFreeTimeSuggestionEvening;
      }
    default:
      return '';
  }
}

/// Short period label (Morning / Afternoon / Evening) for free-time subtitle row.
String myDayPeriodShortLabel(AppLocalizations l10n, String? period) {
  switch (period ?? 'evening') {
    case 'morning':
      return l10n.myDayPeriodMorning;
    case 'afternoon':
      return l10n.myDayPeriodAfternoon;
    default:
      return l10n.myDayPeriodEvening;
  }
}

/// Labels for [currentActivityStatusProvider] action keys (`explore_nearby`, `ask_moody`).
String myDayActionButtonLabel(AppLocalizations l10n, String actionKey) {
  switch (actionKey) {
    case 'explore_nearby':
      return l10n.myDayExploreNearbyButton;
    case 'ask_moody':
      return l10n.myDayAskMoodyButton;
    default:
      return actionKey;
  }
}
