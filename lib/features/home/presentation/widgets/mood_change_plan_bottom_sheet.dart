import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/utils/offline_feedback.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/mood/models/mood_option.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/mood/providers/mood_options_provider.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_loading_screen.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Change mood from Moody Hub: bottom sheet mood grid → [PlanLoadingScreen].
Future<void> showMoodChangePlanBottomSheet(
  BuildContext navigatorContext,
  WidgetRef ref,
) async {
  await Future.delayed(const Duration(milliseconds: 280));
  if (!navigatorContext.mounted) return;

  final l10n = AppLocalizations.of(navigatorContext)!;

  await showModalBottomSheet<void>(
    context: navigatorContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      final moodsAsync = ref.watch(moodOptionsProvider);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.58,
        minChildSize: 0.36,
        maxChildSize: 0.92,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F0E8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: moodsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.homeChatErrorRetry),
                ),
              ),
              data: (List<MoodOption> options) {
                final sorted = [...options]
                  ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
                final active = sorted.where((o) => o.isActive).toList();
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.moodyHubChangeMood,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1C18),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: active.length,
                        itemBuilder: (_, i) {
                          final o = active[i];
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => unawaited(_commitMoodAndOpenLoading(
                                navigatorContext: navigatorContext,
                                sheetContext: sheetCtx,
                                ref: ref,
                                label: o.label,
                              )),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                    const Spacer(),
                                    Text(
                                      o.label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E1C18),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
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
  Navigator.of(sheetContext).pop();
  await Future.delayed(const Duration(milliseconds: 220));

  final online = await ref.read(connectivityServiceProvider).isConnected;
  if (!navigatorContext.mounted) return;
  if (!online) {
    showOfflineSnackBar(navigatorContext);
    return;
  }

  final conv = const Uuid().v4();
  await ref.read(dailyMoodStateNotifierProvider.notifier).setMoodSelection(
        mood: label,
        selectedMoods: [label],
        conversationId: conv,
      );

  final planDate = ref.read(selectedMyDayDateProvider);
  if (!navigatorContext.mounted) return;

  await Navigator.of(navigatorContext).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PlanLoadingScreen(
        selectedMoods: [label],
        targetDate: planDate,
      ),
    ),
  );
}
