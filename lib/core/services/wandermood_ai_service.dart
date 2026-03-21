import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:wandermood/core/models/ai_recommendation.dart';
import 'package:wandermood/core/models/ai_chat_message.dart';
import 'package:wandermood/core/constants/api_keys.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

class WanderMoodAIService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _functionName = 'wandermood-ai';

  /// Get AI-powered activity recommendations based on mood and preferences
  static Future<AIRecommendationResponse> getRecommendations({
    required List<String> moods,
    required double latitude,
    required double longitude,
    String? city,
    Map<String, dynamic>? preferences,
    String? conversationId,
    List<String>? conversationContext,
  }) async {
    debugPrint('🤖 Getting AI recommendations for moods: $moods');
    
    try {
      final requestBody = {
        'moods': moods,
        'latitude': latitude,
        'longitude': longitude,
        'city': city ?? 'Rotterdam',
        'preferences': preferences ?? {},
      };

      debugPrint('📤 Sending request to wandermood-ai function: $requestBody');

      final response = await _supabase.functions.invoke(
        _functionName,
        body: requestBody,
      );

      if (response.status != 200) {
        throw Exception('AI service error: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      debugPrint('✅ AI recommendations received: ${data['recommendations']?.length ?? 0} items');
      
      // Convert the new edge function format to the expected format
      return AIRecommendationResponse(
        success: data['success'] ?? false,
        action: 'recommend',
        timestamp: MoodyClock.now().toIso8601String(),
        summary: 'AI-powered recommendations for ${moods.join(', ')} in ${city ?? 'Rotterdam'}',
        availablePlaces: (data['recommendations'] as List<dynamic>?)?.length ?? 0,
        recommendations: (data['recommendations'] as List<dynamic>?)
            ?.map((rec) => AIRecommendation.fromJson(rec))
            .toList() ?? [],
      );
    } catch (e) {
      debugPrint('❌ Error getting AI recommendations: $e');
      rethrow;
    }
  }

  /// Start or continue a chat conversation with the AI
  static Future<AIChatResponse> chat({
    required String message,
    String? conversationId,
    List<String>? moods,
    double? latitude,
    double? longitude,
    String? city,
  }) async {
    debugPrint('💬 Starting AI chat: ${message.substring(0, message.length.clamp(0, 50))}...');
    
    final openAiKey = ApiKeys.openAiKey;
    final convId = conversationId ?? _generateConversationId();
    
    // If OpenAI key is available, call OpenAI directly
    if (openAiKey.isNotEmpty) {
      try {
        debugPrint('🤖 Calling OpenAI API directly...');
        
        final dio = Dio();
        final systemPrompt = _buildSystemPrompt(moods, city);
        
        // Get conversation history if available - ALWAYS try to load for continuity
        List<Map<String, String>> conversationHistory = [];
        try {
          final history = await getConversationHistory(convId);
          conversationHistory = history.map((msg) => {
            'role': msg.role,
            'content': msg.content,
          }).toList();
          debugPrint('📚 Using ${conversationHistory.length} previous messages for context');
        } catch (e) {
          debugPrint('⚠️ Could not load conversation history: $e');
          // Continue without history - new conversation
        }
        
        // Build messages array
        final messages = <Map<String, String>>[
          {'role': 'system', 'content': systemPrompt},
          ...conversationHistory,
          {'role': 'user', 'content': message},
        ];
        
        final response = await dio.post(
          'https://api.openai.com/v1/chat/completions',
          options: Options(
            headers: {
              'Authorization': 'Bearer $openAiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': 'gpt-4o', // Using gpt-4o for better responses
            'messages': messages,
            'max_tokens': 300,
            'temperature': 0.8,
          },
        );
        
        if (response.statusCode == 200) {
          final aiMessage = response.data['choices'][0]['message']['content'] as String;
          
          // Save conversation to database
          try {
            await _saveConversation(convId, message, aiMessage);
          } catch (e) {
            debugPrint('⚠️ Could not save conversation: $e');
          }
          
          debugPrint('✅ AI chat response received from OpenAI');
          
          return AIChatResponse(
            success: true,
            action: 'chat',
            timestamp: MoodyClock.now().toIso8601String(),
            message: aiMessage.trim(),
            conversationId: convId,
            contextUsed: {
              'moods': moods ?? [],
              'location': city ?? 'Unknown',
            },
          );
        } else {
          throw Exception('OpenAI API error: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Error calling OpenAI directly: $e');
        // Fall through to fallback
      }
    }
    
    // Fallback response when OpenAI is not available or fails
    debugPrint('⚠️ Using fallback response');
    return AIChatResponse(
      success: true,
      action: 'chat',
      timestamp: MoodyClock.now().toIso8601String(),
      message: _getFallbackResponse(message, moods?.first ?? 'exploring'),
      conversationId: convId,
      contextUsed: {},
    );
  }
  
  /// Build system prompt for Moody
  static String _buildSystemPrompt(List<String>? moods, String? city) {
    final moodText = moods?.isNotEmpty == true 
        ? 'The user is currently feeling ${moods!.join(' and ')}.'
        : 'The user is exploring.';
    
    final locationText = city != null ? 'They are in $city.' : '';
    
    return '''You are Moody — a warm, playful travel companion for WanderMood, not a formal assistant. You speak like a close friend: casual, supportive, and genuinely excited about travel.

Your personality:
- Casual and friendly, like talking to a bestie
- Use emojis naturally (but not excessively) ✨
- Remember what users tell you and reference it later
- Ask thoughtful follow-up questions
- Celebrate wins and empathize with struggles
- Keep responses concise (2-3 sentences max)
- Be enthusiastic about travel and discovery

Context:
$moodText $locationText

Guidelines:
- Respond naturally to what the user says
- If they mention activities or places, show interest
- If they're asking for help, be helpful and specific
- Keep it conversational, not robotic
- Match their energy level''';
  }
  
  /// Save conversation to database
  static Future<void> _saveConversation(
    String conversationId,
    String userMessage,
    String aiMessage,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return; // Skip if not authenticated
      
      // Save user message
      await _supabase.from('ai_conversations').insert({
        'conversation_id': conversationId,
        'user_id': user.id,
        'role': 'user',
        'content': userMessage,
        'created_at': MoodyClock.now().toIso8601String(),
      });
      
      // Save AI message
      await _supabase.from('ai_conversations').insert({
        'conversation_id': conversationId,
        'user_id': user.id,
        'role': 'assistant',
        'content': aiMessage,
        'created_at': MoodyClock.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ Error saving conversation: $e');
      // Don't throw - conversation saving is optional
    }
  }

  /// Fallback response when AI service is unavailable
  static String _getFallbackResponse(String userMessage, String mood) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('hi') || lowerMessage.contains('hello') || lowerMessage.contains('hey')) {
      return "Hey there! 👋 I'm Moody, your travel companion! I'm here to help you discover amazing places based on your ${mood} mood. What would you like to explore today?";
    }
    
    if (lowerMessage.contains('help') || lowerMessage.contains('what can you do')) {
      return "I can help you find activities, restaurants, and places that match your mood! Just tell me what you're feeling, and I'll suggest the perfect spots. 🎯";
    }
    
    if (lowerMessage.contains('food') || lowerMessage.contains('eat') || lowerMessage.contains('restaurant')) {
      return "Great choice! 🍽️ Based on your ${mood} mood, I'd recommend checking out some local favorites. Want me to find specific restaurants or cafes?";
    }
    
    if (lowerMessage.contains('activity') || lowerMessage.contains('do') || lowerMessage.contains('fun')) {
      return "Let's find something fun! 🎉 For your ${mood} vibe, I suggest exploring local attractions, parks, or cultural spots. What type of activity interests you?";
    }
    
    // Default response
    return "I'm here to help you discover amazing places! 🌟 Tell me more about what you're looking for, and I'll suggest the perfect spots for your ${mood} mood.";
  }

  /// Create a complete day plan using AI with optional conversation context
  static Future<AIPlanResponse> createDayPlan({
    required List<String> moods,
    required double latitude,
    required double longitude,
    String? city,
    Map<String, dynamic>? preferences,
    String? conversationId,
    List<String>? conversationContext,
  }) async {
    debugPrint('📅 Creating AI day plan for moods: $moods');
    
    try {
      final requestBody = {
        'action': 'plan',
        'moods': moods,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'city': city ?? 'Unknown',
        },
        'preferences': preferences ?? {},
      };

      // Include conversation context if available
      if (conversationId != null) {
        requestBody['conversationId'] = conversationId;
      }
      if (conversationContext != null && conversationContext.isNotEmpty) {
        requestBody['conversationContext'] = conversationContext;
        debugPrint('📝 Including conversation context: ${conversationContext.length} messages');
      }

      final response = await _supabase.functions.invoke(
        _functionName,
        body: requestBody,
      );

      if (response.status != 200) {
        throw Exception('AI planning error: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      debugPrint('✅ AI day plan created');
      
      return AIPlanResponse.fromJson(data);
    } catch (e) {
      debugPrint('❌ Error creating AI day plan: $e');
      rethrow;
    }
  }

  /// Optimize an existing itinerary using AI
  static Future<AIOptimizationResponse> optimizeItinerary({
    required List<Map<String, dynamic>> currentItinerary,
    required double latitude,
    required double longitude,
    String? city,
    Map<String, dynamic>? constraints,
  }) async {
    debugPrint('⚡ Optimizing itinerary with ${currentItinerary.length} activities');
    
    try {
      final response = await _supabase.functions.invoke(
        _functionName,
        body: {
          'action': 'optimize',
          'currentItinerary': currentItinerary,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
            'city': city ?? 'Unknown',
          },
          'constraints': constraints ?? {},
        },
      );

      if (response.status != 200) {
        throw Exception('AI optimization error: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      debugPrint('✅ Itinerary optimized');
      
      return AIOptimizationResponse.fromJson(data);
    } catch (e) {
      debugPrint('❌ Error optimizing itinerary: $e');
      rethrow;
    }
  }

  /// Submit feedback for AI recommendations
  static Future<void> submitRecommendationFeedback({
    required String recommendationId,
    required int rating,
    List<String>? selectedRecommendations,
    String? notes,
  }) async {
    debugPrint('📊 Submitting AI recommendation feedback: $rating/5');
    
    try {
      await _supabase.from('ai_recommendations').update({
        'user_feedback': rating,
        'user_selected': selectedRecommendations,
        'feedback_notes': notes,
      }).eq('id', recommendationId);
      
      debugPrint('✅ Feedback submitted successfully');
    } catch (e) {
      debugPrint('❌ Error submitting feedback: $e');
      rethrow;
    }
  }

  /// Get user's AI conversation history
  static Future<List<AIChatMessage>> getConversationHistory(String conversationId) async {
    debugPrint('📜 Loading conversation history: $conversationId');
    
    try {
      final response = await _supabase
          .from('ai_conversations')
          .select('role, content, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .limit(50); // Limit to last 50 messages to avoid token limits

      final messages = (response as List)
          .map((json) => AIChatMessage.fromJson(json))
          .toList();
      
      debugPrint('✅ Loaded ${messages.length} conversation messages for context');
      return messages;
    } catch (e) {
      debugPrint('❌ Error loading conversation history: $e');
      // Return empty list instead of throwing - allows chat to continue without history
      return [];
    }
  }

  /// Update user preferences for better AI recommendations
  static Future<void> updateUserPreferences({
    int? budgetRange,
    List<String>? preferredTimeSlots,
    List<String>? favoriteMoods,
    List<String>? dietaryRestrictions,
    List<String>? mobilityRequirements,
    String? languagePreference,
  }) async {
    debugPrint('⚙️ Updating user AI preferences');
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};
      if (budgetRange != null) updateData['budget_range'] = budgetRange;
      if (preferredTimeSlots != null) updateData['preferred_time_slots'] = preferredTimeSlots;
      if (favoriteMoods != null) updateData['favorite_moods'] = favoriteMoods;
      if (dietaryRestrictions != null) updateData['dietary_restrictions'] = dietaryRestrictions;
      if (mobilityRequirements != null) updateData['mobility_requirements'] = mobilityRequirements;
      if (languagePreference != null) updateData['language_preference'] = languagePreference;

      await _supabase.from('user_preferences').upsert({
        'user_id': user.id,
        ...updateData,
      });
      
      debugPrint('✅ User preferences updated');
    } catch (e) {
      debugPrint('❌ Error updating user preferences: $e');
      rethrow;
    }
  }

  /// Log activity completion for AI learning
  static Future<void> logActivityCompletion({
    required String activityId,
    required String name,
    required String mood,
    required double latitude,
    required double longitude,
    double? rating,
    int? feedbackRating,
    String? feedbackNotes,
  }) async {
    debugPrint('📝 Logging activity completion: $name');
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('user_activity_history').insert({
        'user_id': user.id,
        'activity_id': activityId,
        'name': name,
        'mood': mood,
        'location_lat': latitude,
        'location_lng': longitude,
        'rating': rating,
        'feedback_rating': feedbackRating,
        'feedback_notes': feedbackNotes,
        'completed_at': MoodyClock.now().toIso8601String(),
      });
      
      debugPrint('✅ Activity completion logged');
    } catch (e) {
      debugPrint('❌ Error logging activity completion: $e');
      rethrow;
    }
  }

  /// Generate a unique conversation ID
  static String _generateConversationId() {
    return 'conv_${MoodyClock.now().millisecondsSinceEpoch}_${_supabase.auth.currentUser?.id?.substring(0, 8) ?? 'anon'}';
  }

  /// Get or create a persistent conversation ID for the current user
  /// This ensures conversations persist across app sessions
  static Future<String> getOrCreateConversationId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return _generateConversationId();
      }

      // Try to get the most recent conversation ID for this user
      final response = await _supabase
          .from('ai_conversations')
          .select('conversation_id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['conversation_id'] != null) {
        final existingId = response['conversation_id'] as String;
        debugPrint('✅ Found existing conversation ID: $existingId');
        return existingId;
      }

      // No existing conversation, create a new one
      final newId = 'conv_${user.id}_${MoodyClock.now().millisecondsSinceEpoch}';
      debugPrint('🆕 Created new conversation ID: $newId');
      return newId;
    } catch (e) {
      debugPrint('⚠️ Error getting conversation ID: $e');
      // Fallback to generating a new one
      return _generateConversationId();
    }
  }

  /// Check if AI service is available
  static Future<bool> isAIServiceAvailable() async {
    try {
      final response = await _supabase.functions.invoke(
        _functionName,
        body: {'action': 'ping'},
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('⚠️ AI service not available: $e');
      return false;
    }
  }
}

// Removed custom debugPrint function - using Flutter's debugPrint from foundation.dart instead 