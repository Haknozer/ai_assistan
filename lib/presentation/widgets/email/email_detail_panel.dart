import 'package:flutter/material.dart';
import '../../../models/email.dart';
import 'email_detail_header.dart';
import 'email_detail_subject_sender.dart';
import 'email_detail_content.dart';
import 'email_detail_attachments.dart';
import 'email_detail_actions.dart';
import 'email_ai_suggestions_card.dart';

/// E-posta detay paneli - Gmail tarzı sade ve modern tasarım
class EmailDetailPanel extends StatelessWidget {
  final Email? email;
  final void Function(Email)? onReply;
  final void Function(Email)? onForward;
  final void Function(Email)? onDelete;
  final void Function(Email)? onMarkAsImportant;

  const EmailDetailPanel({
    super.key,
    this.email,
    this.onReply,
    this.onForward,
    this.onDelete,
    this.onMarkAsImportant,
  });

  @override
  Widget build(BuildContext context) {
    if (email == null) {
      return _buildEmptyState(context);
    }

    // Gmail tarzı minimal, sade tasarım
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Minimal header - Gmail tarzı
          EmailDetailHeader(
            email: email!,
            onReply: onReply != null ? () => onReply!(email!) : null,
            onForward: onForward != null ? () => onForward!(email!) : null,
            onDelete: onDelete != null ? () => onDelete!(email!) : null,
            onMarkAsImportant: onMarkAsImportant != null ? () => onMarkAsImportant!(email!) : null,
          ),

          // İçerik - Gmail tarzı temiz görünüm
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Konu ve gönderen bilgisi - Gmail tarzı
                  EmailDetailSubjectSender(email: email!),

                  // E-posta içeriği - Gmail tarzı tam HTML render
                  EmailDetailContent(email: email!),

                  // AI Önerileri - n8n'den dönen öneriler
                  EmailAiSuggestionsCard(
                    key: ValueKey('email_ai_${email!.messageId ?? email!.id}'),
                    email: email!,
                  ),

                  // Ekler - Gmail tarzı minimal
                  EmailDetailAttachments(email: email!),
                ],
              ),
            ),
          ),

          // Minimal aksiyon butonları - Gmail tarzı
          EmailDetailActions(
            email: email!,
            onReply: onReply != null ? () => onReply!(email!) : null,
            onForward: onForward != null ? () => onForward!(email!) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'E-posta Seçin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Görüntülemek için bir e-posta seçin',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
