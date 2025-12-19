import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/models/email.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email_account.dart';
import 'package:ai_asisstan/core/database/database_service.dart';
import 'package:ai_asisstan/services/gmail_oauth_service.dart';
import 'package:ai_asisstan/core/config/app_config.dart';
import 'package:ai_asisstan/services/backend_email_service.dart';
import '../datasources/email_remote_datasource.dart';

/// Email verilerini API'den veya Redis'ten çeken repository
/// Önce Redis'ten çeker, yoksa API'den çeker
class EmailRepository {
  final EmailRemoteDataSource _remoteDataSource;
  final DatabaseService _databaseService;
  final BackendEmailService _backendEmailService;

  EmailRepository({
    EmailRemoteDataSource? remoteDataSource,
    DatabaseService? databaseService,
    BackendEmailService? backendEmailService,
  })  : _remoteDataSource = remoteDataSource ?? EmailRemoteDataSource(),
        _databaseService = databaseService ?? DatabaseService.instance,
        _backendEmailService = backendEmailService ?? BackendEmailService();

  /// Email listesini Redis'ten veya API'den getir
  /// Önce Redis'ten çeker, yoksa API'den çeker
  /// API hatası durumunda boş liste döndürür (API hazır değilse)
  /// 401 hatası durumunda token yenileme dener
  Future<List<Email>> getEmails({
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
  }) async {
    try {
      // Provider bilgisini al
      EmailProvider? provider;
      if (accountId != null) {
        try {
          final db = await _databaseService.database;
          final accountMaps = await db.query(
            'email_accounts',
            where: 'id = ?',
            whereArgs: [accountId],
            limit: 1,
          );
          if (accountMaps.isNotEmpty) {
            final account = EmailAccount.fromDatabase(accountMaps.first);
            provider = account.provider;
          }
        } catch (e) {
          // Provider alınamazsa default Gmail kullanılır
          debugPrint('Provider bilgisi alınamadı: $e');
        }
      }

      // Önce Redis'ten çekmeyi dene
      try {
        final redisTasks = await _backendEmailService.getTasksFromRedis(
          provider: provider == EmailProvider.outlook ? 'outlook' : 'gmail',
        );
        
        if (redisTasks.isNotEmpty) {
          debugPrint('📦 Redis\'ten ${redisTasks.length} görev alındı, email\'lere dönüştürülüyor...');
          
          // Redis'teki verileri Email modeline dönüştür
          final emails = redisTasks.map((task) {
            final emailData = task['email'] as Map<String, dynamic>?;
            if (emailData == null) return null;
            
            try {
              return _convertRedisEmailToEmail(emailData, accountId: accountId);
            } catch (e) {
              debugPrint('⚠️ Redis email dönüştürme hatası: $e');
              return null;
            }
          }).whereType<Email>().toList();
          
          if (emails.isNotEmpty) {
            debugPrint('✅ Redis\'ten ${emails.length} email alındı');
            
            // Folder filtresi uygula
            if (folder != null && folder.isNotEmpty) {
              final filtered = emails.where((email) {
                final emailFolder = email.folder.name.toLowerCase();
                return emailFolder == folder.toLowerCase();
              }).toList();
              return filtered;
            }
            
            return emails;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Redis\'ten email çekme hatası: $e');
        // Redis hatası durumunda API'den çekmeye devam et
      }

      // Redis'ten veri yoksa veya hata varsa API'den çek
      return await _remoteDataSource.getEmails(
        accountId: accountId,
        folder: folder,
        limit: limit,
        offset: offset,
        accessToken: accessToken,
        provider: provider,
      );
    } on UnauthorizedException catch (e) {
      // 401 hatası - token expire olmuş, yenilemeyi dene
      if (accountId != null) {
        try {
          final newAccessToken = await _refreshTokenIfNeeded(accountId);
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            // Yeni token ile tekrar dene
            try {
              return await _remoteDataSource.getEmails(
                accountId: accountId,
                folder: folder,
                limit: limit,
                offset: offset,
                accessToken: newAccessToken,
              );
            } on UnauthorizedException {
              // Yeni token da geçersiz, bağlantıyı yeniden yapması gerekiyor
              throw UnauthorizedException(
                message: 'Oturum süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.',
                originalError: e.originalError,
              );
            }
          } else {
            // Token yenilenemedi - refresh token yok veya geçersiz
            throw UnauthorizedException(
              message: 'Oturum süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.\n\nAyarlar > E-posta Hesapları bölümünden Gmail hesabınızı yeniden bağlayabilirsiniz.',
              originalError: e.originalError,
            );
          }
        } on ApiException catch (refreshError) {
          // Token yenileme başarısız - daha açıklayıcı mesaj
          String errorMessage = 'Token yenilenemedi. Lütfen Gmail bağlantısını yeniden yapın.';
          
          if (refreshError.message.contains('invalid_grant') || 
              refreshError.message.contains('Refresh token geçersiz')) {
            errorMessage = 'Oturum süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.\n\nAyarlar > E-posta Hesapları bölümünden Gmail hesabınızı yeniden bağlayabilirsiniz.';
          } else if (refreshError.message.contains('Client ID') || 
                     refreshError.message.contains('Client Secret')) {
            errorMessage = 'Gmail bağlantısı yapılandırılmamış. Lütfen Client ID ve Client Secret değerlerini kontrol edin.';
          }
          
          throw UnauthorizedException(
            message: errorMessage,
            originalError: refreshError,
          );
        } catch (refreshError) {
          // Beklenmeyen token yenileme hatası
          throw UnauthorizedException(
            message: 'Oturum süresi dolmuş ve token yenilenemedi. Lütfen Gmail bağlantısını yeniden yapın.',
            originalError: refreshError,
          );
        }
      }
      // accountId yoksa, mevcut hatayı fırlat
      throw UnauthorizedException(
        message: 'Oturum süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.',
        originalError: e.originalError,
      );
    } on ApiException catch (e) {
      // API hatası durumunda (örn: api.example.com erişilemiyor)
      // Boş liste döndür ve hatayı logla
      if (e.message.contains('Failed host lookup') ||
          e.message.contains('api.example.com') ||
          e.message.contains('Network error')) {
        // API hazır değil, boş liste döndür
        return [];
      }
      // Diğer API hatalarını fırlat (Gmail API hataları dahil)
      rethrow;
    } catch (e) {
      // Beklenmeyen hatalar için boş liste döndür
      return [];
    }
  }

  /// Token yenileme yardımcı metodu
  Future<String?> _refreshTokenIfNeeded(int accountId) async {
    try {
      final db = await _databaseService.database;
      final accountMaps = await db.query(
        'email_accounts',
        where: 'id = ? AND is_active = 1',
        whereArgs: [accountId],
        limit: 1,
      );

      if (accountMaps.isEmpty) {
        throw ApiException(message: 'E-posta hesabı bulunamadı');
      }

      final account = EmailAccount.fromDatabase(accountMaps.first);

      // Refresh token yoksa hata fırlat
      if (account.refreshToken == null || account.refreshToken!.isEmpty) {
        throw ApiException(
          message: 'Refresh token bulunamadı. Lütfen Gmail bağlantısını yeniden yapın.',
        );
      }

      // Client ID ve Secret kontrolü
      if (AppConfig.googleClientId.isEmpty || AppConfig.googleClientSecret.isEmpty) {
        throw ApiException(
          message: 'Gmail OAuth yapılandırılmamış. Lütfen Client ID ve Client Secret değerlerini kontrol edin.',
        );
      }

      // Gmail OAuth service ile token yenile
      final gmailOAuth = GmailOAuthService(
        clientId: AppConfig.googleClientId,
        clientSecret: AppConfig.googleClientSecret,
      );

      final authResult = await gmailOAuth.refreshAccessToken(account.refreshToken!);

      // Yenilenen token'ı database'e kaydet
      const expiresIn = 3600; // Gmail API genellikle 1 saat verir
      final tokenExpires = DateTime.now().add(const Duration(seconds: expiresIn));

      await db.update(
        'email_accounts',
        {
          'access_token': authResult.accessToken,
          'token_expires': tokenExpires.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [accountId],
      );

      return authResult.accessToken;
    } on ApiException {
      // API hatalarını yukarı fırlat
      rethrow;
    } catch (e) {
      // Beklenmeyen hatalar
      throw ApiException(
        message: 'Token yenileme hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Tek email detayını API'den getir
  /// Access token gerekli - email account'tan alınmalı
  Future<Email> getEmailById(int emailId, {String? accessToken}) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        message: 'Access token required for Gmail API. Please reconnect your Gmail account.',
      );
    }
    return await _remoteDataSource.getEmailById(emailId, accessToken: accessToken);
  }

  /// Email gönder
  Future<Email> sendEmail({
    required int accountId,
    required List<String> toEmails,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? ccEmails,
    List<String>? bccEmails,
    EmailImportance importance = EmailImportance.normal,
    String? accessToken,
  }) async {
    // Account bilgisini al (provider ve accessToken için)
    // Her zaman account'tan güncel token'ı al (parametre olarak geçilen token eski olabilir)
    EmailProvider? provider;
    String? finalAccessToken;
    
    try {
      final db = await _databaseService.database;
      final accountMaps = await db.query(
        'email_accounts',
        where: 'id = ?',
        whereArgs: [accountId],
        limit: 1,
      );
      if (accountMaps.isNotEmpty) {
        final account = EmailAccount.fromDatabase(accountMaps.first);
        provider = account.provider;
        // Her zaman account'tan güncel token'ı al
        finalAccessToken = account.accessToken;
      }
    } catch (e) {
      debugPrint('Account bilgisi alınamadı: $e');
    }

    // AccessToken hala yoksa hata fırlat
    if (finalAccessToken == null || finalAccessToken.isEmpty) {
      throw ApiException(
        message: 'Access token bulunamadı. Lütfen Gmail bağlantısını yeniden yapın.',
      );
    }

    try {
      return await _remoteDataSource.sendEmail(
        accountId: accountId,
        toEmails: toEmails,
        subject: subject,
        plainText: plainText,
        htmlContent: htmlContent,
        ccEmails: ccEmails,
        bccEmails: bccEmails,
        importance: importance,
        accessToken: finalAccessToken,
        provider: provider,
      );
    } on UnauthorizedException catch (e) {
      // 401 Unauthorized hatası durumunda token'ı yenile ve tekrar dene
      try {
        final newAccessToken = await _refreshTokenIfNeeded(accountId);
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Yenilenen token ile tekrar dene
          try {
            return await _remoteDataSource.sendEmail(
              accountId: accountId,
              toEmails: toEmails,
              subject: subject,
              plainText: plainText,
              htmlContent: htmlContent,
              ccEmails: ccEmails,
              bccEmails: bccEmails,
              importance: importance,
              accessToken: newAccessToken,
              provider: provider,
            );
          } on UnauthorizedException {
            // Yeni token da geçersiz, bağlantıyı yeniden yapması gerekiyor
            throw UnauthorizedException(
              message: 'Oturum süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.',
              originalError: e.originalError,
            );
          }
        } else {
          // Token yenilenemedi - refresh token yok veya geçersiz
          throw UnauthorizedException(
            message: 'Oturum süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.\n\nAyarlar > E-posta Hesapları bölümünden Gmail hesabınızı yeniden bağlayabilirsiniz.',
            originalError: e.originalError,
          );
        }
      } on ApiException catch (refreshError) {
        // Token yenileme başarısız - daha açıklayıcı mesaj
        String errorMessage = 'Token yenilenemedi. Lütfen Gmail bağlantısını yeniden yapın.';
        
        if (refreshError.message.contains('invalid_grant') || 
            refreshError.message.contains('Refresh token geçersiz')) {
          errorMessage = 'Oturum süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.\n\nAyarlar > E-posta Hesapları bölümünden Gmail hesabınızı yeniden bağlayabilirsiniz.';
        }
        
        throw UnauthorizedException(
          message: errorMessage,
          originalError: refreshError,
        );
      }
    } on ApiException {
      // Diğer API hatalarını olduğu gibi fırlat
      rethrow;
    }
  }

  /// Email'i okundu olarak işaretle
  Future<Email> markAsRead(int emailId, {String? accessToken}) async {
    return await _remoteDataSource.markAsRead(emailId, accessToken: accessToken);
  }

  /// Email'i okunmamış olarak işaretle
  Future<Email> markAsUnread(int emailId, {String? accessToken}) async {
    return await _remoteDataSource.markAsUnread(emailId, accessToken: accessToken);
  }

  /// Email'i önemli olarak işaretle/kaldır
  Future<Email> toggleImportant(int emailId, bool isImportant, {String? accessToken}) async {
    return await _remoteDataSource.toggleImportant(emailId, isImportant, accessToken: accessToken);
  }

  /// Email sil
  Future<void> deleteEmail(int emailId, {String? accessToken}) async {
    await _remoteDataSource.deleteEmail(emailId, accessToken: accessToken);
  }

  /// Email ara
  Future<List<Email>> searchEmails({
    required String query,
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
  }) async {
    return await _remoteDataSource.searchEmails(
      query: query,
      accountId: accountId,
      folder: folder,
      limit: limit,
      offset: offset,
      accessToken: accessToken,
    );
  }

  /// Email taslağı kaydet
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
    // Account bilgisini al (provider ve accessToken için)
    // Her zaman account'tan güncel token'ı al (parametre olarak geçilen token eski olabilir)
    EmailProvider? provider;
    String? finalAccessToken;
    
    try {
      final db = await _databaseService.database;
      final accountMaps = await db.query(
        'email_accounts',
        where: 'id = ?',
        whereArgs: [accountId],
        limit: 1,
      );
      if (accountMaps.isNotEmpty) {
        final account = EmailAccount.fromDatabase(accountMaps.first);
        provider = account.provider;
        // Her zaman account'tan güncel token'ı al
        finalAccessToken = account.accessToken;
        
        debugPrint('saveDraft - Account ID: $accountId, Provider: $provider, AccessToken: ${finalAccessToken != null && finalAccessToken.isNotEmpty ? "VAR (${finalAccessToken.length} karakter)" : "YOK"}');
        
        // Eğer accessToken yoksa veya boşsa, token yenilemeyi dene
        if (finalAccessToken == null || finalAccessToken.isEmpty) {
          debugPrint('saveDraft - AccessToken yok, token yenileme deneniyor...');
          try {
            finalAccessToken = await _refreshTokenIfNeeded(accountId);
            debugPrint('saveDraft - Token yenileme sonucu: ${finalAccessToken != null ? "BAŞARILI" : "BAŞARISIZ"}');
          } catch (e) {
            debugPrint('saveDraft - Token yenileme hatası: $e');
          }
        }
      } else {
        debugPrint('saveDraft - Account bulunamadı: accountId=$accountId');
      }
    } catch (e) {
      debugPrint('saveDraft - Account bilgisi alınamadı: $e');
    }

    // AccessToken hala yoksa hata fırlat
    if (finalAccessToken == null || finalAccessToken.isEmpty) {
      debugPrint('saveDraft - AccessToken bulunamadı, hata fırlatılıyor');
      throw ApiException(
        message: 'Access token bulunamadı. Lütfen Gmail bağlantısını yeniden yapın.',
      );
    }

    try {
      return await _remoteDataSource.saveDraft(
        accountId: accountId,
        subject: subject,
        plainText: plainText,
        htmlContent: htmlContent,
        toEmails: toEmails,
        ccEmails: ccEmails,
        bccEmails: bccEmails,
        draftId: draftId,
        accessToken: finalAccessToken,
        provider: provider,
      );
    } on UnauthorizedException catch (e) {
      // 401 Unauthorized hatası durumunda token'ı yenile ve tekrar dene
      try {
        final newAccessToken = await _refreshTokenIfNeeded(accountId);
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Yenilenen token ile tekrar dene
          try {
            return await _remoteDataSource.saveDraft(
              accountId: accountId,
              subject: subject,
              plainText: plainText,
              htmlContent: htmlContent,
              toEmails: toEmails,
              ccEmails: ccEmails,
              bccEmails: bccEmails,
              draftId: draftId,
              accessToken: newAccessToken,
              provider: provider,
            );
          } on UnauthorizedException {
            // Yeni token da geçersiz, bağlantıyı yeniden yapması gerekiyor
            throw UnauthorizedException(
              message: 'Oturum süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.',
              originalError: e.originalError,
            );
          }
        } else {
          // Token yenilenemedi - refresh token yok veya geçersiz
          throw UnauthorizedException(
            message: 'Oturum süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.\n\nAyarlar > E-posta Hesapları bölümünden Gmail hesabınızı yeniden bağlayabilirsiniz.',
            originalError: e.originalError,
          );
        }
      } on ApiException catch (refreshError) {
        // Token yenileme başarısız - daha açıklayıcı mesaj
        String errorMessage = 'Token yenilenemedi. Lütfen Gmail bağlantısını yeniden yapın.';
        
        if (refreshError.message.contains('invalid_grant') || 
            refreshError.message.contains('Refresh token geçersiz')) {
          errorMessage = 'Oturum süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.\n\nAyarlar > E-posta Hesapları bölümünden Gmail hesabınızı yeniden bağlayabilirsiniz.';
        }
        
        throw UnauthorizedException(
          message: errorMessage,
          originalError: refreshError,
        );
      }
    } on ApiException {
      // Diğer API hatalarını olduğu gibi fırlat
      rethrow;
    }
  }

  /// Redis'teki email verisini Email modeline dönüştür
  Email? _convertRedisEmailToEmail(Map<String, dynamic> emailData, {int? accountId}) {
    try {
      // Redis'teki email verisi formatı:
      // {
      //   "id": "...",
      //   "subject": "...",
      //   "sender": "...",
      //   "recipient": "...",
      //   "preview": "...",
      //   "received_date": "2024-01-15T10:30:00Z",
      //   "is_read": false,
      //   "category": "inbox",
      //   "has_attachments": false,
      //   "is_outgoing": false,
      //   "provider": "gmail" | "outlook"
      // }

      final receivedDateStr = emailData['received_date'] as String?;
      DateTime? receivedDate;
      if (receivedDateStr != null) {
        try {
          receivedDate = DateTime.parse(receivedDateStr);
        } catch (e) {
          debugPrint('⚠️ Tarih parse hatası: $e');
          receivedDate = DateTime.now();
        }
      } else {
        receivedDate = DateTime.now();
      }

      // Category'yi EmailFolder'a dönüştür
      EmailFolder? folder;
      final category = (emailData['category'] as String? ?? '').toLowerCase();
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

      // Email modelini oluştur
      final now = DateTime.now();
      final finalAccountId = accountId ?? 0;
      final finalUserId = accountId ?? 0;
      
      return Email(
        id: int.tryParse(emailData['email_id']?.toString() ?? emailData['id']?.toString() ?? '') ?? 0,
        messageId: emailData['email_id']?.toString() ?? emailData['id']?.toString(), // Redis'ten gelen email_id kullan
        accountId: finalAccountId,
        userId: finalUserId,
        subject: emailData['subject']?.toString() ?? '(Konu yok)',
        fromEmail: emailData['from']?.toString() ?? emailData['sender']?.toString() ?? '',
        fromName: emailData['from']?.toString() ?? emailData['sender']?.toString(),
        toEmails: emailData['to'] != null 
            ? [emailData['to'].toString()] 
            : (emailData['recipient'] != null 
                ? [emailData['recipient'].toString()] 
                : []),
        plainText: emailData['plain_text']?.toString() ?? emailData['body']?.toString() ?? emailData['preview']?.toString() ?? '',
        htmlContent: emailData['html_content']?.toString(),
        receivedDate: receivedDate,
        isRead: emailData['is_read'] == true,
        folder: folder,
        isSpam: category == 'spam' || category == 'junk',
        importance: EmailImportance.normal,
        attachments: emailData['has_attachments'] == true ? [] : null,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      debugPrint('❌ Redis email dönüştürme hatası: $e');
      return null;
    }
  }
}
