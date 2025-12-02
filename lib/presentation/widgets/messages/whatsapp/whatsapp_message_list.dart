import 'package:flutter/material.dart';
import 'package:ai_asisstan/presentation/screens/messages/models/message_model.dart';
import 'whatsapp_message_bubble.dart';

/// Seçili kişiye ait mesaj listesini gösteren widget
class WhatsAppMessageList extends StatelessWidget {
  final List<MessageModel> messages;

  const WhatsAppMessageList({
    super.key,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        // Mesajlar kronolojik (eski -> yeni) sıralı; index 0 en eski, son index en yeni (altta)
        final msg = messages[index];
        return WhatsAppMessageBubble(message: msg);
      },
    );
  }
}
