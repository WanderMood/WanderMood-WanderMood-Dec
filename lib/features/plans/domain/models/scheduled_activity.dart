import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';

/// Domain model representing an activity that has been scheduled
/// for a specific calendar date.
class ScheduledActivity {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final DateTime startTime;
  final int duration;
  final String timeSlot;
  final TimeSlot timeSlotEnum;
  final List<String> tags;
  final bool isPaid;
  final double? price;
  final String? bookingUrl;
  final int? availableSpots;
  final int? bookedCount;
  final bool isPopular;
  final String? cancellationPolicy;
  final bool hasMoneyBackGuarantee;
  final PaymentType paymentType;
  final LatLng location;
  final String? priceLevel;
  final String? placeId;

  /// The calendar date this activity is scheduled for (date-only semantics).
  final DateTime scheduledDate;

  const ScheduledActivity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.startTime,
    required this.duration,
    required this.timeSlot,
    required this.timeSlotEnum,
    required this.tags,
    this.isPaid = false,
    this.price,
    this.bookingUrl,
    this.availableSpots,
    this.bookedCount,
    this.isPopular = false,
    this.cancellationPolicy,
    this.hasMoneyBackGuarantee = false,
    this.paymentType = PaymentType.free,
    required this.location,
    this.priceLevel,
    this.placeId,
    required this.scheduledDate,
  });

  /// True if this activity is scheduled for "today" in the user's local time.
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  /// True if this activity's scheduled calendar date is strictly before today.
  bool get isPast {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final scheduledDateOnly =
        DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    return scheduledDateOnly.isBefore(todayDateOnly);
  }
}

