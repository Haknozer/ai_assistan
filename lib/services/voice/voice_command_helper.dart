import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ai_asisstan/core/utils/logger.dart';
import 'package:go_router/go_router.dart';
import '../chatbot_service.dart';
import '../../providers/email_account_provider.dart';
import '../../models/email_account.dart';
import '../n8n_response_storage_service.dart';
import '../n8n_forwarder_service.dart';

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
          type = map['tip']?.toString();
          route = map['rota']?.toString();

          // ÖZEL DURUM: "mailleri_ozetle" için chatbot'un 'cevap' metnini
          // TTS'te KULLANMIYORUZ. Sadece tarih filtresine göre local mailleri
          // bulup, email summary webhook'undan dönen okunacak_metin'i okuyoruz.
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
                final emailResponses =
                    await N8nResponseStorageService().getEmailResponsesByDateRange(startUtc: startUtc, endUtc: endUtc);

                AppLogger.debug('Bulunan email response sayısı: ${emailResponses.length}', 'VOICE');

                if (emailResponses.isNotEmpty) {
                  // Yeni: Email response listesini ve kullanıcının orijinal komutunu
                  // n8n voice summary webhook'una gönder
                  final summaryText = await N8nForwarderService().getEmailSummaryForVoice(
                    emailResponses,
                    commandText: text,
                  );

                  // ÖNEMLİ: Kullanıcının isteği gereği, sadece webhook'tan dönen
                  // okunacak_metin kullanılacak. Lokal fallback ÖZETLER
                  // (sesli_okuma / extractAiSuggestions) HİÇBİR ZAMAN okunmayacak.
                  if (summaryText != null && summaryText.isNotEmpty) {
                    answer = summaryText;
                  } else {
                    answer = 'Email özeti getirilemedi.';
                  }
                } else {
                  answer = 'Bu tarih aralığında kayıtlı email bulunamadı.';
                }
              } catch (e) {
                AppLogger.error('Email özeti çekilirken hata', tag: 'VOICE', error: e);
                // Hata olsa bile chatbot'un 'cevap' metnini okumak istemiyoruz;
                // bunun yerine genel bir hata mesajı dön.
                answer = 'Email özetlenirken bir hata oluştu.';
              }
            }

            // "mailleri_ozetle" tipi için burada özel akış tamam; altta
            // generic cevap extraction'a girmesin diye buradan devam ederiz.
          } else {
            // Diğer tüm tipler için: chatbot'un cevabını kullan
            // Olası cevap alanlarını kontrol et
            answer =
                (map['cevap'] ?? map['text'] ?? map['message'] ?? map['response'] ?? map['content'] ?? responseText)
                    .toString();
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
}
