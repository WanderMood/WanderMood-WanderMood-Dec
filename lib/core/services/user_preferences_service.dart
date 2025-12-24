import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../providers/preferences_provider.dart';
import '../../features/places/models/place.dart';

/// Service to apply user preferences from onboarding to app features
class UserPreferencesService {
  final UserPreferences _preferences;

  UserPreferencesService(this._preferences);

  /// Get user's travel interests from onboarding
  List<String> get travelInterests => _preferences.travelInterests;

  /// Get user's selected moods from onboarding
  List<String> get selectedMoods => _preferences.selectedMoods;

  /// Get user's travel styles from onboarding
  List<String> get travelStyles => _preferences.travelStyles;

  /// Get user's planning pace
  String get planningPace => _preferences.planningPace;

  /// Get user's social vibe preferences
  List<String> get socialVibe => _preferences.socialVibe;

  /// Check if a place matches user's travel interests
  bool placeMatchesInterests(Place place) {
    if (travelInterests.isEmpty) return true; // No preferences = show all

    // Map onboarding interests to place types/categories
    final interestToTypes = {
      'Food & Dining': ['restaurant', 'cafe', 'bar', 'food', 'meal_takeaway'],
      'Arts & Culture': ['museum', 'art_gallery', 'library', 'tourist_attraction'],
      'Shopping & Markets': ['shopping_mall', 'store', 'market', 'clothing_store'],
      'Nature & Outdoors': ['park', 'natural_feature', 'zoo', 'campground'],
      'Nightlife': ['bar', 'night_club', 'lounge'],
      'Wellness & Relaxation': ['spa', 'gym', 'yoga_studio', 'beauty_salon'],
      'Stays & Getaways': ['lodging', 'hotel', 'apartment_rental'],
    };

    // Check if place types match any of user's interests
    for (final interest in travelInterests) {
      final matchingTypes = interestToTypes[interest] ?? [];
      if (matchingTypes.any((type) => place.types.contains(type))) {
        return true;
      }
    }

    return false;
  }

  /// Check if a place matches user's travel styles
  bool placeMatchesTravelStyles(Place place) {
    if (travelStyles.isEmpty) return true; // No preferences = show all

    // Map travel styles to place characteristics
    final styleToCharacteristics = {
      'Adventurous': ['adventure', 'outdoor', 'active', 'exploration'],
      'Relaxed': ['spa', 'cafe', 'park', 'quiet', 'peaceful'],
      'Cultural': ['museum', 'gallery', 'theater', 'cultural'],
      'Social': ['bar', 'restaurant', 'market', 'event', 'social'],
      'Romantic': ['romantic', 'intimate', 'fine_dining', 'scenic'],
      'Budget-Friendly': ['affordable', 'cheap', 'free', 'budget'],
      'Luxury': ['luxury', 'premium', 'fine_dining', 'exclusive'],
    };

    // Check if place description/name matches travel styles
    final placeText = '${place.name} ${place.description ?? ''}'.toLowerCase();
    
    for (final style in travelStyles) {
      final characteristics = styleToCharacteristics[style] ?? [];
      if (characteristics.any((char) => placeText.contains(char))) {
        return true;
      }
    }

    return false;
  }

  /// Get preferred place categories based on interests
  List<String> getPreferredCategories() {
    if (travelInterests.isEmpty) return [];

    final interestToCategory = {
      'Food & Dining': 'restaurants',
      'Arts & Culture': 'culture',
      'Shopping & Markets': 'shopping',
      'Nature & Outdoors': 'nature',
      'Nightlife': 'nightlife',
      'Wellness & Relaxation': 'wellness',
      'Stays & Getaways': 'accommodations',
    };

    return travelInterests
        .map((interest) => interestToCategory[interest])
        .whereType<String>()
        .toList();
  }

  /// Get mood-based activity suggestions
  List<String> getMoodBasedSuggestions(String currentMood) {
    // Use onboarding moods to personalize suggestions
    if (selectedMoods.isEmpty) return [];

    // Map moods to activity types
    final moodToActivities = {
      'Adventurous': ['hiking', 'exploration', 'adventure', 'outdoor'],
      'Peaceful': ['spa', 'meditation', 'quiet', 'relaxation'],
      'Social': ['restaurant', 'bar', 'event', 'social'],
      'Cultural': ['museum', 'gallery', 'theater', 'cultural'],
      'Romantic': ['romantic', 'intimate', 'scenic', 'fine_dining'],
      'Energetic': ['fitness', 'sports', 'active', 'outdoor'],
      'Creative': ['art', 'workshop', 'creative', 'design'],
      'Contemplative': ['library', 'quiet', 'peaceful', 'reflection'],
    };

    // Find matching activities for current mood
    final matchingMoods = selectedMoods.where((mood) => 
      mood.toLowerCase() == currentMood.toLowerCase()
    ).toList();

    if (matchingMoods.isEmpty) return [];

    final activities = <String>[];
    for (final mood in matchingMoods) {
      activities.addAll(moodToActivities[mood] ?? []);
    }

    return activities;
  }

  /// Check if user prefers spontaneous planning (affects My Day suggestions)
  bool prefersSpontaneousPlanning() {
    return planningPace.toLowerCase().contains('same day') || 
           planningPace.toLowerCase().contains('spontaneous');
  }

  /// Check if user prefers advance planning
  bool prefersAdvancePlanning() {
    return planningPace.toLowerCase().contains('advance') || 
           planningPace.toLowerCase().contains('planner');
  }

  /// Get social preferences for recommendations
  bool prefersSocialActivities() {
    return socialVibe.contains('Social') || 
           socialVibe.contains('Group') ||
           socialVibe.contains('Community');
  }

  /// Get solo preferences
  bool prefersSoloActivities() {
    return socialVibe.contains('Solo') || 
           socialVibe.contains('Independent');
  }
}

/// Provider for UserPreferencesService
final userPreferencesServiceProvider = Provider<UserPreferencesService>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return UserPreferencesService(preferences);
});



