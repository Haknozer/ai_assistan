import 'package:ai_asisstan/models/email.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email_account.dart';
import 'package:ai_asisstan/core/database/database_service.dart';
import 'package:ai_asisstan/services/gmail_oauth_service.dart';
import 'package:ai_asisstan/core/config/app_config.dart';
import '../datasources/email_remote_datasource.dart';

/// Email verilerini API'den çeken repository
/// Cache kullanmaz, her zaman API'den çeker
class EmailRepository {
  final EmailRemoteDataSource _remoteDataSource;
  final DatabaseService _databaseService;

  EmailRepository({
    EmailRemoteDataSource? remoteDataSource,
    DatabaseService? databaseService,
  })  : _remoteDataSource = remoteDataSource ?? EmailRemoteDataSource(),
        _databaseService = databaseService ?? DatabaseService.instance;

  /// Email listesini API'den getir
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
      return await _remoteDataSource.getEmails(
        accountId: accountId,
        folder: folder,
        limit: limit,
        offset: offset,
        accessToken: accessToken,
      );
    } on UnauthorizedException {
      // 401 hatası - token expire olmuş, yenilemeyi dene
      if (accountId != null && accessToken != null) {
        try {
          final newAccessToken = await _refreshTokenIfNeeded(accountId);
          if (newAccessToken != null) {
            // Yeni token ile tekrar dene
            return await _remoteDataSource.getEmails(
              accountId: accountId,
              folder: folder,
              limit: limit,
              offset: offset,
              accessToken: newAccessToken,
            );
          }
        } catch (refreshError) {
          // Token yenileme başarısız, hatayı fırlat
          throw ApiException(
            message: 'Token yenilenemedi. Lütfen Gmail bağlantısını yeniden yapın.',
            originalError: refreshError,
          );
        }
      }
      rethrow;
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
        return null;
      }

      final account = EmailAccount.fromDatabase(accountMaps.first);

      // Refresh token yoksa null döndür
      if (account.refreshToken == null || account.refreshToken!.isEmpty) {
        return null;
      }

      // Gmail OAuth service ile token yenile
      final gmailOAuth = GmailOAuthService(
        clientId: AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
        clientSecret: AppConfig.googleClientSecret.isNotEmpty ? AppConfig.googleClientSecret : null,
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
    } catch (e) {
      // Token yenileme hatası
      return null;
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
    return await _remoteDataSource.sendEmail(
      accountId: accountId,
      toEmails: toEmails,
      subject: subject,
      plainText: plainText,
      htmlContent: htmlContent,
      ccEmails: ccEmails,
      bccEmails: bccEmails,
      importance: importance,
      accessToken: accessToken,
    );
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
    return await _remoteDataSource.saveDraft(
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
