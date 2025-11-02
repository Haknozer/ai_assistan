import 'package:flutter/material.dart';
import '../models/message_model.dart';

/// Mesaj detay içeriği - Konu ve mesaj içeriği
class MessageDetailContent extends StatelessWidget {
  final MessageModel message;

  const MessageDetailContent({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Konu
          Text(
            message.subject,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Mesaj İçeriği
          Text(
            message.content ?? message.preview,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

