import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_with_friend_launcher.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/plan_with_friend_bottom_sheet.dart';

/// Deep-link host: opens plan-with-friend sheet then returns.
class PlanWithFriendRouteHost extends StatefulWidget {
  const PlanWithFriendRouteHost({super.key, required this.args});

  final PlanWithFriendArgs args;

  @override
  State<PlanWithFriendRouteHost> createState() => _PlanWithFriendRouteHostState();
}

class _PlanWithFriendRouteHostState extends State<PlanWithFriendRouteHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (!mounted) return;
    await showPlanWithFriendBottomSheet(context, args: widget.args);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}
