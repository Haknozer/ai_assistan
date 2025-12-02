import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// WhatsApp ile mesaj göndermek için Supabase Edge Function kullanan servis.
///
/// Güvenlik gereği, WhatsApp Cloud API access token'ı sadece backend tarafında tutulur.
/// Bu servis yalnızca Supabase Edge Function'larına istek atar.
class WhatsAppService {
  WhatsAppService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Supabase Edge Function ismi
  static const String _sendFunctionName = 'send-message';

  /// Kullanıcı adına WhatsApp üzerinden hızlı mesaj gönder.
  ///
  /// [toNumber] : Ülke kodu dahil alıcı numarası (ör: 905xxxxxxxxx)
  /// [body]     : Mesaj içeriği
  /// [store]    : Backend'e, mümkünse bu mesajı kalıcı olarak saklayıp saklamamasını öneren bayrak.
  ///              Gerçek davranış, backend implementasyonuna bağlıdır.
  Future<void> sendMessage({
    required String toNumber,
    required String body,
    bool store = false,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        _sendFunctionName,
        body: jsonEncode({
          'to': toNumber,
          'message': body,
          'store': store,
        }),
      );

      if (response.status != 200) {
        throw Exception(
          'WhatsApp mesajı gönderilemedi (status: ${response.status}): ${response.data}',
        );
      }

      if (kDebugMode) {
        debugPrint('WhatsApp mesajı gönderildi: $toNumber');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WhatsAppService.sendMessage hata: $e');
      }
      rethrow;
    }
  }
}


