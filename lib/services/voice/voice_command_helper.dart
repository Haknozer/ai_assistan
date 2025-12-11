import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ai_asisstan/core/utils/logger.dart';
import 'package:go_router/go_router.dart';
import '../chatbot_service.dart';

/// Sesli komutları işleyen ve gerekli navigasyon/API çağrılarını yöneten yardımcı sınıf.
/// Bu sınıf sayesinde AIAssistantScreen, GlobalHotkeys ve SideMenu aynı mantığı kullanır.
class VoiceCommandHelper {
  /// Komutu işler: API'ye gönderir, cevabı parse eder, navigasyon varsa yapar,
  /// ve TTS için okunacak metni döndürür.
  static Future<String?> processVoiceCommand({
    required BuildContext context,
    required String text,
    required String userId,
    double? latitude,
    double? longitude,
  }) async {
    if (text.trim().isEmpty) return null;

    try {
      // 1. Chatbot API'ye gönder
      final responseText = await ChatbotService().sendChatMessage(
        text: text,
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        returnRawBody: true,
      );

      if (responseText == null || responseText.isEmpty) {
        return null;
      }

      // 2. Yanıtı Parse Et (JSON mu düz metin mi?)
      String? answer;
      String? route;
      String? type;

      try {
        final decoded = jsonDecode(responseText);
        Map<String, dynamic>? map;
        
        if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
          map = decoded.first as Map<String, dynamic>;
        } else if (decoded is Map<String, dynamic>) {
          map = decoded;
        }

        if (map != null) {
          // Olası cevap alanlarını kontrol et
          answer = (map['cevap'] ?? 
                    map['text'] ?? 
                    map['message'] ?? 
                    map['response'] ?? 
                    map['content'] ?? 
                    responseText).toString();
          
          type = map['tip']?.toString();
          route = map['rota']?.toString();
        } else {
          // JSON ama beklediğimiz yapıda değilse (örn. string listesi)
          answer = responseText;
        }
      } catch (e) {
        // JSON değil, düz metin
        answer = responseText;
      }

      // 3. Navigasyon varsa gerçekleştir
      if (type == 'navigasyon' && route != null && route.isNotEmpty) {
        // UI render cycle'ı çakışmasın diye postFrameCallback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            AppLogger.info('Navigating to $route', 'VOICE');
            GoRouter.of(context).go(route!);
          }
        });
      }

      // 4. TTS için cevabı döndür
      return answer;

    } catch (e, st) {
      AppLogger.error('VoiceCommandHelper Error', error: e, stackTrace: st, tag: 'VOICE');
      return 'Bir hata oluştu, lütfen tekrar deneyin.';
    }
  }
}
