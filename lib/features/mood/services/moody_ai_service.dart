import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/check_in.dart';
import '../models/activity_rating.dart';
import 'check_in_service.dart';
import 'activity_rating_service.dart';

final moodyAIServiceProvider = Provider<MoodyAIService>((ref) {
  final checkInService = ref.watch(checkInServiceProvider);
  final ratingService = ref.watch(activityRatingServiceProvider);
  return MoodyAIService(checkInService, ratingService);
});

class MoodyAIService {
  final CheckInService _checkInService;
  final ActivityRatingService _ratingService;
  final Dio _dio = Dio();
  
  // TODO: Replace with actual API key from environment
  static const String _openAIKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '', // Will use mock responses if not set
  );

  MoodyAIService(this._checkInService, this._ratingService);

  /// Generate contextual response to user's check-in
  Future<String> generateCheckInResponse({
    required String userText,
    required String mood,
    required List<String> activities,
    required List<String> reactions,
    List<ActivityRating>? pendingRatings,
  }) async {
    try {
      // Build context from user history
      final context = await _buildUserContext();
      
      // If OpenAI key is available, use real AI
      if (_openAIKey.isNotEmpty) {
        return await _generateOpenAIResponse(
          userText: userText,
          mood: mood,
          activities: activities,
          reactions: reactions,
          context: context,
          pendingRatings: pendingRatings,
        );
      }
      
      // Fallback to smart rule-based responses
      return _generateSmartResponse(
        userText: userText,
        mood: mood,
        activities: activities,
        reactions: reactions,
        context: context,
        pendingRatings: pendingRatings,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to generate AI response: $e');
      return _generateFallbackResponse(mood);
    }
  }

  /// Build user context from history
  Future<Map<String, dynamic>> _buildUserContext() async {
    final recentCheckIns = await _checkInService.getRecentCheckIns(limit: 5);
    final recentRatings = await _ratingService.getRecentRatings(limit: 10);
    final topRated = await _ratingService.getTopRated(limit: 5);

    return {
      'recent_check_ins': recentCheckIns.map((c) => {
        'mood': c.mood,
        'text': c.text,
        'activities': c.activities,
        'timestamp': c.timestamp.toIso8601String(),
      }).toList(),
      'recent_ratings': recentRatings.map((r) => {
        'activity': r.activityName,
        'stars': r.stars,
        'tags': r.tags,
        'mood': r.mood,
      }).toList(),
      'top_rated_activities': topRated.map((r) => r.activityName).toList(),
      'favorite_tags': _getFavoriteTags(recentRatings),
    };
  }

  /// Generate response using OpenAI
  Future<String> _generateOpenAIResponse({
    required String userText,
    required String mood,
    required List<String> activities,
    required List<String> reactions,
    required Map<String, dynamic> context,
    List<ActivityRating>? pendingRatings,
  }) async {
    try {
      final systemPrompt = _buildSystemPrompt(context);
      final userPrompt = _buildUserPrompt(
        userText: userText,
        mood: mood,
        activities: activities,
        reactions: reactions,
        pendingRatings: pendingRatings,
      );

      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openAIKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'max_tokens': 200,
          'temperature': 0.8,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      return content.trim();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ OpenAI API error: $e');
      // Fallback to smart response
      return _generateSmartResponse(
        userText: userText,
        mood: mood,
        activities: activities,
        reactions: reactions,
        context: context,
        pendingRatings: pendingRatings,
      );
    }
  }

  String _buildSystemPrompt(Map<String, dynamic> context) {
    return '''You are Moody, the friendly AI travel companion for WanderMood app. You're warm, enthusiastic, and genuinely interested in the user's experiences.

Your personality:
- Casual and friendly, like talking to a bestie
- Use emojis naturally (but not excessively)
- Remember what users tell you and reference it later
- Ask thoughtful follow-up questions
- Celebrate wins and empathize with struggles
- Keep responses concise (2-3 sentences max)
- Be culturally aware and inclusive

User context:
${_formatContextForAI(context)}

Guidelines:
- If they mention specific places/activities, respond specifically to those
- If they've rated activities recently, acknowledge patterns
- If it's a recurring activity, reference previous experiences
- Ask "How was it?" for things they did today
- Suggest related activities based on their preferences
- Keep it conversational, not robotic''';
  }

  String _buildUserPrompt({
    required String userText,
    required String mood,
    required List<String> activities,
    required List<String> reactions,
    List<ActivityRating>? pendingRatings,
  }) {
    final parts = <String>[];
    
    parts.add('User check-in:');
    parts.add('Mood: $mood');
    if (activities.isNotEmpty) parts.add('Activities: ${activities.join(", ")}');
    if (reactions.isNotEmpty) parts.add('Quick reactions: ${reactions.join(", ")}');
    parts.add('What they said: "$userText"');
    
    if (pendingRatings != null && pendingRatings.isNotEmpty) {
      parts.add('\nActivities they completed today: ${pendingRatings.map((r) => r.activityName).join(", ")}');
    }

    parts.add('\nGenerate a warm, personalized response. Reference what they said and ask about their completed activities if applicable.');
    
    return parts.join('\n');
  }

  String _formatContextForAI(Map<String, dynamic> context) {
    final parts = <String>[];
    
    final recentCheckIns = context['recent_check_ins'] as List?;
    if (recentCheckIns != null && recentCheckIns.isNotEmpty) {
      parts.add('Recent check-ins:');
      for (final checkIn in recentCheckIns.take(3)) {
        parts.add('- ${checkIn['mood']}: ${checkIn['text']}');
      }
    }
    
    final topActivities = context['top_rated_activities'] as List?;
    if (topActivities != null && topActivities.isNotEmpty) {
      parts.add('\nFavorite activities: ${topActivities.join(", ")}');
    }
    
    final favoriteTags = context['favorite_tags'] as List?;
    if (favoriteTags != null && favoriteTags.isNotEmpty) {
      parts.add('What they love most: ${favoriteTags.join(", ")}');
    }
    
    return parts.join('\n');
  }

  /// Smart rule-based response (fallback when no OpenAI)
  String _generateSmartResponse({
    required String userText,
    required String mood,
    required List<String> activities,
    required List<String> reactions,
    required Map<String, dynamic> context,
    List<ActivityRating>? pendingRatings,
  }) {
    final text = userText.toLowerCase();
    final responses = <String>[];

    // IMPORTANT: Check if user wrote something meaningful first
    if (userText.trim().isNotEmpty) {
      // Food-related
      if (text.contains('hungry') || text.contains('food') || text.contains('order') || text.contains('eat')) {
        responses.add('Ooh hungry vibes! 🍕 Hope you get some delicious food soon!');
      }
      
      // Comfort/Temperature
      if (text.contains('cold') || text.contains('warm') || text.contains('cozy')) {
        if (text.contains('cold')) {
          responses.add('Stay warm! Time to get cozy 🧣');
        } else {
          responses.add('That sounds so cozy! 💙');
        }
      }
      
      // Relaxing/Resting
      if (text.contains('sofa') || text.contains('couch') || text.contains('bed') || text.contains('relax')) {
        responses.add('Perfect chill time! You deserve it 😌');
      }
      
      // Shopping/Clothes
      if (text.contains('tried') || text.contains('wore') || text.contains('bought')) {
        if (text.contains('clothes') || text.contains('outfit')) {
          responses.add('Ooh new clothes! 👗 I love that energy!');
        }
      }
      
      // Energy levels
      if (text.contains('tired') || text.contains('exhausted') || text.contains('sleepy')) {
        responses.add('Sounds like you need some rest 😴');
      }
      
      // Positive vibes
      if (text.contains('amazing') || text.contains('great') || text.contains('awesome') || text.contains('love')) {
        responses.add('Yes! Love that vibe! ✨');
      }
      
      // Work/Productive
      if (text.contains('work') || text.contains('productive') || text.contains('busy')) {
        responses.add('Productive day! 💪');
      }
      
      // Social
      if (text.contains('friend') || text.contains('friends') || text.contains('met') || text.contains('people')) {
        responses.add('Social time is the best! 👥');
      }
    }

    // Ask about completed activities
    if (pendingRatings != null && pendingRatings.isNotEmpty) {
      final activity = pendingRatings.first.activityName;
      responses.add('How was $activity today? 💭');
    }

    // Mood-specific responses (only if nothing else matched)
    if (responses.isEmpty) {
      responses.add(_getMoodResponse(mood));
    }

    // Reference previous check-ins if available
    final recentCheckIns = context['recent_check_ins'] as List?;
    if (recentCheckIns != null && recentCheckIns.length > 1 && responses.length == 1) {
      final previous = recentCheckIns[1] as Map;
      if (previous['mood'] == mood) {
        responses.add('Same vibe as yesterday! Love the consistency 🌟');
      }
    }

    return responses.take(2).join(' ');
  }

  String _getMoodResponse(String mood) {
    final responses = {
      'adventurous': 'Adventure mode activated! Where to next? 🗺️',
      'relaxed': 'Taking it easy today? Perfect vibes 🌸',
      'energetic': 'Love that energy! Let\'s make today count! ⚡',
      'curious': 'Ready to explore something new? I\'m here for it! 👀',
      'inspired': 'That creative spark is showing! ✨',
      'contemplative': 'Reflecting mode, I see. What\'s on your mind? 💭',
    };
    
    return responses[mood.toLowerCase()] ?? 'Hey! Great to check in with you 💛';
  }

  String _generateFallbackResponse(String mood) {
    return 'Thanks for checking in! How\'s your day going? 💛';
  }

  List<String> _getFavoriteTags(List<ActivityRating> ratings) {
    final tagCounts = <String, int>{};
    final highRated = ratings.where((r) => r.stars >= 4);
    
    for (final rating in highRated) {
      for (final tag in rating.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final sorted = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(3).map((e) => e.key).toList();
  }

  /// Generate predictive suggestions based on patterns
  Future<List<String>> generatePredictiveSuggestions({
    required String currentMood,
    required String timeOfDay,
  }) async {
    try {
      final recentRatings = await _ratingService.getRecentRatings(limit: 20);
      final moodRatings = await _ratingService.getRatingsByMood(currentMood);

      // Find patterns: what activities did they love in this mood?
      final highRated = moodRatings.where((r) => r.stars >= 4).toList();
      
      if (highRated.isEmpty) {
        return _getGenericSuggestions(currentMood, timeOfDay);
      }

      // Get activities they loved in this mood
      final suggestions = <String>[];
      final activities = highRated.map((r) => r.activityName).toSet().take(3);
      
      for (final activity in activities) {
        suggestions.add('Based on your vibes, try: $activity 🎯');
      }

      // Add time-based suggestion
      suggestions.add(_getTimeBasedSuggestion(timeOfDay));

      return suggestions.take(3).toList();
    } catch (e) {
      return _getGenericSuggestions(currentMood, timeOfDay);
    }
  }

  List<String> _getGenericSuggestions(String mood, String timeOfDay) {
    final moodSuggestions = {
      'adventurous': ['Try a new hiking trail 🥾', 'Explore a hidden spot 🗺️'],
      'relaxed': ['Find a cozy café ☕', 'Take a peaceful walk 🌿'],
      'energetic': ['Hit a workout class 💪', 'Try a fun activity 🎾'],
      'curious': ['Visit a museum 🏛️', 'Try new cuisine 🍜'],
    };

    return moodSuggestions[mood.toLowerCase()] ?? 
      ['Explore something new today! 🌟', 'Check out local favorites 📍'];
  }

  String _getTimeBasedSuggestion(String timeOfDay) {
    final suggestions = {
      'morning': 'Start with a breakfast spot you\'ve been wanting to try 🥐',
      'afternoon': 'Perfect time for that activity you bookmarked! 🎯',
      'evening': 'Wind down with something special tonight 🌙',
    };
    
    return suggestions[timeOfDay] ?? 'Make today memorable! ✨';
  }

  /// Analyze patterns and generate insights
  Future<Map<String, dynamic>> analyzeUserPatterns(String userId) async {
    try {
      final recentRatings = await _ratingService.getRecentRatings(limit: 50);
      
      if (recentRatings.isEmpty) {
        return {'insights': [], 'recommendations': []};
      }

      // Group by mood
      final moodGroups = <String, List<ActivityRating>>{};
      for (final rating in recentRatings) {
        moodGroups[rating.mood] = [...(moodGroups[rating.mood] ?? []), rating];
      }

      // Find best mood-activity combinations
      final insights = <String>[];
      final recommendations = <String>[];

      for (final entry in moodGroups.entries) {
        final mood = entry.key;
        final ratings = entry.value;
        final avgStars = ratings.fold<int>(0, (sum, r) => sum + r.stars) / ratings.length;
        
        if (avgStars >= 4.0) {
          final topActivity = ratings
              .reduce((a, b) => a.stars > b.stars ? a : b)
              .activityName;
          insights.add('When you\'re $mood, you love: $topActivity');
          recommendations.add('Try more $topActivity when feeling $mood');
        }
      }

      // Find favorite tags
      final tagCounts = <String, int>{};
      for (final rating in recentRatings.where((r) => r.stars >= 4)) {
        for (final tag in rating.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      if (tagCounts.isNotEmpty) {
        final topTag = tagCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        insights.add('You consistently love: $topTag');
      }

      return {
        'insights': insights,
        'recommendations': recommendations,
        'mood_activity_map': moodGroups.map((k, v) => MapEntry(
          k,
          v.map((r) => r.activityName).toSet().toList(),
        )),
      };
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to analyze patterns: $e');
      return {'insights': [], 'recommendations': []};
    }
  }
}

