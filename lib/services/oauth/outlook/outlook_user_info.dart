import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_asisstan/core/api/api_exceptions.dart';

/// Outlook kullanıcı bilgileri helper
class OutlookUserInfo {
  /// Kullanıcı bilgilerini al
  static Future<Map<String, dynamic>> getUserInfo(String accessToken) async {
    final userInfoUrl = Uri.parse('https://graph.microsoft.com/v1.0/me');

    final response = await http.get(
      userInfoUrl,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(
        message: 'Kullanıcı bilgileri alınamadı: ${response.body}',
        originalError: response.body,
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

