import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_endpoints.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email.dart';

/// Email API çağrılarını yöneten servis sınıfı
class EmailService {
  final ApiClient _apiClient;

  EmailService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Email listesini çekme
  /// [accountId] belirtilirse sadece o hesaba ait emailleri getirir
  /// [folder] belirtilirse sadece o klasördeki emailleri getirir
  /// [limit] ve [offset] pagination için kullanılır
  Future<List<Email>> getEmails({
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (accountId != null) queryParams['account_id'] = accountId;
      if (folder != null) queryParams['folder'] = folder;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final endpoint = accountId != null && folder != null
          ? ApiEndpoints.emailsByFolder(accountId, folder)
          : ApiEndpoints.emails;

      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParams,
        accessToken: accessToken,
      );

      // Response formatı: { "data": [...], "total": 100 }
      final emailsData = response['data'] as List<dynamic>? ?? response['emails'] as List<dynamic>? ?? [];
      
      return emailsData.map((json) => Email.fromJson(json as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch emails: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Tek email detayını çekme
  Future<Email> getEmailById(int emailId, {String? accessToken}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.emailById(emailId),
        accessToken: accessToken,
      );

      final emailData = response['data'] ?? response;
      return Email.fromJson(emailData as Map<String, dynamic>);
    } on NotFoundException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch email: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email gönderme
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
    String? accessToken,
  }) async {
    try {
      final body = {
        'account_id': accountId,
        'to_emails': toEmails,
        'subject': subject,
        if (plainText != null) 'plain_text': plainText,
        if (htmlContent != null) 'html_content': htmlContent,
        if (ccEmails != null && ccEmails.isNotEmpty) 'cc_emails': ccEmails,
        if (bccEmails != null && bccEmails.isNotEmpty) 'bcc_emails': bccEmails,
        if (attachments != null && attachments.isNotEmpty) 'attachments': attachments,
        'importance': importance.name,
      };

      final response = await _apiClient.post(
        ApiEndpoints.sendEmail,
        body: body,
        accessToken: accessToken,
      );

      final emailData = response['data'] ?? response;
      return Email.fromJson(emailData as Map<String, dynamic>);
    } on ValidationException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to send email: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email'i okundu olarak işaretleme
  Future<Email> markAsRead(int emailId, {String? accessToken}) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.markAsRead(emailId),
        accessToken: accessToken,
      );

      final emailData = response['data'] ?? response;
      return Email.fromJson(emailData as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to mark email as read: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email'i okunmamış olarak işaretleme
  Future<Email> markAsUnread(int emailId, {String? accessToken}) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.markAsUnread(emailId),
        accessToken: accessToken,
      );

      final emailData = response['data'] ?? response;
      return Email.fromJson(emailData as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to mark email as unread: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email'i önemli olarak işaretleme/kaldırma
  Future<Email> toggleImportant(int emailId, bool isImportant, {String? accessToken}) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.emailById(emailId),
        body: {
          'importance': isImportant ? 'important' : 'normal',
        },
        accessToken: accessToken,
      );

      final emailData = response['data'] ?? response;
      return Email.fromJson(emailData as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to toggle email importance: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email silme
  Future<void> deleteEmail(int emailId, {String? accessToken}) async {
    try {
      await _apiClient.delete(
        ApiEndpoints.deleteEmail(emailId),
        accessToken: accessToken,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete email: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email arama
  Future<List<Email>> searchEmails({
    required String query,
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        if (accountId != null) 'account_id': accountId,
        if (folder != null) 'folder': folder,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };

      final response = await _apiClient.get(
        ApiEndpoints.searchEmails,
        queryParameters: queryParams,
        accessToken: accessToken,
      );

      final emailsData = response['data'] as List<dynamic>? ?? response['emails'] as List<dynamic>? ?? [];
      return emailsData.map((json) => Email.fromJson(json as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to search emails: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email taslağı kaydetme
  Future<Email> saveDraft({
    required int accountId,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? toEmails,
    List<String>? ccEmails,
    List<String>? bccEmails,
    int? draftId,
    String? accessToken,
  }) async {
    try {
      final body = {
        'account_id': accountId,
        'subject': subject,
        'status': 'draft',
        if (plainText != null) 'plain_text': plainText,
        if (htmlContent != null) 'html_content': htmlContent,
        if (toEmails != null) 'to_emails': toEmails,
        if (ccEmails != null) 'cc_emails': ccEmails,
        if (bccEmails != null) 'bcc_emails': bccEmails,
      };

      final endpoint = draftId != null 
          ? ApiEndpoints.emailById(draftId)
          : ApiEndpoints.emails;

      final response = draftId != null
          ? await _apiClient.put(endpoint, body: body, accessToken: accessToken)
          : await _apiClient.post(endpoint, body: body, accessToken: accessToken);

      final emailData = response['data'] ?? response;
      return Email.fromJson(emailData as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to save draft: ${e.toString()}',
        originalError: e,
      );
    }
  }
}

