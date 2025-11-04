import '../config/app_config.dart';

/// API endpoint'lerini tanımlayan sınıf
class ApiEndpoints {
  // Base URL - Config'den alınır
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Email endpoints
  static const String emails = '/api/v1/emails';
  static String emailById(int id) => '$emails/$id';
  static const String sendEmail = '$emails/send';
  static String markAsRead(int id) => '$emails/$id/read';
  static String markAsUnread(int id) => '$emails/$id/unread';
  static String deleteEmail(int id) => '$emails/$id';
  static String emailAttachments(int emailId) => '$emails/$emailId/attachments';
  static String downloadAttachment(int emailId, int attachmentId) => '$emails/$emailId/attachments/$attachmentId';

  // Email Account endpoints
  static const String emailAccounts = '/api/v1/email-accounts';
  static String emailAccountById(int id) => '$emailAccounts/$id';
  static const String connectEmailAccount = '$emailAccounts/connect';
  static String syncEmailAccount(int id) => '$emailAccounts/$id/sync';
  static String refreshToken(int id) => '$emailAccounts/$id/refresh-token';
  static String disconnectEmailAccount(int id) => '$emailAccounts/$id/disconnect';

  // Email Folders endpoints
  static String emailFolders(int accountId) => '$emailAccounts/$accountId/folders';
  static String emailsByFolder(int accountId, String folder) => '$emailAccounts/$accountId/folders/$folder/emails';

  // Search endpoints
  static const String searchEmails = '$emails/search';

  // Full URL helper method
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
