/// Uygulama sabitleri
class AppConstants {
  // Database
  static const String databaseName = 'ai_assistant.db';
  static const int databaseVersion = 1;

  // Storage Keys
  static const String storageKeyTheme = 'theme_preference';
  static const String storageKeyLanguage = 'language';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeyAccessToken = 'access_token';
  static const String storageKeyRefreshToken = 'refresh_token';

  // Route Names
  static const String routeHome = '/home';
  static const String routeMessages = '/messages';
  static const String routeTasks = '/tasks';
  static const String routeCalendar = '/calendar';
  static const String routeEmail = '/email';
  static const String routeAnalytics = '/analytics';
  static const String routeAiAssistant = '/ai-assistant';
  static const String routeSettings = '/settings';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';

  // Email Folders
  static const String folderInbox = 'inbox';
  static const String folderSent = 'sent';
  static const String folderDrafts = 'drafts';
  static const String folderTrash = 'trash';
  static const String folderSpam = 'spam';
  static const String folderImportant = 'important';

  // Task Status
  static const String taskStatusPending = 'pending';
  static const String taskStatusInProgress = 'in_progress';
  static const String taskStatusCompleted = 'completed';
  static const String taskStatusCancelled = 'cancelled';

  // Task Priority
  static const String taskPriorityLow = 'low';
  static const String taskPriorityMedium = 'medium';
  static const String taskPriorityHigh = 'high';
  static const String taskPriorityUrgent = 'urgent';

  // Date Formats
  static const String dateFormatFull = 'dd.MM.yyyy HH:mm';
  static const String dateFormatDate = 'dd.MM.yyyy';
  static const String dateFormatTime = 'HH:mm';
  static const String dateFormatISO = 'yyyy-MM-ddTHH:mm:ss';

  // Regex Patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';

  // File Size Limits
  static const int maxAttachmentSize = 10 * 1024 * 1024; // 10 MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB

  // Pagination
  static const int defaultLimit = 20;
  static const int maxLimit = 100;

  // Error Messages
  static const String errorNetwork = 'İnternet bağlantısı yok';
  static const String errorTimeout = 'İstek zaman aşımına uğradı';
  static const String errorUnauthorized = 'Yetkiniz yok';
  static const String errorNotFound = 'Kayıt bulunamadı';
  static const String errorServer = 'Sunucu hatası';
  static const String errorUnknown = 'Bilinmeyen bir hata oluştu';

  // UI Constants
  static const double defaultBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;
  static const double defaultIconSize = 24.0;
  static const double defaultElevation = 2.0;

  // Animation Durations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // Snackbar Durations
  static const Duration snackbarDurationShort = Duration(seconds: 2);
  static const Duration snackbarDurationMedium = Duration(seconds: 3);
  static const Duration snackbarDurationLong = Duration(seconds: 4);

  // WhatsApp Constants
  static const double whatsappBubbleMaxWidth = 0.6; // %60 of screen width
  static const double whatsappBubbleMinWidth = 40.0;
  static const double whatsappBubbleCharWidth = 11.0; // Estimated character width

  // OAuth Constants
  static const int oauthServerPreferredPort = 8080;
  static const List<int> oauthServerAlternativePorts = [8081, 8082, 8083, 3000, 3001];
  static const String oauthCallbackPath = '/oauth-callback';

  // Platform Names
  static const String platformWhatsApp = 'WhatsApp';
  static const String platformTelegram = 'Telegram';
  static const String platformGmail = 'Gmail';
  static const String platformOutlook = 'Outlook';
  static const String platformGoogleCalendar = 'Google Calendar';
  static const String platformOutlookCalendar = 'Outlook Calendar';

  // Message Constants
  static const int messagePreviewLength = 30;
  static const int messageSubjectMaxLength = 100;
}
