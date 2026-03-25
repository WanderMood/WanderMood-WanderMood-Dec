import 'package:wandermood/l10n/app_localizations.dart';

/// Maps stored [user_preferences] English values to localized chip labels on Profile.
String localizedPreferenceChip(AppLocalizations l10n, String stored) {
  switch (stored) {
    case 'Friendly':
      return l10n.prefCommFriendly;
    case 'Playful':
      return l10n.prefCommPlayful;
    case 'Calm':
      return l10n.prefCommCalm;
    case 'Practical':
      return l10n.prefCommPractical;
    case 'Food':
      return l10n.prefIntFood;
    case 'Culture':
      return l10n.prefIntCulture;
    case 'Nature':
      return l10n.prefIntNature;
    case 'Nightlife':
      return l10n.prefIntNightlife;
    case 'Shopping':
      return l10n.prefIntShopping;
    case 'Wellness':
      return l10n.prefIntWellness;
    case 'Solo':
      return l10n.prefSocSolo;
    case 'Small-group':
      return l10n.prefSocSmallGroup;
    case 'Mix':
      return l10n.prefSocMix;
    case 'Social':
      return l10n.prefSocSocial;
    case 'Relaxed':
      return l10n.prefTravelRelaxed;
    case 'Adventurous':
      return l10n.prefTravelAdventurous;
    case 'Cultural':
      return l10n.prefTravelCultural;
    case 'City-break':
      return l10n.prefTravelCityBreak;
    case 'Happy':
      return l10n.prefSelHappy;
    case 'Romantic':
      return l10n.prefSelRomantic;
    case 'Energetic':
      return l10n.prefSelEnergetic;
    case 'Creative':
      return l10n.prefSelCreative;
    case 'Same Day Planner':
      return l10n.prefPlanSameDay;
    case 'Week Ahead Planner':
      return l10n.prefPlanWeekAhead;
    case 'Spontaneous':
      return l10n.prefPlanSpontaneous;
    default:
      return stored;
  }
}
