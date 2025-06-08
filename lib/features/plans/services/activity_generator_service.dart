import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/google_places_service.dart';
import '../../location/services/location_service.dart';
import '../data/services/places_cache_service.dart';
import '../domain/models/activity.dart';
import '../domain/enums/time_slot.dart';
import '../domain/enums/payment_type.dart';

class ActivityGeneratorService {
  /// Generate activities from Google Places based on moods and user's ACTUAL location
  /// Uses precise mood-to-place-type mapping for targeted suggestions
  static Future<List<Activity>> generateActivities({
    required List<String> selectedMoods,
    required String? userLocation,
    double? lat,
    double? lng,
  }) async {
    debugPrint('🎯 Generating MOOD-AWARE activities for: $selectedMoods in $userLocation');

    // Ensure we have real coordinates - NEVER use hardcoded values for actual queries
    double latitude;
    double longitude;
    
    if (lat != null && lng != null) {
      // Use provided coordinates (actual user location)
      latitude = lat;
      longitude = lng;
      debugPrint('📍 Using provided user coordinates: ($latitude, $longitude)');
    } else {
      // Get current location if not provided
      debugPrint('📍 Getting current user location...');
      try {
        final position = await LocationService.getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
        debugPrint('📍 Retrieved current location: ($latitude, $longitude)');
      } catch (e) {
        debugPrint('❌ Failed to get location: $e');
        // Only fall back to default if we absolutely cannot get user location
        latitude = LocationService.defaultLocation['latitude'] as double;
        longitude = LocationService.defaultLocation['longitude'] as double;
        debugPrint('⚠️ Using fallback location: ($latitude, $longitude)');
      }
    }

    // Log tourism platform mood analysis for debugging
    debugPrint('🎪 Tourism platform mood analysis:');
    for (final mood in selectedMoods) {
      final queries = GooglePlacesService.moodToTourismQueries[mood.toLowerCase()] ?? [];
      final sampleQueries = queries.take(2).map((q) => '"${q['query']}" (${q['minRating']}⭐, ${q['minReviews']}+ reviews)').join(', ');
      debugPrint('   "$mood" → $sampleQueries...');
    }

    // IMPORTANT: Always log the exact coordinates being used for Places API
    debugPrint('🌐 Querying Google Places API with mood-specific filters');
    debugPrint('📍 Location: ($latitude, $longitude) | Radius: 15km');

    try {
      // Step 1: Try to get cached places first (within 15km of user)
      debugPrint('🗄️ Checking cache for mood-appropriate places...');
      List<GooglePlace> places = await PlacesCacheService.getCachedPlaces(
        moods: selectedMoods,
        lat: latitude,
        lng: longitude,
        radiusKm: 15.0,
      );

      // Step 2: If not enough cached places, fetch REAL places using mood-aware filtering
      if (places.length < 12) {
        debugPrint('💡 Not enough cached places (${places.length}/12), using mood-aware API search...');
        
        // Query Google Places API with precise mood-to-place-type filtering
        final apiPlaces = await GooglePlacesService.searchByMood(
          moods: selectedMoods,
          lat: latitude,
          lng: longitude,
          radius: 15000, // 15km radius around user
        );

        debugPrint('🌐 Mood-aware API returned ${apiPlaces.length} relevant places');

        // Log mood distribution in results
        final Map<String, int> typeCount = {};
        for (final place in apiPlaces) {
          for (final type in place.types) {
            typeCount[type] = (typeCount[type] ?? 0) + 1;
          }
        }
        debugPrint('📊 Place type distribution: ${typeCount.entries.take(5).map((e) => '${e.key}(${e.value})').join(', ')}');

        // Cache the new mood-appropriate places for future use
        if (apiPlaces.isNotEmpty) {
          await PlacesCacheService.cachePlaces(
            places: apiPlaces,
            moods: selectedMoods,
            lat: latitude,
            lng: longitude,
          );
          debugPrint('💾 Cached ${apiPlaces.length} mood-appropriate places');
        }

        // Combine cached and API places, removing duplicates
        final placeIds = places.map((p) => p.placeId).toSet();
        final newPlaces = apiPlaces.where((p) => !placeIds.contains(p.placeId)).toList();
        places.addAll(newPlaces);
        
        debugPrint('✅ Total mood-appropriate places: ${places.length} (${places.length - newPlaces.length} cached + ${newPlaces.length} new)');
      } else {
        debugPrint('✅ Using ${places.length} cached mood-appropriate places');
      }

      // Ensure we found real places
      if (places.isEmpty) {
        debugPrint('❌ No mood-appropriate places found near user location');
        debugPrint('🔍 This might indicate: 1) Remote location 2) API key issue 3) No matching mood places nearby');
        return _getFallbackActivities(selectedMoods);
      }

      // Step 3: Convert real mood-appropriate Google Places data into activities
      debugPrint('🏗️ Converting ${places.length} mood-appropriate places into activities...');
      return await _generateActivitiesFromPlaces(places, selectedMoods, userLocation);

    } catch (e) {
      debugPrint('❌ Error in mood-aware activity generation: $e');
      return _getFallbackActivities(selectedMoods);
    }
  }

  /// Generate activities from Google Places data
  static Future<List<Activity>> _generateActivitiesFromPlaces(
    List<GooglePlace> places, 
    List<String> moods,
    String? userLocation,
  ) async {
    debugPrint('🏗️ Converting ${places.length} places to activities');

    final activities = <Activity>[];
    final usedPlaces = <String>{};

    // Shuffle places for variety
    places.shuffle();

    // Distribute activities across time slots: 3-4 per slot with BALANCED allocation
    final morningPlaces = <GooglePlace>[];
    final afternoonPlaces = <GooglePlace>[];
    final eveningPlaces = <GooglePlace>[];

    // CRITICAL FIX: Balanced time slot distribution to ensure afternoon coverage
    // Instead of greedy allocation, distribute fairly across all time slots
    
    // First, categorize places by their time suitability
    final morningCandidates = <GooglePlace>[];
    final afternoonCandidates = <GooglePlace>[];
    final eveningCandidates = <GooglePlace>[];
    
    for (final place in places) {
      final timeSlots = _getTimeSlotsForPlace(place);
      
      if (timeSlots.contains(TimeSlot.morning)) {
        morningCandidates.add(place);
      }
      if (timeSlots.contains(TimeSlot.afternoon)) {
        afternoonCandidates.add(place);
      }
      if (timeSlots.contains(TimeSlot.evening)) {
        eveningCandidates.add(place);
      }
    }

    debugPrint('🎯 Time slot candidates: Morning(${morningCandidates.length}) Afternoon(${afternoonCandidates.length}) Evening(${eveningCandidates.length})');

    // Balanced allocation: prioritize slots with fewer candidates first
    final usedPlaceIds = <String>{};
    
    // Allocate to afternoon first if it has good candidates (this was the missing piece!)
    for (final place in afternoonCandidates) {
      if (afternoonPlaces.length < 4 && !usedPlaceIds.contains(place.placeId)) {
        afternoonPlaces.add(place);
        usedPlaceIds.add(place.placeId);
      }
    }
    
    // Then allocate to morning from remaining candidates
    for (final place in morningCandidates) {
      if (morningPlaces.length < 4 && !usedPlaceIds.contains(place.placeId)) {
        morningPlaces.add(place);
        usedPlaceIds.add(place.placeId);
      }
    }
    
    // Finally allocate to evening from remaining candidates
    for (final place in eveningCandidates) {
      if (eveningPlaces.length < 4 && !usedPlaceIds.contains(place.placeId)) {
        eveningPlaces.add(place);
        usedPlaceIds.add(place.placeId);
      }
    }

    debugPrint('📊 Time distribution: Morning(${morningPlaces.length}) Afternoon(${afternoonPlaces.length}) Evening(${eveningPlaces.length})');

    // Generate 2-3 activities per time slot
    activities.addAll(await _createActivitiesForTimeSlot(
      morningPlaces.take(3).toList(), 
      TimeSlot.morning, 
      moods, 
      usedPlaces,
    ));

    activities.addAll(await _createActivitiesForTimeSlot(
      afternoonPlaces.take(3).toList(), 
      TimeSlot.afternoon, 
      moods, 
      usedPlaces,
    ));

    activities.addAll(await _createActivitiesForTimeSlot(
      eveningPlaces.take(3).toList(), 
      TimeSlot.evening, 
      moods, 
      usedPlaces,
    ));

    debugPrint('✅ Generated ${activities.length} activities');
    return activities;
  }

  /// Create activities for a specific time slot
  static Future<List<Activity>> _createActivitiesForTimeSlot(
    List<GooglePlace> places,
    TimeSlot timeSlot,
    List<String> moods,
    Set<String> usedPlaces,
  ) async {
    final activities = <Activity>[];

    for (final place in places) {
      if (usedPlaces.contains(place.placeId)) continue;
      
      usedPlaces.add(place.placeId);

      // Create DateTime for today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startTime = _getStartTimeForSlot(timeSlot, today);

      final activity = Activity(
        id: 'activity_${DateTime.now().millisecondsSinceEpoch}_${activities.length}',
        name: place.name, // Use actual place name directly
        description: _generateDescription(place, moods),
        timeSlot: _getTimeSlotString(timeSlot),
        timeSlotEnum: timeSlot,
        duration: _estimateDuration(place.types),
        location: LatLng(place.lat ?? 51.9225, place.lng ?? 4.4792),
        paymentType: _determinePaymentType(place.types, place.priceLevel),
        imageUrl: GooglePlacesService.getBestPhotoUrl(place.photoReference, place.types),
        rating: place.rating ?? 4.0,
        tags: _generateTags(moods, place.types),
        startTime: startTime,
        priceLevel: _getPriceLevel(place.priceLevel),
      );

      activities.add(activity);
      debugPrint('   ✅ Created activity: ${activity.name} (${timeSlot.name})');
    }

    return activities;
  }

  /// Get start time for a time slot - using only whole hours, quarters, or halves
  static DateTime _getStartTimeForSlot(TimeSlot timeSlot, DateTime today) {
    // Clean minute intervals: 0, 15, 30, 45
    final cleanMinutes = [0, 15, 30, 45];
    final randomCleanMinutes = cleanMinutes[Random().nextInt(cleanMinutes.length)];
    
    switch (timeSlot) {
      case TimeSlot.morning:
        return today.add(Duration(hours: 9, minutes: randomCleanMinutes));
      case TimeSlot.afternoon:
        return today.add(Duration(hours: 14, minutes: randomCleanMinutes));
      case TimeSlot.evening:
        return today.add(Duration(hours: 19, minutes: randomCleanMinutes));
      case TimeSlot.night:
        return today.add(Duration(hours: 22, minutes: randomCleanMinutes));
    }
  }

  /// Convert TimeSlot enum to string
  static String _getTimeSlotString(TimeSlot timeSlot) {
    switch (timeSlot) {
      case TimeSlot.morning:
        return 'morning';
      case TimeSlot.afternoon:
        return 'afternoon';
      case TimeSlot.evening:
        return 'evening';
      case TimeSlot.night:
        return 'night';
    }
  }

  /// Get price level text
  static String? _getPriceLevel(int? priceLevel) {
    switch (priceLevel) {
      case 1:
        return '€';
      case 2:
        return '€€';
      case 3:
        return '€€€';
      case 4:
        return '€€€€';
      default:
        return null;
    }
  }

  /// Get fallback activities when API fails - with clean time intervals
  static List<Activity> _getFallbackActivities(List<String> moods) {
    debugPrint('🚨 Using fallback activities for moods: $moods');
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      Activity(
        id: 'fallback_morning',
        name: 'Morning Local Discovery',
        description: 'Start your day with a ${moods.join(" and ").toLowerCase()} experience in your local area.',
        timeSlot: 'morning',
        timeSlotEnum: TimeSlot.morning,
        duration: 60,
        location: const LatLng(51.9225, 4.4792),
        paymentType: PaymentType.free,
        imageUrl: GooglePlacesService.getBestPhotoUrl(null, ['cafe']),
        rating: 4.5,
        tags: _generateTags(moods, ['local_business']),
        startTime: _getStartTimeForSlot(TimeSlot.morning, today),
      ),
      Activity(
        id: 'fallback_afternoon',
        name: 'Afternoon ${moods.isNotEmpty ? moods.first : "Adventure"} Experience',
        description: 'Continue your ${moods.join(" and ").toLowerCase()} day with this afternoon activity.',
        timeSlot: 'afternoon',
        timeSlotEnum: TimeSlot.afternoon,
        duration: 90,
        location: const LatLng(51.9225, 4.4792),
        paymentType: PaymentType.reservation,
        imageUrl: GooglePlacesService.getBestPhotoUrl(null, ['tourist_attraction']),
        rating: 4.3,
        tags: _generateTags(moods, ['tourist_attraction']),
        startTime: _getStartTimeForSlot(TimeSlot.afternoon, today),
      ),
      Activity(
        id: 'fallback_evening',
        name: 'Evening ${moods.isNotEmpty ? moods.first : "Adventure"} Finale',
        description: 'End your ${moods.join(" and ").toLowerCase()} day on a high note with this perfect evening activity.',
        timeSlot: 'evening',
        timeSlotEnum: TimeSlot.evening,
        duration: 120,
        location: const LatLng(51.9225, 4.4792),
        paymentType: PaymentType.reservation,
        imageUrl: GooglePlacesService.getBestPhotoUrl(null, ['restaurant']),
        rating: 4.7,
        tags: _generateTags(moods, ['restaurant']),
        startTime: _getStartTimeForSlot(TimeSlot.evening, today),
      ),
    ];
  }

  /// Determine which time slots a place is suitable for
  static List<TimeSlot> _getTimeSlotsForPlace(GooglePlace place) {
    final timeSlots = <TimeSlot>[];
    
    // Morning suitable places
    if (_isMorningSuitable(place)) {
      timeSlots.add(TimeSlot.morning);
    }
    
    // Afternoon suitable places
    if (_isAfternoonSuitable(place)) {
      timeSlots.add(TimeSlot.afternoon);
    }
    
    // Evening suitable places
    if (_isEveningSuitable(place)) {
      timeSlots.add(TimeSlot.evening);
    }
    
    // If no specific time slots, make it available for afternoon (most flexible)
    if (timeSlots.isEmpty) {
      timeSlots.add(TimeSlot.afternoon);
    }
    
    return timeSlots;
  }

  /// Check if place is suitable for morning based on mood-aware place types
  static bool _isMorningSuitable(GooglePlace place) {
    // Morning suitable place types (expanded for better coverage)
    final morningTypes = {
      'cafe', 'bakery', 'park', 'library', 'spa',
      'museum', 'art_gallery', 'tourist_attraction', 'food'
    };
    
    // Morning-friendly keywords
    final morningKeywords = {
      'coffee', 'breakfast', 'brunch', 'morning', 'bakery', 
      'pastry', 'croissant', 'yoga', 'park', 'museum',
      'workshop', 'cooking class', 'market', 'fresh'
    };
    
    final placeName = place.name.toLowerCase();
    
    return place.types.any((type) => morningTypes.contains(type)) || 
           morningKeywords.any((keyword) => placeName.contains(keyword)) ||
           // Specifically look for breakfast and morning establishments
           placeName.contains('am') || placeName.contains('早');
  }

  /// Check if place is suitable for afternoon based on mood-aware place types
  static bool _isAfternoonSuitable(GooglePlace place) {
    // Afternoon suitable place types (most flexible time - EXPANDED for comprehensive coverage)
    final afternoonTypes = {
      'restaurant', 'museum', 'art_gallery', 'shopping_mall', 
      'tourist_attraction', 'amusement_park', 'zoo', 'aquarium',
      'bowling_alley', 'food', 'cafe', 'park', 'library',
      'store', 'establishment', 'point_of_interest' // Added these for broader coverage
    };
    
    // Afternoon-friendly keywords (expanded for food experiences)
    final afternoonKeywords = {
      'restaurant', 'dining', 'lunch', 'cafe', 'food', 'cuisine', 
      'bistro', 'kitchen', 'grill', 'bar', 'tavern', 'eatery',
      'museum', 'gallery', 'zoo', 'attraction', 'tour', 'experience',
      'market', 'hall', 'center', 'place'
    };
    
    final placeName = place.name.toLowerCase();
    
    return place.types.any((type) => afternoonTypes.contains(type)) ||
           afternoonKeywords.any((keyword) => placeName.contains(keyword)) ||
           // Most places are suitable for afternoon unless specifically evening/morning only
           (!placeName.contains('breakfast') && !placeName.contains('brunch') && 
            !placeName.contains('night') && !placeName.contains('club'));
  }

  /// Check if place is suitable for evening based on mood-aware place types
  static bool _isEveningSuitable(GooglePlace place) {
    // Evening suitable place types
    final eveningTypes = {
      'restaurant', 'bar', 'night_club', 'amusement_park',
      'bowling_alley', 'entertainment'
    };
    
    return place.types.any((type) => eveningTypes.contains(type)) ||
           place.name.toLowerCase().contains('dinner') ||
           place.name.toLowerCase().contains('evening') ||
           place.name.toLowerCase().contains('bar') ||
           place.name.toLowerCase().contains('restaurant') ||
           place.name.toLowerCase().contains('club');
  }

  /// Estimate duration based on place types
  static int _estimateDuration(List<String> types) {
    if (types.contains('restaurant')) {
      return 90; // 1.5 hours for dining
    } else if (types.contains('museum') || types.contains('art_gallery')) {
      return 120; // 2 hours for museums
    } else if (types.contains('park')) {
      return 60; // 1 hour in parks
    } else if (types.contains('spa') || types.contains('health')) {
      return 90; // 1.5 hours for wellness
    } else if (types.contains('cafe') || types.contains('bakery')) {
      return 45; // 45 minutes for coffee
    } else if (types.contains('bar') || types.contains('night_club')) {
      return 120; // 2 hours for nightlife
    }
    
    return 60; // Default 1 hour
  }

  /// Determine payment type based on place types and price level
  static PaymentType _determinePaymentType(List<String> types, int? priceLevel) {
    if (types.contains('park') || types.contains('beach')) {
      return PaymentType.free;
    } else if (types.contains('museum') || types.contains('amusement_park') || 
               types.contains('movie_theater')) {
      return PaymentType.ticket;
    } else if (types.contains('restaurant') || types.contains('bar') ||
               types.contains('spa') || types.contains('gym')) {
      return PaymentType.reservation;
    }
    
    // Use price level as fallback
    if (priceLevel == null || priceLevel == 0) {
      return PaymentType.free;
    } else {
      return PaymentType.reservation;
    }
  }

  /// Generate tags based on actual place types (no emojis - those are added in UI)
  static List<String> _generateTags(List<String> moods, List<String> types) {
    final tags = <String>[];
    
    // Primary tags based on actual place types (most important)
    if (types.contains('restaurant') || types.contains('food') || types.contains('meal_takeaway')) {
      tags.add('Food');
    }
    if (types.contains('spa') || types.contains('beauty_salon') || types.contains('health')) {
      tags.add('Wellness');
    }
    if (types.contains('museum') || types.contains('art_gallery')) {
      tags.add('Culture');
    }
    if (types.contains('park') || types.contains('natural_feature')) {
      tags.add('Outdoor');
    }
    if (types.contains('bar') || types.contains('night_club')) {
      tags.add('Nightlife');
    }
    if (types.contains('gym') || types.contains('stadium')) {
      tags.add('Active');
    }
    if (types.contains('shopping_mall') || types.contains('store')) {
      tags.add('Shopping');
    }
    if (types.contains('tourist_attraction')) {
      tags.add('Adventure');
    }
    if (types.contains('cafe') || types.contains('bakery')) {
      tags.add('Cafe');
    }
    if (types.contains('amusement_park') || types.contains('bowling_alley')) {
      tags.add('Entertainment');
    }
    
    // Only add mood-based tags if they're relevant to the place type
    for (final mood in moods) {
      switch (mood.toLowerCase()) {
        case 'romantic':
          // Only add romantic if it's a restaurant, bar, or spa
          if (types.contains('restaurant') || types.contains('bar') || types.contains('spa')) {
            tags.add('Romantic');
          }
          break;
        case 'creative':
          // Only add creative if it's a museum, gallery, or workshop
          if (types.contains('museum') || types.contains('art_gallery') || types.contains('tourist_attraction')) {
            tags.add('Creative');
          }
          break;
        case 'relaxed':
        case 'mindful':
          // Only add if it's actually a wellness place
          if (types.contains('spa') || types.contains('park') || types.contains('cafe')) {
            tags.add('Relaxing');
          }
          break;
      }
    }
    
    return tags.take(2).toList(); // Limit to 2 tags for cleaner display
  }

  /// Generate place-specific description based on place and moods
  static String _generateDescription(GooglePlace place, List<String> moods) {
    final moodText = moods.join(' and ').toLowerCase();
    final rating = place.rating?.toStringAsFixed(1) ?? '4.0';
    final reviewCount = place.userRatingsTotal ?? 0;
    final placeName = place.name;
    
    // Generate place-specific descriptions
    if (place.types.contains('bakery')) {
      return '$placeName offers fresh-baked pastries and artisanal treats perfect for your $moodText morning. This local favorite is rated $rating stars by $reviewCount visitors.';
    } else if (place.types.contains('restaurant')) {
      if (place.types.contains('breakfast') || placeName.toLowerCase().contains('breakfast')) {
        return 'Start your day right at $placeName with a delicious breakfast. This popular spot serves quality food perfect for your $moodText mood. Rated $rating stars.';
      }
      return '$placeName serves exceptional cuisine that locals and tourists love. Experience flavors that match your $moodText mood. Rated $rating stars by $reviewCount diners.';
    } else if (place.types.contains('cafe')) {
      return '$placeName is the perfect coffee spot for your $moodText morning. Enjoy quality coffee and a welcoming atmosphere. Rated $rating stars by $reviewCount coffee lovers.';
    } else if (place.types.contains('tourist_attraction')) {
      if (placeName.toLowerCase().contains('workshop') || placeName.toLowerCase().contains('cooking')) {
        return 'Learn something new at $placeName! This hands-on experience is perfect for your $moodText mood. Create memories while mastering new skills. Rated $rating stars.';
      }
      return 'Discover $placeName, a must-visit attraction that perfectly captures your $moodText spirit. This popular destination is rated $rating stars by $reviewCount visitors.';
    } else if (place.types.contains('park')) {
      return 'Escape to $placeName for a peaceful retreat in nature. This beautiful green space offers the perfect setting for your $moodText day. Rated $rating stars.';
    } else if (place.types.contains('museum') || place.types.contains('art_gallery')) {
      return 'Immerse yourself in culture at $placeName. This inspiring venue offers enriching experiences perfect for your $moodText mood. Rated $rating stars by art enthusiasts.';
    } else if (place.types.contains('spa')) {
      return 'Indulge in relaxation at $placeName. This premium wellness destination offers rejuvenating treatments perfect for your $moodText day. Rated $rating stars.';
    } else if (place.types.contains('bar')) {
      return 'Experience the atmosphere at $placeName, a local hotspot perfect for your $moodText evening. Enjoy quality drinks and great vibes. Rated $rating stars.';
    }
    
    return '$placeName is a highly-rated local gem perfect for your $moodText experience. Discover what makes this place special. Rated $rating stars by $reviewCount visitors.';
  }
}