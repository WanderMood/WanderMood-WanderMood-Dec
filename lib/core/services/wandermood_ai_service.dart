import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/models/ai_recommendation.dart';
import 'package:wandermood/core/models/ai_chat_message.dart';

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
        timestamp: DateTime.now().toIso8601String(),
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
    
    try {
      final response = await _supabase.functions.invoke(
        _functionName,
        body: {
          'action': 'chat',
          'message': message,
          'conversationId': conversationId ?? _generateConversationId(),
          'moods': moods,
          'location': (latitude != null && longitude != null) ? {
            'latitude': latitude,
            'longitude': longitude,
            'city': city,
          } : null,
        },
      );

      if (response.status != 200) {
        throw Exception('AI chat error: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      debugPrint('✅ AI chat response received');
      
      return AIChatResponse.fromJson(data);
    } catch (e) {
      debugPrint('❌ Error in AI chat: $e');
      
      // Fallback response when edge function doesn't exist
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        debugPrint('⚠️ Edge function not found, using fallback response');
        return AIChatResponse(
          success: true,
          action: 'chat',
          timestamp: DateTime.now().toIso8601String(),
          message: _getFallbackResponse(message, moods?.first ?? 'exploring'),
          conversationId: conversationId ?? _generateConversationId(),
          contextUsed: {},
        );
      }
      
      rethrow;
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
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((json) => AIChatMessage.fromJson(json))
          .toList();
      
      debugPrint('✅ Loaded ${messages.length} conversation messages');
      return messages;
    } catch (e) {
      debugPrint('❌ Error loading conversation history: $e');
      rethrow;
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
        'completed_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Activity completion logged');
    } catch (e) {
      debugPrint('❌ Error logging activity completion: $e');
      rethrow;
    }
  }

  /// Generate a unique conversation ID
  static String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${_supabase.auth.currentUser?.id?.substring(0, 8) ?? 'anon'}';
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