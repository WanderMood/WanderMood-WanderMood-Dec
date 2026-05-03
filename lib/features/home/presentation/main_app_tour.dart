import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:wandermood/features/home/presentation/providers/main_navigation_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Legacy global flag (pre–per-user). Migrated on first main open with a session.
const String kMainAppTourCompletedPrefsKey = 'main_app_tour_completed';

String mainAppTourCompletedKeyForUser(String userId) =>
    'main_app_tour_completed_$userId';

/// Max bullet lines per tour step (iOS-first product constraint).
const int kMainAppTourMaxTipsPerStep = 5;

/// Increment to request [MainScreen] to show the tab tour (e.g. from Settings).
final mainAppTourRequestProvider = StateProvider<int>((ref) => 0);

/// If [kMainAppTourCompletedPrefsKey] is still set, copies it to this [userId]
/// and removes the legacy key (one-time per install).
Future<void> migrateLegacyMainAppTourIfNeeded(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(kMainAppTourCompletedPrefsKey) != true) return;
  await prefs.setBool(mainAppTourCompletedKeyForUser(userId), true);
  await prefs.remove(kMainAppTourCompletedPrefsKey);
}

Future<bool> isMainAppTourCompletedForUser(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(mainAppTourCompletedKeyForUser(userId)) ?? false;
}

Future<void> setMainAppTourCompletedForUser(bool value, String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(mainAppTourCompletedKeyForUser(userId), value);
}

void requestMainAppTour(WidgetRef ref) {
  ref.read(mainAppTourRequestProvider.notifier).state++;
}

bool _mainAppTourIsIOS() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

String _tabTitle(AppLocalizations l10n, int i) {
  switch (i) {
    case 0:
      return l10n.navMyDay;
    case 1:
      return l10n.navExplore;
    case 2:
      return l10n.navMoody;
    case 3:
      return l10n.navAgenda;
    case 4:
      return l10n.navProfile;
    default:
      return '';
  }
}

String _tabContentTipsRaw(AppLocalizations l10n, int i) {
  switch (i) {
    case 0:
      return l10n.appTourStepMyDayContentTips;
    case 1:
      return l10n.appTourStepExploreContentTips;
    case 2:
      return l10n.appTourStepMoodyContentTips;
    case 3:
      return l10n.appTourStepAgendaContentTips;
    case 4:
      return l10n.appTourStepProfileContentTips;
    default:
      return '';
  }
}

List<String> parseMainAppTourTips(String raw) {
  return raw
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .take(kMainAppTourMaxTipsPerStep)
      .toList();
}

/// One short step per tab — max [kMainAppTourMaxTipsPerStep] bullets each.
/// [identify] is the tab index `0..4`.
List<TargetFocus> buildMainAppTourTargets({
  required AppLocalizations l10n,
  required List<GlobalKey> contentKeys,
}) {
  assert(contentKeys.length == 5);
  return List<TargetFocus>.generate(5, (tab) {
    final isLast = tab == 4;
    final tips = parseMainAppTourTips(_tabContentTipsRaw(l10n, tab));
    return TargetFocus(
      identify: tab,
      keyTarget: contentKeys[tab],
      shape: ShapeLightFocus.RRect,
      radius: 16,
      paddingFocus: 6,
      enableOverlayTab: false,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return _MainTourTooltip(
              title: _tabTitle(l10n, tab),
              tips: tips,
              primaryLabel: isLast ? l10n.myDayDone : l10n.continueButton,
              onPrimary: () {
                if (_mainAppTourIsIOS()) {
                  HapticFeedback.selectionClick();
                }
                controller.next();
              },
            );
          },
        ),
      ],
    );
  });
}

/// Quick walkthrough: each main tab once, plus bottom-bar hint on the last card.
void showMainAppTour({
  required BuildContext context,
  required WidgetRef ref,
  required List<GlobalKey> contentKeys,
  required String userId,
  required VoidCallback onSessionEnd,
}) {
  final l10n = AppLocalizations.of(context)!;
  TutorialCoachMark(
    targets: buildMainAppTourTargets(
      l10n: l10n,
      contentKeys: contentKeys,
    ),
    beforeFocus: (target) async {
      final tabIndex = target.identify as int;
      ref.read(mainTabProvider.notifier).state = tabIndex;
      // Let [Offstage] mount the tab so [contentKeys] attach to a laid-out subtree.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 220));
    },
    colorShadow: Colors.black,
    opacityShadow: 0.78,
    paddingFocus: 6,
    alignSkip: Alignment.topRight,
    textSkip: l10n.introSkip,
    textStyleSkip: GoogleFonts.poppins(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    useSafeArea: true,
    pulseEnable: false,
    disableBackButton: true,
    showSkipInLastTarget: true,
    onFinish: () {
      onSessionEnd();
      setMainAppTourCompletedForUser(true, userId);
    },
    onSkip: () {
      onSessionEnd();
      setMainAppTourCompletedForUser(true, userId);
      return true;
    },
  ).show(context: context);
}

class _MainTourTooltip extends StatelessWidget {
  const _MainTourTooltip({
    required this.title,
    required this.tips,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final String title;
  final List<String> tips;
  final String primaryLabel;
  final VoidCallback onPrimary;

  static const Color _forest = Color(0xFF2A6049);
  static const Color _cream = Color(0xFFF5F0E8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 32,
          maxHeight: MediaQuery.sizeOf(context).height * 0.48,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E2D8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1C18),
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.32,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < tips.length; i++) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3, right: 8),
                              child: Text(
                                '•',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _forest,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tips[i],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  height: 1.45,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF4A4640),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (i < tips.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: onPrimary,
                  child: Text(
                    primaryLabel,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
