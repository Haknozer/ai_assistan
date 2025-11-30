import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/email.dart';
import '../../../models/email_account.dart';
import '../../../core/theme/app_colors.dart';

/// E-posta listesi widget'ı
class EmailList extends StatelessWidget {
  final List<Email> emails;
  final int? selectedIndex;
  final Function(int) onEmailSelected;
  final Function(Email) onDeleteEmail;
  final Function(Email) onMarkAsImportant;
  final EmailProvider? provider; // Platform bilgisi (fallback)
  final Map<int, EmailProvider> accountProviders; // Account ID -> Provider mapping

  const EmailList({
    super.key,
    required this.emails,
    this.selectedIndex,
    required this.onEmailSelected,
    required this.onDeleteEmail,
    required this.onMarkAsImportant,
    this.provider,
    this.accountProviders = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (emails.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(context),
          width: 1,
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: emails.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            height: 1,
            color: AppColors.getBorderColor(context),
          ),
        ),
        itemBuilder: (context, index) {
          final email = emails[index];
          final isSelected = selectedIndex == index;

          // Email'in accountId'sine göre provider'ı bul
          EmailProvider? emailProvider;
          if (accountProviders.containsKey(email.accountId)) {
            emailProvider = accountProviders[email.accountId];
          }
          // Fallback olarak genel provider'ı kullan
          emailProvider ??= provider;

          return EmailListItem(
            email: email,
            isSelected: isSelected,
            onTap: () => onEmailSelected(index),
            onDelete: () => onDeleteEmail(email),
            onToggleImportant: () => onMarkAsImportant(email),
            provider: emailProvider,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'E-posta bulunamadı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu filtreye uygun e-posta yok',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// E-posta listesi item bileşeni
class EmailListItem extends StatelessWidget {
  final Email email;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleImportant;
  final EmailProvider? provider; // Platform bilgisi

  const EmailListItem({
    super.key,
    required this.email,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onToggleImportant,
    this.provider,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Şimdi';
        }
        return '${difference.inMinutes} dk önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : email.status == EmailStatus.unread
                  ? Theme.of(context).colorScheme.surface
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol icon ve durum
            Column(
              children: [
                // Önem ikonu
                GestureDetector(
                  onTap: onToggleImportant,
                  child: Icon(
                    email.importance == EmailImportance.important ? Icons.star : Icons.star_border,
                    size: 20,
                    color: email.importance == EmailImportance.important
                        ? Colors.amber
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 4),
                // Okunmamış indicator
                if (email.status == EmailStatus.unread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 8, height: 8),
              ],
            ),

            const SizedBox(width: 12),

            // E-posta içeriği
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gönderen ve konu
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          email.fromDisplayName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: email.status == EmailStatus.unread ? FontWeight.w600 : FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Email icon
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Konu
                  Text(
                    email.subject,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: email.status == EmailStatus.unread ? FontWeight.w600 : FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),

                  const SizedBox(height: 4),

                  // Preview
                  Text(
                    email.contentPreview,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 8),

                  // Alt bilgi
                  Row(
                    children: [
                      // Tarih
                      Text(
                        _formatDate(email.receivedDate ?? email.sentDate ?? DateTime.now()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                      const SizedBox(width: 8),
                      // Ek var indicator
                      if (email.hasAttachments)
                        Icon(
                          Icons.attach_file,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      const Spacer(),
                      // Platform badge (Gmail/Outlook)
                      if (provider != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getProviderColor(provider!).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getProviderIcon(provider!),
                                size: 12,
                                color: _getProviderColor(provider!),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                provider!.displayName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getProviderColor(provider!),
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Durum badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(context, email.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(email.status),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(context, email.status),
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Sil butonu
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.delete_outline,
                size: 18,
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, EmailStatus status) {
    switch (status) {
      case EmailStatus.unread:
        return Theme.of(context).colorScheme.primary;
      case EmailStatus.read:
        return Colors.green;
      case EmailStatus.draft:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(EmailStatus status) {
    switch (status) {
      case EmailStatus.unread:
        return 'Okunmamış';
      case EmailStatus.read:
        return 'Okundu';
      case EmailStatus.draft:
        return 'Taslak';
      default:
        return '';
    }
  }

  Color _getProviderColor(EmailProvider provider) {
    switch (provider) {
      case EmailProvider.gmail:
        return Colors.red;
      case EmailProvider.outlook:
        return Colors.blue;
      case EmailProvider.yahoo:
        return Colors.purple;
    }
  }

  IconData _getProviderIcon(EmailProvider provider) {
    switch (provider) {
      case EmailProvider.gmail:
        return Icons.mail;
      case EmailProvider.outlook:
        return Icons.email;
      case EmailProvider.yahoo:
        return Icons.mark_email_read;
    }
  }
}
