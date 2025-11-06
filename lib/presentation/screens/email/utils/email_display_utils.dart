import 'package:flutter/material.dart';

/// E-posta görüntüleme yardımcı fonksiyonları
class EmailDisplayUtils {
  /// Avatar rengi için hash fonksiyonu - Gmail tarzı
  static Color getAvatarColor(String email) {
    const colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
    ];
    final hash = email.hashCode;
    return colors[hash.abs() % colors.length];
  }

  /// Dosya tipine göre ikon al
  static IconData getFileIcon(String contentType) {
    if (contentType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (contentType.contains('word')) {
      return Icons.description;
    } else if (contentType.contains('sheet') || contentType.contains('excel')) {
      return Icons.table_chart;
    } else if (contentType.contains('image')) {
      return Icons.image;
    } else if (contentType.contains('zip') || contentType.contains('rar')) {
      return Icons.archive;
    } else {
      return Icons.attach_file;
    }
  }

  /// Avatar harfi al (ilk harf)
  static String getAvatarLetter(String displayName, String email) {
    if (displayName.isNotEmpty) {
      return displayName[0].toUpperCase();
    } else if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }
}

