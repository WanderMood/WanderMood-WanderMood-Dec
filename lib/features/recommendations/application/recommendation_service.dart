import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mood/application/mood_service.dart';
import '../../weather/application/weather_service.dart';
import '../domain/models/travel_recommendation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../weather/domain/models/weather_location.dart';

part 'recommendation_service.g.dart';

@riverpod
class RecommendationService extends _$RecommendationService {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<WeatherLocation>> build() async {
    return _getPopularDestinations();
  }

  Future<List<WeatherLocation>> _getPopularDestinations() async {
    // Example popular destinations
    return [
      WeatherLocation(
        id: 'paris',
        name: 'Paris',
        latitude: 48.8566,
        longitude: 2.3522,
      ),
      WeatherLocation(
        id: 'tokyo',
        name: 'Tokyo',
        latitude: 35.6762,
        longitude: 139.6503,
      ),
      WeatherLocation(
        id: 'newyork',
        name: 'New York',
        latitude: 40.7128,
        longitude: -74.0060,
      ),
      WeatherLocation(
        id: 'sydney',
        name: 'Sydney',
        latitude: -33.8688,
        longitude: 151.2093,
      ),
      WeatherLocation(
        id: 'dubai',
        name: 'Dubai',
        latitude: 25.2048,
        longitude: 55.2708,
      ),
    ];
  }

  Future<List<TravelRecommendation>> getRecommendations({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 5,
  }) async {
    try {
      final destinations = await _getPopularDestinations();
      final recommendations = <TravelRecommendation>[];

      for (final destination in destinations) {
        final recommendation = TravelRecommendation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: destination.name,
          description: 'Een perfecte bestemming voor je huidige stemming!',
          location: destination.name,
          imageUrl: 'https://example.com/image.jpg',
          rating: 4.5,
          tags: ['cultuur', 'natuur', 'geschiedenis'],
          price: 500.0,
        );

        recommendations.add(recommendation);
      }

      recommendations.sort((a, b) => b.rating.compareTo(a.rating));
      return recommendations.take(limit).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error generating recommendations: $e');
      return [];
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final response = await _supabase
          .from('travel_recommendations')
          .select('is_favorite')
          .eq('id', id)
          .single();

      final currentFavorite = response['is_favorite'] as bool;

      await _supabase
          .from('travel_recommendations')
          .update({'is_favorite': !currentFavorite})
          .eq('id', id);
    } catch (e) {
      if (kDebugMode) debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  Future<List<TravelRecommendation>> getFavorites() async {
    try {
      final response = await _supabase
          .from('travel_recommendations')
          .select()
          .eq('is_favorite', true)
          .order('rating', ascending: false);

      return (response as List)
          .map((json) => TravelRecommendation.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching favorites: $e');
      return [];
    }
  }

  Future<List<TravelRecommendation>> searchRecommendations(String query) async {
    try {
      final response = await _supabase
          .from('travel_recommendations')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%')
          .order('rating', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => TravelRecommendation.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error searching recommendations: $e');
      return [];
    }
  }

  Future<void> saveRecommendation(TravelRecommendation recommendation) async {
    try {
      await _supabase
          .from('travel_recommendations')
          .insert(recommendation.toJson());
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving recommendation: $e');
      rethrow;
    }
  }
} 