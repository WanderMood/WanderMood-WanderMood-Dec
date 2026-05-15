import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_with_friend_launcher.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/plan_with_friend_bottom_sheet.dart'
    show PlanWithFriendBottomSheet;

/// Full-screen friend invite (not a bottom sheet over Explore).
class PlanWithFriendInviteScreen extends StatelessWidget {
  const PlanWithFriendInviteScreen({super.key, required this.args});

  final PlanWithFriendArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GroupPlanningUi.cream,
      appBar: AppBar(
        backgroundColor: GroupPlanningUi.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: GroupPlanningUi.charcoal,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Plan met vriend',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: GroupPlanningUi.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: PlanWithFriendBottomSheet(args: args, fullScreen: true),
    );
  }
}
