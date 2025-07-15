import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/api_constants.dart';
import '../../features/places/models/place.dart';

part 'moody_ai_service.g.dart';

@riverpod
MoodyAIService moodyAIService(MoodyAIServiceRef ref) => MoodyAIService();

class MoodyAIService {
  final String apiKey = ApiConstants.openAiApiKey;
  final String baseUrl = ApiConstants.openAiBaseUrl;

  /// Generate personalized Moody Tips for a specific place using AI
  Future<List<String>> generateMoodyTips({
    required Place place,
    String? userMood,
    String? timeOfDay,
    String? weather,
    List<String>? userPreferences,
  }) async {
    if (apiKey.isEmpty) {
      debugPrint('⚠️ OpenAI API key not configured, using fallback tips');
      return _getFallbackTips(place);
    }

    try {
      final url = Uri.parse('$baseUrl${ApiConstants.completions}');
      
      final prompt = _buildPrompt(
        place: place,
        userMood: userMood,
        timeOfDay: timeOfDay,
        weather: weather,
        userPreferences: userPreferences,
      );

      debugPrint('🤖 Generating Moody Tips for: ${place.name}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini', // Cost-effective and fast
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(),
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Parse the response and extract tips
        final tips = _parseAIResponse(content);
        
        debugPrint('✅ Generated ${tips.length} AI-powered Moody Tips');
        return tips;
      } else {
        debugPrint('❌ OpenAI API error: ${response.statusCode}');
        return _getFallbackTips(place);
      }
    } catch (e) {
      debugPrint('❌ Error generating Moody Tips: $e');
      return _getFallbackTips(place);
    }
  }

  /// Build context-aware prompt for Moody AI
  String _buildPrompt({
    required Place place,
    String? userMood,
    String? timeOfDay,
    String? weather,
    List<String>? userPreferences,
  }) {
    final context = <String>[];
    
    // Add place context
    context.add('Place: ${place.name}');
    context.add('Location: ${place.address}');
    context.add('Type: ${place.activities.join(", ")}');
    if (place.rating > 0) context.add('Rating: ${place.rating}/5.0');
    if (place.isIndoor) context.add('Indoor venue');
    context.add('Energy level: ${place.energyLevel}');
    
    // Add user context
    if (userMood != null) context.add('User mood: $userMood');
    if (timeOfDay != null) context.add('Time of day: $timeOfDay');
    if (weather != null) context.add('Weather: $weather');
    if (userPreferences?.isNotEmpty == true) {
      context.add('User preferences: ${userPreferences!.join(", ")}');
    }

    return '''
Generate 3-4 personalized tips for visiting this place based on the context:

${context.join('\n')}

Make the tips:
- Practical and actionable
- Specific to this place and context
- Mood-appropriate and engaging
- Include relevant emojis
- Written in a friendly, helpful tone as "Moody" the AI travel assistant

Format as a simple list, one tip per line, starting with an emoji.
    ''';
  }

  /// System prompt that defines Moody's personality
  String _getSystemPrompt() {
    return '''
You are Moody, WanderMood's friendly AI travel assistant. You're knowledgeable about travel, mood-based recommendations, and creating memorable experiences.

Your personality:
- Warm, enthusiastic, and helpful
- Mood-aware and emotionally intelligent
- Practical with insider tips
- Uses appropriate emojis to enhance communication
- Focuses on personalized, contextual advice

Generate tips that are:
- Specific to the venue and user's current context
- Practical and immediately actionable
- Mood-appropriate and engaging
- 15-30 words each for quick reading
    ''';
  }

  /// Parse AI response and extract individual tips
  List<String> _parseAIResponse(String content) {
    final lines = content.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final tips = <String>[];
    
    for (String line in lines) {
      // Remove bullet points, numbers, and clean up
      String cleanLine = line
          .replaceAll(RegExp(r'^[-•*]\s*'), '')
          .replaceAll(RegExp(r'^\d+\.\s*'), '')
          .trim();
      
      // Skip if line is too short or looks like a header
      if (cleanLine.length < 10 || cleanLine.contains(':') && cleanLine.length < 20) {
        continue;
      }
      
      tips.add(cleanLine);
    }
    
    // Ensure we have at least 2 tips
    if (tips.length < 2) {
      return _getFallbackTips(null);
    }
    
    // Limit to 4 tips max
    return tips.take(4).toList();
  }

  /// Generate smart Moody Tips based on place context (for emergencies)
  List<String> _getFallbackTips(Place? place) {
    if (place == null) {
      return [
        '🕐 Check opening hours before your visit to avoid disappointment',
        '📱 Download offline maps in case of poor signal',
        '💧 Stay hydrated and bring water, especially during warmer weather',
      ];
    }

    final tips = <String>[];
    final now = DateTime.now();
    final hour = now.hour;
    final timeOfDay = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';
    
    // Generate dynamic activity-specific tips based on place name and type
    final placeName = place.name.toLowerCase();
    final activities = place.activities.map((a) => a.toLowerCase()).toList();
    
    // Museum-specific dynamic tips
    if (activities.contains('museums') || placeName.contains('museum')) {
      if (timeOfDay == 'morning') {
        tips.add('🌅 Perfect timing! Museums are less crowded in the morning for a peaceful experience');
      } else if (timeOfDay == 'afternoon') {
        tips.add('⏰ Great afternoon choice! Allow 2-3 hours to fully appreciate ${place.name}');
      } else {
        tips.add('🌙 Evening visit to ${place.name}? Check if they have special late hours or events');
      }
      tips.add('🎨 Ask staff about hidden gems or recently added exhibits at ${place.name}');
    }
    
    // Nature/Outdoor specific tips
    else if (activities.contains('nature') || activities.contains('outdoor') || !place.isIndoor) {
      if (timeOfDay == 'morning') {
        tips.add('🌅 Perfect morning choice! ${place.name} offers beautiful lighting and fewer crowds');
      } else if (timeOfDay == 'afternoon') {
        tips.add('☀️ Afternoon at ${place.name}? Bring sun protection and stay hydrated');
      } else {
        tips.add('🌅 Evening visit to ${place.name} might offer stunning sunset views!');
      }
      tips.add('👟 Comfortable shoes recommended for exploring ${place.name} to the fullest');
    }
    
    // Sightseeing specific tips
    else if (activities.contains('sightseeing')) {
      if (placeName.contains('tower') || placeName.contains('viewpoint')) {
        tips.add('📸 ${place.name} offers incredible photo opportunities - charge your camera!');
        tips.add('🌤️ Clear day? Perfect for spectacular views from ${place.name}');
      } else {
        tips.add('🚶‍♀️ Take your time exploring ${place.name} - there\'s always more to discover');
        tips.add('📱 Consider downloading a guide app for ${place.name} for insider details');
      }
    }
    
    // Food & Drink specific tips
    else if (activities.contains('food & drink') || placeName.contains('restaurant') || placeName.contains('café')) {
      if (timeOfDay == 'morning') {
        tips.add('☕ Morning at ${place.name}? Perfect time to try their breakfast specialties');
      } else if (timeOfDay == 'afternoon') {
        tips.add('🍽️ Great lunch spot! Ask ${place.name} staff for their signature dishes');
      } else {
        tips.add('🌙 Evening dining at ${place.name}? Consider making a reservation');
      }
      tips.add('🗣️ Chat with locals at ${place.name} - they know the best menu secrets');
    }
    
    // Shopping specific tips
    else if (activities.contains('shopping') || placeName.contains('market') || placeName.contains('shop')) {
      tips.add('💰 Bring cash to ${place.name} - some vendors prefer it over cards');
      tips.add('🛍️ ${place.name} is perfect for finding unique local treasures and souvenirs');
    }
    
    // Entertainment specific tips
    else if (activities.contains('entertainment')) {
      tips.add('🎭 Check ${place.name}\'s schedule - they might have special shows today');
      tips.add('📅 Arrive early at ${place.name} to get the best seats or spots');
    }
    
    // Energy level specific tips with place context
    switch (place.energyLevel.toLowerCase()) {
      case 'low':
        tips.add('😌 ${place.name} is perfect for unwinding - take your time and soak in the peaceful atmosphere');
        break;
      case 'medium':
        tips.add('⚖️ ${place.name} offers a nice balance - suitable for any energy level today');
        break;
      case 'high':
        tips.add('💪 Ready for adventure? ${place.name} will give you an energizing experience!');
        break;
    }
    
    // Rating-based tips with place context
    if (place.rating >= 4.5) {
      tips.add('⭐ ${place.name} is highly rated for good reason - prepare to be impressed!');
    } else if (place.rating >= 4.0) {
      tips.add('👍 ${place.name} has great reviews - perfect choice for your visit');
    }
    
    // Location-specific tips based on place name
    if (placeName.contains('rotterdam')) {
      tips.add('🚲 Consider biking to ${place.name} - Rotterdam is very bike-friendly!');
    }
    
    // Weather-based tips with place context
    if (place.isIndoor) {
      tips.add('🏠 ${place.name} is perfect for any weather - excellent choice regardless of conditions!');
    } else {
      tips.add('🌤️ Check the weather for your visit to ${place.name} to make the most of the experience');
    }
    
    // Add unique tips based on specific keywords in place name
    if (placeName.contains('historic') || placeName.contains('old') || placeName.contains('heritage')) {
      tips.add('📚 ${place.name} has rich history - consider getting a guide or audio tour');
    }
    
    if (placeName.contains('art') || placeName.contains('gallery')) {
      tips.add('🎨 Take time to appreciate the details at ${place.name} - art is meant to be savored');
    }
    
    if (placeName.contains('park') || placeName.contains('garden')) {
      tips.add('🌳 ${place.name} is perfect for a leisurely stroll and connecting with nature');
    }
    
    // Ensure we always have at least 3 tips, add generic but place-specific ones if needed
    if (tips.length < 3) {
      tips.add('💡 Ask locals about hidden features of ${place.name} - they know the best spots');
      tips.add('📸 ${place.name} has great photo opportunities - don\'t forget your camera!');
      tips.add('🎯 Visit ${place.name} with an open mind and prepare to discover something new');
    }
    
    // Limit to 4 tips max and ensure uniqueness
    return tips.toSet().take(4).toList();
  }

  /// Generate mood-specific activity suggestions using AI
  Future<List<String>> generateMoodActivities({
    required String mood,
    required String location,
    String? timeOfDay,
    String? weather,
  }) async {
    if (apiKey.isEmpty) {
      debugPrint('❌ OpenAI API key is empty - cannot generate mood activities');
      return [];
    }

    try {
      final url = Uri.parse('$baseUrl${ApiConstants.completions}');
      
      final prompt = '''
Suggest 4-5 specific activities in $location for someone feeling $mood.
${timeOfDay != null ? 'Time: $timeOfDay' : ''}
${weather != null ? 'Weather: $weather' : ''}

Make suggestions:
- Specific to the location
- Appropriate for the mood and time
- Include emojis
- Brief (10-15 words each)
- Actionable and realistic

Format as simple list, one per line.
      ''';

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are Moody, a friendly AI suggesting mood-based activities.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.8,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return _parseAIResponse(content);
      }
    } catch (e) {
      debugPrint('❌ Error generating mood activities: $e');
      // Return empty list instead of fallback activities
      return [];
    }
    
    // Return empty list instead of fallback activities
    return [];
  }
} 