import 'package:freezed_annotation/freezed_annotation.dart';

part 'place.freezed.dart';
part 'place.g.dart';

@freezed
class Place with _$Place {
  const factory Place({
    required String id,
    required String name,
    required String address,
    @Default(0.0) double rating,
    @Default([]) List<String> photos,
    @Default([]) List<String> types,
    required PlaceLocation location,
    String? description,
    String? emoji,
    String? tag,
    @Default(false) bool isAsset,
    @Default([]) List<String> activities,
    DateTime? dateAdded,
    PlaceOpeningHours? openingHours,
    // New fields for enhanced place cards
    @Default(0) int reviewCount,
    @Default('Medium') String energyLevel, // Low, Medium, High
    @Default(false) bool isIndoor,
    // Pricing information
    int? priceLevel, // 0=Free, 1=€1-15, 2=€15-30, 3=€30-50, 4=€50+
    String? priceRange, // e.g., "€10-25", "FREE", "€50+"
    @Default(false) bool isFree,
  }) = _Place;

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
}

@freezed
class PlaceLocation with _$PlaceLocation {
  const factory PlaceLocation({
    required double lat,
    required double lng,
  }) = _PlaceLocation;

  factory PlaceLocation.fromJson(Map<String, dynamic> json) => 
      _$PlaceLocationFromJson(json);
}

@freezed
class PlaceOpeningHours with _$PlaceOpeningHours {
  const factory PlaceOpeningHours({
    required bool isOpen,
    String? currentStatus,
    @Default([]) List<String> weekdayText,
    DailyHours? todayHours,
  }) = _PlaceOpeningHours;

  factory PlaceOpeningHours.fromJson(Map<String, dynamic> json) => 
      _$PlaceOpeningHoursFromJson(json);
}

@freezed
class DailyHours with _$DailyHours {
  const factory DailyHours({
    required String openTime,
    required String closeTime,
    @Default(false) bool isOpenAllDay,
    @Default(false) bool isClosed,
  }) = _DailyHours;

  factory DailyHours.fromJson(Map<String, dynamic> json) => 
      _$DailyHoursFromJson(json);
} 