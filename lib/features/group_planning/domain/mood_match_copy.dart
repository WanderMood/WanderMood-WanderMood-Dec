import 'package:wandermood/core/utils/canonical_communication_style.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Maps stored `communication_style` (onboarding or profile prefs) to Mood Match keys.
String moodMatchNormalizeCommunicationStyle(String? raw) =>
    canonicalCommunicationStyleKey(raw);

/// Hub hero-card copy: idle vs active session waiting on friend, tuned by communication style.
String moodMatchHubMoodyIntroLine(
  AppLocalizations l10n, {
  required String communicationStyle,
  required bool hasActivePendingSession,
}) {
  final s = moodMatchNormalizeCommunicationStyle(communicationStyle);
  if (hasActivePendingSession) {
    switch (s) {
      case 'professional':
        return l10n.moodMatchHubMoodyIntroWaitingProfessional;
      case 'energetic':
        return l10n.moodMatchHubMoodyIntroWaitingEnergetic;
      case 'direct':
        return l10n.moodMatchHubMoodyIntroWaitingDirect;
      default:
        return l10n.moodMatchHubMoodyIntroWaitingFriendly;
    }
  }
  switch (s) {
    case 'professional':
      return l10n.moodMatchHubMoodyIntroProfessional;
    case 'energetic':
      return l10n.moodMatchHubMoodyIntroEnergetic;
    case 'direct':
      return l10n.moodMatchHubMoodyIntroDirect;
    default:
      return l10n.moodMatchHubMoodyIntroFriendly;
  }
}

/// Lobby mood-pick helper line under the grid, by communication style.
String moodMatchMoodyPickQuoteLine(
  AppLocalizations l10n,
  String communicationStyle,
) {
  switch (moodMatchNormalizeCommunicationStyle(communicationStyle)) {
    case 'professional':
      return l10n.moodMatchMoodyPickQuoteProfessional;
    case 'energetic':
      return l10n.moodMatchMoodyPickQuoteEnergetic;
    case 'direct':
      return l10n.moodMatchMoodyPickQuoteDirect;
    default:
      return l10n.moodMatchMoodyPickQuoteFriendly;
  }
}

/// Prefer `plan_data['moodyMessage']` from the server (generated with the **requesting
/// user's** [communicationStyle] + language when the plan was built). If empty, use
/// tier copy by score and [communicationStyle] (friendly / professional / energetic / direct).
String moodMatchMoodyParagraph(
  AppLocalizations l10n,
  int score,
  String? backendMoodyMessage,
  String communicationStyle,
) {
  final t = backendMoodyMessage?.trim();
  if (t != null && t.isNotEmpty) return t;
  final s = moodMatchNormalizeCommunicationStyle(communicationStyle);
  if (score >= 75) {
    switch (s) {
      case 'professional':
        return l10n.moodMatchRevealCopyHighProfessional;
      case 'energetic':
        return l10n.moodMatchRevealCopyHighEnergetic;
      case 'direct':
        return l10n.moodMatchRevealCopyHighDirect;
      default:
        return l10n.moodMatchRevealCopyHighFriendly;
    }
  }
  if (score >= 50) {
    switch (s) {
      case 'professional':
        return l10n.moodMatchRevealCopyGoodProfessional;
      case 'energetic':
        return l10n.moodMatchRevealCopyGoodEnergetic;
      case 'direct':
        return l10n.moodMatchRevealCopyGoodDirect;
      default:
        return l10n.moodMatchRevealCopyGoodFriendly;
    }
  }
  switch (s) {
    case 'professional':
      return l10n.moodMatchRevealCopyCreativeProfessional;
    case 'energetic':
      return l10n.moodMatchRevealCopyCreativeEnergetic;
    case 'direct':
      return l10n.moodMatchRevealCopyCreativeDirect;
    default:
      return l10n.moodMatchRevealCopyCreativeFriendly;
  }
}

/// Short score label under the ring / in result compat row.
String moodMatchScoreBucketLabel(AppLocalizations l10n, int score) {
  if (score >= 95) return l10n.moodMatchScoreLabelPerfect;
  if (score >= 80) return l10n.moodMatchScoreLabelGreat;
  if (score >= 65) return l10n.moodMatchScoreLabelGoodBalance;
  if (score >= 50) return l10n.moodMatchScoreLabelInteresting;
  return l10n.moodMatchScoreLabelCreative;
}

String moodMatchPlanBuildingMessage(AppLocalizations l10n) =>
    l10n.moodMatchHubPendingBuilding;

String moodMatchMatchLoadingAppBarTitle(AppLocalizations l10n) =>
    l10n.moodMatchMatchLoadingAppBar;

String moodMatchPlanBuildingButtonLabel(AppLocalizations l10n) =>
    l10n.moodMatchPlanBuildButton;

String moodMatchFeelQuestionForNow(AppLocalizations l10n) {
  final h = MoodyClock.now().hour;
  if (h < 12) return l10n.moodMatchFeelQuestionMorning;
  if (h < 17) return l10n.moodMatchFeelQuestionAfternoon;
  if (h < 21) return l10n.moodMatchFeelQuestionEvening;
  return l10n.moodMatchFeelQuestionLate;
}

String moodMatchWaitingPreviewHeadline(
  AppLocalizations l10n, {
  required String friendFirstName,
  required bool locked,
}) {
  if (locked) return l10n.moodMatchWaitingPreviewHeadlineGeneric;
  final n = friendFirstName.trim();
  if (n.isEmpty) return l10n.moodMatchWaitingPreviewHeadlineGeneric;
  return l10n.moodMatchWaitingPreviewHeadlineNamed(n);
}

String moodMatchPlanResultMoodyLine(
  AppLocalizations l10n, {
  required String sessionId,
  required String guestName,
  required String commStyle,
  String? backendOverride,
}) {
  final t = backendOverride?.trim();
  if (t != null && t.isNotEmpty) return t;
  final name = guestName.trim().isEmpty ? 'your match' : guestName.trim();
  final i = (sessionId + commStyle).hashCode.abs() % 4;
  switch (i) {
    case 0:
      return l10n.moodMatchPlanResultMoodyV1(name);
    case 1:
      return l10n.moodMatchPlanResultMoodyV2(name);
    case 2:
      return l10n.moodMatchPlanResultMoodyV3(name);
    default:
      return l10n.moodMatchPlanResultMoodyV4(name);
  }
}

String moodMatchResultHeroMoodyTeaser(String full) {
  final t = full.trim();
  if (t.length <= 96) return t;
  return '${t.substring(0, 93)}…';
}
