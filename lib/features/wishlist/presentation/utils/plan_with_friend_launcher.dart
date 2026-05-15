import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/features/wishlist/data/extract_place_from_url_service.dart';

class PlanWithFriendArgs {
  const PlanWithFriendArgs({
    required this.placeId,
    required this.placeName,
    this.place,
    this.placeData,
    this.sourceUrl,
  });

  final String placeId;
  final String placeName;
  final Place? place;
  final Map<String, dynamic>? placeData;
  final String? sourceUrl;

  factory PlanWithFriendArgs.fromPlace(Place place, {String? sourceUrl}) {
    return PlanWithFriendArgs(
      placeId: place.id,
      placeName: place.name,
      place: place,
      placeData: SavedPlacesService.encodePlaceDataRow(place),
      sourceUrl: sourceUrl,
    );
  }

  factory PlanWithFriendArgs.fromExtracted(
    ExtractedPlacePayload payload, {
    required String sourceUrl,
  }) {
    return PlanWithFriendArgs(
      placeId: payload.placeId,
      placeName: payload.placeName,
      placeData: payload.placeData,
      sourceUrl: sourceUrl,
    );
  }
}

void openPlanWithFriendScreen(BuildContext context, PlanWithFriendArgs args) {
  context.push('/wishlist/plan', extra: args);
}
