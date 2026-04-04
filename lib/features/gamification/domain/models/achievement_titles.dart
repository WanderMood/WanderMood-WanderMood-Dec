import 'package:wandermood/l10n/app_localizations.dart';

/// Localized display title for a preset achievement [id].
String achievementTitleForId(String id, AppLocalizations l10n) {
  switch (id) {
    case 'explorer':
      return l10n.achievementExplorer;
    case 'early_bird':
      return l10n.achievementEarlyBird;
    case 'streak_master':
      return l10n.achievementStreakMaster;
    case 'mood_tracker':
      return l10n.achievementMoodTracker;
    case 'adventurer':
      return l10n.achievementAdventurer;
    default:
      return id;
  }
}
