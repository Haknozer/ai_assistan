import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_endpoints.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email.dart';
import '../parsers/outlook_parser.dart';

/// Outlook (Microsoft Graph API) client - Outlook API çağrılarını yönetir
class OutlookApiClient {
  final ApiClient _apiClient;

  OutlookApiClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Outlook (Microsoft Graph API) email listesi çekme
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
        '\$top': limit ?? 50,
        '\$orderby': 'receivedDateTime desc',
        '\$select':
            'id,subject,from,toRecipients,ccRecipients,bccRecipients,receivedDateTime,sentDateTime,isRead,importance,bodyPreview,body,hasAttachments',
      };

      String endpoint;
      if (folder != null && folder.toLowerCase() != 'inbox') {
        final folderId = OutlookParser.getFolderId(folder);
        if (folderId != null) {
          endpoint = ApiEndpoints.graphMailFolderMessages(folderId);
        } else {
          endpoint = ApiEndpoints.graphMessages;
          queryParams['\$filter'] = "parentFolderId eq 'inbox'";
        }
      } else {
        endpoint = ApiEndpoints.graphMessages;
      }

      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParams,
        accessToken: accessToken,
      );

      final messagesList = response['value'] as List<dynamic>? ?? [];
      if (messagesList.isEmpty) {
        return [];
      }

      final emails = <Email>[];
      for (final messageItem in messagesList.take(limit ?? 50)) {
        try {
          final email = OutlookParser.parseOutlookMessage(
            messageItem,
            userId: userId,
            accountId: accountId,
            folder: folder,
          );
          if (email != null) {
            emails.add(email);
          }
        } catch (e) {
          debugPrint('Outlook message parse hatası: $e');
          continue;
        }
      }

      return emails;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch emails from Outlook API: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Outlook API'den tek email detayını çekme
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
        ApiEndpoints.graphMessageById(messageId),
        queryParameters: {},
        accessToken: accessToken,
      );
      return OutlookParser.parseOutlookMessage(
        response,
        userId: userId,
        accountId: accountId,
        folder: null,
      );
    } on NotFoundException {
      debugPrint('getEmailDetails: Email bulunamadı (messageId: $messageId)');
      return null;
    } catch (e) {
      debugPrint('getEmailDetails hatası (messageId: $messageId): ${e.toString()}');
      return null;
    }
  }

  /// Email gönderme (Microsoft Graph API)
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
      throw ApiException(message: 'Access token required for Outlook API');
    }

    try {
      // Microsoft Graph API için message body oluştur
      final messageBody = <String, dynamic>{
        'message': {
          'toRecipients': toEmails.map((email) => {
            'emailAddress': {'address': email}
          }).toList(),
          if (ccEmails != null && ccEmails.isNotEmpty)
            'ccRecipients': ccEmails.map((email) => {
              'emailAddress': {'address': email}
            }).toList(),
          if (bccEmails != null && bccEmails.isNotEmpty)
            'bccRecipients': bccEmails.map((email) => {
              'emailAddress': {'address': email}
            }).toList(),
          'subject': subject,
          'importance': importance == EmailImportance.important 
              ? 'high' 
              : 'normal',
          'body': {
            'contentType': htmlContent != null ? 'html' : 'text',
            'content': htmlContent ?? plainText ?? '',
          },
        },
      };

      // Microsoft Graph API sendMail endpoint'i response döndürmez (202 Accepted)
      // Gönderilen email'i almak için sent items'dan çekmemiz gerekir
      await _apiClient.post(
        ApiEndpoints.graphSendMessage,
        body: messageBody,
        accessToken: accessToken,
      );

      // Sent items'dan en son gönderilen email'i çek
      // Kısa bir bekleme ekleyelim ki email sent items'a kaydedilsin
      await Future.delayed(const Duration(milliseconds: 500));

      final sentItemsResponse = await _apiClient.get(
        '${ApiEndpoints.graphMailFolders}/sentitems/messages',
        queryParameters: {
          '\$top': 1,
          '\$orderby': 'sentDateTime desc',
          '\$select': 'id,subject,from,toRecipients,ccRecipients,bccRecipients,receivedDateTime,sentDateTime,isRead,importance,bodyPreview,body',
        },
        accessToken: accessToken,
      );

      final sentMessages = sentItemsResponse['value'] as List<dynamic>? ?? [];
      if (sentMessages.isEmpty) {
        throw ApiException(message: 'Email gönderildi ancak sent items\'dan alınamadı');
      }

      final sentMessage = sentMessages.first as Map<String, dynamic>;
      final sentEmail = OutlookParser.parseOutlookMessage(
        sentMessage,
        userId: null,
        accountId: accountId,
        folder: 'sent',
      );

      if (sentEmail == null) {
        throw ApiException(message: 'Email gönderildi ancak parse edilemedi');
      }

      return sentEmail;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Failed to send email: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email taslağı kaydetme (Microsoft Graph API)
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
      throw ApiException(message: 'Access token required for Outlook API');
    }

    try {
      // Microsoft Graph API için message body oluştur
      final messageBody = <String, dynamic>{
        'toRecipients': (toEmails ?? []).map((email) => {
          'emailAddress': {'address': email}
        }).toList(),
        if (ccEmails != null && ccEmails.isNotEmpty)
          'ccRecipients': ccEmails.map((email) => {
            'emailAddress': {'address': email}
          }).toList(),
        if (bccEmails != null && bccEmails.isNotEmpty)
          'bccRecipients': bccEmails.map((email) => {
            'emailAddress': {'address': email}
          }).toList(),
        'subject': subject,
        'body': {
          'contentType': htmlContent != null ? 'html' : 'text',
          'content': htmlContent ?? plainText ?? '',
        },
        'isDraft': true,
      };

      final endpoint = draftId != null
          ? ApiEndpoints.graphMessageById(draftId.toString())
          : ApiEndpoints.graphMessages;

      final response = draftId != null
          ? await _apiClient.put(endpoint, body: messageBody, accessToken: accessToken)
          : await _apiClient.post(endpoint, body: messageBody, accessToken: accessToken);

      final messageId = response['id'] as String?;
      if (messageId == null) {
        throw ApiException(message: 'Failed to save draft: No message ID returned');
      }

      final savedDraft = await getEmailDetails(
        messageId: messageId,
        accessToken: accessToken,
        accountId: accountId,
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

