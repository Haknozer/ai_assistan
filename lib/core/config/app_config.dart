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

  // Debug Configuration
  static const bool debugMode = bool.fromEnvironment('DEBUG', defaultValue: false);
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);
}
