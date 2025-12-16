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
  String get _emailSummaryWebhookUrl => AppConfig.n8nEmailSummaryWebhookUrl;

  bool get isConfigured => _telegramWebhookUrl.isNotEmpty;
  bool get isEmailConfigured => _emailWebhookUrl.isNotEmpty;
  bool get isEmailSummaryConfigured => _emailSummaryWebhookUrl.isNotEmpty;

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
        textContent = htmlContent.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
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
  ///
  /// Sesli mail özeti için ayrı bir webhook:
  /// Body:
  /// {
  ///   "emails": [...],   // lokalde saklanan emailResponses listesi
  ///   "komut": "kullanıcının söylediği/orijinal komut metni"
  /// }
  ///
  /// n8n tarafı iki formatta cevap dönebilir:
  /// 1) Düz JSON:
  ///    { "okunacak_metin": "..." }
  /// 2) Gemini formatı array:
  ///    [
  ///      {
  ///        "content": {
  ///          "parts": [ { "text": "```json\n{\"okunacak_metin\":\"...\"}\n```" } ],
  ///          "role": "model"
  ///        },
  ///        "finishReason": "STOP",
  ///        "index": 0
  ///      }
  ///    ]
  Future<String?> getEmailSummaryForVoice(
    List<Map<String, dynamic>> emailResponses, {
    required String commandText,
  }) async {
    if (!isEmailSummaryConfigured) {
      if (kDebugMode) {
        debugPrint('N8nForwarderService: n8n email summary webhook URL boş, özet istenmedi.');
      }
      return null;
    }

    try {
      final uri = Uri.parse(_emailSummaryWebhookUrl);
      final body = jsonEncode({
        'emails': emailResponses,
        'komut': commandText,
      });

      if (kDebugMode) {
        debugPrint('📤 N8nForwarderService.getEmailSummaryForVoice - URL: $_emailSummaryWebhookUrl');
        debugPrint('📤 Request body length: ${body.length}');
      }

      final res = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      )
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏱️ N8nForwarderService.getEmailSummaryForVoice - Timeout (60 saniye)');
          }
          throw TimeoutException('n8n email summary webhook timeout (60 saniye)');
        },
      );

      if (kDebugMode) {
        debugPrint('📥 N8nForwarderService.getEmailSummaryForVoice - Status: ${res.statusCode}');
        debugPrint('📥 Response body length: ${res.body.length}');
        if (res.body.length < 500) {
          debugPrint('📥 Response body: ${res.body}');
        }
      }

      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('❌ N8nForwarderService.getEmailSummaryForVoice error: ${res.statusCode} ${res.body}');
        }
        return null;
      }

      if (res.body.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ N8nForwarderService.getEmailSummaryForVoice - Response body boş');
        }
        return null;
      }
      final decoded = jsonDecode(res.body);

      // 1) Düz JSON ise: { "okunacak_metin": "..." }
      if (decoded is Map<String, dynamic>) {
        final text = decoded['okunacak_metin']?.toString().trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
        return null;
      }

      // 2) Array formatı ise:
      //    En basit ve tercih edilen format:
      //    [
      //      { "okunacak_metin": "..." }
      //    ]
      //
      //    Eski / alternatif formatlar (temiz_veriler, Gemini) yine destekleniyor
      //    ama önce düz "okunacak_metin" aranacak.
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map<String, dynamic>) {
          // a) Düz okunacak_metin alanı
          final directText = first['okunacak_metin']?.toString().trim();
          if (directText != null && directText.isNotEmpty) {
            return directText;
          }

          // b) temiz_veriler formatını yakala (geri uyumluluk)
          if (first['temiz_veriler'] != null) {
            final rawCleanData = first['temiz_veriler']?.toString();
            if (rawCleanData != null && rawCleanData.isNotEmpty) {
              try {
                final mails = jsonDecode(rawCleanData);
                if (mails is List && mails.isNotEmpty) {
                  // Son iki maili al
                  final lastTwo = mails.length <= 2 ? mails : mails.sublist(mails.length - 2);
                  final parts = <String>[];
                  for (final item in lastTwo) {
                    if (item is Map<String, dynamic>) {
                      final konu = item['konu']?.toString().trim();
                      final ozet = item['ozet']?.toString().trim();
                      if (ozet != null && ozet.isNotEmpty) {
                        // Konu varsa başa ekleyelim
                        parts.add(konu != null && konu.isNotEmpty ? '$konu:\n$ozet' : ozet);
                      }
                    }
                  }
                  final combined = parts.join('\n\n').trim();
                  if (combined.isNotEmpty) {
                    return combined;
                  }
                }
              } catch (_) {
                // temiz_veriler JSON parse edilemezse sessizce Gemini formatına düş
              }
            }
          }

          // c) Gemini formatı (geri uyumluluk)
          final content = first['content'];
          if (content is Map<String, dynamic>) {
            final parts = content['parts'];
            if (parts is List && parts.isNotEmpty) {
              final firstPart = parts.first;
              if (firstPart is Map<String, dynamic>) {
                final rawText = firstPart['text']?.toString();
                if (rawText != null && rawText.isNotEmpty) {
                  // ```json ... ``` code fence'lerini temizle ve içteki JSON'u parse et
                  String cleaned = rawText.trim();

                  // Başındaki ```json / ``` bloklarını kaldır
                  if (cleaned.startsWith('```')) {
                    // İlk satırı (``` veya ```json) at
                    final firstNewline = cleaned.indexOf('\n');
                    if (firstNewline != -1) {
                      cleaned = cleaned.substring(firstNewline + 1);
                    }
                    // Sondaki ``` blokunu kaldır
                    final lastFence = cleaned.lastIndexOf('```');
                    if (lastFence != -1) {
                      cleaned = cleaned.substring(0, lastFence);
                    }
                  }

                  cleaned = cleaned.trim();

                  try {
                    final inner = jsonDecode(cleaned);
                    if (inner is Map<String, dynamic>) {
                      final textFromJson = inner['okunacak_metin']?.toString().trim();
                      if (textFromJson != null && textFromJson.isNotEmpty) {
                        return textFromJson;
                      }
                    }
                  } catch (_) {
                    // İç JSON bozuksa regex ile "okunacak_metin" alanını yakalamayı dene
                    final regex = RegExp(r'"okunacak_metin"\s*:\s*"([\s\S]*?)"');
                    final match = regex.firstMatch(cleaned);
                    if (match != null && match.groupCount >= 1) {
                      var captured = match.group(1) ?? '';
                      // Kaçış karakterlerini basitleştir
                      captured = captured.replaceAll(r'\"', '"').replaceAll(r'\n', '\n');
                      final trimmed = captured.trim();
                      if (trimmed.isNotEmpty) {
                        return trimmed;
                      }
                    }
                    // Hiçbir şey yakalayamazsak ham metni döndürmek yerine null dön,
                    // böylece lokal fallback devreye girer.
                    return null;
                  }
                }
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('N8nForwarderService.getEmailSummaryForVoice exception: $e');
      }
      return null;
    }
  }

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

      final res = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      )
          .timeout(
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
          debugPrint(
              '✅ N8nForwarderService.forwardEmailMessageAndWait - Response decoded, type: ${decoded.runtimeType}');
        }

        // Eğer response bir array ise, ilk elemanı al
        if (decoded is List && decoded.isNotEmpty) {
          if (decoded[0] is Map<String, dynamic>) {
            return decoded[0] as Map<String, dynamic>;
          }
          // Eğer array içinde başka bir format varsa
          if (kDebugMode) {
            debugPrint(
                '⚠️ N8nForwarderService.forwardEmailMessageAndWait - Array içinde beklenmeyen format: ${decoded[0].runtimeType}');
          }
        }

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        if (kDebugMode) {
          debugPrint(
              '⚠️ N8nForwarderService.forwardEmailMessageAndWait - Beklenmeyen response format: ${decoded.runtimeType}');
        }
        return null;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ N8nForwarderService.forwardEmailMessageAndWait - JSON decode hatası: $e');
          debugPrint(
              '❌ Response body (ilk 500 karakter): ${res.body.length > 500 ? res.body.substring(0, 500) : res.body}');
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
