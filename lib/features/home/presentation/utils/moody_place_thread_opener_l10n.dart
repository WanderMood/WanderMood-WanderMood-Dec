import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// First bubble when opening Ask Moody for a place — fully localized (en/nl/de/fr/es)
/// and aligned with [CommunicationStyle].
String moodyPlaceThreadOpenerL10n({
  required AppLocalizations l10n,
  required CommunicationStyle communicationStyle,
  required String source,
  required String title,
  required String placeKey,
  required int hour,
}) {
  final t = title.trim();
  final emptyTitle = t.isEmpty;
  final place = emptyTitle ? l10n.moodyPlaceThreadFallbackPlace : t;
  final v = ('$placeKey|$source|$hour'.hashCode).abs() % 6;

  if (source == 'explore_place_card') {
    return _explorePlaceOpenerL10n(l10n, communicationStyle, v, place);
  }
  return _myDayPlaceOpenerL10n(l10n, communicationStyle, v, t, emptyTitle);
}

String _explorePlaceOpenerL10n(
  AppLocalizations l,
  CommunicationStyle s,
  int v,
  String place,
) {
  switch (s) {
    case CommunicationStyle.friendly:
      switch (v) {
        case 0:
          return l.moodyPlaceThreadExploreV0Friendly(place);
        case 1:
          return l.moodyPlaceThreadExploreV1Friendly(place);
        case 2:
          return l.moodyPlaceThreadExploreV2Friendly(place);
        case 3:
          return l.moodyPlaceThreadExploreV3Friendly(place);
        case 4:
          return l.moodyPlaceThreadExploreV4Friendly(place);
        case 5:
          return l.moodyPlaceThreadExploreV5Friendly(place);
        default:
          return l.moodyPlaceThreadExploreV5Friendly(place);
      }
    case CommunicationStyle.professional:
      switch (v) {
        case 0:
          return l.moodyPlaceThreadExploreV0Professional(place);
        case 1:
          return l.moodyPlaceThreadExploreV1Professional(place);
        case 2:
          return l.moodyPlaceThreadExploreV2Professional(place);
        case 3:
          return l.moodyPlaceThreadExploreV3Professional(place);
        case 4:
          return l.moodyPlaceThreadExploreV4Professional(place);
        case 5:
          return l.moodyPlaceThreadExploreV5Professional(place);
        default:
          return l.moodyPlaceThreadExploreV5Professional(place);
      }
    case CommunicationStyle.direct:
      switch (v) {
        case 0:
          return l.moodyPlaceThreadExploreV0Direct(place);
        case 1:
          return l.moodyPlaceThreadExploreV1Direct(place);
        case 2:
          return l.moodyPlaceThreadExploreV2Direct(place);
        case 3:
          return l.moodyPlaceThreadExploreV3Direct(place);
        case 4:
          return l.moodyPlaceThreadExploreV4Direct(place);
        case 5:
          return l.moodyPlaceThreadExploreV5Direct(place);
        default:
          return l.moodyPlaceThreadExploreV5Direct(place);
      }
    case CommunicationStyle.energetic:
      switch (v) {
        case 0:
          return l.moodyPlaceThreadExploreV0Energetic(place);
        case 1:
          return l.moodyPlaceThreadExploreV1Energetic(place);
        case 2:
          return l.moodyPlaceThreadExploreV2Energetic(place);
        case 3:
          return l.moodyPlaceThreadExploreV3Energetic(place);
        case 4:
          return l.moodyPlaceThreadExploreV4Energetic(place);
        case 5:
          return l.moodyPlaceThreadExploreV5Energetic(place);
        default:
          return l.moodyPlaceThreadExploreV5Energetic(place);
      }
  }
}

String _myDayPlaceOpenerL10n(
  AppLocalizations l,
  CommunicationStyle s,
  int v,
  String placeLabel,
  bool emptyTitle,
) {
  if (emptyTitle) {
    switch (s) {
      case CommunicationStyle.friendly:
        switch (v) {
          case 0:
            return l.moodyPlaceThreadMyDayV0FriendlyEmpty;
          case 1:
            return l.moodyPlaceThreadMyDayV1FriendlyEmpty;
          case 2:
            return l.moodyPlaceThreadMyDayV2FriendlyEmpty;
          case 3:
            return l.moodyPlaceThreadMyDayV3FriendlyEmpty;
          case 4:
            return l.moodyPlaceThreadMyDayV4FriendlyEmpty;
          case 5:
            return l.moodyPlaceThreadMyDayV5FriendlyEmpty;
          default:
            return l.moodyPlaceThreadMyDayV5FriendlyEmpty;
        }
      case CommunicationStyle.professional:
        switch (v) {
          case 0:
            return l.moodyPlaceThreadMyDayV0ProfessionalEmpty;
          case 1:
            return l.moodyPlaceThreadMyDayV1ProfessionalEmpty;
          case 2:
            return l.moodyPlaceThreadMyDayV2ProfessionalEmpty;
          case 3:
            return l.moodyPlaceThreadMyDayV3ProfessionalEmpty;
          case 4:
            return l.moodyPlaceThreadMyDayV4ProfessionalEmpty;
          case 5:
            return l.moodyPlaceThreadMyDayV5ProfessionalEmpty;
          default:
            return l.moodyPlaceThreadMyDayV5ProfessionalEmpty;
        }
      case CommunicationStyle.direct:
        switch (v) {
          case 0:
            return l.moodyPlaceThreadMyDayV0DirectEmpty;
          case 1:
            return l.moodyPlaceThreadMyDayV1DirectEmpty;
          case 2:
            return l.moodyPlaceThreadMyDayV2DirectEmpty;
          case 3:
            return l.moodyPlaceThreadMyDayV3DirectEmpty;
          case 4:
            return l.moodyPlaceThreadMyDayV4DirectEmpty;
          case 5:
            return l.moodyPlaceThreadMyDayV5DirectEmpty;
          default:
            return l.moodyPlaceThreadMyDayV5DirectEmpty;
        }
      case CommunicationStyle.energetic:
        switch (v) {
          case 0:
            return l.moodyPlaceThreadMyDayV0EnergeticEmpty;
          case 1:
            return l.moodyPlaceThreadMyDayV1EnergeticEmpty;
          case 2:
            return l.moodyPlaceThreadMyDayV2EnergeticEmpty;
          case 3:
            return l.moodyPlaceThreadMyDayV3EnergeticEmpty;
          case 4:
            return l.moodyPlaceThreadMyDayV4EnergeticEmpty;
          case 5:
            return l.moodyPlaceThreadMyDayV5EnergeticEmpty;
          default:
            return l.moodyPlaceThreadMyDayV5EnergeticEmpty;
        }
    }
  }
  switch (s) {
    case CommunicationStyle.friendly:
      switch (v) {
        case 0:
          return l.moodyPlaceThreadMyDayV0FriendlyPlace(placeLabel);
        case 1:
          return l.moodyPlaceThreadMyDayV1FriendlyPlace(placeLabel);
        case 2:
          return l.moodyPlaceThreadMyDayV2FriendlyPlace(placeLabel);
        case 3:
          return l.moodyPlaceThreadMyDayV3FriendlyPlace(placeLabel);
        case 4:
          return l.moodyPlaceThreadMyDayV4FriendlyPlace(placeLabel);
        case 5:
          return l.moodyPlaceThreadMyDayV5FriendlyPlace(placeLabel);
        default:
          return l.moodyPlaceThreadMyDayV5FriendlyPlace(placeLabel);
      }
    case CommunicationStyle.professional:
      switch (v) {
        case 0:
          return l.moodyPlaceThreadMyDayV0ProfessionalPlace(placeLabel);
        case 1:
          return l.moodyPlaceThreadMyDayV1ProfessionalPlace(placeLabel);
        case 2:
          return l.moodyPlaceThreadMyDayV2ProfessionalPlace(placeLabel);
        case 3:
          return l.moodyPlaceThreadMyDayV3ProfessionalPlace(placeLabel);
        case 4:
          return l.moodyPlaceThreadMyDayV4ProfessionalPlace(placeLabel);
        case 5:
          return l.moodyPlaceThreadMyDayV5ProfessionalPlace(placeLabel);
        default:
          return l.moodyPlaceThreadMyDayV5ProfessionalPlace(placeLabel);
      }
    case CommunicationStyle.direct:
      switch (v) {
        case 0:
          return l.moodyPlaceThreadMyDayV0DirectPlace(placeLabel);
        case 1:
          return l.moodyPlaceThreadMyDayV1DirectPlace(placeLabel);
        case 2:
          return l.moodyPlaceThreadMyDayV2DirectPlace(placeLabel);
        case 3:
          return l.moodyPlaceThreadMyDayV3DirectPlace(placeLabel);
        case 4:
          return l.moodyPlaceThreadMyDayV4DirectPlace(placeLabel);
        case 5:
          return l.moodyPlaceThreadMyDayV5DirectPlace(placeLabel);
        default:
          return l.moodyPlaceThreadMyDayV5DirectPlace(placeLabel);
      }
    case CommunicationStyle.energetic:
      switch (v) {
        case 0:
          return l.moodyPlaceThreadMyDayV0EnergeticPlace(placeLabel);
        case 1:
          return l.moodyPlaceThreadMyDayV1EnergeticPlace(placeLabel);
        case 2:
          return l.moodyPlaceThreadMyDayV2EnergeticPlace(placeLabel);
        case 3:
          return l.moodyPlaceThreadMyDayV3EnergeticPlace(placeLabel);
        case 4:
          return l.moodyPlaceThreadMyDayV4EnergeticPlace(placeLabel);
        case 5:
          return l.moodyPlaceThreadMyDayV5EnergeticPlace(placeLabel);
        default:
          return l.moodyPlaceThreadMyDayV5EnergeticPlace(placeLabel);
      }
  }
}
