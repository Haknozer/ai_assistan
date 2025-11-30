import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_asisstan/core/api/api_exceptions.dart';

/// Gmail kullanıcı bilgileri helper
class GmailUserInfo {
  /// Kullanıcı bilgilerini al
  static Future<Map<String, dynamic>> getUserInfo(String accessToken) async {
    final userInfoUrl = Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo');

    final response = await http.get(
      userInfoUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        message: 'Kullanıcı bilgileri alınamadı: ${response.body}',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }
}

