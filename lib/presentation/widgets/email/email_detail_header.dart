import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/email.dart';

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
      ],
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
      ),
    );
  }
}

