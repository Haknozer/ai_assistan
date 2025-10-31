import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/user_provider.dart';

void main() {
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
    final userTheme = ref.watch(userThemeProvider);
    final router = ref.watch(routerProvider);
    final systemBrightness = MediaQuery.of(context).platformBrightness;

    // Tema kararını belirle
    ThemeMode themeMode;
    switch (userTheme) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default: // system
        themeMode = systemBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light;
    }

    return MaterialApp.router(
      title: 'AI Asistan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

