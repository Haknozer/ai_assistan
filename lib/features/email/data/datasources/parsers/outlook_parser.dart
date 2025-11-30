import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/models/email.dart';

/// Outlook (Microsoft Graph API) message formatını Email modeline çeviren parser
class OutlookParser {
  /// Outlook folder ID'sini folder adından bul
  static String? getFolderId(String folder) {
    switch (folder.toLowerCase()) {
      case 'inbox':
        return 'inbox';
      case 'sent':
        return 'sentitems';
      case 'drafts':
        return 'drafts';
      case 'junk':
      case 'spam':
        return 'junkemail';
      case 'trash':
      case 'deleted':
        return 'deleteditems';
      default:
        return null;
    }
  }

  /// Outlook message'ı Email modeline çevir
  static Email? parseOutlookMessage(
    Map<String, dynamic> messageData, {
    int? userId,
    int? accountId,
    String? folder,
  }) {
    try {
      final messageId = messageData['id'] as String?;
      if (messageId == null) return null;

      final subject = messageData['subject'] as String? ?? '';
      final from = messageData['from'] as Map<String, dynamic>?;
      final fromEmail = from?['emailAddress']?['address'] as String? ?? '';
      final fromName = from?['emailAddress']?['name'] as String? ?? '';

      final toRecipients = messageData['toRecipients'] as List<dynamic>? ?? [];
      final toEmails = toRecipients
          .map((r) => (r as Map<String, dynamic>)['emailAddress']?['address'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .toList();

      final ccRecipients = messageData['ccRecipients'] as List<dynamic>? ?? [];
      final ccEmails = ccRecipients
          .map((r) => (r as Map<String, dynamic>)['emailAddress']?['address'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .toList();

      final bccRecipients = messageData['bccRecipients'] as List<dynamic>? ?? [];
      final bccEmails = bccRecipients
          .map((r) => (r as Map<String, dynamic>)['emailAddress']?['address'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .toList();

      final body = messageData['body'] as Map<String, dynamic>?;
      final bodyContent = body?['content'] as String? ?? '';
      final bodyContentType = body?['contentType'] as String? ?? 'text';
      final plainText = bodyContentType == 'text' ? bodyContent : '';
      final htmlContent = bodyContentType == 'html' ? bodyContent : '';

      final receivedDateTimeStr = messageData['receivedDateTime'] as String?;
      final sentDateTimeStr = messageData['sentDateTime'] as String?;
      final receivedDate =
          receivedDateTimeStr != null ? DateTime.tryParse(receivedDateTimeStr) ?? DateTime.now() : DateTime.now();
      final sentDate = sentDateTimeStr != null ? DateTime.tryParse(sentDateTimeStr) ?? receivedDate : receivedDate;

      final isRead = messageData['isRead'] as bool? ?? false;
      final importanceStr = messageData['importance'] as String? ?? 'normal';
      EmailImportance importance;
      switch (importanceStr.toLowerCase()) {
        case 'high':
        case 'important':
          importance = EmailImportance.important;
          break;
        case 'low':
          importance = EmailImportance.normal;
          break;
        default:
          importance = EmailImportance.normal;
      }

      // Status belirle
      EmailStatus status;
      if (folder?.toLowerCase() == 'sent' || folder?.toLowerCase() == 'sentitems') {
        status = EmailStatus.sent;
      } else if (folder?.toLowerCase() == 'drafts') {
        status = EmailStatus.draft;
      } else if (isRead) {
        status = EmailStatus.read;
      } else {
        status = EmailStatus.unread;
      }

      return Email(
        id: null,
        userId: userId ?? 0,
        accountId: accountId ?? 0,
        messageId: messageId,
        threadId: null,
        subject: subject,
        fromEmail: fromEmail,
        fromName: fromName.isNotEmpty ? fromName : null,
        toEmails: toEmails,
        ccEmails: ccEmails,
        bccEmails: bccEmails,
        plainText: plainText,
        htmlContent: htmlContent,
        receivedDate: receivedDate,
        sentDate: sentDate,
        status: status,
        importance: importance,
        isRead: isRead,
        isStarred: false,
        isArchived: false,
        isDeleted: folder?.toLowerCase() == 'deleteditems' || folder?.toLowerCase() == 'trash',
        isSpam: folder?.toLowerCase() == 'junkemail' || folder?.toLowerCase() == 'spam',
        folder: EmailFolder.fromString(folder ?? 'inbox'),
        labels: [],
        sizeBytes: null,
        externalId: messageId,
        createdAt: receivedDate,
        updatedAt: receivedDate,
      );
    } catch (e) {
      debugPrint('Outlook message parse hatası: $e');
      return null;
    }
  }
}

