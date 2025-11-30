import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email.dart';
import 'package:ai_asisstan/models/email_account.dart';
import 'gmail/gmail_api_client.dart';
import 'outlook/outlook_api_client.dart';

/// Email remote data source - Gmail ve Outlook API çağrılarını yönetir
class EmailRemoteDataSource {
  final GmailApiClient _gmailClient;
  final OutlookApiClient _outlookClient;

  EmailRemoteDataSource({
    ApiClient? apiClient,
    GmailApiClient? gmailClient,
    OutlookApiClient? outlookClient,
  })  : _gmailClient = gmailClient ?? GmailApiClient(apiClient: apiClient),
        _outlookClient = outlookClient ?? OutlookApiClient(apiClient: apiClient);

  /// Email listesini API'den çekme (Gmail veya Outlook)
  Future<List<Email>> getEmails({
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
    int? userId,
    EmailProvider? provider,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    final emailProvider = provider ?? EmailProvider.gmail;

    if (emailProvider == EmailProvider.outlook) {
      return await _outlookClient.getEmails(
        accountId: accountId,
        folder: folder,
        limit: limit,
        offset: offset,
        accessToken: accessToken,
        userId: userId,
      );
    } else {
      return await _gmailClient.getEmails(
        accountId: accountId,
        folder: folder,
        limit: limit,
        offset: offset,
        accessToken: accessToken,
        userId: userId,
      );
    }
  }

  /// Tek email detayını çekme (Gmail API'den)
  Future<Email> getEmailById(int emailId, {String? accessToken, EmailProvider? provider}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    final emailProvider = provider ?? EmailProvider.gmail;
    final messageId = emailId.toString();

    if (emailProvider == EmailProvider.outlook) {
      final email = await _outlookClient.getEmailDetails(
        messageId: messageId,
        accessToken: accessToken,
      );
      if (email == null) {
        throw NotFoundException(message: 'Email not found');
      }
      return email;
    } else {
      final email = await _gmailClient.getEmailDetails(
        messageId: messageId,
        accessToken: accessToken,
      );
      if (email == null) {
        throw NotFoundException(message: 'Email not found');
      }
      return email;
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
    String? accessToken,
    EmailProvider? provider,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    final emailProvider = provider ?? EmailProvider.gmail;

    if (emailProvider == EmailProvider.outlook) {
      // Outlook send email henüz implement edilmedi
      throw ApiException(message: 'Outlook send email not implemented yet');
    }

    return await _gmailClient.sendEmail(
      accountId: accountId,
      toEmails: toEmails,
      subject: subject,
      plainText: plainText,
      htmlContent: htmlContent,
      ccEmails: ccEmails,
      bccEmails: bccEmails,
      attachments: attachments,
      importance: importance,
      accessToken: accessToken,
    );
  }

  /// Email'i okundu olarak işaretleme (Gmail API)
  Future<Email> markAsRead(int emailId, {String? accessToken, EmailProvider? provider}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    final emailProvider = provider ?? EmailProvider.gmail;
    final messageId = emailId.toString();

    if (emailProvider == EmailProvider.outlook) {
      // Outlook mark as read henüz implement edilmedi
      throw ApiException(message: 'Outlook mark as read not implemented yet');
    }

    return await _gmailClient.markAsRead(
      messageId: messageId,
      accessToken: accessToken,
    );
  }

  /// Email'i okunmamış olarak işaretleme (Gmail API)
  Future<Email> markAsUnread(int emailId, {String? accessToken, EmailProvider? provider}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    final emailProvider = provider ?? EmailProvider.gmail;
    final messageId = emailId.toString();

    if (emailProvider == EmailProvider.outlook) {
      // Outlook mark as unread henüz implement edilmedi
      throw ApiException(message: 'Outlook mark as unread not implemented yet');
    }

    return await _gmailClient.markAsUnread(
      messageId: messageId,
      accessToken: accessToken,
    );
  }

  /// Email'i önemli olarak işaretleme/kaldırma (Gmail API)
  Future<Email> toggleImportant(int emailId, bool isImportant, {String? accessToken, EmailProvider? provider}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    final emailProvider = provider ?? EmailProvider.gmail;
    final messageId = emailId.toString();

    if (emailProvider == EmailProvider.outlook) {
      // Outlook toggle important henüz implement edilmedi
      throw ApiException(message: 'Outlook toggle important not implemented yet');
    }

    return await _gmailClient.toggleImportant(
      messageId: messageId,
      isImportant: isImportant,
      accessToken: accessToken,
    );
  }

  /// Email silme (Gmail API)
  Future<void> deleteEmail(int emailId, {String? accessToken, EmailProvider? provider}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    final emailProvider = provider ?? EmailProvider.gmail;
    final messageId = emailId.toString();

    if (emailProvider == EmailProvider.outlook) {
      // Outlook delete email henüz implement edilmedi
      throw ApiException(message: 'Outlook delete email not implemented yet');
    }

    return await _gmailClient.deleteEmail(
      messageId: messageId,
      accessToken: accessToken,
    );
  }

  /// Email arama (Gmail API)
  Future<List<Email>> searchEmails({
    required String query,
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
    EmailProvider? provider,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    final emailProvider = provider ?? EmailProvider.gmail;

    if (emailProvider == EmailProvider.outlook) {
      // Outlook search emails henüz implement edilmedi
      throw ApiException(message: 'Outlook search emails not implemented yet');
    }

    return await _gmailClient.searchEmails(
      query: query,
      accountId: accountId,
      folder: folder,
      limit: limit,
      offset: offset,
      accessToken: accessToken,
    );
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
    EmailProvider? provider,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required for Gmail API');
    }

    final emailProvider = provider ?? EmailProvider.gmail;

    if (emailProvider == EmailProvider.outlook) {
      // Outlook save draft henüz implement edilmedi
      throw ApiException(message: 'Outlook save draft not implemented yet');
    }

    return await _gmailClient.saveDraft(
      accountId: accountId,
      subject: subject,
      plainText: plainText,
      htmlContent: htmlContent,
      toEmails: toEmails,
      ccEmails: ccEmails,
      bccEmails: bccEmails,
      draftId: draftId,
      accessToken: accessToken,
    );
  }
}
