import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/features/wishlist/data/extract_place_from_url_service.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/plan_with_friend_bottom_sheet.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class PlanWithFriendArgs {
  const PlanWithFriendArgs({
    required this.placeId,
    required this.placeName,
    this.place,
    this.placeData,
    this.sourceUrl,
    this.onAddToMyDay,
  });

  final String placeId;
  final String placeName;
  final Place? place;
  final Map<String, dynamic>? placeData;
  final String? sourceUrl;
  final VoidCallback? onAddToMyDay;

  factory PlanWithFriendArgs.fromPlace(
    Place place, {
    String? sourceUrl,
    VoidCallback? onAddToMyDay,
  }) {
    return PlanWithFriendArgs(
      placeId: place.id,
      placeName: place.name,
      place: place,
      placeData: SavedPlacesService.encodePlaceDataRow(place),
      sourceUrl: sourceUrl,
      onAddToMyDay: onAddToMyDay,
    );
  }

  factory PlanWithFriendArgs.fromExtracted(
    ExtractedPlacePayload payload, {
    required String sourceUrl,
    VoidCallback? onAddToMyDay,
  }) {
    return PlanWithFriendArgs(
      placeId: payload.placeId,
      placeName: payload.placeName,
      placeData: payload.placeData,
      sourceUrl: sourceUrl,
      onAddToMyDay: onAddToMyDay,
    );
  }
}

/// Opens the compact plan-with-friend bottom sheet over the current screen.
void openPlanWithFriend(BuildContext context, PlanWithFriendArgs args) {
  final l10n = AppLocalizations.of(context)!;
  if (Supabase.instance.client.auth.currentUser == null) {
    showWanderMoodToast(context, message: l10n.planMetVriendLoginRequired);
    context.push('/auth/magic-link');
    return;
  }
  showPlanWithFriendBottomSheet(context, args: args);
}

/// @deprecated Use [openPlanWithFriend] — kept for call sites not yet migrated.
void openPlanWithFriendScreen(BuildContext context, PlanWithFriendArgs args) {
  openPlanWithFriend(context, args);
}
