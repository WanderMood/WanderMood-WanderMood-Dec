import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Line under “Moody” in chat UIs — uses [city] when known, the user’s
/// onboarding [CommunicationStyle], and the active [AppLocalizations] locale.
String moodyChatTravelBestieSubtitle({
  required AppLocalizations l10n,
  required CommunicationStyle style,
  String? city,
}) {
  final trimmed = city?.trim() ?? '';
  final hasCity = trimmed.isNotEmpty;
  final place = trimmed;

  switch (style) {
    case CommunicationStyle.energetic:
      return hasCity
          ? l10n.moodyChatSubtitleEnergeticCity(place)
          : l10n.moodyChatSubtitleEnergeticNoCity;
    case CommunicationStyle.friendly:
      return hasCity
          ? l10n.moodyChatSubtitleFriendlyCity(place)
          : l10n.moodyChatSubtitleFriendlyNoCity;
    case CommunicationStyle.professional:
      return hasCity
          ? l10n.moodyChatSubtitleProfessionalCity(place)
          : l10n.moodyChatSubtitleProfessionalNoCity;
    case CommunicationStyle.direct:
      return hasCity
          ? l10n.moodyChatSubtitleDirectCity(place)
          : l10n.moodyChatSubtitleDirectNoCity;
  }
}
