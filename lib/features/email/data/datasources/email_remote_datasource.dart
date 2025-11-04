import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_endpoints.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email.dart';

/// Email remote data source - API çağrılarını yönetir
class EmailRemoteDataSource {
  final ApiClient _apiClient;

  EmailRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Email listesini çekme
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

      final endpoint =
          accountId != null && folder != null ? ApiEndpoints.emailsByFolder(accountId, folder) : ApiEndpoints.emails;

      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParams,
        accessToken: accessToken,
      );

      final emailsData = response['data'] as List<dynamic>? ?? response['emails'] as List<dynamic>? ?? [];

      return emailsData.map((json) => _parseEmailFromApi(json as Map<String, dynamic>)).toList();
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
      return _parseEmailFromApi(emailData as Map<String, dynamic>);
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
      return _parseEmailFromApi(emailData as Map<String, dynamic>);
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
      return _parseEmailFromApi(emailData as Map<String, dynamic>);
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
      return _parseEmailFromApi(emailData as Map<String, dynamic>);
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
      return _parseEmailFromApi(emailData as Map<String, dynamic>);
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
      return emailsData.map((json) => _parseEmailFromApi(json as Map<String, dynamic>)).toList();
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

      final endpoint = draftId != null ? ApiEndpoints.emailById(draftId) : ApiEndpoints.emails;

      final response = draftId != null
          ? await _apiClient.put(endpoint, body: body, accessToken: accessToken)
          : await _apiClient.post(endpoint, body: body, accessToken: accessToken);

      final emailData = response['data'] ?? response;
      return _parseEmailFromApi(emailData as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to save draft: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// API'den gelen JSON'u Email modeline güvenli şekilde parse eder
  /// API snake_case kullanır, model camelCase bekler
  Email _parseEmailFromApi(Map<String, dynamic> json) {
    try {
      // API'den gelen snake_case'i camelCase'e çevir ve null safety kontrolü yap
      final normalizedJson = <String, dynamic>{
        'id': json['id'] as int?,
        'user_id': json['user_id'] ?? json['userId'],
        'account_id': json['account_id'] ?? json['accountId'],
        'message_id': json['message_id'] ?? json['messageId'],
        'thread_id': json['thread_id'] ?? json['threadId'],
        'subject': json['subject'] ?? '',
        'from_email': json['from_email'] ?? json['fromEmail'] ?? '',
        'from_name': json['from_name'] ?? json['fromName'],
        'to_emails': json['to_emails'] ?? json['toEmails'] ?? [],
        'cc_emails': json['cc_emails'] ?? json['ccEmails'],
        'bcc_emails': json['bcc_emails'] ?? json['bccEmails'],
        'plain_text': json['plain_text'] ?? json['plainText'],
        'html_content': json['html_content'] ?? json['htmlContent'],
        'attachments': json['attachments'],
        'received_date': json['received_date'] ?? json['receivedDate'],
        'sent_date': json['sent_date'] ?? json['sentDate'],
        'email_status': json['email_status'] ?? json['status'],
        'email_importance': json['email_importance'] ?? json['importance'],
        'is_read': json['is_read'] ?? json['isRead'] ?? false,
        'is_starred': json['is_starred'] ?? json['isStarred'] ?? false,
        'is_archived': json['is_archived'] ?? json['isArchived'] ?? false,
        'is_deleted': json['is_deleted'] ?? json['isDeleted'] ?? false,
        'is_spam': json['is_spam'] ?? json['isSpam'] ?? false,
        'folder': json['folder'] ?? 'inbox',
        'labels': json['labels'],
        'size_bytes': json['size_bytes'] ?? json['sizeBytes'],
        'external_id': json['external_id'] ?? json['externalId'],
        'created_at': json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
        'updated_at': json['updated_at'] ?? json['updatedAt'] ?? DateTime.now().toIso8601String(),
      };

      // Required alanları kontrol et ve int'e çevir
      if (normalizedJson['user_id'] == null) {
        throw ApiException(message: 'Missing required field: user_id');
      }
      if (normalizedJson['account_id'] == null) {
        throw ApiException(message: 'Missing required field: account_id');
      }

      // int olmayan değerleri int'e çevir
      if (normalizedJson['user_id'] is! int) {
        normalizedJson['user_id'] = int.tryParse(normalizedJson['user_id'].toString()) ?? 0;
      }
      if (normalizedJson['account_id'] is! int) {
        normalizedJson['account_id'] = int.tryParse(normalizedJson['account_id'].toString()) ?? 0;
      }

      if (normalizedJson['subject'] == null || normalizedJson['subject'] == '') {
        normalizedJson['subject'] = '(No Subject)';
      }
      if (normalizedJson['from_email'] == null || normalizedJson['from_email'] == '') {
        normalizedJson['from_email'] = 'unknown@example.com';
      }
      if (normalizedJson['to_emails'] == null || (normalizedJson['to_emails'] is! List)) {
        normalizedJson['to_emails'] = [];
      }

      // Boolean değerleri normalize et
      if (normalizedJson['is_read'] is int) {
        normalizedJson['is_read'] = (normalizedJson['is_read'] as int) == 1;
      }
      if (normalizedJson['is_starred'] is int) {
        normalizedJson['is_starred'] = (normalizedJson['is_starred'] as int) == 1;
      }
      if (normalizedJson['is_archived'] is int) {
        normalizedJson['is_archived'] = (normalizedJson['is_archived'] as int) == 1;
      }
      if (normalizedJson['is_deleted'] is int) {
        normalizedJson['is_deleted'] = (normalizedJson['is_deleted'] as int) == 1;
      }
      if (normalizedJson['is_spam'] is int) {
        normalizedJson['is_spam'] = (normalizedJson['is_spam'] as int) == 1;
      }

      // Status ve importance enum'larını normalize et
      if (normalizedJson['email_status'] is int) {
        normalizedJson['email_status'] = normalizedJson['email_status'];
      } else if (normalizedJson['email_status'] is String) {
        // String ise enum'a çevir
        final statusStr = normalizedJson['email_status'] as String;
        final statusMap = {
          'draft': 0,
          'sent': 1,
          'received': 2,
          'read': 3,
          'unread': 4,
        };
        normalizedJson['email_status'] = statusMap[statusStr.toLowerCase()] ?? 2;
      } else {
        normalizedJson['email_status'] = 2; // Default: received
      }

      if (normalizedJson['email_importance'] is int) {
        normalizedJson['email_importance'] = normalizedJson['email_importance'];
      } else if (normalizedJson['email_importance'] is String) {
        final importanceStr = normalizedJson['email_importance'] as String;
        final importanceMap = {
          'normal': 0,
          'important': 1,
          'urgent': 2,
        };
        normalizedJson['email_importance'] = importanceMap[importanceStr.toLowerCase()] ?? 0;
      } else {
        normalizedJson['email_importance'] = 0; // Default: normal
      }

      // Email.fromDatabase kullan (zaten snake_case bekliyor ve null safety handle ediyor)
      return Email.fromDatabase(normalizedJson);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Failed to parse email: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
