import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/logger.dart';

/// Forward edilen (gönderilen) mesajları kalıcı olarak takip eder.
class ForwardedSentStore {
  ForwardedSentStore({Future<SharedPreferences>? prefs}) : _prefs = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;
  static const String _key = 'n8n_forwarded_sent_telegram_messages';

  /// Kayıtlı mesajları yükle ve Set olarak döndür.
  Future<Set<String>> load() async {
    try {
      final p = await _prefs;
      final jsonString = p.getString(_key);
      if (jsonString == null || jsonString.isEmpty) return <String>{};
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e.toString()).toSet();
    } catch (e) {
      AppLogger.error('Forward edilen gönderilen mesajlar yüklenemedi', tag: 'N8N', error: e);
      return <String>{};
    }
  }

  /// Set'i kaydet.
  Future<void> save(Set<String> values) async {
    try {
      final p = await _prefs;
      final jsonString = jsonEncode(values.toList());
      await p.setString(_key, jsonString);
    } catch (e) {
      AppLogger.error('Forward edilen gönderilen mesajlar kaydedilemedi', tag: 'N8N', error: e);
    }
  }
}

