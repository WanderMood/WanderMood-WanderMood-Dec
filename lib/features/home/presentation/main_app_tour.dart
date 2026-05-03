import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/constants/app_store_demo_account.dart';
import 'package:wandermood/features/home/presentation/providers/main_navigation_provider.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Legacy global flag (pre–per-user). Migrated on first main open with a session.
const String kMainAppTourCompletedPrefsKey = 'main_app_tour_completed';

String mainAppTourCompletedKeyForUser(String userId) =>
    'main_app_tour_completed_$userId';

final mainAppTourRequestProvider = StateProvider<int>((ref) => 0);

Future<void> migrateLegacyMainAppTourIfNeeded(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(kMainAppTourCompletedPrefsKey) != true) return;
  await prefs.setBool(mainAppTourCompletedKeyForUser(userId), true);
  await prefs.remove(kMainAppTourCompletedPrefsKey);
}

Future<bool> isMainAppTourCompletedForUser(
  String userId, [
  String? email,
]) async {
  if (isAppStoreDemoReviewAccount(userId: userId, email: email)) {
    return false;
  }
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(mainAppTourCompletedKeyForUser(userId)) ?? false;
}

Future<void> setMainAppTourCompletedForUser(bool value, String userId) async {
  final email = Supabase.instance.client.auth.currentUser?.email;
  if (value &&
      isAppStoreDemoReviewAccount(userId: userId, email: email)) {
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(mainAppTourCompletedKeyForUser(userId), value);
}

void requestMainAppTour(WidgetRef ref) {
  ref.read(mainAppTourRequestProvider.notifier).state++;
}

bool _mainAppTourIsIOS() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

const Duration _mainAppTourSheetOpenDuration = Duration(milliseconds: 420);
const Duration _mainAppTourSheetCloseDuration = Duration(milliseconds: 400);
const Duration _mainAppTourPauseAfterTabChange = Duration(milliseconds: 300);
const Duration _mainAppTourPauseAfterSheetCloses = Duration(milliseconds: 480);

/// One bottom sheet per tab: switch tab → Moody card slides up from the bottom →
/// Continue runs the close animation, pause, next tab, then the next sheet opens.
Future<void> showMainAppTour({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required VoidCallback onSessionEnd,
}) async {
  final l10n = AppLocalizations.of(context)!;
  const cream = Color(0xFFF5F0E8);
  const forest = Color(0xFF2A6049);
  const charcoal = Color(0xFF1E1C18);
  const dusk = Color(0xFF4A4640);
  const parchment = Color(0xFFE8E2D8);

  final steps = <(int tab, String title, String body)>[
    (0, l10n.appTourSimpleMyDayTitle, l10n.appTourSimpleMyDayBody),
    (1, l10n.appTourSimpleExploreTitle, l10n.appTourSimpleExploreBody),
    (2, l10n.appTourSimpleMoodyTitle, l10n.appTourSimpleMoodyBody),
    (3, l10n.appTourSimpleAgendaTitle, l10n.appTourSimpleAgendaBody),
    (4, l10n.appTourSimpleProfileTitle, l10n.appTourSimpleProfileBody),
  ];

  Future<void> finishTour() async {
    await setMainAppTourCompletedForUser(true, userId);
    onSessionEnd();
  }

  for (var i = 0; i < steps.length; i++) {
    if (!context.mounted) return;
    ref.read(mainTabProvider.notifier).state = steps[i].$1;
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(_mainAppTourPauseAfterTabChange);
    if (!context.mounted) return;

    final isLast = i == steps.length - 1;
    final skipped = await showModalBottomSheet<bool>(
          context: context,
          useRootNavigator: true,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          useSafeArea: false,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.45),
          sheetAnimationStyle: AnimationStyle(
            duration: _mainAppTourSheetOpenDuration,
            reverseDuration: _mainAppTourSheetCloseDuration,
          ),
          builder: (ctx) {
            final mq = MediaQuery.of(ctx);
            final bottomInset = mq.padding.bottom;
            final maxBodyHeight = mq.size.height * 0.52;
            return Material(
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: parchment),
                    left: BorderSide(color: parchment),
                    right: BorderSide(color: parchment),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20 + mq.padding.left,
                    10,
                    20 + mq.padding.right,
                    16 + bottomInset,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9C4BC),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MoodyCharacter(
                            size: 72,
                            mood: 'idle',
                            glowOpacityScale: 0.72,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: maxBodyHeight,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      steps[i].$2,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                        height: 1.25,
                                        color: charcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      steps[i].$3,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: dusk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(ctx).pop(true),
                            child: Text(
                              l10n.introSkip,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: forest,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Spacer(),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: forest,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              if (_mainAppTourIsIOS()) {
                                HapticFeedback.selectionClick();
                              }
                              Navigator.of(ctx).pop(false);
                            },
                            child: Text(
                              isLast ? l10n.myDayDone : l10n.continueButton,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        true;

    if (!context.mounted) {
      await finishTour();
      return;
    }
    if (skipped) {
      await finishTour();
      return;
    }

    if (!isLast) {
      // Full slide-down must finish, then the tab shows without the sheet before the next step.
      await Future<void>.delayed(_mainAppTourPauseAfterSheetCloses);
    }
  }

  await finishTour();
}
