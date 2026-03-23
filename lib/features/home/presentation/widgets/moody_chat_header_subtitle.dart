import 'package:wandermood/core/providers/communication_style_provider.dart';

/// Line under “Moody” in chat UIs — uses [city] when known and the user’s
/// onboarding [CommunicationStyle].
String moodyChatTravelBestieSubtitle({
  required CommunicationStyle style,
  String? city,
}) {
  final trimmed = city?.trim();
  final hasCity = trimmed != null && trimmed.isNotEmpty;
  final place = hasCity ? trimmed : '';

  switch (style) {
    case CommunicationStyle.energetic:
      return hasCity
          ? 'Your $place hype travel bestie'
          : 'Your hype travel bestie';
    case CommunicationStyle.friendly:
      return hasCity
          ? 'Your $place travel bestie'
          : 'Your travel bestie';
    case CommunicationStyle.professional:
      return hasCity
          ? 'Your travel companion in $place'
          : 'Your professional travel companion';
    case CommunicationStyle.direct:
      return hasCity
          ? '$place · straight-up travel bestie'
          : 'Straight-up travel bestie';
  }
}
