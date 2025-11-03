import 'package:flutter/material.dart';
import '../../screens/ai_assistant/data/ai_responses.dart';

/// Chat mesaj giriş alanı widget'ı
class ChatMessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isTyping;

  const ChatMessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildTextField(context),
            ),
            const SizedBox(width: 12),
            _buildSendButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: AIResponses.inputPlaceholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      maxLines: null,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => onSend(),
      enabled: !isTyping,
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isTyping
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: isTyping ? null : onSend,
        icon: isTyping
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send, color: Colors.white),
      ),
    );
  }
}

