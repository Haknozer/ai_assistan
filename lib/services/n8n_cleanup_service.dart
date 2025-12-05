import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';
import '../presentation/widgets/messages/whatsapp_thread_panel.dart';

/// n8n ile ilgili tüm SharedPreferences verilerini temizleyen servis
class N8nCleanupService {
  N8nCleanupService._internal();
  static final N8nCleanupService _instance = N8nCleanupService._internal();
  factory N8nCleanupService() => _instance;

  // Tüm n8n ile ilgili SharedPreferences key'leri
  static const List<String> _n8nKeys = [
    'n8n_forwarded_email_ids',                    // Forward edilen email ID'leri
    'n8n_forwarded_telegram_message_ids',         // Forward edilen Telegram mesaj ID'leri
    'n8n_forwarded_sent_telegram_messages',       // Forward edilen gönderilen Telegram mesajları
    'n8n_telegram_responses',                     // Telegram n8n response'ları
    'n8n_email_responses',                        // Email n8n response'ları
  ];

  /// Tüm n8n verilerini temizle
  Future<void> clearAllN8nData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      int clearedCount = 0;
      for (final key in _n8nKeys) {
        if (await prefs.remove(key)) {
          clearedCount++;
        }
      }
      
      AppLogger.info('$clearedCount n8n verisi temizlendi', 'N8N');
    } catch (e) {
      AppLogger.error('n8n verileri temizlenirken hata', tag: 'N8N', error: e);
      rethrow;
    }
  }

  /// Sadece forward tracking verilerini temizle (response'ları koru)
  Future<void> clearForwardTracking() async {
    try {
      // WhatsAppThreadPanel'den gönderilen mesajları temizle
      await WhatsAppThreadPanel.clearForwardedSentMessages();
      
      final prefs = await SharedPreferences.getInstance();
      
      final trackingKeys = [
        'n8n_forwarded_email_ids',
        'n8n_forwarded_telegram_message_ids',
      ];
      
      int clearedCount = 0;
      for (final key in trackingKeys) {
        if (await prefs.remove(key)) {
          clearedCount++;
        }
      }
      
      AppLogger.info('${clearedCount + 1} forward tracking verisi temizlendi', 'N8N');
    } catch (e) {
      AppLogger.error('Forward tracking verileri temizlenirken hata', tag: 'N8N', error: e);
      rethrow;
    }
  }

  /// Sadece n8n response'larını temizle (forward tracking'i koru)
  Future<void> clearN8nResponses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final responseKeys = [
        'n8n_telegram_responses',
        'n8n_email_responses',
      ];
      
      int clearedCount = 0;
      for (final key in responseKeys) {
        if (await prefs.remove(key)) {
          clearedCount++;
        }
      }
      
      AppLogger.info('$clearedCount n8n response temizlendi', 'N8N');
    } catch (e) {
      AppLogger.error('n8n response\'lar temizlenirken hata', tag: 'N8N', error: e);
      rethrow;
    }
  }

  /// Temizlenen veri sayısını göster
  Future<Map<String, int>> getN8nDataCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final counts = <String, int>{};
      
      for (final key in _n8nKeys) {
        final value = prefs.getString(key);
        if (value != null && value.isNotEmpty) {
          // JSON array veya object olabilir, basitçe karakter sayısına bakalım
          counts[key] = value.length;
        } else {
          counts[key] = 0;
        }
      }
      
      return counts;
    } catch (e) {
      AppLogger.error('n8n veri sayıları alınırken hata', tag: 'N8N', error: e);
      return {};
    }
  }
}

