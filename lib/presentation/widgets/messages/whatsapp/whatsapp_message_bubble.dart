import 'package:flutter/material.dart';
import 'package:ai_asisstan/presentation/screens/messages/models/message_model.dart';

/// Tek bir WhatsApp mesaj baloncuğu
class WhatsAppMessageBubble extends StatelessWidget {
  final MessageModel message;

  const WhatsAppMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isOutgoing;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor =
        isMe ? Theme.of(context).colorScheme.primary : (isDark ? const Color(0xFF303030) : Colors.grey[200]!);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        constraints: BoxConstraints(
          // Baloncuk genişliğini daha okunabilir yap (yaklaşık %60)
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content ?? message.preview,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                message.time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 10,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
