import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode themeMode;
  final bool isDarkMode;

  const ThemeState({
    required this.themeMode,
    required this.isDarkMode,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isDarkMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState(themeMode: ThemeMode.light, isDarkMode: false)) {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;

    if (isDarkMode) {
      state = const ThemeState(themeMode: ThemeMode.dark, isDarkMode: true);
    }
  }

  Future<void> toggleTheme() async {
    final newIsDarkMode = !state.isDarkMode;
    final newThemeMode = newIsDarkMode ? ThemeMode.dark : ThemeMode.light;

    state = state.copyWith(
      themeMode: newThemeMode,
      isDarkMode: newIsDarkMode,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', newIsDarkMode);
  }

  Future<void> setDarkMode(bool isDark) async {
    final newThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    state = state.copyWith(
      themeMode: newThemeMode,
      isDarkMode: isDark,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});