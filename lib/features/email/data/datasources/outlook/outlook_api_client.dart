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
}

