import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_responses.dart';
import '../models/chat_message.dart';

/// AI suggestions provider
final aiSuggestionsProvider = Provider<List<String>>((ref) {
  return AIResponses.suggestions;
});

/// Chat messages provider (stateful)
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

/// Chat messages notifier
class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([]);

  /// Mesaj ekle
  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  /// Mesajları temizle
  void clearMessages() {
    state = [];
  }

  /// AI yanıtı üret ve ekle
  void generateAIResponse(String userMessage) {
    final aiResponse = AIResponses.generateResponse(userMessage);
    addMessage(ChatMessage(
      text: aiResponse,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }
}

