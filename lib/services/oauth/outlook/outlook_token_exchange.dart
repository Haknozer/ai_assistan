import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ai_asisstan/core/api/api_exceptions.dart';

/// Outlook OAuth token exchange helper
class OutlookTokenExchange {
  final String? _clientId;
  final String? _clientSecret;

  OutlookTokenExchange({
    required String? clientId,
    required String? clientSecret,
  })  : _clientId = clientId,
        _clientSecret = clientSecret;

  /// Authorization code'u access token'a çevir
  Future<Map<String, dynamic>> exchangeCodeForTokens(String code, String redirectUri) async {
    if (_clientSecret == null || _clientSecret!.isEmpty) {
      throw ApiException(
        message:
            'Client Secret eksik. Lütfen Azure Portal\'dan Client Secret alıp environment variable olarak ekleyin.',
      );
    }

    final tokenUrl = Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token');

    debugPrint('Token exchange başlatılıyor:');
    debugPrint('  Client ID: $_clientId');
    debugPrint('  Redirect URI: $redirectUri');

    final response = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': _clientId!,
        'client_secret': _clientSecret!,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'scope':
            'https://graph.microsoft.com/Calendars.Read https://graph.microsoft.com/Calendars.ReadWrite https://graph.microsoft.com/User.Read offline_access',
      },
    );

    debugPrint('Token exchange yanıtı: Status=${response.statusCode}');

    if (response.statusCode != 200) {
      final errorBody = response.body;
      debugPrint('❌ Token exchange başarısız!');
      debugPrint('❌ Status Code: ${response.statusCode}');
      debugPrint('❌ Error Body: $errorBody');

      String errorMessage = 'Token alınamadı: $errorBody';

      try {
        final errorJson = jsonDecode(errorBody) as Map<String, dynamic>;
        final error = errorJson['error'] as String?;
        final errorDescription = errorJson['error_description'] as String?;
        if (error != null) {
          errorMessage = errorDescription ?? error;
        }
      } catch (e) {
        // JSON parse hatası, mevcut mesajı kullan
      }

      throw ApiException(
        message: errorMessage,
        originalError: errorBody,
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Refresh token ile access token yenile
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    if (_clientSecret == null || _clientSecret!.isEmpty) {
      throw ApiException(
        message: 'Client Secret eksik. Token yenilenemedi.',
      );
    }

    final tokenUrl = Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token');

    final response = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'refresh_token': refreshToken,
        'client_id': _clientId!,
        'client_secret': _clientSecret!,
        'grant_type': 'refresh_token',
        'scope':
            'https://graph.microsoft.com/Calendars.Read https://graph.microsoft.com/Calendars.ReadWrite https://graph.microsoft.com/User.Read offline_access',
      },
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Token yenilenemedi';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        final errorDescription = errorJson['error_description'] as String?;
        if (errorDescription != null) {
          errorMessage = errorDescription;
        }
      } catch (e) {
        // JSON parse hatası
      }

      if (errorMessage.contains('invalid_grant') || errorMessage.contains('expired')) {
        errorMessage = 'Refresh token geçersiz veya süresi dolmuş. Lütfen Outlook Calendar bağlantısını yeniden yapın.';
      }

      throw ApiException(
        message: errorMessage,
        originalError: response.body,
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

