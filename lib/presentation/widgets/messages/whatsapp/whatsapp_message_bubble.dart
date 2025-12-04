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

    // Metin uzunluğuna göre dinamik genişlik hesapla
    final text = message.content ?? message.preview;
    final screenWidth = MediaQuery.of(context).size.width;
    const perChar = 11.0; // kaba tahmini karakter genişliği (px)
    final estWidth = (text.length * perChar);
    final bubbleMax = screenWidth * 0.20; // hiçbir zaman ekranın %45'inden geniş olmasın
    final bubbleWidth = estWidth.clamp(40.0, bubbleMax); // minimum biraz padding için

    // Align + ConstrainedBox:
    // - Satırın tamamını BOYAMAZ, sadece balon kadar
    // - Balon max ekranın %50'si, kısa metinde yazı kadar dar
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        // Kısa mesajlarda dar, uzun mesajlarda orantılı genişlik (üst sınır: ekranın ~%45'i)
        constraints: BoxConstraints(
          maxWidth: bubbleWidth,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
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
                      fontSize: 14,
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
      ),
    );
  }
}
