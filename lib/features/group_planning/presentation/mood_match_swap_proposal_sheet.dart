import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_v2.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Blocking bottom sheet: accept or decline a pending activity swap.
Future<void> showMoodMatchSwapDecisionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String sessionId,
  required String slot,
  required Map<String, dynamic> planData,
  required String ownerUserId,
  required String? guestUserId,
  required bool guestIsResponder,
  /// When the guest proposed the swap and the owner is deciding.
  required bool ownerIsResponder,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final req = GroupPlanV2.swapRequestForSlot(planData, slot);
  if (req == null) return;
  final proposed = req['proposedActivity'];
  if (proposed is! Map) return;
  final act = GroupPlanV2.activityForSlot(planData, slot);
  final curName =
      (act?['name'] ?? act?['title'] ?? '').toString().trim().isEmpty
          ? l10n.moodMatchPlanV2PickThis
          : (act?['name'] ?? act?['title'] ?? '').toString();
  final propName =
      (proposed['name'] ?? proposed['title'] ?? '').toString().trim().isEmpty
          ? l10n.moodMatchPlanV2PickThis
          : (proposed['name'] ?? proposed['title'] ?? '').toString();

  String slotTitle(String s) {
    switch (s) {
      case 'morning':
        return l10n.moodMatchTimePickerMorning;
      case 'afternoon':
        return l10n.moodMatchTimePickerAfternoon;
      case 'evening':
        return l10n.moodMatchTimePickerEvening;
      default:
        return s;
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: GroupPlanningUi.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GroupPlanningUi.stone.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🔄',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.moodMatchPlanV2SwapSheetTitle(slotTitle(slot)),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: GroupPlanningUi.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.moodMatchPlanV2SwapSheetMoody,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: GroupPlanningUi.forest,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _swapRow(
                l10n.moodMatchPlanV2SwapBannerSubtitle(propName, curName),
                curName,
                propName,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final repo = ref.read(groupPlanningRepositoryProvider);
                        if (guestIsResponder) {
                          await repo.guestResolveSwap(
                            sessionId: sessionId,
                            slot: slot,
                            accept: false,
                            ownerUserId: ownerUserId,
                          );
                        } else if (guestUserId != null) {
                          await repo.ownerResolveSwap(
                            sessionId: sessionId,
                            slot: slot,
                            accept: false,
                            guestUserId: guestUserId,
                          );
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GroupPlanningUi.forest,
                        side: BorderSide(
                          color: GroupPlanningUi.forest.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        ownerIsResponder
                            ? l10n.moodMatchPlanV2KeepOriginal(curName)
                            : l10n.moodMatchPlanV2KeepCurrentPlace,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final repo = ref.read(groupPlanningRepositoryProvider);
                        if (guestIsResponder) {
                          await repo.guestResolveSwap(
                            sessionId: sessionId,
                            slot: slot,
                            accept: true,
                            ownerUserId: ownerUserId,
                          );
                        } else if (guestUserId != null) {
                          await repo.ownerResolveSwap(
                            sessionId: sessionId,
                            slot: slot,
                            accept: true,
                            guestUserId: guestUserId,
                          );
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: GroupPlanningUi.forest,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        ownerIsResponder
                            ? l10n.moodMatchPlanV2AcceptSwap(propName)
                            : l10n.moodMatchPlanV2UseOwnersPick,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _swapRow(String subtitle, String current, String proposed) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: GroupPlanningUi.stone,
          height: 1.35,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        current,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: GroupPlanningUi.charcoal,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '→ $proposed',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFE8784A),
        ),
      ),
    ],
  );
}
