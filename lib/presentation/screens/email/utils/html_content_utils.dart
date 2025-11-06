import 'package:flutter/foundation.dart' show debugPrint;
import 'package:html/parser.dart' as html_parser;

/// HTML içerik temizleme ve parsing yardımcı fonksiyonları
class HtmlContentUtils {
  /// HTML içeriğinden body içeriğini çıkar
  static String extractBodyContent(String htmlContent) {
    String cleanedHtml = htmlContent;

    try {
      // RegExp ile body içeriğini çıkar (case-insensitive, multiline)
      final bodyMatch = RegExp(
        r'<body[^>]*>([\s\S]*?)<\/body>',
        caseSensitive: false,
      ).firstMatch(htmlContent);

      if (bodyMatch != null && bodyMatch.groupCount >= 1) {
        cleanedHtml = bodyMatch.group(1)?.trim() ?? '';
        debugPrint('extractBodyContent: Body içeriği RegExp ile çıkarıldı, uzunluk: ${cleanedHtml.length}');

        // Body içeriğinde hala DOCTYPE varsa temizle
        if (cleanedHtml.toLowerCase().contains('<!doctype')) {
          debugPrint('extractBodyContent: Body içinde DOCTYPE bulundu, temizleniyor...');
          cleanedHtml = cleanHtmlWithoutBody(cleanedHtml);
        }

        // Eğer RegExp ile çıkarılan içerik boşsa, HTML parser ile dene
        if (cleanedHtml.isEmpty || cleanedHtml.trim().isEmpty) {
          debugPrint('extractBodyContent: RegExp ile çıkarılan içerik boş, HTML parser deneniyor...');
          final document = html_parser.parse(htmlContent);
          final bodyElement = document.body;

          if (bodyElement != null) {
            cleanedHtml = bodyElement.innerHtml;
            debugPrint('extractBodyContent: Body içeriği parser ile çıkarıldı, uzunluk: ${cleanedHtml.length}');
          }
        }
      } else {
        // Body tagı bulunamadı, HTML parser ile dene
        debugPrint('extractBodyContent: Body tagı RegExp ile bulunamadı, HTML parser deneniyor...');
        final document = html_parser.parse(htmlContent);
        final bodyElement = document.body;

        if (bodyElement != null) {
          cleanedHtml = bodyElement.innerHtml;
          debugPrint('extractBodyContent: Body içeriği parser ile çıkarıldı, uzunluk: ${cleanedHtml.length}');
        } else {
          debugPrint('extractBodyContent: Body elementi bulunamadı, DOCTYPE ve diğer taglar temizleniyor...');
          // Body yoksa DOCTYPE ve diğer tagları temizle
          cleanedHtml = cleanHtmlWithoutBody(htmlContent);
        }
      }
    } catch (e) {
      debugPrint('extractBodyContent: Body içeriği ayıklama hatası - $e');
      // Hata durumunda DOCTYPE ve diğer tagları temizle
      cleanedHtml = cleanHtmlWithoutBody(htmlContent);
    }

    return cleanedHtml;
  }

  /// HTML'den plain text çıkar (fallback için)
  static String? extractPlainText(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);
      final bodyText = document.body?.text;
      if (bodyText != null) {
        final trimmed = bodyText.trim();
        if (trimmed.isNotEmpty) {
          debugPrint('extractPlainText: Fallback metin hazır, uzunluk: ${trimmed.length}');
          return trimmed;
        }
      }
    } catch (e) {
      debugPrint('extractPlainText: Fallback metin çıkarma hatası - $e');
    }
    return null;
  }

  /// Body olmayan HTML'lerden DOCTYPE, html, head taglarını temizle
  static String cleanHtmlWithoutBody(String htmlContent) {
    String cleaned = htmlContent;
    final htmlLower = cleaned.toLowerCase();

    try {
      // DOCTYPE'ı kaldır
      if (htmlLower.contains('<!doctype')) {
        final doctypeIndex = htmlLower.indexOf('<!doctype');
        final doctypeEnd = cleaned.indexOf('>', doctypeIndex) + 1;
        if (doctypeEnd > doctypeIndex) {
          cleaned = cleaned.substring(doctypeEnd).trim();
          debugPrint('cleanHtmlWithoutBody: DOCTYPE kaldırıldı');
        }
      }

      // HTML comment'leri kaldır
      while (cleaned.toLowerCase().contains('<!--')) {
        final commentStart = cleaned.toLowerCase().indexOf('<!--');
        final commentEnd = cleaned.toLowerCase().indexOf('-->', commentStart);
        if (commentEnd > commentStart) {
          cleaned = cleaned.substring(0, commentStart) + 
                   cleaned.substring(commentEnd + 3);
        } else {
          break;
        }
      }

      // <html> tagını kaldır
      final htmlLower2 = cleaned.toLowerCase();
      if (htmlLower2.contains('<html')) {
        final htmlIndex = htmlLower2.indexOf('<html');
        final htmlTagEnd = cleaned.indexOf('>', htmlIndex) + 1;
        if (htmlTagEnd > htmlIndex) {
          cleaned = cleaned.substring(htmlTagEnd).trim();
          debugPrint('cleanHtmlWithoutBody: <html> tagı kaldırıldı');
        }
      }

      // </html> tagını kaldır
      final htmlLower3 = cleaned.toLowerCase();
      if (htmlLower3.endsWith('</html>')) {
        cleaned = cleaned.substring(0, cleaned.length - 7).trim();
        debugPrint('cleanHtmlWithoutBody: </html> tagı kaldırıldı');
      }

      // <head>...</head> bloğunu kaldır
      final htmlLower4 = cleaned.toLowerCase();
      while (htmlLower4.contains('<head')) {
        final headStart = htmlLower4.indexOf('<head');
        final headEnd = htmlLower4.indexOf('</head>', headStart);
        if (headEnd > headStart) {
          final headBlockEnd = cleaned.indexOf('>', headEnd) + 1;
          cleaned = cleaned.substring(0, headStart) + 
                   cleaned.substring(headBlockEnd);
          debugPrint('cleanHtmlWithoutBody: <head> bloğu kaldırıldı');
        } else {
          break;
        }
      }

      debugPrint('cleanHtmlWithoutBody: Temizlenmiş HTML uzunluğu: ${cleaned.length}');
    } catch (e) {
      debugPrint('cleanHtmlWithoutBody: Temizleme hatası - $e');
    }

    return cleaned;
  }

  /// HTML içerik için custom style builder
  static Map<String, String>? buildCustomStyles(dynamic element) {
    final styles = <String, String>{};

    // Element'in tag adını al
    final tagName = element.localName?.toLowerCase() ?? '';

    // Inline style'ı kontrol et
    final styleAttr = element.attributes['style'] ?? '';
    final hasMaxWidth = styleAttr.toLowerCase().contains('max-width');
    final hasWidth = styleAttr.toLowerCase().contains('width');

    // Table, div, body, td, th gibi container elementler için genişlik ayarla
    if (tagName == 'table' ||
        tagName == 'div' ||
        tagName == 'body' ||
        tagName == 'td' ||
        tagName == 'th' ||
        tagName == 'tr' ||
        tagName == 'tbody' ||
        tagName == 'thead') {
      styles['max-width'] = '100%';
      styles['width'] = '100%';
      styles['box-sizing'] = 'border-box';
    }

    // Image'lar için max-width ayarla
    if (tagName == 'img') {
      styles['max-width'] = '100%';
      styles['height'] = 'auto';
      styles['display'] = 'block';
    }

    // Eğer inline style'da max-width veya width varsa, override et
    if (hasMaxWidth || hasWidth) {
      styles['max-width'] = '100%';
      if (hasWidth && !tagName.contains('img')) {
        styles['width'] = '100%';
      }
    }

    return styles.isEmpty ? null : styles;
  }
}

