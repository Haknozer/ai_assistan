import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// Calendar refresh notifier - n8n response geldiğinde takvimi yenilemek için
class CalendarRefreshNotifier extends StateNotifier<int> {
  CalendarRefreshNotifier() : super(0);

  /// Takvimi yenile (counter'ı artırarak)
  void refresh() {
    state = state + 1;
  }
}

/// Calendar refresh provider
final calendarRefreshProvider = StateNotifierProvider<CalendarRefreshNotifier, int>((ref) {
  return CalendarRefreshNotifier();
});

/// Global calendar refresh instance - email provider'dan erişim için
/// Not: Bu, provider'a erişim olmadan calendar refresh'i tetiklemek için kullanılır
class GlobalCalendarRefresh {
  static CalendarRefreshNotifier? _instance;
  static final List<VoidCallback> _pendingCallbacks = [];
  
  /// Global instance'ı set et (calendar screen'de initialize edilecek)
  static void setInstance(CalendarRefreshNotifier instance) {
    _instance = instance;
    // Bekleyen callback'leri çalıştır
    for (final callback in _pendingCallbacks) {
      callback();
    }
    _pendingCallbacks.clear();
  }
  
  /// Calendar refresh'i tetikle
  /// Eğer instance henüz set edilmemişse, callback'i beklet
  static void refresh() {
    if (_instance != null) {
      _instance!.refresh();
    } else {
      // Instance henüz set edilmemişse, callback'i beklet
      _pendingCallbacks.add(() {
        _instance?.refresh();
      });
    }
  }
}

