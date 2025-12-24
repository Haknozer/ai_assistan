import 'package:flutter/material.dart';
import '../../../models/email.dart';
import '../../screens/email/utils/email_display_utils.dart';

/// E-posta ekleri widget'ı - Gmail tarzı minimal
class EmailDetailAttachments extends StatelessWidget {
  final Email email;

  const EmailDetailAttachments({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    if (!email.hasAttachments) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
            height: 32,
          ),
          Text(
            'Ekler (${email.attachments?.length ?? 0})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 8),
          ...email.attachments?.map(
                (attachment) => _EmailAttachmentItem(attachment: attachment),
              ) ??
              [],
        ],
      ),
    );
  }
}

/// Tek bir ek öğesi - Gmail tarzı minimal
class _EmailAttachmentItem extends StatelessWidget {
  final EmailAttachment attachment;

  const _EmailAttachmentItem({
    required this.attachment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Dosya ikonu - Gmail tarzı
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              EmailDisplayUtils.getFileIcon(attachment.contentType),
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
            ),
          ),
          const SizedBox(width: 12),

          // Dosya bilgileri - Gmail tarzı
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.filename,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  attachment.formattedSize,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),

          // İndir butonu - Gmail tarzı
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${attachment.filename} indiriliyor...'),
                ),
              );
            },
            icon: Icon(
              Icons.download_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: 'İndir',
          ),
        ],
      ),
    );
  }
}
