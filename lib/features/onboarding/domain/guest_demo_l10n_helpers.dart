import 'package:flutter/widgets.dart';
import 'package:wandermood/l10n/app_localizations.dart';

String _guestDemoDataMoodKey(String mood) {
  final m = mood.toLowerCase();
  return m == 'surprise_me' ? 'romantic' : m;
}

/// Shared ARB-backed strings for guest demo places (Explore grid + Day Plan).
String guestDemoMoodDisplayLabel(BuildContext context, String moodKey) {
  final l10n = AppLocalizations.of(context)!;
  switch (moodKey.toLowerCase()) {
    case 'adventurous':
      return l10n.demoMoodAdventurous;
    case 'relaxed':
      return l10n.demoMoodRelaxed;
    case 'surprise_me':
      return l10n.demoMoodSurpriseMe;
    case 'romantic':
      return l10n.demoMoodRomantic;
    case 'cultural':
      return l10n.demoMoodCultural;
    case 'foodie':
      return l10n.demoMoodFoodie;
    case 'social':
      return l10n.demoMoodSocial;
    default:
      return moodKey;
  }
}

String guestDemoPlaceName(AppLocalizations l10n, String mood, int slot) {
  switch (_guestDemoDataMoodKey(mood)) {
    case 'relaxed':
      switch (slot) {
        case 0:
          return l10n.guestDemoRelaxed1Name;
        case 1:
          return l10n.guestDemoRelaxed2Name;
        case 2:
          return l10n.guestDemoRelaxed3Name;
      }
      break;
    case 'foodie':
      switch (slot) {
        case 0:
          return l10n.guestDemoFoodie1Name;
        case 1:
          return l10n.guestDemoFoodie2Name;
        case 2:
          return l10n.guestDemoFoodie3Name;
      }
      break;
    case 'social':
      switch (slot) {
        case 0:
          return l10n.guestDemoSocial1Name;
        case 1:
          return l10n.guestDemoSocial2Name;
        case 2:
          return l10n.guestDemoSocial3Name;
      }
      break;
    case 'adventurous':
      switch (slot) {
        case 0:
          return l10n.guestDemoAdventurous1Name;
        case 1:
          return l10n.guestDemoAdventurous2Name;
        case 2:
          return l10n.guestDemoAdventurous3Name;
      }
      break;
    case 'cultural':
      switch (slot) {
        case 0:
          return l10n.guestDemoCultural1Name;
        case 1:
          return l10n.guestDemoCultural2Name;
        case 2:
          return l10n.guestDemoCultural3Name;
      }
      break;
    case 'romantic':
      switch (slot) {
        case 0:
          return l10n.guestDemoRomantic1Name;
        case 1:
          return l10n.guestDemoRomantic2Name;
        case 2:
          return l10n.guestDemoRomantic3Name;
      }
      break;
  }
  return '';
}

String guestDemoPlaceMeta(AppLocalizations l10n, String mood, int slot) {
  switch (_guestDemoDataMoodKey(mood)) {
    case 'relaxed':
      switch (slot) {
        case 0:
          return l10n.guestDemoRelaxed1Meta;
        case 1:
          return l10n.guestDemoRelaxed2Meta;
        case 2:
          return l10n.guestDemoRelaxed3Meta;
      }
      break;
    case 'foodie':
      switch (slot) {
        case 0:
          return l10n.guestDemoFoodie1Meta;
        case 1:
          return l10n.guestDemoFoodie2Meta;
        case 2:
          return l10n.guestDemoFoodie3Meta;
      }
      break;
    case 'social':
      switch (slot) {
        case 0:
          return l10n.guestDemoSocial1Meta;
        case 1:
          return l10n.guestDemoSocial2Meta;
        case 2:
          return l10n.guestDemoSocial3Meta;
      }
      break;
    case 'adventurous':
      switch (slot) {
        case 0:
          return l10n.guestDemoAdventurous1Meta;
        case 1:
          return l10n.guestDemoAdventurous2Meta;
        case 2:
          return l10n.guestDemoAdventurous3Meta;
      }
      break;
    case 'cultural':
      switch (slot) {
        case 0:
          return l10n.guestDemoCultural1Meta;
        case 1:
          return l10n.guestDemoCultural2Meta;
        case 2:
          return l10n.guestDemoCultural3Meta;
      }
      break;
    case 'romantic':
      switch (slot) {
        case 0:
          return l10n.guestDemoRomantic1Meta;
        case 1:
          return l10n.guestDemoRomantic2Meta;
        case 2:
          return l10n.guestDemoRomantic3Meta;
      }
      break;
  }
  return '';
}

String guestDemoPlaceDesc(AppLocalizations l10n, String mood, int slot) {
  switch (_guestDemoDataMoodKey(mood)) {
    case 'relaxed':
      switch (slot) {
        case 0:
          return l10n.guestDemoRelaxed1Desc;
        case 1:
          return l10n.guestDemoRelaxed2Desc;
        case 2:
          return l10n.guestDemoRelaxed3Desc;
      }
      break;
    case 'foodie':
      switch (slot) {
        case 0:
          return l10n.guestDemoFoodie1Desc;
        case 1:
          return l10n.guestDemoFoodie2Desc;
        case 2:
          return l10n.guestDemoFoodie3Desc;
      }
      break;
    case 'social':
      switch (slot) {
        case 0:
          return l10n.guestDemoSocial1Desc;
        case 1:
          return l10n.guestDemoSocial2Desc;
        case 2:
          return l10n.guestDemoSocial3Desc;
      }
      break;
    case 'adventurous':
      switch (slot) {
        case 0:
          return l10n.guestDemoAdventurous1Desc;
        case 1:
          return l10n.guestDemoAdventurous2Desc;
        case 2:
          return l10n.guestDemoAdventurous3Desc;
      }
      break;
    case 'cultural':
      switch (slot) {
        case 0:
          return l10n.guestDemoCultural1Desc;
        case 1:
          return l10n.guestDemoCultural2Desc;
        case 2:
          return l10n.guestDemoCultural3Desc;
      }
      break;
    case 'romantic':
      switch (slot) {
        case 0:
          return l10n.guestDemoRomantic1Desc;
        case 1:
          return l10n.guestDemoRomantic2Desc;
        case 2:
          return l10n.guestDemoRomantic3Desc;
      }
      break;
  }
  return '';
}

/// Longer Moody-voice copy for guest demo [Activity.description] (About tab + cards).
String guestDemoPlaceMoodyAbout(AppLocalizations l10n, String mood, int slot) {
  switch (_guestDemoDataMoodKey(mood)) {
    case 'relaxed':
      switch (slot) {
        case 0:
          return l10n.guestDemoRelaxed1MoodyAbout;
        case 1:
          return l10n.guestDemoRelaxed2MoodyAbout;
        case 2:
          return l10n.guestDemoRelaxed3MoodyAbout;
      }
      break;
    case 'foodie':
      switch (slot) {
        case 0:
          return l10n.guestDemoFoodie1MoodyAbout;
        case 1:
          return l10n.guestDemoFoodie2MoodyAbout;
        case 2:
          return l10n.guestDemoFoodie3MoodyAbout;
      }
      break;
    case 'social':
      switch (slot) {
        case 0:
          return l10n.guestDemoSocial1MoodyAbout;
        case 1:
          return l10n.guestDemoSocial2MoodyAbout;
        case 2:
          return l10n.guestDemoSocial3MoodyAbout;
      }
      break;
    case 'adventurous':
      switch (slot) {
        case 0:
          return l10n.guestDemoAdventurous1MoodyAbout;
        case 1:
          return l10n.guestDemoAdventurous2MoodyAbout;
        case 2:
          return l10n.guestDemoAdventurous3MoodyAbout;
      }
      break;
    case 'cultural':
      switch (slot) {
        case 0:
          return l10n.guestDemoCultural1MoodyAbout;
        case 1:
          return l10n.guestDemoCultural2MoodyAbout;
        case 2:
          return l10n.guestDemoCultural3MoodyAbout;
      }
      break;
    case 'romantic':
      switch (slot) {
        case 0:
          return l10n.guestDemoRomantic1MoodyAbout;
        case 1:
          return l10n.guestDemoRomantic2MoodyAbout;
        case 2:
          return l10n.guestDemoRomantic3MoodyAbout;
      }
      break;
  }
  return '';
}

/// Moody one-liner above the factual description on guest preview cards.
String guestDemoMoodyPersonalityLine(AppLocalizations l10n, String mood, int slot) {
  final m = _guestDemoDataMoodKey(mood);
  final i = slot.clamp(0, 2);
  switch (m) {
    case 'relaxed':
      if (i == 0) return l10n.guestDemoMoodyRelaxed0;
      if (i == 1) return l10n.guestDemoMoodyRelaxed1;
      return l10n.guestDemoMoodyRelaxed2;
    case 'foodie':
      if (i == 0) return l10n.guestDemoMoodyFoodie0;
      if (i == 1) return l10n.guestDemoMoodyFoodie1;
      return l10n.guestDemoMoodyFoodie2;
    case 'social':
      if (i == 0) return l10n.guestDemoMoodySocial0;
      if (i == 1) return l10n.guestDemoMoodySocial1;
      return l10n.guestDemoMoodySocial2;
    case 'adventurous':
      if (i == 0) return l10n.guestDemoMoodyAdventurous0;
      if (i == 1) return l10n.guestDemoMoodyAdventurous1;
      return l10n.guestDemoMoodyAdventurous2;
    case 'cultural':
      if (i == 0) return l10n.guestDemoMoodyCultural0;
      if (i == 1) return l10n.guestDemoMoodyCultural1;
      return l10n.guestDemoMoodyCultural2;
    case 'romantic':
      if (i == 0) return l10n.guestDemoMoodyRomantic0;
      if (i == 1) return l10n.guestDemoMoodyRomantic1;
      return l10n.guestDemoMoodyRomantic2;
    default:
      return l10n.guestDemoMoodyRelaxed0;
  }
}

/// Localized chip label for guest demo [Activity.tags] (canonical lowercase keys from [guest_demo_activities_builder]).
String guestDemoActivityTag(AppLocalizations l10n, String tagKey) {
  switch (tagKey) {
    case 'relaxed':
      return l10n.moodRelaxed;
    case 'foody':
      return l10n.moodFoody;
    case 'social':
      return l10n.moodSocial;
    case 'adventurous':
      return l10n.moodAdventurous;
    case 'cultural':
      return l10n.moodCultural;
    case 'romantic':
      return l10n.moodRomantic;
    case 'walk':
      return l10n.guestDemoTagWalk;
    case 'nature':
      return l10n.guestDemoTagNature;
    case 'cafe':
      return l10n.guestDemoTagCafe;
    case 'calm':
      return l10n.guestDemoTagCalm;
    case 'restaurant':
      return l10n.guestDemoTagRestaurant;
    case 'sunset':
      return l10n.guestDemoTagSunset;
    case 'breakfast':
      return l10n.guestDemoTagBreakfast;
    case 'market':
      return l10n.guestDemoTagMarket;
    case 'lunch':
      return l10n.guestDemoTagLunch;
    case 'dinner':
      return l10n.guestDemoTagDinner;
    case 'active':
      return l10n.guestDemoTagActive;
    case 'outdoor':
      return l10n.guestDemoTagOutdoor;
    case 'nightlife':
      return l10n.guestDemoTagNightlife;
    case 'music':
      return l10n.guestDemoTagMusic;
    case 'hiking':
      return l10n.guestDemoTagHiking;
    case 'view':
      return l10n.guestDemoTagView;
    case 'bar':
      return l10n.guestDemoTagBar;
    case 'museum':
      return l10n.guestDemoTagMuseum;
    case 'art':
      return l10n.guestDemoTagArt;
    case 'garden':
      return l10n.guestDemoTagGarden;
    case 'jazz':
      return l10n.guestDemoTagJazz;
    case 'wine':
      return l10n.guestDemoTagWine;
    case 'cozy':
      return l10n.guestDemoTagCozy;
    case 'quiet':
      return l10n.guestDemoTagQuiet;
    case 'drinks':
      return l10n.guestDemoTagDrinks;
    case 'evening':
      return l10n.guestDemoTagEvening;
    default:
      return tagKey;
  }
}
