import '../config/app_config.dart';

/// API endpoint'lerini tanımlayan sınıf
class ApiEndpoints {
  // Base URL - Gmail API için
  static const String gmailApiBaseUrl = 'https://gmail.googleapis.com/gmail/v1';

  // Gmail API endpoints - Doğrudan Gmail API kullanıyoruz
  static String get messages => '$gmailApiBaseUrl/users/me/messages';
  static String messageById(String messageId) => '$gmailApiBaseUrl/users/me/messages/$messageId';
  static String get sendMessage => '$gmailApiBaseUrl/users/me/messages/send';
  static String modifyMessage(String messageId) => '$gmailApiBaseUrl/users/me/messages/$messageId/modify';
  static String get batchModify => '$gmailApiBaseUrl/users/me/messages/batchModify';
  static String get trashMessage => '$gmailApiBaseUrl/users/me/messages/{messageId}/trash';
  static String get untrashMessage => '$gmailApiBaseUrl/users/me/messages/{messageId}/untrash';

  // Labels (folders için)
  static String get labels => '$gmailApiBaseUrl/users/me/labels';
  static String labelById(String labelId) => '$gmailApiBaseUrl/users/me/labels/$labelId';

  // Base URL - Google Calendar API için
  static const String calendarApiBaseUrl = 'https://www.googleapis.com/calendar/v3';

  // Google Calendar API endpoints
  static String get calendars => '$calendarApiBaseUrl/users/me/calendarList';
  static String calendarById(String calendarId) => '$calendarApiBaseUrl/calendars/$calendarId';
  static String get events => '$calendarApiBaseUrl/calendars/primary/events';
  static String eventsByCalendar(String calendarId) => '$calendarApiBaseUrl/calendars/$calendarId/events';
  static String eventById(String calendarId, String eventId) =>
      '$calendarApiBaseUrl/calendars/$calendarId/events/$eventId';
  static String createEvent(String calendarId) => '$calendarApiBaseUrl/calendars/$calendarId/events';
  static String updateEvent(String calendarId, String eventId) =>
      '$calendarApiBaseUrl/calendars/$calendarId/events/$eventId';
  static String deleteEvent(String calendarId, String eventId) =>
      '$calendarApiBaseUrl/calendars/$calendarId/events/$eventId';

  // Base URL - Microsoft Graph API için
  static const String graphApiBaseUrl = 'https://graph.microsoft.com/v1.0';

  // Microsoft Graph API endpoints - Outlook için
  static String get graphMessages => '$graphApiBaseUrl/me/messages';
  static String graphMessageById(String messageId) => '$graphApiBaseUrl/me/messages/$messageId';
  static String get graphSendMessage => '$graphApiBaseUrl/me/sendMail';
  static String graphMessageUpdate(String messageId) => '$graphApiBaseUrl/me/messages/$messageId';
  static String get graphMailFolders => '$graphApiBaseUrl/me/mailFolders';
  static String graphMailFolderById(String folderId) => '$graphApiBaseUrl/me/mailFolders/$folderId';
  static String graphMailFolderMessages(String folderId) => '$graphApiBaseUrl/me/mailFolders/$folderId/messages';

  // Microsoft Graph API endpoints - Outlook Calendar için
  static String get graphCalendars => '$graphApiBaseUrl/me/calendars';
  static String graphCalendarById(String calendarId) => '$graphApiBaseUrl/me/calendars/$calendarId';
  // Primary calendar için özel endpoint (calendar ID gerektirmez)
  static String get graphPrimaryCalendarEvents => '$graphApiBaseUrl/me/calendar/events';
  static String get graphPrimaryCalendarEventById => '$graphApiBaseUrl/me/calendar/events'; // eventId ile kullanılacak
  static String get graphPrimaryCalendarCreateEvent => '$graphApiBaseUrl/me/calendar/events';
  // Belirli bir calendar için endpoint'ler
  static String graphCalendarEvents(String calendarId) => '$graphApiBaseUrl/me/calendars/$calendarId/events';
  static String graphCalendarEventById(String calendarId, String eventId) => '$graphApiBaseUrl/me/calendars/$calendarId/events/$eventId';
  static String graphCalendarCreateEvent(String calendarId) => '$graphApiBaseUrl/me/calendars/$calendarId/events';
  static String graphCalendarUpdateEvent(String calendarId, String eventId) => '$graphApiBaseUrl/me/calendars/$calendarId/events/$eventId';
  static String graphCalendarDeleteEvent(String calendarId, String eventId) => '$graphApiBaseUrl/me/calendars/$calendarId/events/$eventId';

  // Legacy endpoints (eski backend API için - şimdilik kullanılmıyor)
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const String emails = '/api/v1/emails';
  static String emailById(int id) => '$emails/$id';
  static const String sendEmail = '$emails/send';
  static String markAsRead(int id) => '$emails/$id/read';
  static String markAsUnread(int id) => '$emails/$id/unread';
  static String deleteEmail(int id) => '$emails/$id';
  static String emailAttachments(int emailId) => '$emails/$emailId/attachments';
  static String downloadAttachment(int emailId, int attachmentId) => '$emails/$emailId/attachments/$attachmentId';
  static const String emailAccounts = '/api/v1/email-accounts';
  static String emailAccountById(int id) => '$emailAccounts/$id';
  static const String connectEmailAccount = '$emailAccounts/connect';
  static String syncEmailAccount(int id) => '$emailAccounts/$id/sync';
  static String refreshToken(int id) => '$emailAccounts/$id/refresh-token';
  static String disconnectEmailAccount(int id) => '$emailAccounts/$id/disconnect';
  static String emailFolders(int accountId) => '$emailAccounts/$accountId/folders';
  static String emailsByFolder(int accountId, String folder) => '$emailAccounts/$accountId/folders/$folder/emails';
  static const String searchEmails = '$emails/search';

  // Full URL helper method
  static String getFullUrl(String endpoint) {
    // Gmail API endpoint'leri zaten full URL, diğerleri için baseUrl ekle
    if (endpoint.startsWith('http')) {
      return endpoint;
    }
    return '$baseUrl$endpoint';
  }
}
