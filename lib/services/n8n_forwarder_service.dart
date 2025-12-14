import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

/// Telegram ve Email mesajlarını n8n'e forward eden basit servis.
class N8nForwarderService {
  N8nForwarderService._internal();
  static final N8nForwarderService _instance = N8nForwarderService._internal();
  factory N8nForwarderService() => _instance;

  String get _telegramWebhookUrl => AppConfig.n8nTelegramWebhookUrl;
  String get _emailWebhookUrl => AppConfig.n8nEmailWebhookUrl;

  bool get isConfigured => _telegramWebhookUrl.isNotEmpty;
  bool get isEmailConfigured => _emailWebhookUrl.isNotEmpty;

  /// Telegram unified mesajını n8n webhook'una gönder (fire-and-forget).
  Future<void> forwardTelegramMessage({
    required String userId,
    required int chatId,
    required String senderName,
    required String text,
    required bool isOutgoing,
    required DateTime? dateTime,
  }) async {
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint('N8nForwarderService: n8n webhook URL boş, mesaj iletilmedi.');
      }
      return;
    }

    try {
      final uri = Uri.parse(_telegramWebhookUrl);
      final body = jsonEncode({
        'user_id': userId,
        'chat_id': chatId,
        'sender_name': senderName,
        'from_name': senderName, // Email ile uyumlu
        'from_email': '', // Telegram'da email yok
        'subject': '', // Telegram'da subject yok
        'text': text,
        'plain_text': text, // Email ile uyumlu
        'html_content': '', // Telegram'da HTML yok
        'is_outgoing': isOutgoing,
        'timestamp': (dateTime ?? DateTime.now()).toUtc().toIso8601String(),
        'platform': 'Telegram',
      });

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('N8nForwarderService.forwardTelegramMessage error: ${res.statusCode} ${res.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('N8nForwarderService.forwardTelegramMessage exception: $e');
      }
    }
  }

  /// Telegram unified mesajını n8n webhook'una gönder ve cevabı JSON olarak geri döndür.
  ///
  /// n8n tarafında "Respond to Webhook" node'u kullanıyorsan ve oradan üretilen
  /// structured çıktıyı uygulamada kullanmak istiyorsan bu metodu kullan.
  Future<Map<String, dynamic>?> forwardTelegramMessageAndWait({
    required String userId,
    required int chatId,
    required String senderName,
    required String text,
    required bool isOutgoing,
    required DateTime? dateTime,
  }) async {
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint('N8nForwarderService: n8n webhook URL boş, mesaj iletilmedi.');
      }
      return null;
    }

    try {
      final uri = Uri.parse(_telegramWebhookUrl);
      final body = jsonEncode({
        'user_id': userId,
        'chat_id': chatId,
        'sender_name': senderName,
        'from_name': senderName, // Email ile uyumlu
        'from_email': '', // Telegram'da email yok
        'subject': '', // Telegram'da subject yok
        'text': text,
        'plain_text': text, // Email ile uyumlu
        'html_content': '', // Telegram'da HTML yok
        'is_outgoing': isOutgoing,
        'timestamp': (dateTime ?? DateTime.now()).toUtc().toIso8601String(),
        'platform': 'Telegram',
      });

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('N8nForwarderService.forwardTelegramMessageAndWait error: ${res.statusCode} ${res.body}');
        }
        return null;
      }

      if (res.body.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(res.body);
      
      // Eğer response bir array ise, ilk elemanı al
      if (decoded is List && decoded.isNotEmpty) {
        if (decoded[0] is Map<String, dynamic>) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
      
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('N8nForwarderService.forwardTelegramMessageAndWait exception: $e');
      }
      return null;
    }
  }

  /// Email verisini Gemini API için hazırla (null değerleri temizle, text alanı ekle)
  Map<String, dynamic> _prepareEmailBody({
    required String userId,
    required int accountId,
    required String messageId,
    required String fromEmail,
    required String? fromName,
    required String subject,
    required String? plainText,
    required String? htmlContent,
    required List<String> toEmails,
    List<String>? ccEmails,
    List<String>? bccEmails,
    required DateTime? receivedDate,
    required bool isRead,
    required String folder,
  }) {
    // Text alanı için: önce plain_text, yoksa html_content'ten HTML tag'lerini temizle
    String? textContent = plainText;
    if (textContent == null || textContent.isEmpty) {
      if (htmlContent != null && htmlContent.isNotEmpty) {
        // HTML tag'lerini temizle (basit regex ile)
        textContent = htmlContent
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }
    }

    // Email'de folder == "sent" ise bizim gönderdiğimiz email (is_outgoing: true)
    final isOutgoing = folder.toLowerCase() == 'sent';
    
    return {
      'user_id': userId,
      'account_id': accountId,
      'message_id': messageId,
      'from_email': fromEmail,
      'from_name': fromName ?? '',
      'subject': subject,
      'text': textContent ?? '', // Gemini için her zaman string olmalı (null değil)
      'plain_text': plainText ?? '', // Null yerine boş string
      'html_content': htmlContent ?? '', // Null yerine boş string
      'to_emails': toEmails,
      'cc_emails': ccEmails ?? [], // Null yerine boş array
      'bcc_emails': bccEmails ?? [], // Null yerine boş array
      'timestamp': (receivedDate ?? DateTime.now()).toUtc().toIso8601String(),
      'is_read': isRead,
      'is_outgoing': isOutgoing, // Email için: folder == "sent" ise true
      'folder': folder,
      'platform': 'Email',
    };
  }

  /// Email mesajını n8n webhook'una gönder (fire-and-forget).
  Future<void> forwardEmailMessage({
    required String userId,
    required int accountId,
    required String messageId,
    required String fromEmail,
    required String? fromName,
    required String subject,
    required String? plainText,
    required String? htmlContent,
    required List<String> toEmails,
    List<String>? ccEmails,
    List<String>? bccEmails,
    required DateTime? receivedDate,
    required bool isRead,
    required String folder,
  }) async {
    if (!isEmailConfigured) {
      if (kDebugMode) {
        debugPrint('N8nForwarderService: n8n email webhook URL boş, email iletilmedi.');
      }
      return;
    }

    try {
      final uri = Uri.parse(_emailWebhookUrl);
      final bodyData = _prepareEmailBody(
        userId: userId,
        accountId: accountId,
        messageId: messageId,
        fromEmail: fromEmail,
        fromName: fromName,
        subject: subject,
        plainText: plainText,
        htmlContent: htmlContent,
        toEmails: toEmails,
        ccEmails: ccEmails,
        bccEmails: bccEmails,
        receivedDate: receivedDate,
        isRead: isRead,
        folder: folder,
      );
      final body = jsonEncode(bodyData);

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('N8nForwarderService.forwardEmailMessage error: ${res.statusCode} ${res.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('N8nForwarderService.forwardEmailMessage exception: $e');
      }
    }
  }

  /// Email mesajını n8n webhook'una gönder ve cevabı JSON olarak geri döndür.
  ///
  /// n8n tarafında "Respond to Webhook" node'u kullanıyorsan ve oradan üretilen
  /// structured çıktıyı uygulamada kullanmak istiyorsan bu metodu kullan.
  Future<Map<String, dynamic>?> forwardEmailMessageAndWait({
    required String userId,
    required int accountId,
    required String messageId,
    required String fromEmail,
    required String? fromName,
    required String subject,
    required String? plainText,
    required String? htmlContent,
    required List<String> toEmails,
    List<String>? ccEmails,
    List<String>? bccEmails,
    required DateTime? receivedDate,
    required bool isRead,
    required String folder,
  }) async {
    if (!isEmailConfigured) {
      if (kDebugMode) {
        debugPrint('N8nForwarderService: n8n email webhook URL boş, email iletilmedi.');
      }
      return null;
    }

    try {
      final uri = Uri.parse(_emailWebhookUrl);
      final bodyData = _prepareEmailBody(
        userId: userId,
        accountId: accountId,
        messageId: messageId,
        fromEmail: fromEmail,
        fromName: fromName,
        subject: subject,
        plainText: plainText,
        htmlContent: htmlContent,
        toEmails: toEmails,
        ccEmails: ccEmails,
        bccEmails: bccEmails,
        receivedDate: receivedDate,
        isRead: isRead,
        folder: folder,
      );
      final body = jsonEncode(bodyData);

      if (kDebugMode) {
        debugPrint('📤 N8nForwarderService.forwardEmailMessageAndWait - URL: $_emailWebhookUrl');
        debugPrint('📤 Request body length: ${body.length}');
      }

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(
        const Duration(seconds: 60), // 60 saniye timeout
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏱️ N8nForwarderService.forwardEmailMessageAndWait - Timeout (60 saniye)');
          }
          throw TimeoutException('n8n webhook timeout (60 saniye)');
        },
      );

      if (kDebugMode) {
        debugPrint('📥 N8nForwarderService.forwardEmailMessageAndWait - Status: ${res.statusCode}');
        debugPrint('📥 Response body length: ${res.body.length}');
        if (res.body.length < 500) {
          debugPrint('📥 Response body: ${res.body}');
        }
      }

      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('❌ N8nForwarderService.forwardEmailMessageAndWait error: ${res.statusCode} ${res.body}');
        }
        return null;
      }

      if (res.body.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ N8nForwarderService.forwardEmailMessageAndWait - Response body boş');
        }
        return null;
      }

      try {
        final decoded = jsonDecode(res.body);
        
        if (kDebugMode) {
          debugPrint('✅ N8nForwarderService.forwardEmailMessageAndWait - Response decoded, type: ${decoded.runtimeType}');
        }
        
        // Eğer response bir array ise, ilk elemanı al
        if (decoded is List && decoded.isNotEmpty) {
          if (decoded[0] is Map<String, dynamic>) {
            return decoded[0] as Map<String, dynamic>;
          }
          // Eğer array içinde başka bir format varsa
          if (kDebugMode) {
            debugPrint('⚠️ N8nForwarderService.forwardEmailMessageAndWait - Array içinde beklenmeyen format: ${decoded[0].runtimeType}');
          }
        }
        
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        
        if (kDebugMode) {
          debugPrint('⚠️ N8nForwarderService.forwardEmailMessageAndWait - Beklenmeyen response format: ${decoded.runtimeType}');
        }
        return null;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ N8nForwarderService.forwardEmailMessageAndWait - JSON decode hatası: $e');
          debugPrint('❌ Response body (ilk 500 karakter): ${res.body.length > 500 ? res.body.substring(0, 500) : res.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('N8nForwarderService.forwardEmailMessageAndWait exception: $e');
      }
      return null;
    }
  }
}


