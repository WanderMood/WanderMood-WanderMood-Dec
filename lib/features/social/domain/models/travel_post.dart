import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_post.freezed.dart';
part 'travel_post.g.dart';

@freezed
class TravelPost with _$TravelPost {
  const factory TravelPost({
    required String id,
    required String userId,
    String? title,
    required String story,
    required String mood,
    String? location,
    LocationDetails? locationDetails,
    WeatherData? weatherData,
    @Default([]) List<String> tags,
    @Default([]) List<String> photos,
    @Default([]) List<String> activities,
    @Default([]) List<String> travelCompanions,
    double? budgetSpent,
    @Default('EUR') String currencyCode,
    int? rating,
    String? travelTips,
    String? bestTimeToVisit,
    @Default('public') String privacyLevel,
    String? featuredPhotoUrl,
    @Default(0) int viewCount,
    @Default(0) int shareCount,
    @Default(0) int likesCount,
    @Default(0) int reactionsCount,
    @Default(0) int commentsCount,
    double? totalExpenses,
    @Default([]) List<ItineraryItem> itinerary,
    @Default([]) List<TravelExpense> expenses,
    @Default([]) List<PostReaction> reactions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TravelPost;

  factory TravelPost.fromJson(Map<String, dynamic> json) =>
      _$TravelPostFromJson(json);
}

@freezed
class LocationDetails with _$LocationDetails {
  const factory LocationDetails({
    String? placeId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? country,
    String? city,
    String? region,
    @Default([]) List<String> types, // restaurant, tourist_attraction, etc.
    double? rating,
    String? priceLevel,
    String? website,
    String? phoneNumber,
    Map<String, dynamic>? openingHours,
  }) = _LocationDetails;

  factory LocationDetails.fromJson(Map<String, dynamic> json) =>
      _$LocationDetailsFromJson(json);
}

@freezed
class WeatherData with _$WeatherData {
  const factory WeatherData({
    required double temperature,
    required String condition, // sunny, cloudy, rainy, etc.
    String? description,
    double? humidity,
    double? windSpeed,
    String? windDirection,
    double? pressure,
    double? visibility,
    String? icon,
    DateTime? timestamp,
  }) = _WeatherData;

  factory WeatherData.fromJson(Map<String, dynamic> json) =>
      _$WeatherDataFromJson(json);
}

@freezed
class ItineraryItem with _$ItineraryItem {
  const factory ItineraryItem({
    required String id,
    required String title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? startTime,
    DateTime? endTime,
    double? cost,
    String? category, // restaurant, attraction, accommodation, transport
    int? rating,
    @Default([]) List<String> photos,
    String? tips,
    String? bookingUrl,
    @Default(0) int orderIndex,
  }) = _ItineraryItem;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) =>
      _$ItineraryItemFromJson(json);
}

@freezed
class TravelExpense with _$TravelExpense {
  const factory TravelExpense({
    required String id,
    required String category, // food, transport, accommodation, activities, shopping
    String? description,
    required double amount,
    @Default('EUR') String currencyCode,
    DateTime? date,
    String? location,
    String? receiptUrl,
  }) = _TravelExpense;

  factory TravelExpense.fromJson(Map<String, dynamic> json) =>
      _$TravelExpenseFromJson(json);
}

@freezed
class PostReaction with _$PostReaction {
  const factory PostReaction({
    required String id,
    required String userId,
    required String type, // love, wow, wanderlust, helpful, inspiring
    DateTime? createdAt,
  }) = _PostReaction;

  factory PostReaction.fromJson(Map<String, dynamic> json) =>
      _$PostReactionFromJson(json);
}

// Extensions for business logic
extension TravelPostX on TravelPost {
  bool get hasLocation => location?.isNotEmpty == true;
  bool get hasPhotos => photos.isNotEmpty;
  bool get hasWeather => weatherData != null;
  bool get hasItinerary => itinerary.isNotEmpty;
  bool get hasExpenses => expenses.isNotEmpty;
  bool get isRated => rating != null && rating! > 0;
  bool get isPublic => privacyLevel == 'public';
  bool get hasBudget => budgetSpent != null && budgetSpent! > 0;
  
  String get formattedBudget {
    if (budgetSpent == null) return '';
    return '${budgetSpent!.toStringAsFixed(0)} $currencyCode';
  }
  
  String get readablePrivacy {
    switch (privacyLevel) {
      case 'public': return 'Public';
      case 'friends': return 'Friends only';
      case 'private': return 'Private';
      default: return 'Public';
    }
  }
  
  double get totalCostFromItinerary {
    return itinerary
        .where((item) => item.cost != null)
        .fold(0.0, (sum, item) => sum + item.cost!);
  }
  
  double get totalExpensesAmount {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }
  
  // Get the primary photo for display
  String? get primaryPhoto {
    if (featuredPhotoUrl?.isNotEmpty == true) return featuredPhotoUrl;
    if (photos.isNotEmpty) return photos.first;
    return null;
  }
  
  // Calculate engagement score
  double get engagementScore {
    return (likesCount * 1.0) + 
           (reactionsCount * 1.5) + 
           (commentsCount * 2.0) + 
           (shareCount * 3.0) +
           (viewCount * 0.1);
  }
}

// Helper for mapping database fields
extension TravelPostFromDatabase on TravelPost {
  static TravelPost fromDatabase(Map<String, dynamic> data) {
    return TravelPost(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      title: data['title'] as String?,
      story: data['story'] as String,
      mood: data['mood'] as String,
      location: data['location'] as String?,
      locationDetails: data['location_details'] != null
          ? LocationDetails.fromJson(data['location_details'])
          : null,
      weatherData: data['weather_data'] != null
          ? WeatherData.fromJson(data['weather_data'])
          : null,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      photos: (data['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      activities: (data['activities'] as List<dynamic>?)?.cast<String>() ?? [],
      travelCompanions: (data['travel_companions'] as List<dynamic>?)?.cast<String>() ?? [],
      budgetSpent: data['budget_spent']?.toDouble(),
      currencyCode: data['currency_code'] as String? ?? 'EUR',
      rating: data['rating'] as int?,
      travelTips: data['travel_tips'] as String?,
      bestTimeToVisit: data['best_time_to_visit'] as String?,
      privacyLevel: data['privacy_level'] as String? ?? 'public',
      featuredPhotoUrl: data['featured_photo_url'] as String?,
      viewCount: data['view_count'] as int? ?? 0,
      shareCount: data['share_count'] as int? ?? 0,
      likesCount: data['likes_count'] as int? ?? 0,
      reactionsCount: data['reactions_count'] as int? ?? 0,
      commentsCount: data['comments_count'] as int? ?? 0,
      totalExpenses: data['total_expenses']?.toDouble(),
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : null,
      updatedAt: data['updated_at'] != null 
          ? DateTime.parse(data['updated_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'story': story,
      'mood': mood,
      'location': location,
      'location_details': locationDetails?.toJson(),
      'weather_data': weatherData?.toJson(),
      'tags': tags,
      'photos': photos,
      'activities': activities,
      'travel_companions': travelCompanions,
      'budget_spent': budgetSpent,
      'currency_code': currencyCode,
      'rating': rating,
      'travel_tips': travelTips,
      'best_time_to_visit': bestTimeToVisit,
      'privacy_level': privacyLevel,
      'featured_photo_url': featuredPhotoUrl,
      'view_count': viewCount,
      'share_count': shareCount,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

// Create post request model
@freezed
class CreateTravelPostRequest with _$CreateTravelPostRequest {
  const factory CreateTravelPostRequest({
    String? title,
    required String story,
    required String mood,
    String? location,
    LocationDetails? locationDetails,
    @Default([]) List<String> tags,
    @Default([]) List<String> activities,
    @Default([]) List<String> travelCompanions,
    double? budgetSpent,
    @Default('EUR') String currencyCode,
    int? rating,
    String? travelTips,
    String? bestTimeToVisit,
    @Default('public') String privacyLevel,
    @Default([]) List<ItineraryItem> itinerary,
    @Default([]) List<TravelExpense> expenses,
  }) = _CreateTravelPostRequest;

  factory CreateTravelPostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTravelPostRequestFromJson(json);
}

// Constants for categories and types
class TravelPostConstants {
  static const List<String> moods = [
    'happy', 'excited', 'peaceful', 'adventurous', 'romantic', 
    'nostalgic', 'grateful', 'inspired', 'relaxed', 'curious'
  ];
  
  static const List<String> privacyLevels = [
    'public', 'friends', 'private'
  ];
  
  static const List<String> reactionTypes = [
    'love', 'wow', 'wanderlust', 'helpful', 'inspiring'
  ];
  
  static const List<String> expenseCategories = [
    'food', 'transport', 'accommodation', 'activities', 
    'shopping', 'entertainment', 'other'
  ];
  
  static const List<String> itineraryCategories = [
    'restaurant', 'attraction', 'accommodation', 'transport',
    'shopping', 'entertainment', 'nature', 'culture', 'other'
  ];
  
  static const List<String> commonActivities = [
    'Sightseeing', 'Food tasting', 'Shopping', 'Photography',
    'Hiking', 'Beach', 'Museums', 'Nightlife', 'Art & Culture',
    'Adventure sports', 'Relaxation', 'Local experiences'
  ];
} 