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
      // SMART CACHE STRATEGY: Use cached data when available, supplement with fresh API calls for variety
      debugPrint('🧠 Using smart caching strategy: cached data + fresh supplements for variety...');
      List<GooglePlace> places = [];

      // Step 1: Try to get some cached places first (cost-efficient)
      final cachedPlaces = await PlacesCacheService.getCachedPlaces(
        moods: selectedMoods,
        lat: latitude,
        lng: longitude,
        radiusKm: 15.0,
      );

      debugPrint('💾 Found ${cachedPlaces.length} cached places for these moods');

      // Step 2: Apply tourism relevance filtering to cached places
      final filteredCachedPlaces = cachedPlaces.where(_isTouristRelevant).toList();
      debugPrint('✅ Cached places after tourism filtering: ${filteredCachedPlaces.length}');

      // Step 3: If we have good cached data, use it as foundation
      if (filteredCachedPlaces.isNotEmpty) {
        places.addAll(filteredCachedPlaces);
        debugPrint('💾 Using ${filteredCachedPlaces.length} cached places as foundation');
      }

      // Step 4: Always supplement with some fresh API calls for variety (but not all)
      // Extract city name from user location for targeted searches
      String cityName = 'Rotterdam'; // Default
      if (userLocation != null) {
        if (userLocation.toLowerCase().contains('amsterdam')) {
          cityName = 'Amsterdam';
        } else if (userLocation.toLowerCase().contains('den haag') || userLocation.toLowerCase().contains('the hague')) {
          cityName = 'Den Haag';
        } else if (userLocation.toLowerCase().contains('utrecht')) {
          cityName = 'Utrecht';
        } else if (userLocation.toLowerCase().contains('eindhoven')) {
          cityName = 'Eindhoven';
        } else if (userLocation.toLowerCase().contains('rotterdam')) {
          cityName = 'Rotterdam';
        }
      }
      
      debugPrint('🆕 Supplementing with fresh API calls for variety and new discoveries...');
      final freshApiPlaces = await GooglePlacesService.searchByMood(
          moods: selectedMoods,
          lat: latitude,
          lng: longitude,
          radius: 15000, // 15km radius around user
        cityName: cityName,
        );

      debugPrint('🌐 Fresh API returned ${freshApiPlaces.length} new places');
      
      // Step 5: Combine cached + fresh places, remove duplicates
      final allPlaceIds = places.map((p) => p.placeId).toSet();
      final newFreshPlaces = freshApiPlaces.where((p) => !allPlaceIds.contains(p.placeId)).toList();
      
      places.addAll(newFreshPlaces);
      debugPrint('🔄 Combined: ${filteredCachedPlaces.length} cached + ${newFreshPlaces.length} fresh = ${places.length} total');

        // CRITICAL DEBUG: Check if problematic places are in results
        for (final place in places) {
          if (place.name.toLowerCase().contains('yoga')) {
            debugPrint('🔍 FOUND YOGA IN RESULTS: ${place.name} (types: ${place.types})');
          }
          if (place.name.toLowerCase().contains('bodycare') || place.name.toLowerCase().contains('body')) {
            debugPrint('🔍 FOUND BODYCARE IN RESULTS: ${place.name} (types: ${place.types})');
          }
        }

        // Log mood distribution in results
        final Map<String, int> typeCount = {};
        for (final place in places) {
          for (final type in place.types) {
            typeCount[type] = (typeCount[type] ?? 0) + 1;
          }
        }
        debugPrint('📊 Place type distribution: ${typeCount.entries.take(5).map((e) => '${e.key}(${e.value})').join(', ')}');

        // Step 6: Cache the new fresh places for future use
        if (newFreshPlaces.isNotEmpty) {
          await PlacesCacheService.cachePlaces(
            places: newFreshPlaces,
            moods: selectedMoods,
            lat: latitude,
            lng: longitude,
          );
          debugPrint('💾 Cached ${newFreshPlaces.length} new places for future use');
        }

        debugPrint('✅ Smart caching result: ${places.length} total places (${filteredCachedPlaces.length} cached + ${newFreshPlaces.length} fresh)');

      // CRITICAL: NEVER use fallback activities - force real API data usage
      if (places.isEmpty) {
        debugPrint('🚨 CRITICAL: No mood-appropriate places found near user location');
        debugPrint('🔧 FORCING direct API search to get REAL activities...');
        
        // EMERGENCY FALLBACK: Force direct API search without mood filtering
        try {
          final emergencyPlaces = await GooglePlacesService.searchPlaces(
            query: "restaurants cafes attractions ${selectedMoods.join(' ')} in Rotterdam",
            lat: latitude,
            lng: longitude,
            radius: 15000, // Larger radius
          );
          
          debugPrint('🆘 Emergency search found ${emergencyPlaces.length} places');
          
          if (emergencyPlaces.isNotEmpty) {
            // Use the emergency places instead of fallback activities
            return await _generateActivitiesFromPlaces(emergencyPlaces, selectedMoods, userLocation);
          }
        } catch (e) {
          debugPrint('❌ Emergency search also failed: $e');
        }
        
        // As LAST RESORT, return empty list instead of fallback activities
        debugPrint('❌ ALL SEARCHES FAILED - returning empty list to force retry');
        return [];
      }

      // Step 3: Convert real mood-appropriate Google Places data into activities
      debugPrint('🏗️ Converting ${places.length} mood-appropriate places into activities...');
      return await _generateActivitiesFromPlaces(places, selectedMoods, userLocation);

    } catch (e) {
      debugPrint('❌ Error in mood-aware activity generation: $e');
      
      // NEVER return fallback activities - force retry instead
      debugPrint('🔄 ERROR RECOVERY: Attempting simple places search...');
      try {
        final simplePlaces = await GooglePlacesService.searchPlaces(
          query: "restaurants ${selectedMoods.join(' ')} Rotterdam",
          lat: latitude,
          lng: longitude,
          radius: 10000,
        );
        
        if (simplePlaces.isNotEmpty) {
          debugPrint('✅ ERROR RECOVERY: Found ${simplePlaces.length} places via simple search');
          return await _generateActivitiesFromPlaces(simplePlaces, selectedMoods, userLocation);
        }
      } catch (recoveryError) {
        debugPrint('❌ Recovery search also failed: $recoveryError');
      }
      
      // Return empty list to force retry instead of fallback activities
      debugPrint('🚨 RETURNING EMPTY LIST - NO FALLBACK ACTIVITIES ALLOWED');
      return [];
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

      // Generate photo URL using async method that handles NEW API conversion
      debugPrint('🏢 Creating activity for: ${place.name}');
      debugPrint('   📷 Photo reference: ${place.photoReference ?? "null"}');
      debugPrint('   🏷️ Types: ${place.types}');
      final photoUrl = await GooglePlace.getBestPhotoUrlAsync(
        place.photoReference, 
        place.types, 
        placeName: place.name,
        placeId: place.placeId,
      );
      debugPrint('🎨 Final Photo URL for "${place.name}": $photoUrl');

      final activity = Activity(
        id: 'activity_${DateTime.now().millisecondsSinceEpoch}_${activities.length}',
        name: _cleanPlaceName(place.name), // Clean up place names to remove prefixes
        description: _generateDescription(place, moods),
        timeSlot: _getTimeSlotString(timeSlot),
        timeSlotEnum: timeSlot,
        duration: _estimateDuration(place.types),
        location: LatLng(place.lat ?? 51.9225, place.lng ?? 4.4792),
        paymentType: _determinePaymentType(place.types, place.priceLevel),
        imageUrl: photoUrl,
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

  /// Get start time for a time slot - using user's current timezone
  static DateTime _getStartTimeForSlot(TimeSlot timeSlot, DateTime today) {
    // Get current time to understand user's timezone
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // Clean minute intervals: 0, 15, 30, 45
    final cleanMinutes = [0, 15, 30, 45];
    final randomCleanMinutes = cleanMinutes[Random().nextInt(cleanMinutes.length)];
    
    // Dynamic time slot calculation based on current time
    DateTime baseTime;
    
    switch (timeSlot) {
      case TimeSlot.morning:
        // Morning: 7 AM - 11 AM
        int morningHour = 7 + Random().nextInt(4); // 7-10 AM
        baseTime = DateTime(today.year, today.month, today.day, morningHour, randomCleanMinutes);
        
        // If it's already past morning, schedule for next day
        if (currentHour >= 11) {
          baseTime = baseTime.add(const Duration(days: 1));
        }
        break;
        
      case TimeSlot.afternoon:
        // Afternoon: 12 PM - 5 PM
        int afternoonHour = 12 + Random().nextInt(5); // 12-4 PM
        baseTime = DateTime(today.year, today.month, today.day, afternoonHour, randomCleanMinutes);
        
        // If it's already past afternoon, schedule for next day
        if (currentHour >= 17) {
          baseTime = baseTime.add(const Duration(days: 1));
        }
        break;
        
      case TimeSlot.evening:
        // Evening: 5 PM - 9 PM
        int eveningHour = 17 + Random().nextInt(4); // 5-8 PM
        baseTime = DateTime(today.year, today.month, today.day, eveningHour, randomCleanMinutes);
        
        // If it's already past evening, schedule for next day
        if (currentHour >= 21) {
          baseTime = baseTime.add(const Duration(days: 1));
        }
        break;
        
      case TimeSlot.night:
        // Night: 9 PM - 11 PM
        int nightHour = 21 + Random().nextInt(2); // 9-10 PM
        baseTime = DateTime(today.year, today.month, today.day, nightHour, randomCleanMinutes);
        
        // If it's already past night, schedule for next day
        if (currentHour >= 23) {
          baseTime = baseTime.add(const Duration(days: 1));
        }
        break;
    }
    
    debugPrint('🕐 Generated time for ${timeSlot.name}: ${baseTime.hour}:${baseTime.minute.toString().padLeft(2, '0')} (current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')})');
    return baseTime;
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

  /// REMOVED: No more fallback activities - service is now fully dynamic
  /// All activities must come from real Google Places API data

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

  /// Enhanced tourist relevance filtering - same logic as GooglePlacesService
  static bool _isTouristRelevant(GooglePlace place) {
    debugPrint('🔍 Checking tourist relevance for: ${place.name} (types: ${place.types})');
    
    // STRICT exclusion types - these are NEVER tourist attractions
    final excludedTypes = {
      'accounting', 'atm', 'bank', 'dentist', 'doctor', 'electrician', 
      'finance', 'funeral_home', 'gas_station', 'hospital', 'insurance_agency',
      'lawyer', 'local_government_office', 'locksmith', 'moving_company', 
      'painter', 'pharmacy', 'physiotherapist', 'plumber', 'real_estate_agency',
      'roofing_contractor', 'veterinary_care', 'car_dealer', 'car_repair',
      'car_wash', 'storage', 'post_office', 'school', 'university',
      'gym', 'health' // Added these based on the problematic results
    };

    // Check if place has any excluded types
    for (final type in place.types) {
      if (excludedTypes.contains(type)) {
        debugPrint('🚫 EXCLUDED BY TYPE: ${place.name} has excluded type "$type"');
        return false;
      }
    }

    // EXTENSIVE keyword exclusions - these indicate personal services
    final excludedKeywords = [
      // Fitness and health services
      'yoga school', 'yogaschool', 'fitness center', 'gym', 'bodycare', 
      'body care', 'personal training', 'massage therapy', 'physiotherapy',
      
      // Medical and wellness services  
      'clinic', 'medical center', 'therapy', 'counseling', 'rehabilitation',
      'wellness center', 'health center', 'dental', 'optometry',
      
      // Dutch equivalents
      'zorgcentrum', 'medisch centrum', 'tandarts', 'fysiotherapie',
      'massage praktijk', 'gezondheidscentrum',
      
      // Personal and beauty services
      'nail salon', 'hair salon', 'barber shop', 'beauty salon',
      'spa treatments', 'cosmetic', 'esthetic',
      
      // Business services
      'accounting', 'insurance', 'legal services', 'consultancy',
      'office space', 'storage facility'
    ];

    final nameAndTypes = '${place.name.toLowerCase()} ${place.types.join(' ').toLowerCase()}';
    
    for (final keyword in excludedKeywords) {
      if (nameAndTypes.contains(keyword)) {
        return false;
      }
    }

    // Enhanced spa/wellness filtering - be very strict about wellness places
    if (place.types.contains('spa') || place.types.contains('health') || 
        place.types.contains('beauty_salon') || nameAndTypes.contains('wellness')) {
      // Only allow tourist-oriented spas/wellness (hotels, resorts, day spas)
      bool isTouristWellness = nameAndTypes.contains('day spa') || 
                              nameAndTypes.contains('resort') ||
                              nameAndTypes.contains('hotel') ||
                              (place.userRatingsTotal != null && place.userRatingsTotal! > 200);
      if (!isTouristWellness) {
        return false;
      }
    }

    debugPrint('✅ TOURIST APPROVED: ${place.name}');
    return true;
  }

  /// Clean up place names by removing common prefixes and improving readability
  static String _cleanPlaceName(String name) {
    String cleaned = name;
    
    // Remove common prefixes that don't add value
    final prefixesToRemove = [
      'Begin ',
      'Start ',
      'Visit ',
      'Go to ',
      'Explore ',
      'See ',
      'Discover ',
    ];
    
    for (final prefix in prefixesToRemove) {
      if (cleaned.startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length);
        break; // Only remove one prefix
      }
    }
    
    // Clean up common suffixes that are redundant
    final suffixesToRemove = [
      ' - Restaurant',
      ' Restaurant',
      ' - Cafe',
      ' Cafe',
      ' - Bar',
      ' Bar',
    ];
    
    for (final suffix in suffixesToRemove) {
      if (cleaned.endsWith(suffix) && cleaned.length > suffix.length + 5) {
        cleaned = cleaned.substring(0, cleaned.length - suffix.length);
        break; // Only remove one suffix
      }
    }
    
    // Trim whitespace and return
    return cleaned.trim();
  }
  
  /// Generate an alternative activity for "not feeling this" feature
  static Future<Activity?> generateAlternativeActivity({
    required Activity originalActivity,
    required List<String> moods,
    required double latitude,
    required double longitude,
    required String userLocation,
  }) async {
    debugPrint('🔄 Generating alternative activity for ${originalActivity.name}');
    debugPrint('   Time slot: ${originalActivity.timeSlot}');
    debugPrint('   Moods: $moods');
    
    try {
      // Search for alternatives in the same time slot
      final places = await GooglePlacesService.searchByMood(
        moods: moods,
        lat: latitude,
        lng: longitude,
        cityName: userLocation,
      );
      
      if (places.isEmpty) {
        debugPrint('❌ No alternative places found for mood search');
        
        // Try a broader search
        final broadPlaces = await GooglePlacesService.searchPlaces(
          query: "restaurants cafes attractions ${moods.join(' ')} $userLocation",
          lat: latitude,
          lng: longitude,
          radius: 12000,
        );
        
        if (broadPlaces.isEmpty) {
          debugPrint('❌ No places found even with broad search');
          return null;
        }
        
        // Use broad places
        final filteredBroadPlaces = broadPlaces.where((place) => 
          place.placeId != originalActivity.id && 
          _isSuitableForTimeSlot(place, originalActivity.timeSlotEnum)
        ).toList();
        
        if (filteredBroadPlaces.isEmpty) {
          debugPrint('❌ No suitable alternative places found');
          return null;
        }
        
        // Create activity from first suitable place
        return await _createActivityFromPlace(
          filteredBroadPlaces.first,
          originalActivity.timeSlotEnum,
          moods,
          originalActivity.startTime,
          originalActivity.duration,
        );
      }
      
      // Filter out the original activity and find suitable alternatives
      final alternatives = places.where((place) => 
        place.placeId != originalActivity.id && 
        _isSuitableForTimeSlot(place, originalActivity.timeSlotEnum)
      ).toList();
      
      if (alternatives.isEmpty) {
        debugPrint('❌ No suitable alternatives found after filtering');
        return null;
      }
      
      // Shuffle and pick a random alternative
      alternatives.shuffle();
      final selectedPlace = alternatives.first;
      
      debugPrint('✅ Found alternative: ${selectedPlace.name}');
      
      // Create the alternative activity with same timing
      return await _createActivityFromPlace(
        selectedPlace,
        originalActivity.timeSlotEnum,
        moods,
        originalActivity.startTime,
        originalActivity.duration,
      );
      
    } catch (e) {
      debugPrint('❌ Error generating alternative activity: $e');
      return null;
    }
  }
  
  /// Create an activity from a GooglePlace with specific timing
  static Future<Activity> _createActivityFromPlace(
    GooglePlace place,
    TimeSlot timeSlot,
    List<String> moods,
    DateTime startTime,
    int duration,
  ) async {
    // Generate photo URL using async method
    final photoUrl = await GooglePlace.getBestPhotoUrlAsync(
      place.photoReference, 
      place.types, 
      placeName: place.name,
      placeId: place.placeId,
    );
    
    return Activity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}_${place.placeId}',
      name: _cleanPlaceName(place.name),
      description: _generateDescription(place, moods),
      timeSlot: _getTimeSlotString(timeSlot),
      timeSlotEnum: timeSlot,
      duration: duration, // Keep original duration
      location: LatLng(place.lat ?? 51.9225, place.lng ?? 4.4792),
      paymentType: _determinePaymentType(place.types, place.priceLevel),
      imageUrl: photoUrl,
      rating: place.rating ?? 4.0,
      tags: _generateTags(moods, place.types),
      startTime: startTime, // Keep original start time
      priceLevel: _getPriceLevel(place.priceLevel),
      refreshCount: 0, // Reset refresh count for new activity
    );
  }
  
  /// Check if a place is suitable for a specific time slot
  static bool _isSuitableForTimeSlot(GooglePlace place, TimeSlot timeSlot) {
    final suitableSlots = _getTimeSlotsForPlace(place);
    return suitableSlots.contains(timeSlot);
  }
}