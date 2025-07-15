import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:math' as math;

part 'place.freezed.dart';
part 'place.g.dart';

@freezed
class Place with _$Place {
  const factory Place({
    required String placeId,
    required String name,
    required String formattedAddress,
    required PlaceGeometry geometry,
    @Default([]) List<String> types,
    String? vicinity,
    double? rating,
    int? userRatingsTotal,
    int? priceLevel,
    String? website,
    String? phoneNumber,
    PlaceOpeningHours? openingHours,
    @Default([]) List<PlacePhoto> photos,
    @Default([]) List<PlaceReview> reviews,
    String? businessStatus,
    bool? permanentlyClosed,
    @Default([]) List<String> photoUrls,
  }) = _Place;

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
}

@freezed
class PlaceGeometry with _$PlaceGeometry {
  const factory PlaceGeometry({
    required PlaceLocation location,
    PlaceViewport? viewport,
  }) = _PlaceGeometry;

  factory PlaceGeometry.fromJson(Map<String, dynamic> json) => _$PlaceGeometryFromJson(json);
}

@freezed
class PlaceLocation with _$PlaceLocation {
  const factory PlaceLocation({
    required double lat,
    required double lng,
  }) = _PlaceLocation;

  factory PlaceLocation.fromJson(Map<String, dynamic> json) => _$PlaceLocationFromJson(json);
}

@freezed
class PlaceViewport with _$PlaceViewport {
  const factory PlaceViewport({
    required PlaceLocation northeast,
    required PlaceLocation southwest,
  }) = _PlaceViewport;

  factory PlaceViewport.fromJson(Map<String, dynamic> json) => _$PlaceViewportFromJson(json);
}

@freezed
class PlacePhoto with _$PlacePhoto {
  const factory PlacePhoto({
    required int height,
    required int width,
    required String photoReference,
    @Default([]) List<String> htmlAttributions,
  }) = _PlacePhoto;

  factory PlacePhoto.fromJson(Map<String, dynamic> json) => _$PlacePhotoFromJson(json);
}

@freezed
class PlaceOpeningHours with _$PlaceOpeningHours {
  const factory PlaceOpeningHours({
    required bool openNow,
    @Default([]) List<String> weekdayText,
    @Default([]) List<PlaceOpeningPeriod> periods,
  }) = _PlaceOpeningHours;

  factory PlaceOpeningHours.fromJson(Map<String, dynamic> json) => _$PlaceOpeningHoursFromJson(json);
}

@freezed
class PlaceOpeningPeriod with _$PlaceOpeningPeriod {
  const factory PlaceOpeningPeriod({
    PlaceOpeningTime? open,
    PlaceOpeningTime? close,
  }) = _PlaceOpeningPeriod;

  factory PlaceOpeningPeriod.fromJson(Map<String, dynamic> json) => _$PlaceOpeningPeriodFromJson(json);
}

@freezed
class PlaceOpeningTime with _$PlaceOpeningTime {
  const factory PlaceOpeningTime({
    required int day,
    required String time,
  }) = _PlaceOpeningTime;

  factory PlaceOpeningTime.fromJson(Map<String, dynamic> json) => _$PlaceOpeningTimeFromJson(json);
}

@freezed
class PlaceReview with _$PlaceReview {
  const factory PlaceReview({
    required String authorName,
    required int rating,
    required String text,
    required DateTime time,
    String? authorUrl,
    String? profilePhotoUrl,
    String? language,
  }) = _PlaceReview;

  factory PlaceReview.fromJson(Map<String, dynamic> json) => _$PlaceReviewFromJson(json);
}

@freezed
class PlaceAutocomplete with _$PlaceAutocomplete {
  const factory PlaceAutocomplete({
    required String placeId,
    required String description,
    @Default([]) List<String> types,
    @Default([]) List<PlaceAutocompleteTerm> terms,
    @Default([]) List<PlaceAutocompleteMatchedSubstring> matchedSubstrings,
    String? reference,
    PlaceStructuredFormatting? structuredFormatting,
  }) = _PlaceAutocomplete;

  factory PlaceAutocomplete.fromJson(Map<String, dynamic> json) => _$PlaceAutocompleteFromJson(json);
}

@freezed
class PlaceAutocompleteTerm with _$PlaceAutocompleteTerm {
  const factory PlaceAutocompleteTerm({
    required int offset,
    required String value,
  }) = _PlaceAutocompleteTerm;

  factory PlaceAutocompleteTerm.fromJson(Map<String, dynamic> json) => _$PlaceAutocompleteTermFromJson(json);
}

@freezed
class PlaceAutocompleteMatchedSubstring with _$PlaceAutocompleteMatchedSubstring {
  const factory PlaceAutocompleteMatchedSubstring({
    required int length,
    required int offset,
  }) = _PlaceAutocompleteMatchedSubstring;

  factory PlaceAutocompleteMatchedSubstring.fromJson(Map<String, dynamic> json) => _$PlaceAutocompleteMatchedSubstringFromJson(json);
}

@freezed
class PlaceStructuredFormatting with _$PlaceStructuredFormatting {
  const factory PlaceStructuredFormatting({
    required String mainText,
    required String secondaryText,
    @Default([]) List<PlaceAutocompleteMatchedSubstring> mainTextMatchedSubstrings,
    @Default([]) List<PlaceAutocompleteMatchedSubstring> secondaryTextMatchedSubstrings,
  }) = _PlaceStructuredFormatting;

  factory PlaceStructuredFormatting.fromJson(Map<String, dynamic> json) => _$PlaceStructuredFormattingFromJson(json);
}

// Extension methods for business logic
extension PlaceExtension on Place {
  /// Get a formatted price level string
  String get formattedPriceLevel {
    switch (priceLevel) {
      case 0:
        return 'Free';
      case 1:
        return 'Inexpensive';
      case 2:
        return 'Moderate';
      case 3:
        return 'Expensive';
      case 4:
        return 'Very Expensive';
      default:
        return 'Price not available';
    }
  }

  /// Get formatted rating with stars
  String get formattedRating {
    if (rating == null) return 'No rating';
    final stars = '★' * rating!.round() + '☆' * (5 - rating!.round());
    return '$stars (${rating!.toStringAsFixed(1)})';
  }

  /// Check if the place is currently open
  bool get isOpen {
    return openingHours?.openNow ?? false;
  }

  /// Get primary place type
  String get primaryType {
    if (types.isEmpty) return 'Place';
    final typeMap = {
      'restaurant': 'Restaurant',
      'tourist_attraction': 'Tourist Attraction',
      'lodging': 'Hotel',
      'gas_station': 'Gas Station',
      'hospital': 'Hospital',
      'pharmacy': 'Pharmacy',
      'bank': 'Bank',
      'atm': 'ATM',
      'shopping_mall': 'Shopping Mall',
      'park': 'Park',
      'museum': 'Museum',
      'church': 'Church',
      'airport': 'Airport',
      'subway_station': 'Subway Station',
      'bus_station': 'Bus Station',
    };
    
    for (final type in types) {
      if (typeMap.containsKey(type)) {
        return typeMap[type]!;
      }
    }
    
    return types.first.replaceAll('_', ' ').split(' ').map((word) => 
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  /// Get the best photo URL
  String? get bestPhotoUrl {
    if (photoUrls.isNotEmpty) return photoUrls.first;
    return null;
  }

  /// Calculate distance from given coordinates (rough estimate)
  double distanceFromLocation(double lat, double lng) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat - geometry.location.lat);
    final double dLng = _degreesToRadians(lng - geometry.location.lng);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(geometry.location.lat)) * math.cos(_degreesToRadians(lat)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
} 