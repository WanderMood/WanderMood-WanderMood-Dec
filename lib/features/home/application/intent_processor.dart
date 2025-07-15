import '../../../features/places/models/place.dart';
import 'context_manager.dart';

class IntentProcessor {
  /// Process user intent with smart context awareness
  static Map<String, dynamic> processIntent(
    String intent, 
    List<Place> places, {
    SmartContext? context,
  }) {
    switch (intent) {
      case 'chill':
        return _processChillIntent(places);
      case 'adventure':
        return _processAdventureIntent(places);
      case 'foodie':
        return _processFoodieIntent(places);
      case 'culture':
        return _processCultureIntent(places);
      case 'social':
        return _processSocialIntent(places);
      case 'nature':
        return _processNatureIntent(places);
      case 'surprise':
        return _processSurpriseIntent(places);
              case 'now':
        return _processNowIntent(places, context);
      case 'later':
        return _processLaterIntent(places, context);
      default:
        return {
          'filteredPlaces': places,
          'explanation': 'Here are some great options for you ✨',
          'priority': 'all',
        };
    }
  }

  /// Process natural language search queries with context awareness
  static Map<String, dynamic> processNaturalLanguage(
    String query, 
    List<Place> places, {
    SmartContext? context,
  }) {
    final lowerQuery = query.toLowerCase();
    
    // Intent keywords mapping
    final intentKeywords = {
      'chill': ['chill', 'relax', 'calm', 'peaceful', 'quiet', 'cozy'],
      'adventure': ['adventure', 'exciting', 'thrill', 'explore', 'discover'],
      'foodie': ['food', 'eat', 'drink', 'restaurant', 'cafe', 'dining', 'hungry'],
      'culture': ['art', 'museum', 'culture', 'history', 'gallery', 'cultural'],
      'social': ['friends', 'group', 'hangout', 'social', 'together', 'meet'],
      'nature': ['nature', 'outdoor', 'park', 'green', 'fresh air', 'outside'],
    };

    // Find matching intent
    String? detectedIntent;
    for (final entry in intentKeywords.entries) {
      if (entry.value.any((keyword) => lowerQuery.contains(keyword))) {
        detectedIntent = entry.key;
        break;
      }
    }

    if (detectedIntent != null) {
      return processIntent(detectedIntent, places, context: context);
    }

    // If no intent detected, do text-based filtering
    final filteredPlaces = places.where((place) {
      return place.name.toLowerCase().contains(lowerQuery) ||
             (place.description ?? '').toLowerCase().contains(lowerQuery) ||
             place.activities.any((activity) => activity.toLowerCase().contains(lowerQuery)) ||
             place.address.toLowerCase().contains(lowerQuery);
    }).toList();

    return {
      'filteredPlaces': filteredPlaces,
      'explanation': filteredPlaces.isEmpty 
        ? 'No exact matches found. Try a different search! 🔍'
        : 'Found ${filteredPlaces.length} places matching "$query" 🎯',
      'priority': 'search',
    };
  }

  static Map<String, dynamic> _processChillIntent(List<Place> places) {
    final chillActivities = ['cafe', 'coffee', 'spa', 'park', 'library', 'tea', 'quiet'];
    final filteredPlaces = _filterByActivities(places, chillActivities);
    
    return {
      'filteredPlaces': filteredPlaces,
      'explanation': 'Perfect spots to unwind and chill 😌',
      'priority': 'high_rating',
    };
  }

  static Map<String, dynamic> _processAdventureIntent(List<Place> places) {
    final adventureActivities = ['adventure', 'tour', 'climbing', 'hiking', 'explore', 'outdoor'];
    final filteredPlaces = _filterByActivities(places, adventureActivities);
    
    return {
      'filteredPlaces': filteredPlaces,
      'explanation': 'Ready for an adventure? Let\'s go! 🗺️',
      'priority': 'activity_rich',
    };
  }

  static Map<String, dynamic> _processFoodieIntent(List<Place> places) {
    final foodieActivities = ['restaurant', 'food', 'dining', 'cafe', 'bar', 'market', 'brewery'];
    final filteredPlaces = _filterByActivities(places, foodieActivities);
    
    return {
      'filteredPlaces': filteredPlaces,
      'explanation': 'Delicious discoveries await! 🍽️',
      'priority': 'rating_and_reviews',
    };
  }

  static Map<String, dynamic> _processCultureIntent(List<Place> places) {
    final cultureActivities = ['museum', 'art', 'gallery', 'cultural', 'history', 'architecture'];
    final filteredPlaces = _filterByActivities(places, cultureActivities);
    
    return {
      'filteredPlaces': filteredPlaces,
      'explanation': 'Dive into culture and creativity 🎨',
      'priority': 'cultural_significance',
    };
  }

  static Map<String, dynamic> _processSocialIntent(List<Place> places) {
    final socialActivities = ['bar', 'pub', 'social', 'group', 'event', 'entertainment'];
    final filteredPlaces = _filterByActivities(places, socialActivities);
    
    return {
      'filteredPlaces': filteredPlaces,
      'explanation': 'Great spots to hang with friends! 👥',
      'priority': 'social_vibes',
    };
  }

  static Map<String, dynamic> _processNatureIntent(List<Place> places) {
    final natureActivities = ['park', 'nature', 'outdoor', 'garden', 'walk', 'green'];
    final filteredPlaces = _filterByActivities(places, natureActivities);
    
    return {
      'filteredPlaces': filteredPlaces,
      'explanation': 'Connect with nature and breathe fresh air 🌳',
      'priority': 'outdoor_rating',
    };
  }

  static Map<String, dynamic> _processSurpriseIntent(List<Place> places) {
    // Shuffle and pick diverse places
    final shuffledPlaces = List<Place>.from(places)..shuffle();
    final surprisePlaces = shuffledPlaces.take(6).toList();
    
    return {
      'filteredPlaces': surprisePlaces,
      'explanation': 'Surprise! Here are some random gems 🎲',
      'priority': 'random',
    };
  }

  static Map<String, dynamic> _processNowIntent(List<Place> places, SmartContext? context) {
    List<Place> filteredPlaces;
    String explanation;
    
    if (context != null) {
      // Use smart context for enhanced recommendations
      final timeContext = context.timeContext;
      final weatherContext = context.weatherContext;
      final moodContext = context.moodContext;
      
      List<String> activities = [];
      
      // Time-based activities
      switch (timeContext.timeOfDay) {
        case TimeOfDay.morning:
          activities.addAll(timeContext.isWeekend 
            ? ['brunch', 'cafe', 'market', 'park', 'breakfast'] 
            : ['cafe', 'coffee', 'quick', 'breakfast']);
          break;
        case TimeOfDay.afternoon:
          activities.addAll(['lunch', 'museum', 'gallery', 'restaurant', 'shopping']);
          break;
        case TimeOfDay.evening:
          activities.addAll(['dinner', 'restaurant', 'bar', 'entertainment']);
          if (timeContext.isWeekend) activities.addAll(['nightlife', 'social']);
          break;
        case TimeOfDay.night:
          activities.addAll(['bar', 'pub', 'late', 'night']);
          break;
      }
      
      // Weather-based filtering
      if (!weatherContext.isGoodForOutdoor) {
        activities.addAll(['indoor', 'cozy', 'warm']);
        activities.removeWhere((activity) => ['park', 'outdoor', 'walk'].contains(activity));
      } else {
        activities.addAll(['outdoor', 'terrace', 'patio']);
      }
      
      // Mood-based filtering
      switch (moodContext.energyLevel) {
        case EnergyLevel.high:
          activities.addAll(['active', 'adventure', 'energetic']);
          break;
        case EnergyLevel.low:
          activities.addAll(['calm', 'quiet', 'peaceful', 'spa']);
          break;
        case EnergyLevel.medium:
          // Keep all activities
          break;
      }
      
      filteredPlaces = _filterByActivities(places, activities);
      
      // Create context-aware explanation
      final timeDesc = _getTimeDescription(timeContext);
      final weatherDesc = weatherContext.recommendation;
      explanation = '$timeDesc Perfect timing! ${_getContextualEmoji(timeContext, weatherContext)}';
      
    } else {
      // Fallback to basic time-based filtering
      final currentHour = DateTime.now().hour;
      
      if (currentHour >= 6 && currentHour < 12) {
        filteredPlaces = _filterByActivities(places, ['cafe', 'coffee', 'park', 'market', 'breakfast']);
        explanation = 'Perfect morning spots for you! ☀️';
      } else if (currentHour >= 12 && currentHour < 17) {
        filteredPlaces = _filterByActivities(places, ['museum', 'restaurant', 'gallery', 'shopping', 'lunch']);
        explanation = 'Great afternoon activities await! 🌤️';
      } else if (currentHour >= 17 && currentHour < 22) {
        filteredPlaces = _filterByActivities(places, ['restaurant', 'bar', 'dinner', 'entertainment', 'pub']);
        explanation = 'Perfect evening vibes! 🌆';
      } else {
        filteredPlaces = _filterByActivities(places, ['bar', 'pub', 'late', 'night']);
        explanation = 'Late night adventures! 🌙';
      }
    }
    
    return {
      'filteredPlaces': filteredPlaces,
      'explanation': explanation,
      'priority': 'time_relevant',
    };
  }

  static Map<String, dynamic> _processLaterIntent(List<Place> places, SmartContext? context) {
    List<String> planningActivities = ['museum', 'restaurant', 'tour', 'spa', 'experience'];
    String explanation = 'Perfect for planning ahead! 📅';
    
    if (context != null) {
      final moodContext = context.moodContext;
      final timeContext = context.timeContext;
      
      // Add mood-specific planning activities
      switch (moodContext.activityType) {
        case ActivityType.cultural:
          planningActivities.addAll(['gallery', 'cultural', 'art', 'history']);
          explanation = 'Great cultural experiences to plan! 🎨';
          break;
        case ActivityType.active:
          planningActivities.addAll(['adventure', 'outdoor', 'sport', 'activity']);
          explanation = 'Exciting adventures worth planning! 🗺️';
          break;
        case ActivityType.social:
          planningActivities.addAll(['social', 'group', 'event', 'entertainment']);
          explanation = 'Fun group activities to plan! 👥';
          break;
        case ActivityType.relaxing:
          planningActivities.addAll(['spa', 'wellness', 'peaceful', 'calm']);
          explanation = 'Relaxing experiences to look forward to! 😌';
          break;
        case ActivityType.mixed:
          // Keep default activities
          break;
      }
      
      // Consider weekend vs weekday planning
      if (timeContext.isWeekend) {
        explanation += ' Weekend plans are the best!';
      } else {
        explanation += ' Something to anticipate!';
      }
    }
    
    final filteredPlaces = _filterByActivities(places, planningActivities);
    
    return {
      'filteredPlaces': filteredPlaces,
      'explanation': explanation,
      'priority': 'bookable',
    };
  }

  /// Helper method to filter places by activity keywords
  static List<Place> _filterByActivities(List<Place> places, List<String> keywords) {
    return places.where((place) {
      final searchText = '${place.name} ${place.description ?? ''} ${place.activities.join(' ')}'.toLowerCase();
      return keywords.any((keyword) => searchText.contains(keyword));
    }).toList();
  }

  /// Sort places based on priority type
  static List<Place> sortByPriority(List<Place> places, String priority) {
    switch (priority) {
      case 'high_rating':
        return places..sort((a, b) => b.rating.compareTo(a.rating));
      case 'activity_rich':
        return places..sort((a, b) => b.activities.length.compareTo(a.activities.length));
      case 'rating_and_reviews':
        return places..sort((a, b) {
          final aScore = a.rating * (a.reviewCount / 10);
          final bScore = b.rating * (b.reviewCount / 10);
          return bScore.compareTo(aScore);
        });
      case 'random':
        return places..shuffle();
      case 'time_relevant':
      case 'bookable':
      case 'search':
      default:
        return places;
    }
  }
  
  /// Helper methods for context-aware descriptions
  static String _getTimeDescription(TimeContext timeContext) {
    switch (timeContext.timeOfDay) {
      case TimeOfDay.morning:
        return timeContext.isWeekend ? 'Relaxed weekend morning.' : 'Fresh morning start.';
      case TimeOfDay.afternoon:
        return 'Perfect afternoon timing.';
      case TimeOfDay.evening:
        return timeContext.isWeekend ? 'Fun weekend evening!' : 'Lovely evening ahead.';
      case TimeOfDay.night:
        return 'Late night vibes.';
    }
  }
  
  static String _getContextualEmoji(TimeContext timeContext, WeatherContext weatherContext) {
    if (!weatherContext.isGoodForOutdoor) {
      return '🏠'; // Indoor recommended
    }
    
    switch (timeContext.timeOfDay) {
      case TimeOfDay.morning:
        return '☀️';
      case TimeOfDay.afternoon:
        return '🌤️';
      case TimeOfDay.evening:
        return '🌆';
      case TimeOfDay.night:
        return '🌙';
    }
  }
} 