import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart'
    show GroupMemberView;
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Compact row when both users have agreed on a slot: avatars + “You’re both in”.
class GroupPlanningResultSlotBothInFooter extends StatelessWidget {
  const GroupPlanningResultSlotBothInFooter({
    super.key,
    required this.l10n,
    required this.isOwner,
    required this.ownerMember,
    required this.guestMember,
    required this.ownerName,
    required this.guestName,
  });

  final AppLocalizations l10n;
  final bool isOwner;
  final GroupMemberView? ownerMember;
  final GroupMemberView? guestMember;
  final String ownerName;
  final String guestName;

  static const _slotCardBodyInk = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    Widget face(GroupMemberView? m) {
      final url = m?.avatarUrl?.trim();
      final label = (m?.displayName ?? '?').trim();
      final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: CircleAvatar(
          radius: 13,
          backgroundColor: GroupPlanningUi.forest,
          backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
          child: url == null || url.isEmpty
              ? Text(
                  initial,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                )
              : null,
        ),
      );
    }

    final caption = isOwner
        ? l10n.moodMatchPlanV2YouBothIn(guestName)
        : l10n.moodMatchPlanV2YouBothIn(ownerName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DFD4)),
      ),
      child: Row(
        children: [
          face(ownerMember),
          Transform.translate(
            offset: const Offset(-8, 0),
            child: face(guestMember),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: _slotCardBodyInk.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
