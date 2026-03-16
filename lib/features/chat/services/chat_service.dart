import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';

class ChatService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Save a chat message to the database
  static Future<ChatMessage> saveChatMessage({
    required String content,
    required bool isFromUser,
    Map<String, dynamic>? context,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      final response = await _supabase
          .from('chat_messages')
          .insert({
            'user_id': userId,
            'content': content,
            'is_from_user': isFromUser,
            'context': context ?? {},
          })
          .select()
          .single();

      return ChatMessage.fromJson(response);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving chat message: $e');
      rethrow;
    }
  }

  /// Get chat messages for the current user
  static Future<List<ChatMessage>> getChatMessages({
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      var query = _supabase
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final response = await query;
      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList()
          .reversed
          .toList(); // Return in chronological order
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting chat messages: $e');
      return [];
    }
  }

  /// Stream of chat messages for real-time updates
  static Stream<List<ChatMessage>> watchChatMessages() {
    final userId = _supabase.auth.currentUser!.id;
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList());
  }

  /// Delete a chat message
  static Future<void> deleteChatMessage(String messageId) async {
    try {
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('id', messageId)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error deleting chat message: $e');
      rethrow;
    }
  }

  /// Clear all chat messages for the current user
  static Future<void> clearChatHistory() async {
    try {
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error clearing chat history: $e');
      rethrow;
    }
  }
} 