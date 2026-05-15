import 'package:flutter/material.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_with_friend_launcher.dart';

const _wmForest = Color(0xFF2A6049);

/// Small 👥 control for Explore / My Day place cards.
class PlanWithFriendIconButton extends StatelessWidget {
  const PlanWithFriendIconButton({
    super.key,
    required this.place,
    this.size = 36,
  });

  final Place place;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => openPlanWithFriendScreen(
          context,
          PlanWithFriendArgs.fromPlace(place),
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(
            Icons.groups_outlined,
            size: 18,
            color: _wmForest,
          ),
        ),
      ),
    );
  }
}
