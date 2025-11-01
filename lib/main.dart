import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/database/database_service.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows için database factory initialization
  if (defaultTargetPlatform == TargetPlatform.windows) {
    databaseFactory = databaseFactoryFfi;
  }

  // Supabase'i başlat
  await Supabase.initialize(
    url: 'https://laxjsbkonbwuckdwutxg.supabase.co', // Buraya Supabase URL'iniz gelecek
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxheGpzYmtvbmJ3dWNrZHd1dHhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5ODI4MjQsImV4cCI6MjA3NzU1ODgyNH0.TeXuMpYl2Oln3vBEB-LQn3jvq8Y_JI2T_Uu0-bIXyZg', // Buraya anon key gelecek
    debug: true,
  );

  // Veritabanını başlat
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
