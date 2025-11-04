import 'package:flutter/material.dart';

/// Settings yardımcı fonksiyonları
class SettingsUtils {
  /// Kategori açıklaması
  static String getCategoryDescription(String category) {
    switch (category) {
      case 'E-posta Entegrasyonları':
        return 'E-posta servislerinizi bağlayın';
      case 'Takvim Entegrasyonları':
        return 'Takvimlerinizi senkronize edin';
      case 'İletişim':
        return 'Mesajlaşma uygulamalarını entegre edin';
      default:
        return 'Servisleri bağlayın';
    }
  }

  /// Kategori ikonu
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'E-posta Entegrasyonları':
        return Icons.email_outlined;
      case 'Takvim Entegrasyonları':
        return Icons.calendar_today_outlined;
      case 'İletişim':
        return Icons.chat_outlined;
      case 'Proje Yönetimi':
        return Icons.task_alt_outlined;
      case 'Depolama':
        return Icons.cloud_upload_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

