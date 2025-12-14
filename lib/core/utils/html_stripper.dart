import 'package:flutter/foundation.dart';

/// HTML tag'lerini temizleme utility'si
class HtmlStripper {
  /// HTML tag'lerini temizle ve plain text'e çevir
  static String stripHtmlTags(String html) {
    if (html.isEmpty) return html;
    
    try {
      // Önce HTML entity'leri decode et
      String cleaned = html
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&apos;', "'")
          .replaceAll('&mdash;', '—')
          .replaceAll('&ndash;', '–')
          .replaceAll('&hellip;', '…')
          .replaceAll('&copy;', '©')
          .replaceAll('&reg;', '®')
          .replaceAll('&trade;', '™');
      
      // HTML tag'lerini kaldır
      cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), ' ');
      
      // Birden fazla boşlukları tek boşluğa çevir
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
      
      // Başta ve sonda boşlukları temizle
      cleaned = cleaned.trim();
      
      return cleaned;
    } catch (e) {
      debugPrint('HtmlStripper - HTML temizleme hatası: $e');
      // Hata durumunda basit regex ile temizle
      return html.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    }
  }

  /// String'de HTML tag'leri var mı kontrol et
  static bool containsHtmlTags(String text) {
    if (text.isEmpty) return false;
    return text.contains('<') && text.contains('>');
  }

  /// HTML tag'leri varsa temizle, yoksa olduğu gibi döndür
  static String cleanIfNeeded(String text) {
    if (text.isEmpty) return text;
    if (containsHtmlTags(text)) {
      return stripHtmlTags(text);
    }
    return text;
  }
}

