import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/recommendation.dart';

part 'supabase_recommendation_repository.g.dart';

@riverpod
SupabaseRecommendationRepository supabaseRecommendationRepository(
  SupabaseRecommendationRepositoryRef ref,
) {
  return SupabaseRecommendationRepository(
    Supabase.instance.client,
  );
}

class SupabaseRecommendationRepository {
  final SupabaseClient _client;
  static const String _table = 'recommendations';

  SupabaseRecommendationRepository(this._client);

  Future<List<Recommendation>> getRecommendations() async {
    final response = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) =>
            Recommendation.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<void> saveRecommendation(Recommendation recommendation) async {
    await _client.from(_table).upsert({
      'id': recommendation.id,
      'title': recommendation.title,
      'description': recommendation.description,
      'category': recommendation.category,
      'confidence': recommendation.confidence,
      'tags': recommendation.tags,
      'created_at': recommendation.createdAt.toIso8601String(),
      'current_mood': recommendation.currentMood?.toJson(),
      'current_weather': recommendation.currentWeather?.toJson(),
      'is_completed': recommendation.isCompleted,
    });
  }

  Future<void> markAsCompleted(String recommendationId) async {
    await _client
        .from(_table)
        .update({'is_completed': true})
        .eq('id', recommendationId);
  }

  Stream<List<Recommendation>> watchRecommendations() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((records) => records
            .map((record) =>
                Recommendation.fromJson(Map<String, dynamic>.from(record)))
            .toList());
  }
}
