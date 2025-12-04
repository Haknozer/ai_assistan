import 'package:flutter/material.dart';
import '../../screens/messages/models/message_model.dart';
import '../circle_avatar_with_initials.dart';

/// Mesaj kartı widget'ı - Liste görünümünde gösterilen mesaj kartı
class MessageCard extends StatelessWidget {
  final MessageModel message;
  final bool isSelected;
  final VoidCallback onTap;

  const MessageCard({
    super.key,
    required this.message,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? message.color.withValues(alpha: 0.15)
              : (message.isUnread ? message.color.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? message.color
                : (message.isUnread ? message.color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatarWithInitials(
              initials: message.getInitials(),
              radius: 24,
              backgroundColor: message.color,
              textColor: Colors.white,
            ),

            const SizedBox(width: 12),

            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Satır: İsim, Uygulama İkonu, Saat
                  Row(
                    children: [
                      // İsim
                      Expanded(
                        child: Text(
                          message.sender,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Uygulama İkonu
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: message.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          message.icon,
                          color: message.color,
                          size: 14,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Saat
                      Text(
                        message.time,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Mesaj İçeriği
                  Text(
                    // Telegram'da "Test - Test" gibi çift yazmayı engelle:
                    // Tüm platformlarda sadece preview göster.
                    message.preview,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
