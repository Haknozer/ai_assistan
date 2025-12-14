import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/email.dart';
import '../../../services/n8n_forwarder_service.dart';
import '../../../services/n8n_response_storage_service.dart';
import '../../../core/utils/logger.dart';

/// E-posta detay header widget'ı - Gmail tarzı minimal
class EmailDetailHeader extends ConsumerStatefulWidget {
  final Email email;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkAsImportant;

  const EmailDetailHeader({
    super.key,
    required this.email,
    this.onReply,
    this.onForward,
    this.onDelete,
    this.onMarkAsImportant,
  });

  @override
  ConsumerState<EmailDetailHeader> createState() => _EmailDetailHeaderState();
}

class _EmailDetailHeaderState extends ConsumerState<EmailDetailHeader> {
  bool _isSendingToN8n = false;

  Future<void> _sendToN8n() async {
    if (_isSendingToN8n) return;

    setState(() => _isSendingToN8n = true);

    try {
      final n8nService = N8nForwarderService();
      
      final response = await n8nService.forwardEmailMessageAndWait(
        userId: widget.email.userId.toString(),
        accountId: widget.email.accountId,
        messageId: widget.email.messageId ?? widget.email.id?.toString() ?? '',
        fromEmail: widget.email.fromEmail,
        fromName: widget.email.fromName,
        subject: widget.email.subject,
        plainText: widget.email.plainText,
        htmlContent: widget.email.htmlContent,
        toEmails: widget.email.toEmails,
        ccEmails: widget.email.ccEmails,
        bccEmails: widget.email.bccEmails,
        receivedDate: widget.email.receivedDate,
        isRead: widget.email.isRead,
        folder: widget.email.folder.name,
      );

      if (mounted) {
        if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email n8n\'e başarıyla gönderildi!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Response'u kaydet
          await N8nResponseStorageService().saveEmailResponse(
            widget.email.messageId ?? widget.email.id?.toString() ?? '',
            response,
            receivedDate: widget.email.receivedDate,
          );
          
          // Sayfayı yenile (AI önerileri güncellensin)
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email n8n\'e gönderildi ancak response alınamadı.\n\nn8n workflow\'unda "Respond to Webhook" node\'u olduğundan emin olun.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('n8n\'e email gönderilirken hata', tag: 'EmailDetailHeader', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingToN8n = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Önem butonu - Gmail tarzı
          IconButton(
            onPressed: widget.onMarkAsImportant,
            icon: Icon(
              widget.email.importance == EmailImportance.important
                  ? Icons.star
                  : Icons.star_border,
              color: widget.email.importance == EmailImportance.important
                  ? Colors.amber
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 8),

          // Diğer işlemler - Gmail tarzı
          IconButton(
            onPressed: widget.onReply,
            icon: Icon(
              Icons.reply,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: 'Yanıtla',
          ),
          IconButton(
            onPressed: widget.onForward,
            icon: Icon(
              Icons.forward,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: 'Yönlendir',
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: 'Sil',
          ),
          // Test butonu - n8n'e gönder
          IconButton(
            onPressed: _isSendingToN8n ? null : _sendToN8n,
            icon: _isSendingToN8n
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.send,
                    size: 20,
                    color: Colors.blue,
                  ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: 'n8n\'e Gönder (Test)',
          ),
          const Spacer(),
          _buildMoreMenu(context),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'reply':
            widget.onReply?.call();
            break;
          case 'forward':
            widget.onForward?.call();
            break;
          case 'delete':
            widget.onDelete?.call();
            break;
          case 'send_to_n8n':
            _sendToN8n();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'reply',
          child: Row(
            children: [
              Icon(Icons.reply, size: 18),
              SizedBox(width: 8),
              Text('Yanıtla'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'forward',
          child: Row(
            children: [
              Icon(Icons.forward, size: 18),
              SizedBox(width: 8),
              Text('Yönlendir'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Sil', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'send_to_n8n',
          child: Row(
            children: [
              Icon(Icons.send, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('n8n\'e Gönder (Test)', style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
      ],
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
      ),
    );
  }
}

