import 'package:flutter/material.dart';
import '../../screens/ai_assistant/models/chat_message.dart';
import 'chat_message_bubble.dart';
import 'chat_welcome_screen.dart';

/// Chat mesajları alan widget'ı
class ChatArea extends StatelessWidget {
  final List<ChatMessage> messages;
  final Function(String) onSuggestionTap;

  const ChatArea({
    super.key,
    required this.messages,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return ChatWelcomeScreen(onSuggestionTap: onSuggestionTap);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatMessageBubble(message: messages[index]);
      },
    );
  }
}

