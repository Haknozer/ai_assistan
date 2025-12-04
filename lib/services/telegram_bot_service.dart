import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';

/// Telegram Bot API servis katmanı
///
/// Uygulama, Telegram'dan mesajları Bot API ile alır (getUpdates),
/// sonra bu ham JSON update'leri UI'ye ve/veya n8n'e iletir.
class TelegramBotService {
  TelegramBotService._internal() {
    _loadLastUpdateId();
  }
  static final TelegramBotService _instance = TelegramBotService._internal();
  factory TelegramBotService() => _instance;

  static const String _baseUrl = 'https://api.telegram.org';
  static const String _lastUpdateIdKey = 'telegram_last_update_id';

  int _lastUpdateId = 0;
  Timer? _pollTimer;

  final _updatesController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get updatesStream => _updatesController.stream;

  String get _token => AppConfig.telegramBotToken;
  bool get isConfigured => _token.isNotEmpty;

  /// Son update ID'yi SharedPreferences'ten yükle
  Future<void> _loadLastUpdateId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastUpdateId = prefs.getInt(_lastUpdateIdKey) ?? 0;
    } catch (e) {
      // Sessizce yut
    }
  }

  /// Son update ID'yi SharedPreferences'e kaydet
  Future<void> _saveLastUpdateId(int updateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateIdKey, updateId);
    } catch (e) {
      // Sessizce yut
    }
  }

  Uri _buildUri(String method) {
    return Uri.parse('$_baseUrl/bot$_token/$method');
  }

  Future<void> _fetchUpdates() async {
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint('TelegramBotService: Bot token boş, getUpdates çağrılmadı.');
      }
      return;
    }

    try {
      // Son update ID'yi yükle (eğer henüz yüklenmediyse)
      await _loadLastUpdateId();
      
      final offset = _lastUpdateId + 1;
      final uri = _buildUri('getUpdates').replace(queryParameters: {
        'offset': offset.toString(),
        'timeout': '0',
      });

      final res = await http.get(uri);
      if (res.statusCode != 200) {
        // 409: "Conflict: terminated by other getUpdates request" uyarısını
        // üretmesin diye özel olarak sessizce yutuyoruz.
        if (res.statusCode == 409) {
          return;
        }
        if (kDebugMode) {
          debugPrint('TelegramBotService.getUpdates error: ${res.statusCode} ${res.body}');
        }
        return;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return;

      if (decoded['ok'] != true || decoded['result'] is! List) return;

      final List<dynamic> results = decoded['result'];
      for (final dynamic item in results) {
        if (item is! Map<String, dynamic>) continue;
        final updateId = item['update_id'] as int?;
        if (updateId != null && updateId > _lastUpdateId) {
          _lastUpdateId = updateId;
          // Her yeni update ID geldiğinde kaydet
          _saveLastUpdateId(_lastUpdateId);
        }
        if (!_updatesController.isClosed) {
          _updatesController.add(item);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TelegramBotService.getUpdates exception: $e');
      }
    }
  }

  /// Bekleyen update'leri bir kez çek (entegrasyon açıldığında kuyruktaki mesajları almak için)
  Future<void> fetchPendingUpdates() async {
    // Önce son update ID'yi yükle (eğer henüz yüklenmediyse)
    await _loadLastUpdateId();
    await _fetchUpdates();
  }

  /// Periyodik polling başlat.
  void startPolling({Duration interval = const Duration(seconds: 2)}) {
    if (_pollTimer != null) return;
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint('TelegramBotService: Bot token boş, polling başlatılmadı.');
      }
      return;
    }

    _pollTimer = Timer.periodic(interval, (_) {
      _fetchUpdates();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> dispose() async {
    stopPolling();
    await _updatesController.close();
  }

  /// Belirli bir chat'e mesaj gönder (sendMessage)
  Future<void> sendMessage({
    required int chatId,
    required String text,
  }) async {
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint('TelegramBotService.sendMessage: Bot token boş, mesaj gönderilmedi.');
      }
      return;
    }

    try {
      final uri = _buildUri('sendMessage');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': text,
        }),
      );

      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('TelegramBotService.sendMessage error: ${res.statusCode} ${res.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TelegramBotService.sendMessage exception: $e');
      }
    }
  }
}


