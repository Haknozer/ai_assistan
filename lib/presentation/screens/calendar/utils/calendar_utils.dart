import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/calendar_event.dart';
import '../../../../core/theme/app_theme.dart';

/// Takvim yardımcı fonksiyonları
class CalendarUtils {
  /// Etkinlik tipi rengini döndürür
  static Color getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.meeting:
        return AppTheme.primaryColor; // Mavi
      case EventType.appointment:
        return AppTheme.successColor; // Yeşil
      case EventType.task:
        return AppTheme.warningColor; // Turuncu
      case EventType.personal:
        return Colors.purple;
      case EventType.other:
        return Colors.grey;
    }
  }

  /// Etkinlik tipi ikonunu döndürür
  static IconData getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.meeting:
        return Icons.groups;
      case EventType.appointment:
        return Icons.event;
      case EventType.task:
        return Icons.task_alt;
      case EventType.personal:
        return Icons.person;
      case EventType.other:
        return Icons.event_note;
    }
  }

  /// Etkinlik kaynağı rengini döndürür
  static Color getEventSourceColor(EventSource source) {
    switch (source) {
      case EventSource.manual:
        return Colors.grey;
      case EventSource.google:
        return const Color(0xFF4285F4); // Google Blue
      case EventSource.outlook:
        return const Color(0xFF0078D4); // Microsoft Blue
      case EventSource.apple:
        return Colors.black;
    }
  }

  /// Etkinlik kaynağı ikonunu döndürür
  static IconData getEventSourceIcon(EventSource source) {
    switch (source) {
      case EventSource.manual:
        return Icons.edit_calendar;
      case EventSource.google:
        return Icons.calendar_today;
      case EventSource.outlook:
        return Icons.mail_outline;
      case EventSource.apple:
        return Icons.apple;
    }
  }

  /// Ay ismini döndürür
  static String getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return months[month - 1];
  }

  /// Gün ismini döndürür
  static String getDayName(int weekday) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday - 1];
  }

  /// Tarih formatla (örn: "15 Kasım 2025")
  static String formatDate(DateTime date) {
    return '${date.day} ${getMonthName(date.month)} ${date.year}';
  }

  /// Saat formatla (örn: "14:30")
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Tarih ve saat formatla (örn: "15 Kasım 2025, 14:30")
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)}, ${formatTime(dateTime)}';
  }

  /// Süre hesapla (örn: "2 saat 30 dakika")
  static String calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '$hours saat $minutes dakika';
    } else if (hours > 0) {
      return '$hours saat';
    } else {
      return '$minutes dakika';
    }
  }

  /// Bugün mü kontrol et
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Geçmiş tarih mi kontrol et
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Gelecek tarih mi kontrol et
  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
  }

  /// Ayın ilk gününü döndürür
  static DateTime getFirstDayOfMonth(DateTime month) {
    return DateTime(month.year, month.month, 1);
  }

  /// Ayın son gününü döndürür
  static DateTime getLastDayOfMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0);
  }

  /// Ayın gün sayısını döndürür
  static int getDaysInMonth(DateTime month) {
    return getLastDayOfMonth(month).day;
  }

  /// Ayın ilk gününün haftanın hangi günü olduğunu döndürür (1 = Pazartesi)
  static int getFirstWeekdayOfMonth(DateTime month) {
    return getFirstDayOfMonth(month).weekday;
  }

  /// Takvim grid için gerekli gün sayısını hesapla (önceki/sonraki ay günleri dahil)
  static int getCalendarGridDays(DateTime month) {
    final firstWeekday = getFirstWeekdayOfMonth(month);
    final daysInMonth = getDaysInMonth(month);
    final totalDays = firstWeekday - 1 + daysInMonth;
    return ((totalDays / 7).ceil() * 7);
  }
}

