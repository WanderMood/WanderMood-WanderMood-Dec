import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';

enum DietaryOption {
  halal,
  kosher,
  vegetarian,
  vegan,
  glutenFree
}

enum InclusivityTag {
  lgbtqFriendly,
  wheelchairAccessible,
  familyFriendly,
  petFriendly
}

class Activity {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final DateTime startTime;
  final int duration;
  final String timeSlot;
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
  final TimeSlot timeSlotEnum;
  final LatLng location;
  final String? priceLevel;
  /// Google Place ID for fetching opening_hours (open_now) from Places API.
  final String? placeId;
  final List<DietaryOption> dietaryOptions;
  final List<InclusivityTag> inclusivityTags;
  int refreshCount;
  final String? groupSessionId;

  Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.startTime,
    required this.duration,
    required this.timeSlot,
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
    required this.timeSlotEnum,
    required this.location,
    this.priceLevel,
    this.placeId,
    this.refreshCount = 0,
    this.dietaryOptions = const [],
    this.inclusivityTags = const [],
    this.groupSessionId,
  });

  // Helper method to check if this activity is a restaurant or dining-related
  bool get isRestaurant => 
    tags.contains('restaurant') || 
    tags.contains('dining') || 
    name.toLowerCase().contains('restaurant') ||
    name.toLowerCase().contains('dining') ||
    tags.any((tag) => tag.toLowerCase().contains('food'));

  // Helper method to get a user-friendly name for dietary options
  String getDietaryOptionName(DietaryOption option) {
    switch (option) {
      case DietaryOption.halal:
        return 'Halal';
      case DietaryOption.kosher:
        return 'Kosher';
      case DietaryOption.vegetarian:
        return 'Vegetarian';
      case DietaryOption.vegan:
        return 'Vegan';
      case DietaryOption.glutenFree:
        return 'Gluten-Free';
    }
  }

  // Helper method to get a user-friendly name for inclusivity tags
  String getInclusivityTagName(InclusivityTag tag) {
    switch (tag) {
      case InclusivityTag.lgbtqFriendly:
        return 'LGBTQ+ Friendly';
      case InclusivityTag.wheelchairAccessible:
        return 'Wheelchair Accessible';
      case InclusivityTag.familyFriendly:
        return 'Family Friendly';
      case InclusivityTag.petFriendly:
        return 'Pet Friendly';
    }
  }

  Activity copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? rating,
    DateTime? startTime,
    int? duration,
    String? timeSlot,
    List<String>? tags,
    bool? isPaid,
    double? price,
    String? bookingUrl,
    int? availableSpots,
    int? bookedCount,
    bool? isPopular,
    String? cancellationPolicy,
    bool? hasMoneyBackGuarantee,
    PaymentType? paymentType,
    TimeSlot? timeSlotEnum,
    LatLng? location,
    String? priceLevel,
    String? placeId,
    int? refreshCount,
    List<DietaryOption>? dietaryOptions,
    List<InclusivityTag>? inclusivityTags,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      timeSlot: timeSlot ?? this.timeSlot,
      tags: tags ?? this.tags,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      availableSpots: availableSpots ?? this.availableSpots,
      bookedCount: bookedCount ?? this.bookedCount,
      isPopular: isPopular ?? this.isPopular,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      hasMoneyBackGuarantee: hasMoneyBackGuarantee ?? this.hasMoneyBackGuarantee,
      paymentType: paymentType ?? this.paymentType,
      timeSlotEnum: timeSlotEnum ?? this.timeSlotEnum,
      location: location ?? this.location,
      priceLevel: priceLevel ?? this.priceLevel,
      placeId: placeId ?? this.placeId,
      refreshCount: refreshCount ?? this.refreshCount,
      dietaryOptions: dietaryOptions ?? this.dietaryOptions,
      inclusivityTags: inclusivityTags ?? this.inclusivityTags,
    );
  }
} 