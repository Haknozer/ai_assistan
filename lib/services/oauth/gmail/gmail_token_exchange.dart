import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ai_asisstan/core/api/api_exceptions.dart';

/// Gmail OAuth token exchange helper
class GmailTokenExchange {
  final String? _clientId;
  final String? _clientSecret;

  GmailTokenExchange({
    required String? clientId,
    required String? clientSecret,
  })  : _clientId = clientId,
        _clientSecret = clientSecret;

  /// Authorization code'u access token'a çevir
  Future<Map<String, dynamic>> exchangeCodeForTokens(String code, String redirectUri) async {
    if (_clientSecret == null || _clientSecret!.isEmpty) {
      throw ApiException(
        message:
            'Client Secret eksik. Lütfen Google Cloud Console\'dan Client Secret alıp environment variable olarak ekleyin.',
      );
    }

    final tokenUrl = Uri.parse('https://oauth2.googleapis.com/token');

    debugPrint('Token exchange başlatılıyor:');
    debugPrint('  Client ID: $_clientId');
    debugPrint('  Redirect URI: $redirectUri');
    debugPrint('  Client Secret: ${_clientSecret!.substring(0, 6)}... (ilk 6 karakter)');

    final response = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': _clientId!,
        'client_secret': _clientSecret!,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    debugPrint('Token exchange yanıtı: Status=${response.statusCode}');
    debugPrint('Token exchange body: ${response.body}');

    if (response.statusCode != 200) {
      final errorBody = response.body;
      String errorMessage = 'Token alınamadı: $errorBody';

      if (errorBody.contains('invalid_client')) {
        errorMessage =
            'Client ID veya Client Secret yanlış. Lütfen Google Cloud Console\'daki değerlerle eşleştiğinden emin olun. Ayrıca OAuth Client ID tipinin "Web application" olduğundan emin olun.';
      } else if (errorBody.contains('invalid_grant')) {
        errorMessage = 'Authorization code geçersiz veya süresi dolmuş. Lütfen tekrar deneyin.';
      } else if (errorBody.contains('redirect_uri_mismatch')) {
        errorMessage =
            'Redirect URI eşleşmiyor. Google Cloud Console\'da şu redirect URI\'leri eklemeniz gerekiyor:\n\n'
            '1. http://localhost:8080/oauth-callback\n'
            '2. http://localhost:8081/oauth-callback\n'
            '3. http://localhost:8082/oauth-callback\n'
            '4. http://localhost:8083/oauth-callback\n'
            '5. http://localhost:3000/oauth-callback\n'
            '6. http://localhost:3001/oauth-callback\n\n'
            'Google Cloud Console > APIs & Services > Credentials > OAuth 2.0 Client ID > Authorized redirect URIs';
      }

      throw ApiException(
        message: errorMessage,
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Refresh token ile access token yenile
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    if (_clientId == null || _clientId!.isEmpty) {
      throw ApiException(
        message: 'Client ID yapılandırılmamış',
      );
    }
    if (_clientSecret == null || _clientSecret!.isEmpty) {
      throw ApiException(
        message: 'Client Secret yapılandırılmamış',
      );
    }

    final tokenUrl = Uri.parse('https://oauth2.googleapis.com/token');

    final response = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId!,
        'client_secret': _clientSecret!,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      },
    );

    if (response.statusCode != 200) {
      final errorBody = response.body;
      String errorMessage = 'Token yenilenemedi: $errorBody';

      if (errorBody.contains('invalid_grant')) {
        errorMessage = 'Refresh token geçersiz veya süresi dolmuş. Lütfen Gmail bağlantısını yeniden yapın.';
      } else if (errorBody.contains('invalid_client')) {
        errorMessage = 'Client ID veya Client Secret yanlış.';
      }

      throw ApiException(message: errorMessage);
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }
}

