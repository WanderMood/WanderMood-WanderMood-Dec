import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Premium list card for [PlanMetVriendPlansScreen].
class PlanMetVriendPlanCard extends StatelessWidget {
  const PlanMetVriendPlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.isBusy = false,
  });

  final PlanMetVriendPlanListItem plan;
  final VoidCallback? onTap;
  final bool isBusy;

  static const double _thumbSize = 76;
  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final copy = _PlanCardCopy.build(l10n, plan, locale);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          decoration: GroupPlanningUi.moodMatchFloatingCard(radius: _radius),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PlaceThumbnail(photoUrl: plan.photoUrl, placeName: plan.placeName),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.placeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: GroupPlanningUi.charcoal,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (plan.friendLabel != null &&
                          plan.friendLabel!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _FriendRow(
                          name: plan.friendLabel!,
                          avatarUrl: plan.friendAvatarUrl,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _StatusChip(copy: copy),
                      if (copy.metadata.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          copy.metadata,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            height: 1.35,
                            color: GroupPlanningUi.stone,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _TrailingAction(
                  kind: plan.cardKind,
                  label: l10n.planMetVriendPlansOpenPlan,
                  isBusy: isBusy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCardCopy {
  const _PlanCardCopy({
    required this.chipLabel,
    required this.metadata,
    required this.kind,
  });

  final String chipLabel;
  final String metadata;
  final PlanMetVriendPlanCardKind kind;

  static _PlanCardCopy build(
    AppLocalizations l10n,
    PlanMetVriendPlanListItem plan,
    String locale,
  ) {
    final friend = plan.friendFirstName ?? plan.friendLabel?.trim();
    final dateLabel = _dateLabel(l10n, plan.plannedDate, locale);
    final slotLabel = _slotLabel(l10n, plan.timeSlot);

    final chipLabel = switch (plan.cardKind) {
      PlanMetVriendPlanCardKind.confirmed => _confirmedChip(l10n, plan, locale),
      PlanMetVriendPlanCardKind.needsReply => l10n.planMetVriendPlansChipNeedsReply,
      PlanMetVriendPlanCardKind.waiting => friend != null && friend.isNotEmpty
          ? l10n.planMetVriendPlansChipWaitingFor(friend)
          : l10n.planMetVriendPlansChipWaitingGeneric,
    };

    final parts = switch (plan.cardKind) {
      PlanMetVriendPlanCardKind.confirmed => [
          if (_isToday(plan.plannedDate))
            l10n.planMetVriendPlansTonight
          else if (dateLabel != null)
            dateLabel,
          if (slotLabel != null) slotLabel,
        ],
      PlanMetVriendPlanCardKind.needsReply => [
          if (friend != null && friend.isNotEmpty)
            l10n.planMetVriendPlansMetaFriendSuggested(friend)
          else
            l10n.planMetVriendPlansChipNeedsReply,
          if (slotLabel != null) slotLabel,
          if (dateLabel != null) dateLabel,
        ],
      PlanMetVriendPlanCardKind.waiting => [
          if (plan.isHost)
            l10n.planMetVriendPlansMetaInviteSent
          else if (friend != null && friend.isNotEmpty)
            l10n.planMetVriendPlansMetaWaitingOnFriend(friend)
          else
            l10n.planMetVriendPlansMetaInviteSent,
          if (slotLabel != null) slotLabel,
          if (dateLabel != null) dateLabel,
        ],
    };

    return _PlanCardCopy(
      chipLabel: chipLabel,
      metadata: parts.join(' · '),
      kind: plan.cardKind,
    );
  }

  static String _confirmedChip(
    AppLocalizations l10n,
    PlanMetVriendPlanListItem plan,
    String locale,
  ) {
    if (_isToday(plan.plannedDate)) {
      return l10n.planMetVriendPlansChipConfirmedTonight;
    }
    final label = _dateLabel(l10n, plan.plannedDate, locale);
    if (label != null) {
      return l10n.planMetVriendPlansChipConfirmedFor(label);
    }
    return l10n.planMetVriendPlansChipConfirmedTonight;
  }

  static bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool _isTomorrow(DateTime date) {
    final t = DateTime.now();
    final tomorrow = DateTime(t.year, t.month, t.day + 1);
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  static String? _dateLabel(
    AppLocalizations l10n,
    DateTime? date,
    String locale,
  ) {
    if (date == null) return null;
    final d = DateTime(date.year, date.month, date.day);
    if (_isToday(d)) return l10n.planMetVriendPlansTonight;
    if (_isTomorrow(d)) return l10n.planMetVriendDateTomorrow;
    return DateFormat.MMMd(locale).format(d);
  }

  static String? _slotLabel(AppLocalizations l10n, String? slot) {
    switch (slot) {
      case 'morning':
        return l10n.planMetVriendPlansSlotMorning;
      case 'afternoon':
        return l10n.planMetVriendPlansSlotAfternoon;
      case 'evening':
        return l10n.planMetVriendPlansSlotEvening;
      default:
        return null;
    }
  }
}

class _PlaceThumbnail extends StatelessWidget {
  const _PlaceThumbnail({
    required this.photoUrl,
    required this.placeName,
  });

  final String? photoUrl;
  final String placeName;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: PlanMetVriendPlanCard._thumbSize,
        height: PlanMetVriendPlanCard._thumbSize,
        child: url != null && url.isNotEmpty
            ? WmPlacePhotoNetworkImage(
                url,
                fit: BoxFit.cover,
                width: PlanMetVriendPlanCard._thumbSize,
                height: PlanMetVriendPlanCard._thumbSize,
              )
            : ColoredBox(
                color: GroupPlanningUi.forestTint,
                child: Icon(
                  Icons.place_rounded,
                  size: 32,
                  color: GroupPlanningUi.forest.withValues(alpha: 0.55),
                ),
              ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.name,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final url = avatarUrl?.trim();

    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 22,
            height: 22,
            child: url != null && url.isNotEmpty
                ? WmNetworkImage(url, fit: BoxFit.cover)
                : ColoredBox(
                    color: GroupPlanningUi.forestTint,
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: GroupPlanningUi.forest,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: GroupPlanningUi.dusk,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.copy});

  final _PlanCardCopy copy;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (copy.kind) {
      PlanMetVriendPlanCardKind.confirmed => (
          GroupPlanningUi.forest,
          Colors.white,
          Icons.check_rounded,
        ),
      PlanMetVriendPlanCardKind.needsReply => (
          const Color(0xFFF3E8CF),
          const Color(0xFF7A5E28),
          Icons.help_outline_rounded,
        ),
      PlanMetVriendPlanCardKind.waiting => (
          GroupPlanningUi.moodMatchTabActiveOrange.withValues(alpha: 0.14),
          GroupPlanningUi.moodMatchTabActiveOrange,
          Icons.schedule_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              copy.chipLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({
    required this.kind,
    required this.label,
    required this.isBusy,
  });

  final PlanMetVriendPlanCardKind kind;
  final String label;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (kind == PlanMetVriendPlanCardKind.confirmed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GroupPlanningUi.forestTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GroupPlanningUi.forest.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: GroupPlanningUi.forest,
          ),
        ),
      );
    }

    return Icon(
      Icons.chevron_right_rounded,
      color: GroupPlanningUi.forest.withValues(alpha: 0.85),
      size: 28,
    );
  }
}
