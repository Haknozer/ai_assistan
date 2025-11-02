import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/email.dart';
import '../../../../core/theme/app_theme.dart';

/// E-posta yardımcı fonksiyonları
class EmailUtils {
  /// E-posta önem derecesi rengini döndürür
  static Color getImportanceColor(EmailImportance importance) {
    switch (importance) {
      case EmailImportance.important:
        return AppTheme.errorColor; // Kırmızı
      case EmailImportance.urgent:
        return Colors.red[900]!; // Koyu kırmızı
      case EmailImportance.normal:
        return Colors.grey;
    }
  }

  /// E-posta önem derecesi ikonunu döndürür
  static IconData getImportanceIcon(EmailImportance importance) {
    switch (importance) {
      case EmailImportance.important:
        return Icons.priority_high;
      case EmailImportance.urgent:
        return Icons.error_outline;
      case EmailImportance.normal:
        return Icons.mail_outline;
    }
  }

  /// E-posta durumu rengini döndürür
  static Color getStatusColor(EmailStatus status) {
    switch (status) {
      case EmailStatus.unread:
        return AppTheme.primaryColor;
      case EmailStatus.read:
        return Colors.grey;
      case EmailStatus.received:
        return AppTheme.primaryColor;
      case EmailStatus.sent:
        return AppTheme.successColor;
      case EmailStatus.draft:
        return AppTheme.warningColor;
    }
  }

  /// E-posta durumu ikonunu döndürür
  static IconData getStatusIcon(EmailStatus status) {
    switch (status) {
      case EmailStatus.unread:
        return Icons.mark_email_unread;
      case EmailStatus.read:
        return Icons.mark_email_read;
      case EmailStatus.received:
        return Icons.inbox;
      case EmailStatus.sent:
        return Icons.send;
      case EmailStatus.draft:
        return Icons.drafts;
    }
  }

  /// Tarih formatla (örn: "15 Kasım 2025, 14:30")
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emailDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (emailDate == today) {
      // Bugünse sadece saat göster
      return 'Bugün ${DateFormat('HH:mm').format(dateTime)}';
    } else if (emailDate == today.subtract(const Duration(days: 1))) {
      // Dünse
      return 'Dün ${DateFormat('HH:mm').format(dateTime)}';
    } else if (dateTime.year == now.year) {
      // Bu yılsa yılı gösterme
      return DateFormat('d MMMM, HH:mm', 'tr_TR').format(dateTime);
    } else {
      // Tam tarih
      return DateFormat('d MMMM yyyy, HH:mm', 'tr_TR').format(dateTime);
    }
  }

  /// E-posta adresinden isim çıkar
  static String extractNameFromEmail(String email) {
    final parts = email.split('@');
    if (parts.isEmpty) return email;

    final namePart = parts[0].replaceAll('.', ' ').replaceAll('_', ' ');
    return namePart.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// E-posta boyutunu formatla (örn: "1.5 MB", "345 KB")
  static String formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// E-posta adresini doğrula
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Baş harfleri al (avatar için)
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// E-posta sayısını formatla (örn: "5", "99+")
  static String formatEmailCount(int count) {
    if (count > 99) {
      return '99+';
    }
    return count.toString();
  }
}
