import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/places/models/place.dart';
import 'context_manager.dart';

/// Service for dynamically grouping and prioritizing places based on context
class DynamicGroupingService {
  static final _supabase = Supabase.instance.client;
  
  /// Group places dynamically based on smart context and user preferences
  static Future<Map<String, dynamic>> groupPlacesByContext({
    required List<Place> places,
    required SmartContext context,
    String? userId,
  }) async {
    
    // Get user preferences from Supabase if available
    final userPreferences = userId != null 
      ? await _getUserPreferences(userId)
      : <String, dynamic>{};
    
    // Create contextual groups
    final groups = await _createContextualGroups(places, context, userPreferences);
    
    // Generate smart recommendations
    final recommendations = await _generateSmartRecommendations(groups, context, userPreferences);
    
    return {
      'groups': groups,
      'recommendations': recommendations,
      'totalPlaces': places.length,
      'context': context,
    };
  }
  
  /// Create contextual place groups based on current situation
  static Future<Map<String, List<Place>>> _createContextualGroups(
    List<Place> places,
    SmartContext context,
    Map<String, dynamic> userPreferences,
  ) async {
    final groups = <String, List<Place>>{};
    
    // Time-based primary grouping
    final timeContext = context.timeContext;
    final weatherContext = context.weatherContext;
    final moodContext = context.moodContext;
    
    // Define contextual categories
    final categories = _getContextualCategories(timeContext, weatherContext, moodContext);
    
    // Score and group places
    for (final place in places) {
      final scores = await _scorePlaceForContext(place, context, userPreferences);
      
      // Assign to best matching groups
      for (final category in categories.keys) {
        if (scores[category] != null && scores[category]! > 0.3) {
          groups[category] ??= [];
          groups[category]!.add(place);
        }
      }
    }
    
    // Sort each group by relevance score
    for (final groupName in groups.keys) {
      groups[groupName]!.sort((a, b) {
        final aScore = _calculatePlaceScore(a, context, userPreferences);
        final bScore = _calculatePlaceScore(b, context, userPreferences);
        return bScore.compareTo(aScore);
      });
      
      // Limit group size to prevent overwhelming UI
      if (groups[groupName]!.length > 8) {
        groups[groupName] = groups[groupName]!.take(8).toList();
      }
    }
    
    return groups;
  }
  
  /// Get contextual categories based on current situation
  static Map<String, String> _getContextualCategories(
    TimeContext timeContext,
    WeatherContext weatherContext,
    MoodContext moodContext,
  ) {
    final categories = <String, String>{};
    
    // Time-based categories
    switch (timeContext.timeOfDay) {
      case TimeOfDay.morning:
        categories['perfect_start'] = timeContext.isWeekend 
          ? '☀️ Perfect Weekend Start'
          : '⚡ Energize Your Morning';
        break;
      case TimeOfDay.afternoon:
        categories['afternoon_perfect'] = '🌤️ Afternoon Adventures';
        break;
      case TimeOfDay.evening:
        categories['evening_vibes'] = timeContext.isWeekend
          ? '🌆 Weekend Evening Fun'
          : '✨ Evening Unwind';
        break;
      case TimeOfDay.night:
        categories['night_life'] = '🌙 Late Night Vibes';
        break;
    }
    
    // Weather-based categories
    if (!weatherContext.isGoodForOutdoor) {
      categories['indoor_gems'] = '🏠 Cozy Indoor Spots';
    } else {
      categories['outdoor_fun'] = '🌿 Great Outdoor Options';
    }
    
    // Mood-based categories
    switch (moodContext.energyLevel) {
      case EnergyLevel.high:
        categories['high_energy'] = '🚀 High Energy Adventures';
        break;
      case EnergyLevel.low:
        categories['peaceful'] = '😌 Peaceful & Calm';
        break;
      case EnergyLevel.medium:
        categories['flexible'] = '🎯 Perfectly Balanced';
        break;
    }
    
    // Social preference categories
    switch (moodContext.socialPreference) {
      case SocialPreference.social:
        categories['social_spots'] = '👥 Great for Groups';
        break;
      case SocialPreference.solo:
        categories['solo_friendly'] = '🧘 Solo-Friendly Spots';
        break;
      case SocialPreference.flexible:
        // Don't add specific social category
        break;
    }
    
    return categories;
  }
  
  /// Score a place for different contextual categories
  static Future<Map<String, double>> _scorePlaceForContext(
    Place place,
    SmartContext context,
    Map<String, dynamic> userPreferences,
  ) async {
    var scores = <String, double>{};
    final activities = place.activities.map((a) => a.toLowerCase()).toList();
    final description = (place.description ?? '').toLowerCase();
    final name = place.name.toLowerCase();
    
    final timeContext = context.timeContext;
    final weatherContext = context.weatherContext;
    final moodContext = context.moodContext;
    
    // Time-based scoring
    switch (timeContext.timeOfDay) {
      case TimeOfDay.morning:
        scores['perfect_start'] = _scoreForKeywords(
          place, 
          ['cafe', 'coffee', 'breakfast', 'brunch', 'market', 'morning', 'fresh']
        );
        break;
      case TimeOfDay.afternoon:
        scores['afternoon_perfect'] = _scoreForKeywords(
          place, 
          ['lunch', 'museum', 'gallery', 'shopping', 'activity', 'tour']
        );
        break;
      case TimeOfDay.evening:
        scores['evening_vibes'] = _scoreForKeywords(
          place, 
          ['dinner', 'restaurant', 'bar', 'entertainment', 'evening', 'nightlife']
        );
        break;
      case TimeOfDay.night:
        scores['night_life'] = _scoreForKeywords(
          place, 
          ['bar', 'pub', 'club', 'late', 'night', '24h']
        );
        break;
    }
    
    // Weather-based scoring
    if (!weatherContext.isGoodForOutdoor) {
      scores['indoor_gems'] = _scoreForKeywords(
        place, 
        ['indoor', 'museum', 'gallery', 'cafe', 'restaurant', 'shopping', 'cozy']
      );
    } else {
      scores['outdoor_fun'] = _scoreForKeywords(
        place, 
        ['outdoor', 'park', 'terrace', 'patio', 'garden', 'walk', 'nature']
      );
    }
    
    // Energy level scoring
    switch (moodContext.energyLevel) {
      case EnergyLevel.high:
        scores['high_energy'] = _scoreForKeywords(
          place, 
          ['adventure', 'active', 'sport', 'climbing', 'tour', 'exciting', 'energy']
        );
        break;
      case EnergyLevel.low:
        scores['peaceful'] = _scoreForKeywords(
          place, 
          ['peaceful', 'calm', 'quiet', 'spa', 'wellness', 'relax', 'serene']
        );
        break;
      case EnergyLevel.medium:
        scores['flexible'] = 0.5; // Neutral score for medium energy
        break;
    }
    
    // Social preference scoring
    switch (moodContext.socialPreference) {
      case SocialPreference.social:
        scores['social_spots'] = _scoreForKeywords(
          place, 
          ['social', 'group', 'bar', 'restaurant', 'entertainment', 'event']
        );
        break;
      case SocialPreference.solo:
        scores['solo_friendly'] = _scoreForKeywords(
          place, 
          ['quiet', 'peaceful', 'library', 'museum', 'solo', 'contemplative']
        );
        break;
      case SocialPreference.flexible:
        // No specific scoring needed
        break;
    }
    
    // Apply user preference boosting
    if (userPreferences.isNotEmpty) {
      scores = _applyUserPreferenceBoost(scores, place, userPreferences);
    }
    
    return scores;
  }
  
  /// Score a place based on keyword matching
  static double _scoreForKeywords(Place place, List<String> keywords) {
    double score = 0.0;
    final searchText = '${place.name} ${place.description ?? ''} ${place.activities.join(' ')}'.toLowerCase();
    
    for (final keyword in keywords) {
      if (searchText.contains(keyword)) {
        score += 0.3;
      }
    }
    
    // Boost for high ratings
    score += (place.rating - 3.0) * 0.1;
    
    // Cap at 1.0
    return score > 1.0 ? 1.0 : score;
  }
  
  /// Calculate overall relevance score for a place
  static double _calculatePlaceScore(
    Place place,
    SmartContext context,
    Map<String, dynamic> userPreferences,
  ) {
    double score = place.rating * 0.3; // Base rating score
    
    // Add context relevance
    final timeBonus = _getTimeRelevanceBonus(place, context.timeContext);
    final weatherBonus = _getWeatherRelevanceBonus(place, context.weatherContext);
    final moodBonus = _getMoodRelevanceBonus(place, context.moodContext);
    
    score += timeBonus + weatherBonus + moodBonus;
    
    // User preference boost
    if (userPreferences.isNotEmpty) {
      score += _getUserPreferenceBonus(place, userPreferences);
    }
    
    return score;
  }
  
  static double _getTimeRelevanceBonus(Place place, TimeContext timeContext) {
    final keywords = _getTimeKeywords(timeContext);
    return _scoreForKeywords(place, keywords) * 0.4;
  }
  
  static double _getWeatherRelevanceBonus(Place place, WeatherContext weatherContext) {
    final keywords = weatherContext.isGoodForOutdoor 
      ? ['outdoor', 'terrace', 'patio', 'garden']
      : ['indoor', 'cozy', 'warm', 'covered'];
    return _scoreForKeywords(place, keywords) * 0.3;
  }
  
  static double _getMoodRelevanceBonus(Place place, MoodContext moodContext) {
    List<String> keywords = [];
    switch (moodContext.energyLevel) {
      case EnergyLevel.high:
        keywords = ['active', 'adventure', 'exciting', 'energy'];
        break;
      case EnergyLevel.low:
        keywords = ['peaceful', 'calm', 'quiet', 'relax'];
        break;
      case EnergyLevel.medium:
        keywords = ['flexible', 'comfortable'];
        break;
    }
    return _scoreForKeywords(place, keywords) * 0.3;
  }
  
  static List<String> _getTimeKeywords(TimeContext timeContext) {
    switch (timeContext.timeOfDay) {
      case TimeOfDay.morning:
        return ['cafe', 'coffee', 'breakfast', 'morning'];
      case TimeOfDay.afternoon:
        return ['lunch', 'museum', 'gallery', 'activity'];
      case TimeOfDay.evening:
        return ['dinner', 'restaurant', 'bar', 'evening'];
      case TimeOfDay.night:
        return ['bar', 'pub', 'late', 'night'];
    }
  }
  
  /// Get user preferences from Supabase
  static Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final response = await _supabase
        .from('user_preferences')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();
      
      if (response == null) {
        // Create default preferences if none exist
        await _createDefaultUserPreferences(userId);
        return {};
      }
      
      return response;
    } catch (e) {
      print('Error fetching user preferences: $e');
      return {};
    }
  }
  
  /// Apply user preference boost to scores
  static Map<String, double> _applyUserPreferenceBoost(
    Map<String, double> scores,
    Place place,
    Map<String, dynamic> userPreferences,
  ) {
    final boostedScores = Map<String, double>.from(scores);
    
    // Boost based on preferred activity types
    final preferredActivities = userPreferences['preferred_activities'] as List<dynamic>? ?? [];
    for (final activity in preferredActivities) {
      if (place.activities.any((a) => a.toLowerCase().contains(activity.toString().toLowerCase()))) {
        boostedScores.updateAll((key, value) => value + 0.2);
      }
    }
    
    // Boost based on preferred venue types
    final preferredVenues = userPreferences['preferred_venues'] as List<dynamic>? ?? [];
    for (final venue in preferredVenues) {
      if (place.name.toLowerCase().contains(venue.toString().toLowerCase()) ||
          (place.description ?? '').toLowerCase().contains(venue.toString().toLowerCase())) {
        boostedScores.updateAll((key, value) => value + 0.15);
      }
    }
    
    return boostedScores;
  }
  
  static double _getUserPreferenceBonus(Place place, Map<String, dynamic> userPreferences) {
    double bonus = 0.0;
    
    // Check visit history
    final visitedPlaces = userPreferences['visited_places'] as List<dynamic>? ?? [];
    if (visitedPlaces.contains(place.id)) {
      bonus += 0.1; // Small boost for previously visited places
    }
    
    // Check saved places
    final savedPlaces = userPreferences['saved_places'] as List<dynamic>? ?? [];
    if (savedPlaces.contains(place.id)) {
      bonus += 0.3; // Bigger boost for saved places
    }
    
    return bonus;
  }
  
  /// Generate smart recommendations based on groups
  static Future<List<String>> _generateSmartRecommendations(
    Map<String, List<Place>> groups,
    SmartContext context,
    Map<String, dynamic> userPreferences,
  ) async {
    final recommendations = <String>[];
    
    // Add group-based recommendations
    for (final groupName in groups.keys) {
      final groupPlaces = groups[groupName]!;
      if (groupPlaces.isNotEmpty) {
        recommendations.add('${groupPlaces.length} ${groupName.replaceAll('_', ' ')} options');
      }
    }
    
    // Add contextual recommendations
    final timeContext = context.timeContext;
    if (timeContext.isWeekend) {
      recommendations.add('Weekend special activities available');
    }
    
    if (context.weatherContext.isGoodForOutdoor) {
      recommendations.add('Perfect weather for outdoor activities');
    }
    
    return recommendations.take(3).toList();
  }
  
  /// Create default user preferences in Supabase
  static Future<void> _createDefaultUserPreferences(String userId) async {
    try {
      await _supabase.from('user_preferences').insert({
        'user_id': userId,
        'preferred_activities': <String>[],
        'preferred_venues': <String>[],
        'visited_places': <String>[],
        'saved_places': <String>[],
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating default user preferences: $e');
    }
  }
  
  /// Update user preferences based on interactions
  static Future<void> updateUserPreferences({
    required String userId,
    String? visitedPlaceId,
    String? savedPlaceId,
    List<String>? preferredActivities,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (visitedPlaceId != null) {
        // Add to visited places
        final current = await _getUserPreferences(userId);
        final visited = List<String>.from(current['visited_places'] ?? []);
        if (!visited.contains(visitedPlaceId)) {
          visited.add(visitedPlaceId);
          updates['visited_places'] = visited;
        }
      }
      
      if (savedPlaceId != null) {
        // Add to saved places
        final current = await _getUserPreferences(userId);
        final saved = List<String>.from(current['saved_places'] ?? []);
        if (!saved.contains(savedPlaceId)) {
          saved.add(savedPlaceId);
          updates['saved_places'] = saved;
        }
      }
      
      if (preferredActivities != null) {
        updates['preferred_activities'] = preferredActivities;
      }
      
      if (updates.isNotEmpty) {
        await _supabase
          .from('user_preferences')
          .update(updates)
          .eq('user_id', userId);
      }
    } catch (e) {
      print('Error updating user preferences: $e');
    }
  }
} 