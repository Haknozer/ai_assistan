import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/ai/ai_feature.dart';

/// Chat mesaj balonu widget'ı
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAIAvatar(context),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: _buildMessageContainer(context, isUser),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            _buildUserAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAIAvatar(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: const Icon(
        Icons.auto_awesome,
        size: 18,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildMessageContainer(BuildContext context, bool isUser) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }
}

