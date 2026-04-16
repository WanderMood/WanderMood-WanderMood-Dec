import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/utils/moody_toast.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Persists an Explore-style [Place] into `scheduled_activities` (same shape as Explore).
/// Returns `true` when a new row was inserted.
Future<bool> saveExplorePlaceToMyDay({
  required BuildContext context,
  required WidgetRef ref,
  required Place place,
  required DateTime startTime,
  required int photoSelectionSeed,
}) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    if (context.mounted) {
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.myDayAddSignInRequired,
        isError: true,
      );
    }
    return false;
  }

  try {
    final hour = startTime.hour;
    final timeOfDay = (hour >= 6 && hour < 12)
        ? 'morning'
        : (hour >= 12 && hour < 17)
            ? 'afternoon'
            : 'evening';
    final timeSlotEnum = timeOfDay == 'morning'
        ? TimeSlot.morning
        : timeOfDay == 'afternoon'
            ? TimeSlot.afternoon
            : TimeSlot.evening;

    var paymentType = PaymentType.free;
    if (place.types.any((t) =>
        ['restaurant', 'spa', 'museum', 'tourist_attraction'].contains(t))) {
      paymentType = PaymentType.reservation;
    }

    var duration = 60;
    for (final type in place.types) {
      final t = type.toLowerCase();
      if (['museum', 'tourist_attraction', 'amusement_park'].contains(t)) {
        duration = 120;
        break;
      } else if (['store', 'shopping_mall'].contains(t)) {
        duration = 90;
        break;
      }
    }

    final photoIdx = place.photos.isNotEmpty
        ? (place.id.hashCode.abs() + photoSelectionSeed) % place.photos.length
        : 0;
    final imageUrl = place.photos.isNotEmpty
        ? place.photos[photoIdx]
        : 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80';

    final l10n = AppLocalizations.of(context)!;
    final activity = Activity(
      id: 'place_${place.id}_${MoodyClock.now().millisecondsSinceEpoch}',
      name: place.name,
      description: place.description ??
          l10n.explorePlaceDescriptionFallback(place.name),
      imageUrl: imageUrl,
      rating: place.rating > 0 ? place.rating : 4.5,
      startTime: startTime,
      duration: duration,
      timeSlot: timeOfDay,
      timeSlotEnum: timeSlotEnum,
      tags: place.types.isNotEmpty ? place.types : ['explore'],
      location: LatLng(place.location.lat, place.location.lng),
      paymentType: paymentType,
      priceLevel: place.priceRange,
      placeId: place.id,
    );

    final scheduledActivityService =
        ref.read(scheduledActivityServiceProvider);
    final inserted = await scheduledActivityService.saveScheduledActivities(
      [activity],
      isConfirmed: false,
    );
    if (inserted == 0) {
      if (context.mounted) {
        showMoodyToast(context, l10n.exploreAlreadyInDayPlan);
      }
      return false;
    }

    final selectedDay =
        DateTime(startTime.year, startTime.month, startTime.day);
    ref.read(selectedMyDayDateProvider.notifier).state = selectedDay;
    ref.invalidate(scheduledActivityServiceProvider);
    ref.invalidate(scheduledActivitiesForTodayProvider);
    ref.invalidate(todayActivitiesProvider);
    ref.invalidate(cachedActivitySuggestionsProvider);

    if (context.mounted) {
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.dayPlanCardAddedToMyDay(place.name),
        duration: const Duration(seconds: 3),
        actionLabel: AppLocalizations.of(context)!.activityOptionsViewAction,
        onAction: () {
          if (context.mounted) {
            context.go('/main', extra: {
              'tab': 0,
              'refresh': true,
              'targetDate': selectedDay.toIso8601String(),
            });
          }
        },
      );
    }
    return true;
  } catch (e) {
    debugPrint('saveExplorePlaceToMyDay: $e');
    if (context.mounted) {
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.myDayAddFailedTryAgain,
        isError: true,
      );
    }
    return false;
  }
}
