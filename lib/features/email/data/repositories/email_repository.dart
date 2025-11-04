import 'package:ai_asisstan/models/email.dart';
import '../datasources/email_remote_datasource.dart';

/// Email verilerini API'den çeken repository
/// Cache kullanmaz, her zaman API'den çeker
class EmailRepository {
  final EmailRemoteDataSource _remoteDataSource;

  EmailRepository({
    EmailRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? EmailRemoteDataSource();

  /// Email listesini API'den getir
  Future<List<Email>> getEmails({
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
  }) async {
    return await _remoteDataSource.getEmails(
      accountId: accountId,
      folder: folder,
      limit: limit,
      offset: offset,
      accessToken: accessToken,
    );
  }

  /// Tek email detayını API'den getir
  Future<Email> getEmailById(int emailId, {String? accessToken}) async {
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
