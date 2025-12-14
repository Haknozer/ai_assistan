import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

/// n8n'den dönen AI önerilerini saklayan ve yöneten servis
class N8nResponseStorageService {
  N8nResponseStorageService._internal();
  static final N8nResponseStorageService _instance = N8nResponseStorageService._internal();
  factory N8nResponseStorageService() => _instance;

  static const String _telegramResponsesKey = 'n8n_telegram_responses';
  static const String _emailResponsesKey = 'n8n_email_responses';

  /// Telegram mesajı için n8n response'u kaydet
  Future<void> saveTelegramResponse(String messageId, Map<String, dynamic>? response) async {
    if (messageId.isEmpty || response == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString(_telegramResponsesKey);
      final Map<String, dynamic> responses = existingJson != null && existingJson.isNotEmpty
          ? jsonDecode(existingJson) as Map<String, dynamic>
          : {};

      responses[messageId] = response;
      await prefs.setString(_telegramResponsesKey, jsonEncode(responses));
      
      AppLogger.debug('Telegram mesaj $messageId için n8n response kaydedildi', 'N8N');
    } catch (e) {
      AppLogger.error('Telegram n8n response kaydedilirken hata', tag: 'N8N', error: e);
    }
  }

  /// Email için n8n response'u kaydet
  Future<void> saveEmailResponse(
    String emailId,
    Map<String, dynamic>? response, {
    DateTime? receivedDate,
  }) async {
    if (emailId.isEmpty || response == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString(_emailResponsesKey);
      final Map<String, dynamic> responses = existingJson != null && existingJson.isNotEmpty
          ? jsonDecode(existingJson) as Map<String, dynamic>
          : {};

      responses[emailId] = {
        'data': response,
        'timestamp': (receivedDate ?? DateTime.now()).toUtc().toIso8601String(),
      };
      await prefs.setString(_emailResponsesKey, jsonEncode(responses));
      
      AppLogger.debug('Email $emailId için n8n response kaydedildi', 'N8N');
    } catch (e) {
      AppLogger.error('Email n8n response kaydedilirken hata', tag: 'N8N', error: e);
    }
  }

  /// Telegram mesajı için n8n response'u getir
  Future<Map<String, dynamic>?> getTelegramResponse(String messageId) async {
    if (messageId.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_telegramResponsesKey);
      if (jsonString == null || jsonString.isEmpty) return null;

      final responses = jsonDecode(jsonString) as Map<String, dynamic>;
      final response = responses[messageId];
      
      // Eğer response string ise, parse et
      if (response is String) {
        try {
          return jsonDecode(response) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      
      return response as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.error('Telegram n8n response yüklenirken hata', tag: 'N8N', error: e);
      return null;
    }
  }

  /// Email için n8n response'u getir
  Future<Map<String, dynamic>?> getEmailResponse(String emailId) async {
    if (emailId.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_emailResponsesKey);
      if (jsonString == null || jsonString.isEmpty) return null;

      final responses = jsonDecode(jsonString) as Map<String, dynamic>;
      final stored = responses[emailId];

      if (stored is Map<String, dynamic>) {
        // Yeni format: { data: {...}, timestamp: ... }
        if (stored.containsKey('data')) {
          final data = stored['data'];
          // Eğer data bir array ise, direkt array olarak döndür (parse işlemi widget'ta yapılacak)
          if (data is List) {
            AppLogger.debug('getEmailResponse - Data bir array, direkt döndürülüyor', 'N8N');
            return {'_isArray': true, '_arrayData': data};
          }
          if (data is Map<String, dynamic>) return data;
          if (data is String) {
            try {
              final decoded = jsonDecode(data);
              // Eğer decode edilen bir array ise
              if (decoded is List) {
                AppLogger.debug('getEmailResponse - Decoded data bir array, direkt döndürülüyor', 'N8N');
                return {'_isArray': true, '_arrayData': decoded};
              }
              // Eğer decode edilen bir map ise
              if (decoded is Map<String, dynamic>) {
                return decoded;
              }
            } catch (_) {
              return null;
            }
          }
        }
        // Eski format veya fallback
        return stored;
      }

      // Eski string format
      if (stored is String) {
        try {
          return jsonDecode(stored) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('Email n8n response yüklenirken hata', tag: 'N8N', error: e);
      return null;
    }
  }

  /// Belirli tarih aralığındaki (UTC) email response'larını getir
  Future<List<Map<String, dynamic>>> getEmailResponsesByDateRange({
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_emailResponsesKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final responses = jsonDecode(jsonString) as Map<String, dynamic>;
      final List<Map<String, dynamic>> result = [];

      for (final entry in responses.entries) {
        final value = entry.value;
        DateTime? ts;
        Map<String, dynamic>? data;

        if (value is Map<String, dynamic>) {
          final tsStr = value['timestamp']?.toString();
          if (tsStr != null && tsStr.isNotEmpty) {
            try {
              ts = DateTime.parse(tsStr).toUtc();
            } catch (_) {}
          }
          if (value.containsKey('data')) {
            final raw = value['data'];
            if (raw is Map<String, dynamic>) {
              data = raw;
            } else if (raw is String) {
              try {
                data = jsonDecode(raw) as Map<String, dynamic>;
              } catch (_) {}
            }
          } else {
            data = value;
          }
        } else if (value is String) {
          try {
            data = jsonDecode(value) as Map<String, dynamic>;
          } catch (_) {}
        }

        ts ??= DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        data ??= {};

        if (ts.isAfter(startUtc.subtract(const Duration(microseconds: 1))) &&
            ts.isBefore(endUtc.add(const Duration(microseconds: 1)))) {
          result.add({
            'email_id': entry.key,
            'timestamp': ts.toIso8601String(),
            'data': data,
          });
        }
      }

      return result;
    } catch (e) {
      AppLogger.error('Email response tarih filtresi hatası', tag: 'N8N', error: e);
      return [];
    }
  }

  /// n8n response'dan AI önerilerini çıkar (sadece text formatında)
  String? extractAiSuggestions(Map<String, dynamic>? response) {
    if (response == null) return null;

    // Debug: Response formatını logla
    AppLogger.debug('extractAiSuggestions - Response: $response', 'N8N');
    AppLogger.debug('extractAiSuggestions - Response type: ${response.runtimeType}', 'N8N');
    AppLogger.debug('extractAiSuggestions - Response keys: ${response.keys.toList()}', 'N8N');

    // n8n'den gelen cevap formatı (en yaygın format: {cevap: "...", tip: "...", islem_ozeti: {...}})
    if (response.containsKey('cevap')) {
      final cevapValue = response['cevap'];
      if (cevapValue != null) {
        final cevap = cevapValue.toString().trim();
        if (cevap.isNotEmpty) {
          AppLogger.debug('extractAiSuggestions - Found cevap: $cevap', 'N8N');
          // Cevap içeriğini formatla - sadece önemli kısımları göster
          final formatted = _formatCevapForDisplay(cevap);
          if (formatted != null && formatted.isNotEmpty) {
            return formatted;
          }
          return cevap;
        }
      }
    }

    // Özel görev formatı (ör: {mesaj, detay, gorev_adi, tarih, linkler, durum})
    final taskMessage = response['mesaj']?.toString().trim();
    final taskDetail = response['detay']?.toString().trim();
    final taskName = response['gorev_adi']?.toString().trim();
    final taskDate = response['tarih']?.toString().trim();
    final status = response['durum']?.toString().trim();
    String? taskLinks;
    if (response['linkler'] is Map) {
      final map = (response['linkler'] as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      final nonEmpty = map.entries.where((e) => e.value.trim().isNotEmpty).toList();
      if (nonEmpty.isNotEmpty) {
        taskLinks = nonEmpty.map((e) => '${e.key}: ${e.value}').join(' | ');
      }
    }
    final taskLines = <String>[];
    if (status?.isNotEmpty == true) taskLines.add('Durum: $status');
    if (taskName?.isNotEmpty == true) taskLines.add('Görev: $taskName');
    if (taskMessage?.isNotEmpty == true) taskLines.add(taskMessage!);
    if (taskDetail?.isNotEmpty == true) taskLines.add(taskDetail!);
    if (taskDate?.isNotEmpty == true) taskLines.add('Tarih: $taskDate');
    if (taskLinks?.isNotEmpty == true) taskLines.add(taskLinks!);
    if (taskLines.isNotEmpty) {
      return taskLines.join('\n');
    }

    // Eğer response bir array içinde geliyorsa (n8n webhook response formatı)
    // Örnek: [{parts: [{text: "..."}], role: "model"}]
    if (response.containsKey('body') && response['body'] is List) {
      final bodyList = response['body'] as List;
      if (bodyList.isNotEmpty && bodyList[0] is Map<String, dynamic>) {
        AppLogger.debug('extractAiSuggestions - Found body array, extracting first element', 'N8N');
        return extractAiSuggestions(bodyList[0] as Map<String, dynamic>);
      }
    }

    // Gemini API formatı: {content: {parts: [{text: "..."}], role: "model"}}
    // Önce content içindeki parts'i kontrol et
    if (response.containsKey('content')) {
      final content = response['content'];
      if (content is Map<String, dynamic>) {
        AppLogger.debug('extractAiSuggestions - Found content, extracting from content', 'N8N');
        return extractAiSuggestions(content);
      }
    }

    // Gemini API formatı: {parts: [{text: "..."}], role: "model"}
    // Öncelikle parts içindeki text'i ara
    if (response.containsKey('parts')) {
      final parts = response['parts'];
      AppLogger.debug('extractAiSuggestions - Found parts: $parts', 'N8N');
      
      if (parts is List && parts.isNotEmpty) {
        for (final part in parts) {
          AppLogger.debug('extractAiSuggestions - Processing part: $part', 'N8N');
          
          if (part is Map<String, dynamic>) {
            if (part.containsKey('text')) {
              final textValue = part['text'];
              AppLogger.debug('extractAiSuggestions - Found text: $textValue', 'N8N');
              
              if (textValue != null) {
                final text = textValue.toString().trim();
                if (text.isNotEmpty) {
                  AppLogger.debug('extractAiSuggestions - Returning text: $text', 'N8N');
                  return text;
                }
              }
            }
          } else if (part is String) {
            // Eğer part direkt string ise
            final text = part.trim();
            if (text.isNotEmpty) {
              AppLogger.debug('extractAiSuggestions - Returning string part: $text', 'N8N');
              return text;
            }
          }
        }
      }
    }

    // Eğer response'un kendisi bir array içinde geliyorsa (n8n webhook response formatı)
    // Örnek: [{parts: [{text: "..."}], role: "model"}]
    if (response.containsKey('body')) {
      final body = response['body'];
      if (body is Map<String, dynamic>) {
        return extractAiSuggestions(body);
      }
    }

    // Direkt text alanı varsa
    if (response.containsKey('text')) {
      final textValue = response['text'];
      if (textValue != null) {
        final text = textValue.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    // Content alanı varsa
    if (response.containsKey('content')) {
      final contentValue = response['content'];
      if (contentValue != null) {
        final content = contentValue.toString().trim();
        if (content.isNotEmpty) {
          return content;
        }
      }
    }

    // Message alanı varsa
    if (response.containsKey('message')) {
      final messageValue = response['message'];
      if (messageValue != null) {
        final message = messageValue.toString().trim();
        if (message.isNotEmpty) {
          return message;
        }
      }
    }

    // Suggestions array varsa
    if (response.containsKey('suggestions')) {
      final suggestions = response['suggestions'];
      if (suggestions is List) {
        final result = suggestions
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .join('\n');
        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    // Eğer direkt string ise
    if (response.length == 1 && response.values.first is String) {
      final value = response.values.first.toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    // Text bulunamadı, null döndür (JSON gösterme)
    return null;
  }

  /// Cevap içeriğini formatla - sadece önemli kısımları göster
  String? _formatCevapForDisplay(String cevap) {
    if (cevap.isEmpty) return null;
    // Basit hal - direkt cevabı döndür
    return cevap;
  }

  /// Tüm Telegram n8n response'larını temizle
  Future<void> clearAllTelegramResponses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_telegramResponsesKey);
      AppLogger.info('Tüm Telegram n8n response\'ları temizlendi', 'N8N');
    } catch (e) {
      AppLogger.error('Telegram n8n response\'ları temizlenirken hata', tag: 'N8N', error: e);
    }
  }

  /// Tüm Email n8n response'larını temizle
  Future<void> clearAllEmailResponses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailResponsesKey);
      AppLogger.info('Tüm Email n8n response\'ları temizlendi', 'N8N');
    } catch (e) {
      AppLogger.error('Email n8n response\'ları temizlenirken hata', tag: 'N8N', error: e);
    }
  }

  /// Tüm n8n response'larını temizle (Telegram + Email)
  Future<void> clearAllResponses() async {
    await Future.wait([
      clearAllTelegramResponses(),
      clearAllEmailResponses(),
    ]);
  }
}

