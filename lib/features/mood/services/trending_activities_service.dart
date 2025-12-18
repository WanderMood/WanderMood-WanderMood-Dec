import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trending_activity.dart';

class TrendingActivitiesService {
  TrendingActivitiesService(this._client);

  final SupabaseClient _client;

  Future<List<TrendingActivity>> fetchTrendingActivities({int limit = 10}) async {
    final response = await _client
        .from('social_posts')
        .select('id, caption, image_urls, location, mood_tag, likes_count')
        .order('likes_count', ascending: false)
        .limit(limit);

    final List data = response as List;
    return data.map((e) {
      final imageUrls = (e['image_urls'] as List?)?.cast<String>() ?? const [];
      final caption = (e['caption'] as String?) ?? '';
      final mood = (e['mood_tag'] as String?)?.toLowerCase() ?? '';
      final category = _inferCategoryFromCaptionOrMood(caption, mood);
      final likes = (e['likes_count'] as int?) ?? 0;
      final trend = likes > 50 ? 'hot' : likes > 20 ? 'rising' : 'popular';
      final peopleCount = (likes * 1.5).toInt().clamp(5, 9999);
      final popularityScore = (likes > 0 ? (80 + (likes % 20)) : 82).toDouble();
      return TrendingActivity(
        id: e['id'] as String,
        title: caption.trim().isNotEmpty ? caption : 'Trending spot',
        description: caption,
        imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
        location: e['location'] as String? ?? '',
        moodTag: mood,
        likes: likes,
        emoji: _emojiForMood(mood),
        trend: trend,
        subtitle: _subtitleForCategory(category),
        peopleCount: peopleCount,
        popularityScore: popularityScore,
        category: category,
      );
    }).toList();
  }
}

final trendingActivitiesServiceProvider = Provider<TrendingActivitiesService>((ref) {
  final client = Supabase.instance.client;
  return TrendingActivitiesService(client);
});

final trendingActivitiesProvider = FutureProvider<List<TrendingActivity>>((ref) async {
  final service = ref.watch(trendingActivitiesServiceProvider);
  return service.fetchTrendingActivities(limit: 12);
});

String _emojiForMood(String mood) {
  switch (mood) {
    case 'adventurous':
      return '🚀';
    case 'relaxed':
      return '😌';
    case 'cultural':
      return '🎭';
    case 'romantic':
      return '💕';
    case 'social':
      return '👥';
    case 'energetic':
      return '⚡';
    case 'creative':
      return '🎨';
    case 'contemplative':
      return '🧘';
    default:
      return '⭐';
  }
}

String _inferCategoryFromCaptionOrMood(String caption, String mood) {
  final text = '${caption.toLowerCase()} $mood';
  if (text.contains('museum') || text.contains('gallery') || text.contains('art')) return 'culture';
  if (text.contains('restaurant') || text.contains('cafe') || text.contains('food') || text.contains('bar')) return 'dining';
  if (text.contains('park') || text.contains('walk') || text.contains('tour') || text.contains('outdoor')) return 'outdoor';
  if (text.contains('view') || text.contains('bridge') || text.contains('tower') || text.contains('landmark')) return 'sightseeing';
  if (text.contains('shop') || text.contains('market')) return 'shopping';
  if (text.contains('gym') || text.contains('fitness') || text.contains('run')) return 'fitness';
  return 'activity';
}

String _subtitleForCategory(String category) {
  switch (category) {
    case 'dining':
      return 'Tasty bites and cozy vibes';
    case 'culture':
      return 'Art, history, and inspiration';
    case 'outdoor':
      return 'Fresh air and open spaces';
    case 'sightseeing':
      return 'Iconic views and photo spots';
    case 'shopping':
      return 'Local finds and unique shops';
    case 'fitness':
      return 'Move your body, feel great';
    default:
      return 'Popular with locals right now';
  }
}


