import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:wandermood/core/localization/localized_mood_labels.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/utils/offline_feedback.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/home/presentation/widgets/mood_hub_style_mood_tile.dart';
import 'package:wandermood/features/mood/models/mood_option.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/mood/providers/mood_options_provider.dart';
import 'package:wandermood/features/mood/services/mood_options_service.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_loading_screen.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Premium floating shadow (Explore quick-peek style, stronger lift).
List<BoxShadow> _moodChangeSheetShadows() => [
      BoxShadow(
        color: const Color(0xFF1E1C18).withValues(alpha: 0.14),
        blurRadius: 36,
        spreadRadius: -6,
        offset: const Offset(0, -10),
      ),
      BoxShadow(
        color: const Color(0xFF1E1C18).withValues(alpha: 0.07),
        blurRadius: 14,
        offset: const Offset(0, -3),
      ),
    ];

/// Change mood from Moody Hub: bottom sheet mood grid → [PlanLoadingScreen].
/// Opens from the bottom over the main shell (including nav), like Explore quick peek.
Future<void> showMoodChangePlanBottomSheet(BuildContext navigatorContext) async {
  await Future<void>.delayed(const Duration(milliseconds: 280));
  if (!navigatorContext.mounted) return;

  await showModalBottomSheet<void>(
    context: navigatorContext,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    barrierLabel:
        MaterialLocalizations.of(navigatorContext).modalBarrierDismissLabel,
    enableDrag: true,
    showDragHandle: false,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 320),
      reverseDuration: Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    builder: (sheetCtx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.38,
        maxChildSize: 0.94,
        snap: true,
        snapSizes: const [0.62, 0.94],
        builder: (context, scrollController) {
          // Modal builders are not Riverpod build methods: [ref.watch] here never
          // triggers a rebuild when [moodOptionsProvider] completes — wrap in
          // [Consumer] so the sheet leaves the loading state.
          return Consumer(
            builder: (_, sheetRef, __) {
              final l10n = AppLocalizations.of(sheetCtx)!;
              final moodsAsync = sheetRef.watch(moodOptionsProvider);
              final bottomInset = MediaQuery.paddingOf(sheetCtx).bottom;

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: _moodChangeSheetShadows(),
                ),
                clipBehavior: Clip.antiAlias,
                child: moodsAsync.when(
                  loading: () => SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.sizeOf(sheetCtx).height * 0.32,
                      ),
                      child: Padding(
                        padding:
                            EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2A6049),
                          ),
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) => SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.sizeOf(sheetCtx).height * 0.28,
                      ),
                      child: Padding(
                        padding:
                            EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                        child: Center(child: Text(l10n.homeChatErrorRetry)),
                      ),
                    ),
                  ),
                  data: (List<MoodOption> options) {
                    final sorted = [...options]
                      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
                    var active = sorted.where((o) => o.isActive).toList();
                    if (active.isEmpty) {
                      active = MoodOptionsService.fallbackMoodOptions()
                          .where((o) => o.isActive)
                          .toList();
                    }
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 16 + bottomInset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0DCD4),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                            child: Text(
                              l10n.moodyHubChangeMood,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1C18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.32,
                              ),
                              itemCount: active.length,
                              itemBuilder: (_, i) {
                                final o = active[i];
                                return MoodHubStyleMoodTile(
                                  emoji: o.emoji,
                                  pastelBase: o.color,
                                  title: localizedMoodDisplayLabel(l10n, o.label),
                                  isSelected: false,
                                  dimmed: false,
                                  emojiSize: 26,
                                  titleSize: 10,
                                  tileRadius: 16,
                                  showCheckBadge: false,
                                  onTap: () => unawaited(_commitMoodAndOpenLoading(
                                        navigatorContext: navigatorContext,
                                        sheetContext: sheetCtx,
                                        ref: sheetRef,
                                        label: o.label,
                                      )),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    },
  );
}

Future<void> _commitMoodAndOpenLoading({
  required BuildContext navigatorContext,
  required BuildContext sheetContext,
  required WidgetRef ref,
  required String label,
}) async {
  // Read everything we need up-front so async gaps after sheet close do not
  // touch a disposed Consumer ref.
  final connectivity = ref.read(connectivityServiceProvider);
  final moodNotifier = ref.read(dailyMoodStateNotifierProvider.notifier);
  final planDate = ref.read(selectedMyDayDateProvider);

  Navigator.of(sheetContext).pop();
  await Future<void>.delayed(const Duration(milliseconds: 220));

  final online = await connectivity.isConnected;
  if (!navigatorContext.mounted) return;
  if (!online) {
    showOfflineSnackBar(navigatorContext);
    return;
  }

  final conv = const Uuid().v4();
  await moodNotifier.setMoodSelection(
        mood: label,
        selectedMoods: [label],
        conversationId: conv,
      );
  if (!navigatorContext.mounted) return;

  await Navigator.of(navigatorContext).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PlanLoadingScreen(
        selectedMoods: [label],
        targetDate: planDate,
        forceRefresh: true,
      ),
    ),
  );
}
