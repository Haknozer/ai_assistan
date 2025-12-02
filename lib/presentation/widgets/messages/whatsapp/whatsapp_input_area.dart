import 'package:flutter/material.dart';

/// WhatsApp mesaj giriş alanı ve gönder butonu
class WhatsAppInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool canSend;
  final Future<void> Function() onSend;

  const WhatsAppInputArea({
    super.key,
    required this.controller,
    required this.isSending,
    required this.canSend,
    required this.onSend,
  });

  Future<void> _handleSubmit() async {
    await onSend();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              enabled: canSend && !isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSubmit(),
              decoration: InputDecoration(
                hintText: 'Mesaj yaz...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: !isSending && canSend ? _handleSubmit : null,
            icon: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}


