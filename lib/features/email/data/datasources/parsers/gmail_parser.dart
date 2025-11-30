import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/models/email.dart';

/// Gmail API message formatını Email modeline çeviren parser
class GmailParser {
  /// Gmail message'ı Email modeline çevir
  static Email parseGmailMessage(
    Map<String, dynamic> gmailMessage,
    String messageId, {
    int? userId,
    int? accountId,
  }) {
    final payload = gmailMessage['payload'] as Map<String, dynamic>? ?? {};
    final headers = payload['headers'] as List<dynamic>? ?? [];
    final labelIds = gmailMessage['labelIds'] as List<dynamic>? ?? [];

    // Header'ları Map'e çevir
    final headersMap = <String, String>{};
    for (final header in headers) {
      final name = (header['name'] as String? ?? '').toLowerCase();
      final value = header['value'] as String? ?? '';
      headersMap[name] = value;
    }

    // Email bilgilerini çıkar
    final subject = headersMap['subject'] ?? '(No Subject)';
    final fromEmail = _extractEmail(headersMap['from'] ?? '');
    final fromName = _extractName(headersMap['from'] ?? '');
    final toEmails = _extractEmails(headersMap['to'] ?? '');
    final ccEmails = headersMap['cc'] != null ? _extractEmails(headersMap['cc']!) : null;
    final bccEmails = headersMap['bcc'] != null ? _extractEmails(headersMap['bcc']!) : null;

    // Body'yi çıkar
    final bodyResult = _extractBody(payload);
    final plainText = bodyResult['plainText'];
    final htmlContent = bodyResult['htmlContent'];

    // Tarihleri parse et
    final internalDate = gmailMessage['internalDate'] as String?;
    final receivedDate =
        internalDate != null ? DateTime.fromMillisecondsSinceEpoch(int.parse(internalDate)) : DateTime.now();

    // Label'lardan folder ve status belirle
    final folder = _determineFolder(labelIds);
    final isRead = !labelIds.contains('UNREAD');
    final isStarred = labelIds.contains('STARRED');
    final isSpam = labelIds.contains('SPAM');
    final isTrash = labelIds.contains('TRASH');

    // Status belirle
    EmailStatus status;
    if (labelIds.contains('SENT')) {
      status = EmailStatus.sent;
    } else if (labelIds.contains('DRAFT')) {
      status = EmailStatus.draft;
    } else if (isRead) {
      status = EmailStatus.read;
    } else {
      status = EmailStatus.unread;
    }

    // Email modelini oluştur
    return Email(
      id: null,
      userId: userId ?? 0,
      accountId: accountId ?? 0,
      messageId: messageId,
      threadId: gmailMessage['threadId'] as String?,
      subject: subject,
      fromEmail: fromEmail,
      fromName: fromName.isNotEmpty ? fromName : null,
      toEmails: toEmails,
      ccEmails: ccEmails,
      bccEmails: bccEmails,
      plainText: plainText,
      htmlContent: htmlContent,
      receivedDate: receivedDate,
      sentDate: receivedDate,
      status: status,
      importance: EmailImportance.normal,
      isRead: isRead,
      isStarred: isStarred,
      isArchived: labelIds.contains('ARCHIVED'),
      isDeleted: isTrash,
      isSpam: isSpam,
      folder: folder,
      labels: labelIds.map((e) => e.toString()).toList(),
      sizeBytes: gmailMessage['sizeEstimate'] as int?,
      externalId: messageId,
      createdAt: receivedDate,
      updatedAt: receivedDate,
    );
  }

  /// Email adresini header'dan çıkar
  static String _extractEmail(String headerValue) {
    final match = RegExp(r'<(.+?)>').firstMatch(headerValue);
    if (match != null) {
      return match.group(1) ?? headerValue.trim();
    }
    return headerValue.trim();
  }

  /// İsmi header'dan çıkar
  static String _extractName(String headerValue) {
    final match = RegExp(r'^(.+?)\s*<').firstMatch(headerValue);
    if (match != null) {
      return match.group(1)?.replaceAll('"', '').trim() ?? '';
    }
    return '';
  }

  /// Email listesini header'dan çıkar
  static List<String> _extractEmails(String headerValue) {
    final emails = <String>[];
    final parts = headerValue.split(',');
    for (final part in parts) {
      emails.add(_extractEmail(part.trim()));
    }
    return emails;
  }

  /// HTML içeriğini recursive olarak parts içinden çıkar
  static String? _extractHtmlFromParts(Map<String, dynamic> payload) {
    final mimeType = payload['mimeType'] as String? ?? '';
    final body = payload['body'] as Map<String, dynamic>?;
    final data = body?['data'] as String?;

    if (mimeType == 'text/html' && data != null) {
      try {
        String normalizedData = data.replaceAll('-', '+').replaceAll('_', '/');
        while (normalizedData.length % 4 != 0) {
          normalizedData += '=';
        }
        final decoded = base64.decode(normalizedData);
        final content = utf8.decode(decoded);
        debugPrint('_extractHtmlFromParts: HTML bulundu ve decode edildi, uzunluk: ${content.length}');
        return content;
      } catch (e) {
        debugPrint('_extractHtmlFromParts: HTML decode hatası: $e, base64Url.decode deneniyor...');
        try {
          final decoded = base64Url.decode(data);
          final content = utf8.decode(decoded);
          debugPrint('_extractHtmlFromParts: base64Url.decode ile başarılı');
          return content;
        } catch (e2) {
          debugPrint('_extractHtmlFromParts: base64Url.decode da başarısız: $e2');
        }
      }
    }

    final parts = payload['parts'] as List<dynamic>?;
    if (parts != null) {
      debugPrint('_extractHtmlFromParts: ${parts.length} part bulundu, recursive aranıyor...');
      for (final part in parts) {
        final result = _extractHtmlFromParts(part as Map<String, dynamic>);
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  /// Plain text içeriğini recursive olarak parts içinden çıkar
  static String? _extractPlainTextFromParts(Map<String, dynamic> payload) {
    final mimeType = payload['mimeType'] as String? ?? '';
    final body = payload['body'] as Map<String, dynamic>?;
    final data = body?['data'] as String?;

    if (mimeType == 'text/plain' && data != null) {
      try {
        String normalizedData = data.replaceAll('-', '+').replaceAll('_', '/');
        while (normalizedData.length % 4 != 0) {
          normalizedData += '=';
        }
        final decoded = base64.decode(normalizedData);
        final content = utf8.decode(decoded);
        debugPrint('_extractPlainTextFromParts: Plain text bulundu ve decode edildi, uzunluk: ${content.length}');
        return content;
      } catch (e) {
        debugPrint('_extractPlainTextFromParts: Plain text decode hatası: $e, base64Url.decode deneniyor...');
        try {
          final decoded = base64Url.decode(data);
          final content = utf8.decode(decoded);
          debugPrint('_extractPlainTextFromParts: base64Url.decode ile başarılı');
          return content;
        } catch (e2) {
          debugPrint('_extractPlainTextFromParts: base64Url.decode da başarısız: $e2');
        }
      }
    }

    final parts = payload['parts'] as List<dynamic>?;
    if (parts != null) {
      for (final part in parts) {
        final result = _extractPlainTextFromParts(part as Map<String, dynamic>);
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  /// Body'yi payload'dan çıkar - Recursive approach ile nested parts desteği
  static Map<String, String?> _extractBody(Map<String, dynamic> payload) {
    String? plainText;
    String? htmlContent;

    final body = payload['body'] as Map<String, dynamic>?;
    if (body != null) {
      final data = body['data'] as String?;
      final mimeType = payload['mimeType'] as String? ?? '';

      if (data != null) {
        try {
          String normalizedData = data.replaceAll('-', '+').replaceAll('_', '/');
          while (normalizedData.length % 4 != 0) {
            normalizedData += '=';
          }
          final decoded = base64.decode(normalizedData);
          final content = utf8.decode(decoded);

          if (mimeType == 'text/html') {
            htmlContent = content;
            debugPrint('_extractBody: Body\'den HTML alındı, uzunluk: ${content.length}');
          } else {
            plainText = content;
            debugPrint('_extractBody: Body\'den plain text alındı, uzunluk: ${content.length}');
          }
        } catch (e) {
          debugPrint('_extractBody: Body decode hatası: $e, base64Url.decode deneniyor...');
          try {
            final decoded = base64Url.decode(data);
            final content = utf8.decode(decoded);
            if (mimeType == 'text/html') {
              htmlContent = content;
            } else {
              plainText = content;
            }
            debugPrint('_extractBody: base64Url.decode ile başarılı');
          } catch (e2) {
            debugPrint('_extractBody: base64Url.decode da başarısız: $e2');
          }
        }
      }
    }

    htmlContent ??= _extractHtmlFromParts(payload);
    plainText ??= _extractPlainTextFromParts(payload);

    debugPrint('_extractBody: Final - plainText: ${plainText?.length ?? 0}, htmlContent: ${htmlContent?.length ?? 0}');
    return {
      'plainText': plainText,
      'htmlContent': htmlContent,
    };
  }

  /// Label'lardan folder belirle
  static EmailFolder _determineFolder(List<dynamic> labelIds) {
    if (labelIds.contains('SENT')) {
      return EmailFolder.sent;
    } else if (labelIds.contains('DRAFT')) {
      return EmailFolder.drafts;
    } else if (labelIds.contains('SPAM')) {
      return EmailFolder.spam;
    } else if (labelIds.contains('TRASH')) {
      return EmailFolder.trash;
    }
    return EmailFolder.inbox;
  }
}

