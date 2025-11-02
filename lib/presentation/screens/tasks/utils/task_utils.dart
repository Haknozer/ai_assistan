import 'package:flutter/material.dart';
import '../../../../models/task.dart';
import '../../../../core/theme/app_theme.dart';

/// Görev yardımcı fonksiyonları
class TaskUtils {
  /// Durum rengini döndürür
  static Color getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppTheme.warningColor; // Turuncu - Yapılacak
      case TaskStatus.inProgress:
        return AppTheme.primaryColor; // Mavi - Devam Ediyor
      case TaskStatus.completed:
        return AppTheme.successColor; // Yeşil - Yapıldı
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }

  /// Durum ikonunu döndürür
  static IconData getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending_actions;
      case TaskStatus.inProgress:
        return Icons.autorenew;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Öncelik rengini döndürür
  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return const Color(0xFFD32F2F); // Kırmızı
      case TaskPriority.high:
        return AppTheme.errorColor; // Kırmızı
      case TaskPriority.medium:
        return AppTheme.warningColor; // Turuncu
      case TaskPriority.low:
        return AppTheme.successColor; // Yeşil
    }
  }

  /// Tarih formatla
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

