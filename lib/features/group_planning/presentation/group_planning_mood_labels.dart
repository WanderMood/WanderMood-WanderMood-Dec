import 'package:wandermood/l10n/app_localizations.dart';

/// Maps stored mood tags to localized chip labels.
String groupPlanLocalizedMoodTag(AppLocalizations l10n, String tag) {
  switch (tag) {
    case 'adventurous':
      return l10n.groupPlanMoodAdventurous;
    case 'relaxed':
      return l10n.groupPlanMoodRelaxed;
    case 'social':
      return l10n.groupPlanMoodSocial;
    case 'cultural':
      return l10n.groupPlanMoodCultural;
    case 'romantic':
      return l10n.groupPlanMoodRomantic;
    case 'energetic':
      return l10n.groupPlanMoodEnergetic;
    case 'foody':
      return l10n.groupPlanMoodFoody;
    case 'creative':
      return l10n.groupPlanMoodCreative;
    case 'cozy':
      return l10n.groupPlanMoodCozy;
    case 'surprise':
      return l10n.groupPlanMoodSurprise;
    default:
      return tag;
  }
}
