import 'package:wandermood/l10n/app_localizations.dart';

/// Maps stored mood keys (any casing) to a short label for notifications/UI.
String localisedMoodName(String moodKey, AppLocalizations l) {
  switch (moodKey.toLowerCase()) {
    case 'happy':
      return l.moodHappy;
    case 'relaxed':
      return l.moodRelaxed;
    case 'foody':
    case 'foodie':
      return l.moodFoodie;
    case 'romantic':
      return l.moodRomantic;
    case 'adventurous':
      return l.moodAdventurous;
    case 'social':
      return l.moodSocial;
    case 'cultural':
      return l.moodCultural;
    case 'curious':
      return l.moodCurious;
    case 'cozy':
      return l.moodCozy;
    case 'excited':
      return l.moodExcited;
    case 'energetic':
      return l.moodEnergetic;
    case 'surprise':
      return l.moodSurprise;
    default:
      return moodKey;
  }
}
