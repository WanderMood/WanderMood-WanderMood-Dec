import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/place.dart';

part 'filtered_places_provider.g.dart';

const int PAGE_SIZE = 10;

@riverpod
class FilteredPlaces extends _$FilteredPlaces {
  final Map<String, List<String>> _moodToActivityTypes = {
    'Energetic': ['gym', 'park', 'stadium', 'amusement_park', 'sports_complex'],
    'Relaxed': ['spa', 'park', 'cafe', 'library', 'art_gallery'],
    'Cultural': ['museum', 'art_gallery', 'church', 'historic', 'landmark'],
    'Social': ['restaurant', 'bar', 'night_club', 'cafe', 'shopping_mall'],
    'Romantic': ['restaurant', 'park', 'art_gallery', 'cafe', 'tourist_attraction'],
    'Adventure': ['amusement_park', 'park', 'tourist_attraction', 'zoo', 'aquarium'],
    'Foodie': ['restaurant', 'cafe', 'bakery', 'food', 'bar'],
  };

  @override
  Future<List<Place>> build({
    required String currentMood,
    required List<Place> allPlaces,
    int page = 0,
  }) async {
    final start = page * PAGE_SIZE;
    final end = start + PAGE_SIZE;

    // Get relevant activity types for current mood
    final relevantTypes = _moodToActivityTypes[currentMood] ?? [];

    // Filter and score places
    final scoredPlaces = allPlaces.map((place) {
      final score = _calculatePlaceScore(
        place,
        currentMood,
        relevantTypes,
      );
      return MapEntry(place, score);
    }).where((entry) => entry.value > 0.0) // Filter out places with 0 score
        .toList();

    // Sort by score
    scoredPlaces.sort((a, b) => b.value.compareTo(a.value));

    // Return paginated results
    final paginatedPlaces = scoredPlaces
        .skip(start)
        .take(PAGE_SIZE)
        .map((entry) => entry.key)
        .toList();

    return paginatedPlaces;
  }

  double _calculatePlaceScore(
    Place place,
    String currentMood,
    List<String> relevantTypes,
  ) {
    double score = 0.0;

    // Mood match (40%)
    final moodScore = _calculateMoodScore(place, relevantTypes);
    score += moodScore * 0.4;

    // Rating score (30%)
    final ratingScore = (place.rating ?? 0.0) / 5.0;
    score += ratingScore * 0.3;

    // Time relevance (20%)
    final timeScore = _calculateTimeScore(place);
    score += timeScore * 0.2;

    // Distance score (10%) - lower is better
    final distanceScore = _calculateDistanceScore(place);
    score += distanceScore * 0.1;

    return score;
  }

  double _calculateMoodScore(Place place, List<String> relevantTypes) {
    if (place.types.isEmpty) return 0.0;
    
    int matchingTypes = 0;
    for (final type in place.types) {
      if (relevantTypes.contains(type.toLowerCase())) {
        matchingTypes++;
      }
    }
    
    return matchingTypes / place.types.length;
  }

  double _calculateTimeScore(Place place) {
    if (place.openingHours == null) return 0.5; // Neutral score if unknown
    
    // Check if place is open now
    if (place.openingHours?.isOpen == true) {
      return 1.0;
    }
    
    return 0.3; // Lower score for closed places
  }

  double _calculateDistanceScore(Place place) {
    // [Place] has no cached distance here; keep a neutral contribution until
    // caller passes user-relative distances into scoring.
    return 0.5;
  }
} 