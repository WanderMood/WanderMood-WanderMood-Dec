import 'package:wandermood/core/constants/app_link_config.dart';

/// Shareable link when the invitee does not have WanderMood yet.
Uri planMetVriendDownloadInviteUri({
  required String placeId,
  required String placeName,
}) {
  final encodedName = Uri.encodeComponent(placeName.trim());
  if (AppLinkConfig.hasHttpsJoinOrigin) {
    return Uri.parse(AppLinkConfig.universalLinkOrigin).replace(
      path: '/download',
      queryParameters: {
        'ref': 'plan_met_vriend',
        'place': placeId,
        if (encodedName.isNotEmpty) 'place_name': placeName.trim(),
      },
    );
  }
  return Uri.https(
    'wandermood-landing.vercel.app',
    '/',
    {
      'ref': 'plan_met_vriend',
      'place': placeId,
      if (encodedName.isNotEmpty) 'place_name': placeName.trim(),
    },
  );
}

String planMetVriendShareMessage({
  required String placeName,
  required String inviterName,
  required Uri link,
}) {
  return '$inviterName wil $placeName met je bezoeken op WanderMood.\n\n'
      'Download de app en plan samen jullie beschikbaarheid:\n$link';
}
