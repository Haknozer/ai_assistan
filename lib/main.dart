import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/database/database_service.dart';
import 'core/config/app_config.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows için database factory initialization
  if (defaultTargetPlatform == TargetPlatform.windows) {
    databaseFactory = databaseFactoryFfi;
  }

  // Supabase'i başlat
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      debug: AppConfig.debugMode,
      authOptions: const FlutterAuthClientOptions(
        // Network hatalarını sessizce yönet
        autoRefreshToken: true,
      ),
    );

    // Auth state değişikliklerini dinle ve network hatalarını yönet
    Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        
        // Sadece önemli event'leri logla
        if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
          if (kDebugMode) {
            debugPrint('[Supabase Auth] Event: $event');
          }
        }
      },
      onError: (error) {
        // Network hatalarını sessizce yönet (DNS lookup failures, connection errors, etc.)
        // Bu hatalar Supabase'in otomatik token yenileme mekanizmasından kaynaklanır
        // ve offline durumda normaldir
        if (kDebugMode && AppConfig.debugMode) {
          final errorStr = error.toString();
          // Sadece network hataları değil, diğer önemli hataları logla
          if (!errorStr.contains('Failed host lookup') &&
              !errorStr.contains('SocketException') &&
              !errorStr.contains('AuthRetryableFetchException')) {
            debugPrint('[Supabase Auth] Error: $error');
          }
        }
      },
    );
  } catch (e) {
    // Network hatası durumunda uygulama çalışmaya devam etsin
    debugPrint('Supabase initialization error (non-critical): $e');
  }

  // Veritabanını başlatH
  try {
    await DatabaseService.instance.database;
  } catch (e) {
    debugPrint('Database initialization error: $e');
  }

  runApp(
    const ProviderScope(
      child: AIAssistantApp(),
    ),
  );
}

class AIAssistantApp extends ConsumerWidget {
  const AIAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTheme = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AI Asistan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: userTheme.themeMode,
      routerConfig: router,
    );
  }
}
