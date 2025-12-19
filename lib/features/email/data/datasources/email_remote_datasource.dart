import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email.dart';
import 'package:ai_asisstan/models/email_account.dart';
import 'package:ai_asisstan/services/backend_email_service.dart';

/// Email remote data source - Backend API çağrılarını yönetir
/// Artık direkt Gmail/Outlook API'lerine çağrı yapmıyor, sadece backend'e istek atıyor
class EmailRemoteDataSource {
  final BackendEmailService _backendEmailService;

  EmailRemoteDataSource({
    BackendEmailService? backendEmailService,
  }) : _backendEmailService = backendEmailService ?? BackendEmailService();

  /// Email listesini backend'den çekme (Gmail veya Outlook)
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
    // folder null ise category de null olmalı (tüm kategorilerden çek)
    // folder null değilse belirtilen kategoriyi kullan
    final category = folder; // null = tüm kategorilerden çek
    final emailLimit = limit ?? 50;

    try {
      BackendEmailResponse response;
      
      if (emailProvider == EmailProvider.outlook) {
        response = await _backendEmailService.fetchOutlookEmails(
          accessToken: accessToken,
          category: category,
          limit: emailLimit,
        );
      } else {
        response = await _backendEmailService.fetchGmailEmails(
          accessToken: accessToken,
          category: category,
          limit: emailLimit,
        );
      }

      // BackendEmailResponse'u Email listesine dönüştür
      final emails = <Email>[];
      
      for (final backendEmail in response.emails) {
        try {
          final email = _convertBackendEmailToEmail(
            backendEmail,
            accountId: accountId ?? 0,
            userId: userId ?? 0,
            provider: emailProvider,
          );
          emails.add(email);
        } catch (e) {
          debugPrint('⚠️ Backend email dönüştürme hatası: $e');
          continue;
        }
      }

      return emails;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Backend\'den email çekme hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// BackendEmail'i Email modeline dönüştür
  Email _convertBackendEmailToEmail(
    BackendEmail backendEmail, {
    required int accountId,
    required int userId,
    required EmailProvider provider,
  }) {
    // Category'yi EmailFolder'a dönüştür
    EmailFolder folder;
    final category = backendEmail.category.toLowerCase();
    switch (category) {
      case 'inbox':
        folder = EmailFolder.inbox;
        break;
      case 'sent':
        folder = EmailFolder.sent;
        break;
      case 'spam':
      case 'junk':
        folder = EmailFolder.spam;
        break;
      case 'drafts':
        folder = EmailFolder.drafts;
        break;
      default:
        folder = EmailFolder.inbox;
    }

    final now = DateTime.now();
    
    return Email(
      id: int.tryParse(backendEmail.id) ?? 0,
      messageId: backendEmail.id,
      accountId: accountId,
      userId: userId,
      subject: backendEmail.subject,
      fromEmail: backendEmail.sender,
      fromName: null,
      toEmails: backendEmail.recipient != null 
          ? [backendEmail.recipient!] 
          : [],
      plainText: backendEmail.plainText ?? (backendEmail.htmlContent != null ? null : backendEmail.preview),
      htmlContent: backendEmail.htmlContent,
      receivedDate: backendEmail.receivedDate,
      isRead: backendEmail.isRead,
      folder: folder,
      isSpam: category == 'spam' || category == 'junk',
      importance: EmailImportance.normal,
      attachments: backendEmail.hasAttachments ? [] : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Tek email detayını çekme (Backend'den)
  /// Not: Backend şu anda sadece email listesi döndürüyor, tek email detayı için
  /// email listesinden filtreleme yapıyoruz. Backend'de detay endpoint'i eklendiğinde
  /// bu metod güncellenebilir.
  Future<Email> getEmailById(int emailId, {String? accessToken, EmailProvider? provider}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    // Şimdilik email listesinden buluyoruz
    // Backend'de detay endpoint'i eklendiğinde bu kısım güncellenecek
    final emails = await getEmails(
      accessToken: accessToken,
      provider: provider,
      limit: 100, // Daha fazla email çekerek bulma şansını artırıyoruz
    );

    final email = emails.firstWhere(
      (e) => e.id == emailId || e.messageId == emailId.toString(),
      orElse: () => throw NotFoundException(message: 'Email not found'),
    );

    return email;
  }

  /// Email gönderme (Backend üzerinden)
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
      throw ApiException(message: 'Access token required');
    }

    final emailProvider = provider ?? EmailProvider.gmail;

    try {
      BackendEmail backendEmail;
      
      if (emailProvider == EmailProvider.outlook) {
        backendEmail = await _backendEmailService.sendOutlookEmail(
          accessToken: accessToken,
          toEmails: toEmails,
          subject: subject,
          plainText: plainText,
          htmlContent: htmlContent,
          ccEmails: ccEmails,
          bccEmails: bccEmails,
        );
      } else {
        backendEmail = await _backendEmailService.sendGmailEmail(
          accessToken: accessToken,
          toEmails: toEmails,
          subject: subject,
          plainText: plainText,
          htmlContent: htmlContent,
          ccEmails: ccEmails,
          bccEmails: bccEmails,
        );
      }

      return _convertBackendEmailToEmail(
        backendEmail,
        accountId: accountId,
        userId: accountId,
        provider: emailProvider,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Email gönderme hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email'i okundu olarak işaretleme (Backend üzerinden)
  Future<Email> markAsRead(int emailId, {String? accessToken, EmailProvider? provider}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    final emailProvider = provider ?? EmailProvider.gmail;
    final messageId = emailId.toString();

    try {
      BackendEmail backendEmail;
      
      if (emailProvider == EmailProvider.outlook) {
        backendEmail = await _backendEmailService.markOutlookAsRead(
          accessToken: accessToken,
          messageId: messageId,
        );
      } else {
        backendEmail = await _backendEmailService.markGmailAsRead(
          accessToken: accessToken,
          messageId: messageId,
        );
      }

      return _convertBackendEmailToEmail(
        backendEmail,
        accountId: 0,
        userId: 0,
        provider: emailProvider,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Email okundu işaretleme hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email'i okunmamış olarak işaretleme (Backend üzerinden)
  Future<Email> markAsUnread(int emailId, {String? accessToken, EmailProvider? provider}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    final emailProvider = provider ?? EmailProvider.gmail;
    final messageId = emailId.toString();

    try {
      BackendEmail backendEmail;
      
      if (emailProvider == EmailProvider.outlook) {
        backendEmail = await _backendEmailService.markOutlookAsUnread(
          accessToken: accessToken,
          messageId: messageId,
        );
      } else {
        backendEmail = await _backendEmailService.markGmailAsUnread(
          accessToken: accessToken,
          messageId: messageId,
        );
      }

      return _convertBackendEmailToEmail(
        backendEmail,
        accountId: 0,
        userId: 0,
        provider: emailProvider,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Email okunmamış işaretleme hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email'i önemli olarak işaretleme/kaldırma (Backend üzerinden)
  Future<Email> toggleImportant(int emailId, bool isImportant, {String? accessToken, EmailProvider? provider}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    final emailProvider = provider ?? EmailProvider.gmail;
    final messageId = emailId.toString();

    try {
      BackendEmail backendEmail;
      
      if (emailProvider == EmailProvider.outlook) {
        backendEmail = await _backendEmailService.toggleOutlookImportant(
          accessToken: accessToken,
          messageId: messageId,
          isImportant: isImportant,
        );
      } else {
        backendEmail = await _backendEmailService.toggleGmailImportant(
          accessToken: accessToken,
          messageId: messageId,
          isImportant: isImportant,
        );
      }

      return _convertBackendEmailToEmail(
        backendEmail,
        accountId: 0,
        userId: 0,
        provider: emailProvider,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Email önemli işaretleme hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email silme (Backend üzerinden)
  Future<void> deleteEmail(int emailId, {String? accessToken, EmailProvider? provider}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    final emailProvider = provider ?? EmailProvider.gmail;
    final messageId = emailId.toString();

    try {
      if (emailProvider == EmailProvider.outlook) {
        await _backendEmailService.deleteOutlookEmail(
          accessToken: accessToken,
          messageId: messageId,
        );
      } else {
        await _backendEmailService.deleteGmailEmail(
          accessToken: accessToken,
          messageId: messageId,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Email silme hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email arama (Backend üzerinden)
  /// Not: Backend'de arama özelliği henüz yok, şimdilik tüm email'leri çekip
  /// client tarafında filtreliyoruz. Backend'de arama endpoint'i eklendiğinde güncellenecek.
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
      throw ApiException(message: 'Access token required');
    }

    // Şimdilik tüm email'leri çekip client tarafında filtreliyoruz
    final allEmails = await getEmails(
      accountId: accountId,
      folder: folder,
      limit: limit ?? 100,
      accessToken: accessToken,
      provider: provider,
    );

    // Basit bir arama filtresi (subject ve sender'da arama yapar)
    final queryLower = query.toLowerCase();
    final filtered = allEmails.where((email) {
      return email.subject.toLowerCase().contains(queryLower) ||
          email.fromEmail.toLowerCase().contains(queryLower) ||
          (email.plainText?.toLowerCase().contains(queryLower) ?? false);
    }).toList();

    return filtered;
  }

  /// Email taslağı kaydetme (Backend üzerinden)
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
      throw ApiException(message: 'Access token required');
    }

    final emailProvider = provider ?? EmailProvider.gmail;

    try {
      BackendEmail backendEmail;
      
      if (emailProvider == EmailProvider.outlook) {
        backendEmail = await _backendEmailService.saveOutlookDraft(
          accessToken: accessToken,
          subject: subject,
          plainText: plainText,
          htmlContent: htmlContent,
          toEmails: toEmails,
          ccEmails: ccEmails,
          bccEmails: bccEmails,
          draftId: draftId?.toString(),
        );
      } else {
        backendEmail = await _backendEmailService.saveGmailDraft(
          accessToken: accessToken,
          subject: subject,
          plainText: plainText,
          htmlContent: htmlContent,
          toEmails: toEmails,
          ccEmails: ccEmails,
          bccEmails: bccEmails,
          draftId: draftId?.toString(),
        );
      }

      return _convertBackendEmailToEmail(
        backendEmail,
        accountId: accountId,
        userId: accountId,
        provider: emailProvider,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Email taslağı kaydetme hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
