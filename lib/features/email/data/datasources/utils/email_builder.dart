import 'dart:convert';

/// Gmail API için email body oluşturucu (RFC 2822 format)
class EmailBuilder {
  /// Gmail API için email body oluştur (RFC 2822 format)
  static String createEmailBody({
    required List<String> toEmails,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? ccEmails,
    List<String>? bccEmails,
  }) {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln('To: ${toEmails.join(', ')}');
    if (ccEmails != null && ccEmails.isNotEmpty) {
      buffer.writeln('Cc: ${ccEmails.join(', ')}');
    }
    if (bccEmails != null && bccEmails.isNotEmpty) {
      buffer.writeln('Bcc: ${bccEmails.join(', ')}');
    }
    buffer.writeln('Subject: $subject');
    buffer.writeln('MIME-Version: 1.0');

    // Body
    if (htmlContent != null && plainText != null) {
      // Multipart/alternative
      final boundary = 'boundary_${DateTime.now().millisecondsSinceEpoch}';
      buffer.writeln('Content-Type: multipart/alternative; boundary="$boundary"');
      buffer.writeln();
      buffer.writeln('--$boundary');
      buffer.writeln('Content-Type: text/plain; charset=UTF-8');
      buffer.writeln();
      buffer.writeln(plainText);
      buffer.writeln('--$boundary');
      buffer.writeln('Content-Type: text/html; charset=UTF-8');
      buffer.writeln();
      buffer.writeln(htmlContent);
      buffer.writeln('--$boundary--');
    } else if (htmlContent != null) {
      buffer.writeln('Content-Type: text/html; charset=UTF-8');
      buffer.writeln();
      buffer.writeln(htmlContent);
    } else {
      buffer.writeln('Content-Type: text/plain; charset=UTF-8');
      buffer.writeln();
      buffer.writeln(plainText ?? '');
    }

    // Base64 encode et
    final emailString = buffer.toString();
    final bytes = utf8.encode(emailString);
    return base64Url.encode(bytes);
  }
}

