import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_endpoints.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email.dart';
import '../parsers/gmail_parser.dart';
import '../utils/email_builder.dart';

/// Gmail API client - Gmail API çağrılarını yönetir
class GmailApiClient {
  final ApiClient _apiClient;

  GmailApiClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Gmail API'den email listesi çekme
  Future<List<Email>> getEmails({
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    required String accessToken,
    int? userId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'maxResults': limit ?? 50,
      };

      // Folder'a göre query oluştur
      String query = _buildFolderQuery(folder);
      queryParams['q'] = query;

      // Gmail API'den message listesini çek
      final response = await _apiClient.get(
        ApiEndpoints.messages,
        queryParameters: queryParams,
        accessToken: accessToken,
      );

      final messagesList = response['messages'] as List<dynamic>? ?? [];
      if (messagesList.isEmpty) {
        return [];
      }

      // Her message için detaylı bilgi çek
      final emails = <Email>[];
      for (final messageItem in messagesList.take(limit ?? 50)) {
        try {
          final messageIdValue = messageItem['id'];
          if (messageIdValue == null) continue;
          final String messageId = messageIdValue.toString();
          if (messageId.isEmpty) continue;
          final email = await getEmailDetails(
            messageId: messageId,
            accessToken: accessToken,
            userId: userId,
            accountId: accountId,
          );
          if (email != null) {
            emails.add(email);
          }
        } catch (e) {
          continue;
        }
      }

      return emails;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch emails from Gmail API: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Folder'a göre Gmail query oluştur
  String _buildFolderQuery(String? folder) {
    if (folder == null) return 'in:inbox';
    switch (folder.toLowerCase()) {
      case 'inbox':
        return 'in:inbox';
      case 'sent':
        return 'in:sent';
      case 'drafts':
        return 'in:drafts';
      case 'spam':
        return 'in:spam';
      case 'trash':
        return 'in:trash';
      default:
        return 'in:inbox';
    }
  }

  /// Gmail API'den tek email detayını çekme
  Future<Email?> getEmailDetails({
    required String messageId,
    required String accessToken,
    int? userId,
    int? accountId,
  }) async {
    try {
      if (accessToken.isEmpty) {
        debugPrint('getEmailDetails: Access token boş!');
        return null;
      }

      final response = await _apiClient.get(
        ApiEndpoints.messageById(messageId),
        queryParameters: {'format': 'full'},
        accessToken: accessToken,
      );
      return GmailParser.parseGmailMessage(response, messageId, userId: userId, accountId: accountId);
    } on NotFoundException {
      debugPrint('getEmailDetails: Email bulunamadı (messageId: $messageId)');
      return null;
    } catch (e) {
      debugPrint('getEmailDetails hatası (messageId: $messageId): ${e.toString()}');
      return null;
    }
  }

  /// Email gönderme (Gmail API)
  Future<Email> sendEmail({
    required int accountId,
    required List<String> toEmails,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? ccEmails,
    List<String>? bccEmails,
    List<Map<String, dynamic>>? attachments,
    EmailImportance importance = EmailImportance.normal,
    required String accessToken,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      final emailBody = EmailBuilder.createEmailBody(
        toEmails: toEmails,
        subject: subject,
        plainText: plainText,
        htmlContent: htmlContent,
        ccEmails: ccEmails,
        bccEmails: bccEmails,
      );

      final body = {'raw': emailBody};

      final response = await _apiClient.post(
        ApiEndpoints.sendMessage,
        body: body,
        accessToken: accessToken,
      );

      final messageId = response['id'] as String?;
      if (messageId == null) {
        throw ApiException(message: 'Failed to send email: No message ID returned');
      }

      final sentEmail = await getEmailDetails(
        messageId: messageId,
        accessToken: accessToken,
      );
      if (sentEmail == null) {
        throw ApiException(message: 'Failed to fetch sent email');
      }
      return sentEmail;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Failed to send email via Gmail API: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email'i okundu olarak işaretleme (Gmail API)
  Future<Email> markAsRead({
    required String messageId,
    required String accessToken,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      await _apiClient.post(
        ApiEndpoints.modifyMessage(messageId),
        body: {
          'removeLabelIds': ['UNREAD'],
        },
        accessToken: accessToken,
      );

      final existingEmail = await getEmailDetails(
        messageId: messageId,
        accessToken: accessToken,
      );
      if (existingEmail != null) {
        return existingEmail;
      }

      throw NotFoundException(message: 'Email not found after update');
    } catch (e) {
      if (e is NotFoundException || e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Failed to mark email as read: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email'i okunmamış olarak işaretleme (Gmail API)
  Future<Email> markAsUnread({
    required String messageId,
    required String accessToken,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      await _apiClient.post(
        ApiEndpoints.modifyMessage(messageId),
        body: {
          'addLabelIds': ['UNREAD'],
        },
        accessToken: accessToken,
      );

      final updatedEmail = await getEmailDetails(
        messageId: messageId,
        accessToken: accessToken,
      );
      if (updatedEmail == null) {
        throw NotFoundException(message: 'Email not found');
      }
      return updatedEmail;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Failed to mark email as unread: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email'i önemli olarak işaretleme/kaldırma (Gmail API)
  Future<Email> toggleImportant({
    required String messageId,
    required bool isImportant,
    required String accessToken,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      if (isImportant) {
        await _apiClient.post(
          ApiEndpoints.modifyMessage(messageId),
          body: {
            'addLabelIds': ['IMPORTANT'],
          },
          accessToken: accessToken,
        );
      } else {
        await _apiClient.post(
          ApiEndpoints.modifyMessage(messageId),
          body: {
            'removeLabelIds': ['IMPORTANT'],
          },
          accessToken: accessToken,
        );
      }

      final updatedEmail = await getEmailDetails(
        messageId: messageId,
        accessToken: accessToken,
      );
      if (updatedEmail == null) {
        throw NotFoundException(message: 'Email not found');
      }
      return updatedEmail;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Failed to toggle email importance: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email silme (Gmail API)
  Future<void> deleteEmail({
    required String messageId,
    required String accessToken,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      await _apiClient.post(
        ApiEndpoints.modifyMessage(messageId),
        body: {
          'addLabelIds': ['TRASH'],
        },
        accessToken: accessToken,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Failed to delete email: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email arama (Gmail API)
  Future<List<Email>> searchEmails({
    required String query,
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    required String accessToken,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'maxResults': limit ?? 50,
      };

      final response = await _apiClient.get(
        ApiEndpoints.messages,
        queryParameters: queryParams,
        accessToken: accessToken,
      );

      final messagesList = response['messages'] as List<dynamic>? ?? [];
      if (messagesList.isEmpty) {
        return [];
      }

      final emails = <Email>[];
      for (final messageItem in messagesList.take(limit ?? 50)) {
        try {
          final messageId = messageItem['id'] as String;
          final email = await getEmailDetails(
            messageId: messageId,
            accessToken: accessToken,
          );
          if (email != null) {
            emails.add(email);
          }
        } catch (e) {
          continue;
        }
      }

      return emails;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Failed to search emails: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email taslağı kaydetme (Gmail API)
  Future<Email> saveDraft({
    required int accountId,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? toEmails,
    List<String>? ccEmails,
    List<String>? bccEmails,
    int? draftId,
    required String accessToken,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      final emailBody = EmailBuilder.createEmailBody(
        toEmails: toEmails ?? [],
        subject: subject,
        plainText: plainText,
        htmlContent: htmlContent,
        ccEmails: ccEmails,
        bccEmails: bccEmails,
      );

      final body = {
        'message': {'raw': emailBody}
      };

      final endpoint = draftId != null
          ? ApiEndpoints.labelById(draftId.toString())
          : '${ApiEndpoints.labels}/drafts';

      final response = draftId != null
          ? await _apiClient.put(endpoint, body: body, accessToken: accessToken)
          : await _apiClient.post(endpoint, body: body, accessToken: accessToken);

      final messageId = response['id'] as String?;
      if (messageId == null) {
        throw ApiException(message: 'Failed to save draft: No message ID returned');
      }

      final savedDraft = await getEmailDetails(
        messageId: messageId,
        accessToken: accessToken,
      );
      if (savedDraft == null) {
        throw ApiException(message: 'Failed to fetch saved draft');
      }
      return savedDraft;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Failed to save draft: ${e.toString()}',
        originalError: e,
      );
    }
  }
}

