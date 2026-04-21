import 'package:wandermood/core/utils/canonical_communication_style.dart';
import 'package:wandermood/features/home/presentation/providers/moody_hub_state_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Hub hero subtitle: varies by [MoodyHubState] and saved communication style.
/// Rotates daily through 4 variants per state/style so the copy feels fresh
/// each day rather than static.
String moodyHubHeroBodyLine(
  AppLocalizations l10n,
  MoodyHubState state,
  String rawCommunicationStyle,
) {
  final c = canonicalCommunicationStyleKey(rawCommunicationStyle);
  // Rotate 4 variants per day (weekday: 1-7, mapped to 0-3).
  final v = (DateTime.now().weekday - 1) % 4; // 0, 1, 2, 3

  if (state.match.state == MoodyMatchState.invite) {
    return switch (c) {
      'professional' => _pick(v, [
          l10n.moodyHubHeroBodyInviteProfessional,
          l10n.moodyHubHeroBodyInviteProfessional2,
          l10n.moodyHubHeroBodyInviteProfessional3,
          l10n.moodyHubHeroBodyInviteProfessional4,
        ]),
      'energetic' => _pick(v, [
          l10n.moodyHubHeroBodyInviteEnergetic,
          l10n.moodyHubHeroBodyInviteEnergetic2,
          l10n.moodyHubHeroBodyInviteEnergetic3,
          l10n.moodyHubHeroBodyInviteEnergetic4,
        ]),
      'direct' => _pick(v, [
          l10n.moodyHubHeroBodyInviteDirect,
          l10n.moodyHubHeroBodyInviteDirect2,
          l10n.moodyHubHeroBodyInviteDirect3,
          l10n.moodyHubHeroBodyInviteDirect4,
        ]),
      _ => _pick(v, [
          l10n.moodyHubHeroBodyInviteFriendly,
          l10n.moodyHubHeroBodyInviteFriendly2,
          l10n.moodyHubHeroBodyInviteFriendly3,
          l10n.moodyHubHeroBodyInviteFriendly4,
        ]),
    };
  }

  if (state.match.state == MoodyMatchState.sharedReady) {
    // Shared plan is ready; copy differs: empty My Day → lead with Mood Match,
    // active day → status line about the plan at the top.
    if (state.day == MoodyDayState.empty) {
      return switch (c) {
        'professional' => l10n.moodyHubHeroBodySharedReadyDayEmptyProfessional,
        'energetic' => l10n.moodyHubHeroBodySharedReadyDayEmptyEnergetic,
        'direct' => l10n.moodyHubHeroBodySharedReadyDayEmptyDirect,
        _ => l10n.moodyHubHeroBodySharedReadyDayEmptyFriendly,
      };
    }
    return switch (c) {
      'professional' => l10n.moodyHubHeroBodySharedReadyProfessional,
      'energetic' => l10n.moodyHubHeroBodySharedReadyEnergetic,
      'direct' => l10n.moodyHubHeroBodySharedReadyDirect,
      _ => l10n.moodyHubHeroBodySharedReadyFriendly,
    };
  }

  if (state.day == MoodyDayState.empty) {
    return switch (c) {
      'professional' => _pick(v, [
          l10n.moodyHubHeroBodyEmptyProfessional,
          l10n.moodyHubHeroBodyEmptyProfessional2,
          l10n.moodyHubHeroBodyEmptyProfessional3,
          l10n.moodyHubHeroBodyEmptyProfessional4,
        ]),
      'energetic' => _pick(v, [
          l10n.moodyHubHeroBodyEmptyEnergetic,
          l10n.moodyHubHeroBodyEmptyEnergetic2,
          l10n.moodyHubHeroBodyEmptyEnergetic3,
          l10n.moodyHubHeroBodyEmptyEnergetic4,
        ]),
      'direct' => _pick(v, [
          l10n.moodyHubHeroBodyEmptyDirect,
          l10n.moodyHubHeroBodyEmptyDirect2,
          l10n.moodyHubHeroBodyEmptyDirect3,
          l10n.moodyHubHeroBodyEmptyDirect4,
        ]),
      _ => _pick(v, [
          l10n.moodyHubHeroBodyEmptyFriendly,
          l10n.moodyHubHeroBodyEmptyFriendly2,
          l10n.moodyHubHeroBodyEmptyFriendly3,
          l10n.moodyHubHeroBodyEmptyFriendly4,
        ]),
    };
  }

  return switch (c) {
    'professional' => _pick(v, [
        l10n.moodyHubHeroBodyActiveProfessional,
        l10n.moodyHubHeroBodyActiveProfessional2,
        l10n.moodyHubHeroBodyActiveProfessional3,
        l10n.moodyHubHeroBodyActiveProfessional4,
      ]),
    'energetic' => _pick(v, [
        l10n.moodyHubHeroBodyActiveEnergetic,
        l10n.moodyHubHeroBodyActiveEnergetic2,
        l10n.moodyHubHeroBodyActiveEnergetic3,
        l10n.moodyHubHeroBodyActiveEnergetic4,
      ]),
    'direct' => _pick(v, [
        l10n.moodyHubHeroBodyActiveDirect,
        l10n.moodyHubHeroBodyActiveDirect2,
        l10n.moodyHubHeroBodyActiveDirect3,
        l10n.moodyHubHeroBodyActiveDirect4,
      ]),
    _ => _pick(v, [
        l10n.moodyHubHeroBodyActiveFriendly,
        l10n.moodyHubHeroBodyActiveFriendly2,
        l10n.moodyHubHeroBodyActiveFriendly3,
        l10n.moodyHubHeroBodyActiveFriendly4,
      ]),
  };
}

String _pick(int index, List<String> options) =>
    options[index.clamp(0, options.length - 1)];
