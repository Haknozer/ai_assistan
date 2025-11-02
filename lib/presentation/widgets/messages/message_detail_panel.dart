import 'package:flutter/material.dart';
import '../../screens/messages/models/message_model.dart';
import 'message_detail_header.dart';
import 'message_detail_content.dart';
import 'ai_summary_card.dart';
import 'reply_section.dart';
import 'empty_message_state.dart';

/// Mesaj detay paneli - Seçilen mesajın detaylarını gösterir
class MessageDetailPanel extends StatelessWidget {
  final MessageModel? message;

  const MessageDetailPanel({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    // Mesaj seçilmediyse boş durum göster
    if (message == null) {
      return const EmptyMessageState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mesaj Başlığı
            Container(
              padding: const EdgeInsets.all(24),
              child: MessageDetailHeader(message: message!),
            ),

            // Mesaj İçeriği
            MessageDetailContent(message: message!),

            // AI Özeti
            AiSummaryCard(message: message!),

            // Yanıtla Bölümü
            ReplySection(
              onSend: () {
                // TODO: Implement send functionality
              },
              onAttach: () {
                // TODO: Implement attach functionality
              },
              onEmoji: () {
                // TODO: Implement emoji picker
              },
            ),
          ],
        ),
      ),
    );
  }
}
