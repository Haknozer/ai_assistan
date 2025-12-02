import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lokal olarak WhatsApp kişi isimlerini tutan basit servis.
///
/// Map yapısı: { '<phone_number>': 'Görünen İsim' }
class WhatsAppContactsService {
  static const _storageKey = 'whatsapp_contacts';

  /// Tüm kişileri yükle.
  Future<Map<String, String>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  /// Tek bir kişi kaydet / güncelle.
  Future<void> saveContact(String phoneNumber, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadContacts();
    current[phoneNumber] = displayName;
    await prefs.setString(_storageKey, jsonEncode(current));
  }
}
