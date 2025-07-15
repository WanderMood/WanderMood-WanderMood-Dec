import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

/// Provider for chat messages
final chatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  return ChatService.watchChatMessages();
});

/// Provider for loading chat history
final chatHistoryProvider = FutureProvider<List<ChatMessage>>((ref) async {
  return ChatService.getChatMessages();
});

/// Provider for managing chat state
final chatStateProvider = StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatNotifier() : super(const AsyncValue.loading()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      state = const AsyncValue.loading();
      final messages = await ChatService.getChatMessages();
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> sendMessage(String content, {Map<String, dynamic>? context}) async {
    try {
      final message = await ChatService.saveChatMessage(
        content: content,
        isFromUser: true,
        context: context,
      );

      state.whenData((messages) {
        state = AsyncValue.data([...messages, message]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addAIResponse(String content, {Map<String, dynamic>? context}) async {
    try {
      final message = await ChatService.saveChatMessage(
        content: content,
        isFromUser: false,
        context: context,
      );

      state.whenData((messages) {
        state = AsyncValue.data([...messages, message]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await ChatService.deleteChatMessage(messageId);
      state.whenData((messages) {
        state = AsyncValue.data(
          messages.where((m) => m.id != messageId).toList(),
        );
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> clearHistory() async {
    try {
      await ChatService.clearChatHistory();
      state = const AsyncValue.data([]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() {
    _loadMessages();
  }
} 