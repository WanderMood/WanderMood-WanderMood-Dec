import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/features/wishlist/presentation/screens/availability_picker_screen.dart';
import 'package:wandermood/features/wishlist/presentation/screens/match_found_screen.dart';

void _push<T extends Widget>(BuildContext context, T screen) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => screen),
  );
}

void openAvailabilityPicker(
  BuildContext context, {
  required PlanMetVriendFriend friend,
  required PlanMetVriendPlace place,
}) {
  _push(
    context,
    AvailabilityPickerScreen(friend: friend, place: place),
  );
}

void openPlanMetVriendDayPicker(BuildContext context, String sessionId) {
  context.pushNamed(
    'wishlist-day-picker',
    pathParameters: {'sessionId': sessionId},
  );
}

void openMatchFound(BuildContext context, PlanMetVriendMatchArgs args) {
  _push(context, MatchFoundScreen(args: args));
}
