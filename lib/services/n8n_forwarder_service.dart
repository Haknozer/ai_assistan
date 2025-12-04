import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

/// Telegram'dan gelen mesajları n8n'e forward eden basit servis.
class N8nForwarderService {
  N8nForwarderService._internal();
  static final N8nForwarderService _instance = N8nForwarderService._internal();
  factory N8nForwarderService() => _instance;

  String get _webhookUrl => AppConfig.n8nTelegramWebhookUrl;

  bool get isConfigured => _webhookUrl.isNotEmpty;

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
      final uri = Uri.parse(_webhookUrl);
      final body = jsonEncode({
        'user_id': userId,
        'chat_id': chatId,
        'sender_name': senderName,
        'text': text,
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
      final uri = Uri.parse(_webhookUrl);
      final body = jsonEncode({
        'user_id': userId,
        'chat_id': chatId,
        'sender_name': senderName,
        'text': text,
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
}


