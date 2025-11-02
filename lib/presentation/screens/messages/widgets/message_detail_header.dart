import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'user_avatar.dart';

/// Mesaj detay başlığı - Gönderen bilgileri ve avatar
class MessageDetailHeader extends StatelessWidget {
  final MessageModel message;

  const MessageDetailHeader({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        UserAvatar(
          name: message.sender,
          color: message.color,
          size: 56,
          fontSize: 20,
        ),
        const SizedBox(width: 16),
        // İsim ve Platform
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.sender,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    message.icon,
                    size: 16,
                    color: message.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.platform,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: message.color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Tarih
        Text(
          message.date ?? message.time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

