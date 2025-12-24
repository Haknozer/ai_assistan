import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/email.dart';
import '../../../models/email_account.dart';
import '../../../features/email/providers/email_provider.dart';
import 'compose_email_dialog.dart';
import '../../../providers/user_provider.dart';

/// E-posta oluşturma dialog handler'ı
class EmailComposeHandler {
  final BuildContext context;
  final WidgetRef ref;

  EmailComposeHandler(this.context, this.ref);

  /// Yeni e-posta oluştur dialog'unu göster
  void showComposeDialog(
    EmailNotifier emailNotifier, {
    int? accountId,
    String? accessToken,
    List<EmailAccount>? availableAccounts,
  }) {
    final currentUser = ref.read(currentUserProvider);

    // AccountId'yi belirle
    int? finalAccountId = accountId ?? emailNotifier.accountId;

    if (finalAccountId == null || finalAccountId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-posta hesabı bulunamadı. Lütfen e-posta hesabınızı kontrol edin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ComposeEmailDialog(
        accountId: finalAccountId,
        userId: currentUser?.id,
        availableAccounts: availableAccounts,
        onEmailSent: (email) => _handleEmailSent(
          email,
          emailNotifier,
          finalAccountId,
        ),
        onDraftSaved: (email) => _handleDraftSaved(
          email,
          emailNotifier,
          finalAccountId,
        ),
      ),
    );
  }

  Future<void> _handleEmailSent(
    Email email,
    EmailNotifier emailNotifier,
    int finalAccountId,
  ) async {
    try {
      final selectedAccountId = email.accountId > 0 ? email.accountId : finalAccountId;
      await emailNotifier.sendEmail(
        accountId: selectedAccountId,
        toEmails: email.toEmails,
        subject: email.subject,
        plainText: email.plainText,
        htmlContent: email.htmlContent,
        importance: email.importance,
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta başarıyla gönderildi'),
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
    Email email,
    EmailNotifier emailNotifier,
    int finalAccountId,
  ) async {
    try {
      final selectedAccountId = email.accountId > 0 ? email.accountId : finalAccountId;
      if (selectedAccountId == 0) {
        throw Exception('Account ID bulunamadı. Lütfen e-posta hesabınızı kontrol edin.');
      }
      await emailNotifier.saveDraft(
        accountId: selectedAccountId,
        subject: email.subject,
        plainText: email.plainText,
        htmlContent: email.htmlContent,
        toEmails: email.toEmails.isNotEmpty ? email.toEmails : null,
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

