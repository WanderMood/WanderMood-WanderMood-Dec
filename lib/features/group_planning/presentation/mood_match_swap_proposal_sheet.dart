import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_v2.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/plans/presentation/providers/place_photo_url_provider.dart';
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
  final proposedRaw = req['proposedActivity'];
  if (proposedRaw is! Map) return;
  final proposed = Map<String, dynamic>.from(proposedRaw);
  final current = GroupPlanV2.activityForSlot(planData, slot) ??
      const <String, dynamic>{};

  String nameOf(Map<String, dynamic> a) {
    final n = (a['name'] ?? a['title'] ?? '').toString().trim();
    return n.isEmpty ? l10n.moodMatchPlanV2PickThis : n;
  }

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
      return _SwapDecisionBody(
        l10n: l10n,
        ref: ref,
        sessionId: sessionId,
        slot: slot,
        slotTitle: slotTitle(slot),
        current: current,
        proposed: proposed,
        curName: nameOf(current),
        propName: nameOf(proposed),
        ownerUserId: ownerUserId,
        guestUserId: guestUserId,
        guestIsResponder: guestIsResponder,
        ownerIsResponder: ownerIsResponder,
      );
    },
  );
}

/// Stateful body so the sheet can show a spinner on the tapped button and
/// keep itself open if the repo call fails (instead of swallowing errors).
class _SwapDecisionBody extends StatefulWidget {
  const _SwapDecisionBody({
    required this.l10n,
    required this.ref,
    required this.sessionId,
    required this.slot,
    required this.slotTitle,
    required this.current,
    required this.proposed,
    required this.curName,
    required this.propName,
    required this.ownerUserId,
    required this.guestUserId,
    required this.guestIsResponder,
    required this.ownerIsResponder,
  });

  final AppLocalizations l10n;
  final WidgetRef ref;
  final String sessionId;
  final String slot;
  final String slotTitle;
  final Map<String, dynamic> current;
  final Map<String, dynamic> proposed;
  final String curName;
  final String propName;
  final String ownerUserId;
  final String? guestUserId;
  final bool guestIsResponder;
  final bool ownerIsResponder;

  @override
  State<_SwapDecisionBody> createState() => _SwapDecisionBodyState();
}

class _SwapDecisionBodyState extends State<_SwapDecisionBody> {
  // 'accept' or 'decline' while a repo call is in flight; null = idle.
  String? _inFlight;

  Future<void> _resolve({required bool accept}) async {
    if (_inFlight != null) return;
    setState(() => _inFlight = accept ? 'accept' : 'decline');
    try {
      final repo = widget.ref.read(groupPlanningRepositoryProvider);
      if (widget.guestIsResponder) {
        await repo.guestResolveSwap(
          sessionId: widget.sessionId,
          slot: widget.slot,
          accept: accept,
          ownerUserId: widget.ownerUserId,
        );
      } else if (widget.guestUserId != null) {
        await repo.ownerResolveSwap(
          sessionId: widget.sessionId,
          slot: widget.slot,
          accept: accept,
          guestUserId: widget.guestUserId!,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _inFlight = null);
      GroupPlanningUi.showErrorSnack(context, widget.l10n, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _inFlight != null;
    return Container(
      decoration: const BoxDecoration(
        color: GroupPlanningUi.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
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
            const Text(
              '🔄',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              widget.l10n.moodMatchPlanV2SwapSheetTitle(widget.slotTitle),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GroupPlanningUi.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.l10n.moodMatchPlanV2SwapSheetMoody,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: GroupPlanningUi.forest,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.l10n.moodMatchPlanV2SwapBannerSubtitle(
                widget.propName,
                widget.curName,
              ),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: GroupPlanningUi.stone,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            _SwapActivityCard(
              activity: widget.current,
              name: widget.curName,
              label: widget.l10n.moodMatchPlanV2KeepCurrentPlace,
              background: Colors.white,
              accent: GroupPlanningUi.charcoal,
            ),
            const SizedBox(height: 8),
            _SwapActivityCard(
              activity: widget.proposed,
              name: widget.propName,
              label: widget.l10n.moodMatchPlanV2PickThis,
              background: GroupPlanningUi.forestTint,
              accent: GroupPlanningUi.forest,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _resolve(accept: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GroupPlanningUi.forest,
                      side: BorderSide(
                        color: GroupPlanningUi.forest.withValues(alpha: 0.35),
                      ),
                    ),
                    child: _inFlight == 'decline'
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: GroupPlanningUi.forest,
                            ),
                          )
                        : Text(
                            widget.ownerIsResponder
                                ? widget.l10n
                                    .moodMatchPlanV2KeepOriginal(widget.curName)
                                : widget.l10n.moodMatchPlanV2KeepCurrentPlace,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : () => _resolve(accept: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: GroupPlanningUi.forest,
                      foregroundColor: Colors.white,
                    ),
                    child: _inFlight == 'accept'
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.ownerIsResponder
                                ? widget.l10n
                                    .moodMatchPlanV2AcceptSwap(widget.propName)
                                : widget.l10n.moodMatchPlanV2UseOwnersPick,
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
  }
}

/// Tappable activity row inside the swap sheet — opens an inline preview with
/// photo + description so users can check the place before accepting.
class _SwapActivityCard extends StatelessWidget {
  const _SwapActivityCard({
    required this.activity,
    required this.name,
    required this.label,
    required this.background,
    required this.accent,
  });

  final Map<String, dynamic> activity;
  final String name;
  final String label;
  final Color background;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $name',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showActivityPreview(context, activity),
          child: Ink(
            decoration: GroupPlanningUi.softCardDecoration(background: background),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: accent.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showActivityPreview(
  BuildContext context,
  Map<String, dynamic> activity,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ActivityPreviewSheet(activity: activity),
  );
}

class _ActivityPreviewSheet extends ConsumerWidget {
  const _ActivityPreviewSheet({required this.activity});

  final Map<String, dynamic> activity;

  String get _name {
    final n = (activity['name'] ?? activity['title'] ?? '').toString().trim();
    return n;
  }

  String get _description {
    for (final k in const [
      'description',
      'summary',
      'short_description',
      'reason',
      'why',
      'explanation',
    ]) {
      final v = activity[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  String? get _address {
    for (final k in const ['address', 'formatted_address', 'vicinity']) {
      final v = activity[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  String? get _placeId {
    for (final k in const ['place_id', 'placeId', 'id']) {
      final v = activity[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.isEmpty ? l10n.moodMatchPlanV2PickThis : _name;
    final description = _description;
    final address = _address;
    final embedded = GroupPlanV2.resolveActivityImageUrl(activity);
    final placeId = _placeId;

    // Resolve photo: prefer embedded image URL; else look up via places_cache.
    final resolvedPhoto = embedded.isNotEmpty
        ? AsyncValue<String?>.data(embedded)
        : (placeId != null
            ? ref.watch(placePhotoUrlProvider(placeId))
            : const AsyncValue<String?>.data(null));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.58,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (sheetContext, scrollController) {
        return Material(
          color: GroupPlanningUi.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              16 + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: Column(
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
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: resolvedPhoto.when(
                      data: (url) {
                        final src = url?.trim() ?? '';
                        if (src.isEmpty) return _photoPlaceholder();
                        return WmPlaceOrHttpsNetworkImage(
                          src,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder(),
                        );
                      },
                      loading: () => Container(
                        color: GroupPlanningUi.forestTint,
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: GroupPlanningUi.forest,
                            ),
                          ),
                        ),
                      ),
                      error: (_, __) => _photoPlaceholder(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GroupPlanningUi.charcoal,
                  ),
                ),
                if (address != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: GroupPlanningUi.stone,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: GroupPlanningUi.stone,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: GroupPlanningUi.charcoal,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: GroupPlanningUi.forest,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Text(l10n.back),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: GroupPlanningUi.forestTint,
      child: Icon(
        Icons.image_outlined,
        size: 36,
        color: GroupPlanningUi.forest.withValues(alpha: 0.6),
      ),
    );
  }
}
