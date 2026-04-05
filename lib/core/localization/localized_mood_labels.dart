import 'package:wandermood/l10n/app_localizations.dart';

/// Maps stored mood keys / labels (English or Title Case) to [AppLocalizations].
String localizedMoodDisplayLabel(AppLocalizations l10n, String raw) {
  final m = raw.toLowerCase().trim();
  switch (m) {
    case 'happy':
    case 'blij':
      return l10n.moodHubMoodHappy;
    case 'adventurous':
    case 'avontuurlijk':
      return l10n.moodHubMoodAdventurous;
    case 'relaxed':
    case 'ontspannen':
      return l10n.moodHubMoodRelaxed;
    case 'energetic':
    case 'energiek':
      return l10n.moodHubMoodEnergetic;
    case 'romantic':
    case 'romantisch':
      return l10n.moodHubMoodRomantic;
    case 'social':
    case 'sociaal':
      return l10n.moodHubMoodSocial;
    case 'cultural':
    case 'cultureel':
      return l10n.moodHubMoodCultural;
    case 'curious':
    case 'nieuwsgierig':
      return l10n.moodHubMoodCurious;
    case 'cozy':
    case 'gezellig':
      return l10n.moodHubMoodCozy;
    case 'excited':
    case 'enthousiast':
    case 'opgewonden':
      return l10n.moodHubMoodExcited;
    case 'foody':
    case 'foodie':
      return l10n.moodHubMoodFoody;
    case 'surprise':
    case 'verrassing':
      return l10n.moodHubMoodSurprise;
    default:
      if (raw.isEmpty) return raw;
      return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }
}
