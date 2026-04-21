import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_invite_wanderer_panel.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
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
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: GroupPlanningUi.moodMatchDeep,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, topInset + 26, 16, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GroupPlanningUi.moodMatchDeepSurface,
                      GroupPlanningUi.moodMatchDeep,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const MoodyCharacter(size: 50, mood: 'happy'),
                    const SizedBox(height: 10),
                    Text(
                      l10n.moodMatchInviteTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: topInset + 4,
                left: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
          Expanded(
            child: Material(
              color: GroupPlanningUi.cream,
              elevation: 8,
              shadowColor: GroupPlanningUi.moodMatchShadow(0.35),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: GroupPlanningUi.stone.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
          ),
        ],
      ),
    );
  }
}
