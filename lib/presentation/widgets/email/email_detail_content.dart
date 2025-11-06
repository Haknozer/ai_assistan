import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../models/email.dart';
import '../../screens/email/utils/html_content_utils.dart';

/// E-posta içerik widget'ı - Gmail tarzı HTML/Plain text render
class EmailDetailContent extends StatelessWidget {
  final Email email;

  const EmailDetailContent({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final htmlContent = email.htmlContent;
    final plainText = email.plainText;

    // Debug: İçeriği kontrol et
    debugPrint(
      'EmailDetailContent: htmlContent: ${htmlContent?.length ?? 0} karakter, '
      'plainText: ${plainText?.length ?? 0} karakter',
    );

    final hasContent = (plainText != null && plainText.isNotEmpty) || (htmlContent != null && htmlContent.isNotEmpty);

    if (!hasContent) {
      return _buildEmptyContent(context, htmlContent, plainText);
    }

    // Gmail tarzı içerik alanı - minimal padding, temiz görünüm
    final contentWidget = htmlContent != null && htmlContent.isNotEmpty
        ? _EmailHtmlContent(htmlContent: htmlContent, plainText: plainText)
        : _EmailPlainTextContent(text: plainText ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: contentWidget,
    );
  }

  Widget _buildEmptyContent(
    BuildContext context,
    String? htmlContent,
    String? plainText,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Bu e-postanın içeriği yok',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Debug: htmlContent='
              '${htmlContent?.substring(0, htmlContent.length > 100 ? 100 : htmlContent.length) ?? 'null'}, '
              'plainText='
              '${plainText?.substring(0, plainText.length > 100 ? 100 : plainText.length) ?? 'null'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// HTML içerik renderer
class _EmailHtmlContent extends StatelessWidget {
  final String htmlContent;
  final String? plainText;

  const _EmailHtmlContent({
    required this.htmlContent,
    this.plainText,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('_EmailHtmlContent: HTML içeriği render ediliyor, uzunluk: ${htmlContent.length}');

    // Fallback metin
    final fallbackText = HtmlContentUtils.extractPlainText(htmlContent);

    try {
      // Body içeriğini çıkar
      final cleanedHtml = HtmlContentUtils.extractBodyContent(htmlContent);

      // Temizlenmiş HTML'in boş olmadığını kontrol et
      if (cleanedHtml.trim().isEmpty) {
        debugPrint('_EmailHtmlContent: Temizlenmiş HTML boş, fallback metin kullanılıyor');
        if (fallbackText != null && fallbackText.isNotEmpty) {
          return _EmailPlainTextContent(text: fallbackText);
        }
      }

      debugPrint('_EmailHtmlContent: Temizlenmiş HTML uzunluğu: ${cleanedHtml.length}');

      // HtmlWidget ile HTML'i render et - sadece body içeriği
      return SizedBox(
        width: double.infinity,
        child: HtmlWidget(
          cleanedHtml,
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.5,
              ),
          customStylesBuilder: (element) {
            return HtmlContentUtils.buildCustomStyles(element);
          },
        ),
      );
    } catch (e, stackTrace) {
      // Hata durumunda parse edilmiş metni göster
      debugPrint('_EmailHtmlContent: HtmlWidget HATA - $e');
      debugPrint('_EmailHtmlContent: StackTrace - $stackTrace');

      // Fallback metin varsa onu göster
      if (fallbackText != null && fallbackText.isNotEmpty) {
        debugPrint('_EmailHtmlContent: Fallback metin gösteriliyor');
        return _EmailPlainTextContent(text: fallbackText);
      }

      // Fallback metin yoksa, boş içerik mesajı göster
      return _buildErrorContent(context);
    }
  }

  Widget _buildErrorContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'E-posta içeriği görüntülenemedi',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              ),
        ),
      ),
    );
  }
}

/// Plain text içerik renderer
class _EmailPlainTextContent extends StatelessWidget {
  final String text;

  const _EmailPlainTextContent({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text.isEmpty ? 'İçerik bulunamadı' : text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}
