import 'package:flutter/material.dart';
import '../../../models/email.dart';

/// E-posta aksiyon butonları widget'ı - Gmail tarzı minimal
class EmailDetailActions extends StatelessWidget {
  final Email email;
  final VoidCallback? onReply;
  final VoidCallback? onForward;

  const EmailDetailActions({
    super.key,
    required this.email,
    this.onReply,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Yanıtla butonu - Gmail tarzı text button
          TextButton.icon(
            onPressed: onReply,
            icon: Icon(
              Icons.reply,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
            ),
            label: Text(
              'Yanıtla',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.87),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: 8),

          // Yönlendir butonu - Gmail tarzı text button
          TextButton.icon(
            onPressed: onForward,
            icon: Icon(
              Icons.forward,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
            ),
            label: Text(
              'Yönlendir',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.87),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

