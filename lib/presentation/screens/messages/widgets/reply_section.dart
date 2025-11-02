import 'package:flutter/material.dart';

/// Yanıtlama bölümü widget'ı
class ReplySection extends StatelessWidget {
  final VoidCallback? onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onEmoji;

  const ReplySection({
    super.key,
    this.onSend,
    this.onAttach,
    this.onEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yanıtla',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          // Mesaj Input
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mesajınızı yazın...',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          // Alt Aksiyonlar
          Row(
            children: [
              // Dosya Ekleme
              IconButton(
                onPressed: onAttach,
                icon: const Icon(Icons.attach_file),
                tooltip: 'Dosya Ekle',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 8),
              // Emoji
              IconButton(
                onPressed: onEmoji,
                icon: const Icon(Icons.emoji_emotions_outlined),
                tooltip: 'Emoji Ekle',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              const Spacer(),
              // Gönder Butonu
              ElevatedButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Gönder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

