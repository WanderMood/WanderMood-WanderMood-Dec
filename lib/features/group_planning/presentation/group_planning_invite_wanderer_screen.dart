import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_invite_wanderer_panel.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Search WanderMood profiles by username and send an in-app Mood Match invite.
class GroupPlanningInviteWandererScreen extends ConsumerStatefulWidget {
  const GroupPlanningInviteWandererScreen({
    super.key,
    required this.sessionId,
    required this.joinCode,
  });

  final String sessionId;
  final String joinCode;

  @override
  ConsumerState<GroupPlanningInviteWandererScreen> createState() =>
      _GroupPlanningInviteWandererScreenState();
}

class _GroupPlanningInviteWandererScreenState
    extends ConsumerState<GroupPlanningInviteWandererScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: GroupPlanningUi.cream,
      appBar: AppBar(
        backgroundColor: GroupPlanningUi.cream,
        elevation: 0,
        foregroundColor: GroupPlanningUi.charcoal,
        title: Text(
          l10n.moodMatchInviteTitle,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: GroupPlanningUi.charcoal,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.moodMatchInviteSubtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.35,
                  color: GroupPlanningUi.stone,
                ),
              ),
              const SizedBox(height: 16),
              GroupPlanningInviteWandererPanel(
                sessionId: widget.sessionId,
                joinCode: widget.joinCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
