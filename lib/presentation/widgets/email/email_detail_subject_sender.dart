import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/email.dart';
import '../../screens/email/utils/email_display_utils.dart';

/// E-posta konu ve gönderen bilgisi widget'ı - Gmail tarzı
class EmailDetailSubjectSender extends StatelessWidget {
  final Email email;

  const EmailDetailSubjectSender({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Konu - Gmail tarzı büyük başlık
          Text(
            email.subject,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 20),

          // Gönderen bilgisi - Gmail tarzı minimal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar - Gmail tarzı küçük ve renkli
              CircleAvatar(
                radius: 20,
                backgroundColor: EmailDisplayUtils.getAvatarColor(email.fromEmail),
                child: Text(
                  EmailDisplayUtils.getAvatarLetter(
                    email.fromDisplayName,
                    email.fromEmail,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Gönderen bilgileri - Gmail tarzı
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            email.fromDisplayName.isNotEmpty
                                ? email.fromDisplayName
                                : email.fromEmail,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                          ),
                        ),
                        Text(
                          DateFormat('d MMM yyyy, HH:mm').format(
                            email.receivedDate ?? email.sentDate ?? DateTime.now(),
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.54),
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.fromEmail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.54),
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

