import 'dart:convert';
import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_endpoints.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email.dart';

/// Email remote data source - Gmail API çağrılarını yönetir
class EmailRemoteDataSource {
  final ApiClient _apiClient;

  EmailRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Email listesini Gmail API'den çekme
  Future<List<Email>> getEmails({
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
    int? userId, // Email account'tan alınacak
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      // Gmail API query parametreleri
      final queryParams = <String, dynamic>{
        'maxResults': limit ?? 50,
      };

      // Folder'a göre query oluştur
      String query = '';
      if (folder != null) {
        switch (folder.toLowerCase()) {
          case 'inbox':
            query = 'in:inbox';
            break;
          case 'sent':
            query = 'in:sent';
            break;
          case 'drafts':
            query = 'in:drafts';
            break;
          case 'spam':
            query = 'in:spam';
            break;
          case 'trash':
            query = 'in:trash';
            break;
          default:
            query = 'in:inbox';
        }
      } else {
        query = 'in:inbox';
      }

      queryParams['q'] = query;

      // Gmail API'den message listesini çek
      final response = await _apiClient.get(
        ApiEndpoints.messages,
        queryParameters: queryParams,
        accessToken: accessToken,
      );

      // Gmail API response formatı: { "messages": [{ "id": "...", "threadId": "..." }], "nextPageToken": "..." }
      final messagesList = response['messages'] as List<dynamic>? ?? [];

      if (messagesList.isEmpty) {
        return [];
      }

      // Her message için detaylı bilgi çek (batch olarak)
      final emails = <Email>[];
      for (final messageItem in messagesList.take(limit ?? 50)) {
        try {
          final messageId = messageItem['id'] as String;
          final email = await _getEmailDetails(
            messageId, 
            accessToken: accessToken,
            userId: userId,
            accountId: accountId,
          );
          if (email != null) {
            emails.add(email);
          }
        } catch (e) {
          // Tek bir email hatası tüm listeyi bozmasın
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

  /// Gmail API'den tek email detayını çekme
  Future<Email?> _getEmailDetails(
    String messageId, {
    required String accessToken,
    int? userId,
    int? accountId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.messageById(messageId),
        queryParameters: {'format': 'full'},
        accessToken: accessToken,
      );

      return _parseGmailMessage(response, messageId, userId: userId, accountId: accountId);
    } catch (e) {
      return null;
    }
  }

  /// Gmail API message formatını Email modeline çevir
  Email _parseGmailMessage(
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
    final receivedDate = internalDate != null 
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(internalDate)) 
        : DateTime.now();

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
      id: null, // Gmail API'den gelen email'lerin kendi ID'leri yok, messageId kullanılabilir
      userId: userId ?? 0, // Account'dan alınacak
      accountId: accountId ?? 0, // Account'dan alınacak
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
      importance: EmailImportance.normal, // Gmail API'de importance yok, normal olarak işaretle
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
  String _extractEmail(String headerValue) {
    final match = RegExp(r'<(.+?)>').firstMatch(headerValue);
    if (match != null) {
      return match.group(1) ?? headerValue.trim();
    }
    return headerValue.trim();
  }

  /// İsmi header'dan çıkar
  String _extractName(String headerValue) {
    final match = RegExp(r'^(.+?)\s*<').firstMatch(headerValue);
    if (match != null) {
      return match.group(1)?.replaceAll('"', '').trim() ?? '';
    }
    return '';
  }

  /// Email listesini header'dan çıkar
  List<String> _extractEmails(String headerValue) {
    final emails = <String>[];
    final parts = headerValue.split(',');
    for (final part in parts) {
      emails.add(_extractEmail(part.trim()));
    }
    return emails;
  }

  /// Body'yi payload'dan çıkar
  Map<String, String?> _extractBody(Map<String, dynamic> payload) {
    String? plainText;
    String? htmlContent;

    final body = payload['body'] as Map<String, dynamic>?;
    if (body != null) {
      final data = body['data'] as String?;
      if (data != null) {
        try {
          final decoded = base64Url.decode(data);
          final content = utf8.decode(decoded);
          plainText = content;
        } catch (e) {
          // Decode hatası, geç
        }
      }
    }

    final parts = payload['parts'] as List<dynamic>?;
    if (parts != null) {
      for (final part in parts) {
        final mimeType = part['mimeType'] as String? ?? '';
        final bodyData = part['body'] as Map<String, dynamic>?;
        final data = bodyData?['data'] as String?;

        if (data != null) {
          try {
            final decoded = base64Url.decode(data);
            final content = utf8.decode(decoded);

            if (mimeType == 'text/plain' && plainText == null) {
              plainText = content;
            } else if (mimeType == 'text/html' && htmlContent == null) {
              htmlContent = content;
            }
          } catch (e) {
            // Decode hatası, geç
          }
        }

        // Nested parts kontrolü
        final nestedParts = part['parts'] as List<dynamic>?;
        if (nestedParts != null) {
          final nestedResult = _extractBody({'parts': nestedParts});
          if (plainText == null) plainText = nestedResult['plainText'];
          if (htmlContent == null) htmlContent = nestedResult['htmlContent'];
        }
      }
    }

    return {'plainText': plainText, 'htmlContent': htmlContent};
  }

  /// Label'lardan folder belirle
  EmailFolder _determineFolder(List<dynamic> labelIds) {
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

  /// Tek email detayını çekme (Gmail API'den)
  Future<Email> getEmailById(int emailId, {String? accessToken}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }
    
    // Gmail API messageId string kullanır, bu yüzden emailId'yi messageId olarak kullan
    final email = await _getEmailDetails(emailId.toString(), accessToken: accessToken);
    if (email == null) {
      throw NotFoundException(message: 'Email not found');
    }
    return email;
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
    String? accessToken,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      // Gmail API için email formatını oluştur
      final emailBody = _createEmailBody(
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

      // Gmail API response: { "id": "...", "threadId": "...", "labelIds": [...] }
      final messageId = response['id'] as String?;
      if (messageId == null) {
        throw ApiException(message: 'Failed to send email: No message ID returned');
      }

      // Gönderilen email'i tekrar çek
      final sentEmail = await _getEmailDetails(messageId, accessToken: accessToken);
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

  /// Gmail API için email body oluştur (RFC 2822 format)
  String _createEmailBody({
    required List<String> toEmails,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? ccEmails,
    List<String>? bccEmails,
  }) {
    final buffer = StringBuffer();
    
    // Headers
    buffer.writeln('To: ${toEmails.join(', ')}');
    if (ccEmails != null && ccEmails.isNotEmpty) {
      buffer.writeln('Cc: ${ccEmails.join(', ')}');
    }
    if (bccEmails != null && bccEmails.isNotEmpty) {
      buffer.writeln('Bcc: ${bccEmails.join(', ')}');
    }
    buffer.writeln('Subject: $subject');
    buffer.writeln('MIME-Version: 1.0');
    
    // Body
    if (htmlContent != null && plainText != null) {
      // Multipart/alternative
      final boundary = 'boundary_${DateTime.now().millisecondsSinceEpoch}';
      buffer.writeln('Content-Type: multipart/alternative; boundary="$boundary"');
      buffer.writeln();
      buffer.writeln('--$boundary');
      buffer.writeln('Content-Type: text/plain; charset=UTF-8');
      buffer.writeln();
      buffer.writeln(plainText);
      buffer.writeln('--$boundary');
      buffer.writeln('Content-Type: text/html; charset=UTF-8');
      buffer.writeln();
      buffer.writeln(htmlContent);
      buffer.writeln('--$boundary--');
    } else if (htmlContent != null) {
      buffer.writeln('Content-Type: text/html; charset=UTF-8');
      buffer.writeln();
      buffer.writeln(htmlContent);
    } else {
      buffer.writeln('Content-Type: text/plain; charset=UTF-8');
      buffer.writeln();
      buffer.writeln(plainText ?? '');
    }

    // Base64 encode et
    final emailString = buffer.toString();
    final bytes = utf8.encode(emailString);
    return base64Url.encode(bytes);
  }

  /// Email'i okundu olarak işaretleme (Gmail API)
  Future<Email> markAsRead(int emailId, {String? accessToken}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      await _apiClient.post(
        ApiEndpoints.modifyMessage(emailId.toString()),
        body: {
          'removeLabelIds': ['UNREAD'],
        },
        accessToken: accessToken,
      );

      // Güncellenmiş email'i tekrar çek
      final updatedEmail = await _getEmailDetails(emailId.toString(), accessToken: accessToken);
      if (updatedEmail == null) {
        throw NotFoundException(message: 'Email not found');
      }
      return updatedEmail;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Failed to mark email as read: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email'i okunmamış olarak işaretleme (Gmail API)
  Future<Email> markAsUnread(int emailId, {String? accessToken}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      await _apiClient.post(
        ApiEndpoints.modifyMessage(emailId.toString()),
        body: {
          'addLabelIds': ['UNREAD'],
        },
        accessToken: accessToken,
      );

      // Güncellenmiş email'i tekrar çek
      final updatedEmail = await _getEmailDetails(emailId.toString(), accessToken: accessToken);
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
  Future<Email> toggleImportant(int emailId, bool isImportant, {String? accessToken}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      if (isImportant) {
        await _apiClient.post(
          ApiEndpoints.modifyMessage(emailId.toString()),
          body: {
            'addLabelIds': ['IMPORTANT'],
          },
          accessToken: accessToken,
        );
      } else {
        await _apiClient.post(
          ApiEndpoints.modifyMessage(emailId.toString()),
          body: {
            'removeLabelIds': ['IMPORTANT'],
          },
          accessToken: accessToken,
        );
      }

      // Güncellenmiş email'i tekrar çek
      final updatedEmail = await _getEmailDetails(emailId.toString(), accessToken: accessToken);
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
  Future<void> deleteEmail(int emailId, {String? accessToken}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      await _apiClient.post(
        ApiEndpoints.modifyMessage(emailId.toString()),
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
    String? accessToken,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
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
          final email = await _getEmailDetails(messageId, accessToken: accessToken);
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
    String? accessToken,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    try {
      // Gmail API için draft body oluştur
      final emailBody = _createEmailBody(
        toEmails: toEmails ?? [],
        subject: subject,
        plainText: plainText,
        htmlContent: htmlContent,
        ccEmails: ccEmails,
        bccEmails: bccEmails,
      );

      final body = {'message': {'raw': emailBody}};

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

      final savedDraft = await _getEmailDetails(messageId, accessToken: accessToken);
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