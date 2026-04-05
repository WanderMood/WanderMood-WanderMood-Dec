import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';

/// Converts a plan [Activity] to a [Place] so the same PlaceCard design
/// can be used on the Day Plan screen (Explore-style cards).
/// [Place] for Moody blurbs and Places details (uses [Activity.placeId] when set).
Place placeForMoodyBlurb(Activity activity, {String? locationLabel}) {
  final pid = activity.placeId?.trim();
  final id = (pid != null && pid.isNotEmpty)
      ? (pid.startsWith('google_') ? pid : 'google_$pid')
      : activity.id;
  return Place(
    id: id,
    name: activity.name,
    address: (locationLabel ?? '').trim(),
    rating: activity.rating,
    photos: activity.imageUrl.isNotEmpty ? [activity.imageUrl] : const [],
    types: activity.tags.isNotEmpty ? activity.tags : const ['point_of_interest'],
    location: PlaceLocation(
      lat: activity.location.latitude,
      lng: activity.location.longitude,
    ),
    description: activity.description,
    priceRange: activity.priceLevel,
    isFree: activity.paymentType == PaymentType.free,
    priceLevel: activity.paymentType == PaymentType.free
        ? 0
        : activity.paymentType == PaymentType.reservation
            ? 2
            : 1,
  );
}

Place activityToPlace(Activity activity) {
  return Place(
    id: activity.id,
    name: activity.name,
    address: activity.description,
    rating: activity.rating,
    photos: activity.imageUrl.isNotEmpty ? [activity.imageUrl] : [],
    types: activity.tags.isNotEmpty ? activity.tags : ['activity'],
    location: PlaceLocation(
      lat: activity.location.latitude,
      lng: activity.location.longitude,
    ),
    description: activity.description,
    priceRange: activity.priceLevel,
    isFree: activity.paymentType == PaymentType.free,
    priceLevel: activity.paymentType == PaymentType.free
        ? 0
        : activity.paymentType == PaymentType.reservation
            ? 2
            : 1,
  );
}
