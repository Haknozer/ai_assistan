import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/email.dart';
import '../../../models/email_account.dart';
import '../../../features/email/providers/email_provider.dart';
import 'compose_email_dialog.dart';
import '../../../providers/user_provider.dart';

/// E-posta işlemleri handler'ı (reply, forward, delete, mark important)
class EmailActionsHandler {
  final BuildContext context;
  final WidgetRef ref;

  EmailActionsHandler(this.context, this.ref);

  /// E-postayı yanıtla
  Future<void> replyToEmail(
    Email email,
    EmailNotifier emailNotifier,
    String? accessToken,
    List<EmailAccount> accounts,
    EmailAccount primaryAccount,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    final accountId = email.accountId;

    showDialog(
      context: context,
      builder: (context) => ComposeEmailDialog(
        replyTo: email,
        accountId: accountId,
        userId: currentUser?.id,
        onEmailSent: (newEmail) => _handleEmailSent(
          newEmail,
          emailNotifier,
          accountId,
          'E-posta başarıyla gönderildi',
        ),
        onDraftSaved: (newEmail) => _handleDraftSaved(
          newEmail,
          emailNotifier,
          accountId,
        ),
      ),
    );
  }

  /// E-postayı yönlendir
  Future<void> forwardEmail(
    Email email,
    EmailNotifier emailNotifier,
    String? accessToken,
    List<EmailAccount> accounts,
    EmailAccount primaryAccount,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    final accountId = email.accountId;

    showDialog(
      context: context,
      builder: (context) => ComposeEmailDialog(
        forwardTo: email,
        accountId: accountId,
        userId: currentUser?.id,
        onEmailSent: (newEmail) => _handleEmailSent(
          newEmail,
          emailNotifier,
          accountId,
          'E-posta başarıyla yönlendirildi',
        ),
        onDraftSaved: (newEmail) => _handleDraftSaved(
          newEmail,
          emailNotifier,
          accountId,
        ),
      ),
    );
  }

  /// E-postayı sil
  void deleteEmail(
    Email email,
    EmailNotifier emailNotifier,
    EmailListParams emailParams,
    VoidCallback onDeleted,
  ) {
    if (email.messageId == null) return;
    final emailId = int.tryParse(email.messageId!) ?? 0;
    if (emailId == 0) return;

    emailNotifier.deleteEmail(emailId, accessToken: emailParams.accessToken);
    onDeleted();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-posta silindi')),
    );
  }

  /// E-postayı önemli olarak işaretle/kaldır
  void markAsImportant(
    Email email,
    EmailNotifier emailNotifier,
    EmailListParams emailParams,
  ) {
    if (email.messageId == null) return;
    final isImportant = email.importance != EmailImportance.important;
    final emailId = int.tryParse(email.messageId!) ?? 0;
    if (emailId == 0) return;

    emailNotifier.toggleImportant(emailId, isImportant, accessToken: emailParams.accessToken);
  }

  Future<void> _handleEmailSent(
    Email newEmail,
    EmailNotifier emailNotifier,
    int accountId,
    String successMessage,
  ) async {
    try {
      await emailNotifier.sendEmail(
        accountId: accountId,
        toEmails: newEmail.toEmails,
        subject: newEmail.subject,
        plainText: newEmail.plainText,
        htmlContent: newEmail.htmlContent,
        importance: newEmail.importance,
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-posta gönderilirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDraftSaved(
    Email newEmail,
    EmailNotifier emailNotifier,
    int accountId,
  ) async {
    try {
      await emailNotifier.saveDraft(
        accountId: accountId,
        subject: newEmail.subject,
        plainText: newEmail.plainText,
        htmlContent: newEmail.htmlContent,
        toEmails: newEmail.toEmails.isNotEmpty ? newEmail.toEmails : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Taslak başarıyla kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Taslak kaydedilirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

