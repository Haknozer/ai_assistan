/// Uygulama konfigürasyon yönetimi
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://laxjsbkonbwuckdwutxg.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxheGpzYmtvbmJ3dWNrZHd1dHhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5ODI4MjQsImV4cCI6MjA3NzU1ODgyNH0.TeXuMpYl2Oln3vBEB-LQn3jvq8Y_JI2T_Uu0-bIXyZg',
  );

  // App Configuration
  static const String appName = 'AI Asistan';
  static const String appVersion = '1.0.0+1';

  // Timeout Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheTimeout = Duration(minutes: 15);

  // Pagination Configuration
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Feature Flags
  static const bool enableEmailSync = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;

  // Google OAuth Configuration (Windows için)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '', // Environment variable'dan gelecek - run_windows.bat script'i kullanın
  );

  static const String googleClientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: '', // Google Cloud Console'dan alınacak (güvenlik için kullanılmayabilir)
  );

  // Microsoft OAuth Configuration (Outlook için)
  static const String microsoftClientId = String.fromEnvironment(
    'MICROSOFT_CLIENT_ID',
    defaultValue: '', // Azure Portal'dan alınacak - run_windows.bat script'i kullanın
  );

  static const String microsoftClientSecret = String.fromEnvironment(
    'MICROSOFT_CLIENT_SECRET',
    defaultValue: '', // Azure Portal'dan alınacak
  );

  // Weather API Configuration
  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: '', // OpenWeatherMap API key - https://openweathermap.org/api
  );

  // Telegram Bot Configuration
  static const String telegramBotToken = String.fromEnvironment(
    'TELEGRAM_BOT_TOKEN',
    defaultValue: '',
  );

  // n8n Webhook URL (Telegram mesajlarını iletmek için)
  static const String n8nTelegramWebhookUrl = String.fromEnvironment(
    'N8N_TELEGRAM_WEBHOOK_URL',
    defaultValue: '',
  );

  // n8n Webhook URL (Email mesajlarını iletmek için)
  static const String n8nEmailWebhookUrl = String.fromEnvironment(
    'N8N_EMAIL_WEBHOOK_URL',
    defaultValue: '',
  );

  // n8n Webhook URL (Sesli mail özeti için)
  static const String n8nEmailSummaryWebhookUrl = String.fromEnvironment(
    'N8N_EMAIL_SUMMARY_WEBHOOK_URL',
    defaultValue: 'https://hakanozerr.app.n8n.cloud/webhook/be5cf629-98b2-4a8a-8c6f-61ca8acea3ff',
  );

  // Chatbot webhook URL (AI asistan mesajları için)
  static const String chatbotWebhookUrl = String.fromEnvironment(
    'CHATBOT_WEBHOOK_URL',
    defaultValue: 'https://hakanozerr.app.n8n.cloud/webhook/bb831b87-a172-418d-b3e9-7d12b7192d90',
  );

  // Telegram polling feature flag
  // Varsayılan olarak KAPALI gelir; sadece ENABLE_TELEGRAM_POLLING=true dersen açılır.
  static const bool enableTelegramPolling = bool.fromEnvironment(
    'ENABLE_TELEGRAM_POLLING',
    defaultValue: false,
  );

  // Google Cloud Speech/Text settings
  static const String googleApplicationCredentials = String.fromEnvironment(
    'GOOGLE_APPLICATION_CREDENTIALS',
    defaultValue: '',
  );

  static const String gcpProjectId = String.fromEnvironment(
    'GCP_PROJECT_ID',
    defaultValue: '',
  );

  static const String gcpSttLanguage = String.fromEnvironment(
    'GCP_STT_LANGUAGE',
    defaultValue: 'tr-TR',
  );

  static const String gcpTtsVoice = String.fromEnvironment(
    'GCP_TTS_VOICE',
    defaultValue: 'tr-TR-Standard-A', // Wavenet yerine Standard kullanımı (daha güvenli)
  );

  static const String gcpTtsEncoding = String.fromEnvironment(
    'GCP_TTS_ENCODING',
    defaultValue: 'MP3', // audioplayers MP3 header'ını tanır, LINEAR16 (RAW PCM) çalamaz
  );

  // Debug Configuration
  static const bool debugMode = bool.fromEnvironment('DEBUG', defaultValue: false);
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);
}
