import 'package:flutter/material.dart';
import 'package:ai_asisstan/presentation/screens/messages/models/message_model.dart';

/// WhatsApp sohbet başlığı - kişi adı ve numara alanı
class WhatsAppThreadHeader extends StatelessWidget {
  final MessageModel message;
  final Future<void> Function()? onEditPressed;

  const WhatsAppThreadHeader({
    super.key,
    required this.message,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: message.color,
            child: Text(
              message.getInitials(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.sender,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onEditPressed != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'İsmi düzenle',
                        onPressed: onEditPressed,
                      ),
                  ],
                ),
                Text(
                  message.fromNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
