import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

/// Basit chatbot service - AI asistan mesajlarını n8n webhook'una iletir.
class ChatbotService {
  ChatbotService._internal();
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;

  String get _webhookUrl => AppConfig.chatbotWebhookUrl;

  bool get isConfigured => _webhookUrl.isNotEmpty;

  /// Chat mesajını webhook'a gönderir ve varsa dönen cevabı string olarak verir.
  ///
  /// [latitude] ve [longitude] geolocator'dan gelen değerlerdir. Webhook örneğine
  /// uyum için virgülle ayrılmış string'e çevrilir (37,2 gibi).
  Future<String?> sendChatMessage({
    required String text,
    String? userId,
    double? latitude,
    double? longitude,
    bool returnRawBody = false,
  }) async {
    if (!isConfigured) {
      throw Exception('Chatbot webhook URL tanımlı değil');
    }

    try {
      final uri = Uri.parse(_webhookUrl);
      final body = <String, dynamic>{
        'text': text,
      };
      if (latitude != null) {
        body['lat'] = _formatCoordinate(latitude);
      }
      if (longitude != null) {
        body['lon'] = _formatCoordinate(longitude);
      }
      if (userId != null && userId.isNotEmpty) {
        body['user_id'] = userId;
      }

      final payload = [body];

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Webhook hata döndürdü: ${response.statusCode} ${response.body}');
      }

      if (response.body.isEmpty) return null;
      if (returnRawBody) return response.body;

      final decoded = jsonDecode(response.body);
      if (decoded is String) return decoded;

      // n8n'ün dönebileceği olası formatları yakala
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map<String, dynamic>) {
          final text = _extractTextFromMap(first);
          if (text != null && text.isNotEmpty) return text;
        }
        if (first is String) return first;
      }

      if (decoded is Map<String, dynamic>) {
        return _extractTextFromMap(decoded);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ChatbotService.sendChatMessage exception: $e');
      }
      rethrow;
    }
  }

  String _formatCoordinate(double value) {
    // Örnek payload ile uyumlu olması için nokta yerine virgül kullan
    return value.toStringAsFixed(6).replaceAll('.', ',');
  }

  String? _extractTextFromMap(Map<String, dynamic> data) {
    // Yeni format: { "cevap": "...", "tip": "bot_mesaji" }
    if (data['cevap'] != null) {
      return data['cevap'].toString();
    }

    // OpenAI / PaLM benzeri çıktı: { content: { parts: [{text: ...}], role: ... } }
    final content = data['content'];
    if (content is Map<String, dynamic>) {
      final contentParts = content['parts'];
      if (contentParts is List && contentParts.isNotEmpty) {
        final texts = contentParts
            .map((p) {
              if (p is String) return p;
              if (p is Map<String, dynamic>) {
                final t = p['text'] ?? p['message'] ?? p['content'];
                return t?.toString();
              }
              return null;
            })
            .whereType<String>()
            .where((t) => t.trim().isNotEmpty)
            .toList();
        if (texts.isNotEmpty) {
          return texts.join('\n').trim();
        }
      }
    }

    // Önce olası "parts" dizisinden metinleri topla (n8n/LLM output formatı)
    final parts = data['parts'];
    if (parts is List && parts.isNotEmpty) {
      final texts = parts
          .map((p) {
            if (p is String) return p;
            if (p is Map<String, dynamic>) {
              final t = p['text'] ?? p['message'] ?? p['content'];
              return t?.toString();
            }
            return null;
          })
          .whereType<String>()
          .where((t) => t.trim().isNotEmpty)
          .toList();
      if (texts.isNotEmpty) {
        return texts.join('\n').trim();
      }
    }

    // Yaygın alan adlarını kontrol et
    return (data['text'] ??
            data['message'] ??
            data['response'] ??
            data['content'])
        ?.toString();
  }
}


