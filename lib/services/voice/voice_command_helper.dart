import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ai_asisstan/core/utils/logger.dart';
import 'package:go_router/go_router.dart';
import '../chatbot_service.dart';
import '../../providers/email_account_provider.dart';
import '../../models/email_account.dart';
import '../n8n_response_storage_service.dart';

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
    bool gmailConnected = false,
    bool outlookConnected = false,
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
        gmailConnected: gmailConnected,
        outlookConnected: outlookConnected,
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
          
          // Eğer tip "mailleri_ozetle" ise, filtre objesindeki tarih aralığına göre local email özetlerini çek
          if (type == 'mailleri_ozetle' && map['filtre'] is Map<String, dynamic>) {
            final filtre = map['filtre'] as Map<String, dynamic>;
            final baslangicTarihi = filtre['baslangic_tarihi']?.toString();
            final bitisTarihi = filtre['bitis_tarihi']?.toString();
            
            if (baslangicTarihi != null && bitisTarihi != null) {
              try {
                final startUtc = DateTime.parse(baslangicTarihi).toUtc();
                final endUtc = DateTime.parse(bitisTarihi).toUtc();
                
                AppLogger.debug('Email özeti için tarih aralığı: $startUtc - $endUtc', 'VOICE');
                
                // Local'deki email response'larını çek
                final emailResponses = await N8nResponseStorageService()
                    .getEmailResponsesByDateRange(startUtc: startUtc, endUtc: endUtc);
                
                AppLogger.debug('Bulunan email response sayısı: ${emailResponses.length}', 'VOICE');
                
                // Email response'larını özetle
                if (emailResponses.isNotEmpty) {
                  final summary = _summarizeEmailResponses(emailResponses);
                  // Orijinal cevabın üzerine özeti ekle
                  answer = '$answer\n\n$summary';
                } else {
                  answer = '$answer\n\nBu tarih aralığında kayıtlı email özeti bulunamadı.';
                }
              } catch (e) {
                AppLogger.error('Email özeti çekilirken hata', tag: 'VOICE', error: e);
                // Hata olsa bile orijinal cevabı döndür
              }
            }
          }
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

  /// Email bağlantı durumlarını (gmail/outlook) belirler.
  /// Başarısız olursa konservatif şekilde false/false döner.
  static Future<({bool gmail, bool outlook})> resolveEmailConnections({int? userId}) async {
    try {
      final repo = EmailAccountRepository();
      final accounts = await repo.getEmailAccounts(userId: userId);
      final gmail = accounts.any((a) => a.provider == EmailProvider.gmail);
      final outlook = accounts.any((a) => a.provider == EmailProvider.outlook);
      return (gmail: gmail, outlook: outlook);
    } catch (_) {
      return (gmail: false, outlook: false);
    }
  }

  /// Email response'larını özetleyen metod
  static String _summarizeEmailResponses(List<Map<String, dynamic>> emailResponses) {
    if (emailResponses.isEmpty) {
      return 'Email özeti bulunamadı.';
    }

    final buffer = StringBuffer();
    buffer.writeln('📧 **Email Özeti (${emailResponses.length} adet):**\n');

    for (int i = 0; i < emailResponses.length; i++) {
      final response = emailResponses[i];
      final emailId = response['email_id']?.toString() ?? 'Bilinmeyen';
      final timestamp = response['timestamp']?.toString();
      final data = response['data'] as Map<String, dynamic>?;

      if (data != null) {
        // AI önerilerini çıkar
        final suggestions = N8nResponseStorageService().extractAiSuggestions(data);
        
        if (suggestions != null && suggestions.isNotEmpty) {
          buffer.writeln('${i + 1}. **Email ID: $emailId**');
          if (timestamp != null) {
            try {
              final date = DateTime.parse(timestamp).toLocal();
              buffer.writeln('   Tarih: ${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}');
            } catch (_) {
              buffer.writeln('   Tarih: $timestamp');
            }
          }
          buffer.writeln('   $suggestions');
          buffer.writeln();
        }
      }
    }

    return buffer.toString().trim();
  }
}
