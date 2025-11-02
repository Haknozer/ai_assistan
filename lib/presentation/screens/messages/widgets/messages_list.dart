import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'message_card.dart';

/// Mesajlar listesi widget'ı - Tüm mesajları gösterir
class MessagesList extends StatelessWidget {
  final List<MessageModel> messages;
  final int? selectedIndex;
  final ValueChanged<int> onMessageSelected;

  const MessagesList({
    super.key,
    required this.messages,
    required this.selectedIndex,
    required this.onMessageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Sayı
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesajlar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${messages.length} mesaj',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Mesaj Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return MessageCard(
                  message: message,
                  isSelected: selectedIndex == index,
                  onTap: () => onMessageSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

