import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/core/config/app_config.dart';

/// Outlook Calendar OAuth servisi - Microsoft Graph API ile Calendar hesabı bağlama
class OutlookCalendarOAuthService {
  final String? _clientId;
  final String? _clientSecret;

  OutlookCalendarOAuthService({
    String? clientId,
    String? clientSecret,
  })  : _clientId = clientId ?? (AppConfig.microsoftClientId.isNotEmpty ? AppConfig.microsoftClientId : null),
        _clientSecret =
            clientSecret ?? (AppConfig.microsoftClientSecret.isNotEmpty ? AppConfig.microsoftClientSecret : null) {
    debugPrint('OutlookCalendarOAuthService initialized:');
    debugPrint('  Client ID: ${_clientId ?? "NULL"}');
    debugPrint('  Client Secret: ${_clientSecret != null && _clientSecret!.isNotEmpty ? "***SET***" : "NULL/EMPTY"}');
  }

  /// Outlook Calendar hesabına bağlan (OAuth flow)
  /// Returns: (accessToken, refreshToken, email, displayName)
  Future<CalendarAuthResult> connectCalendar() async {
    try {
      // Tüm platformlar için web tabanlı OAuth (Microsoft Graph API)
      return await _connectCalendarWeb();
    } on ApiException {
      rethrow;
    } catch (e) {
      String errorMessage = 'Outlook Calendar bağlantısı başarısız';

      if (e.toString().contains('NETWORK_ERROR')) {
        errorMessage = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
      } else {
        errorMessage = 'Outlook Calendar bağlantısı başarısız: ${e.toString()}';
      }

      throw ApiException(
        message: errorMessage,
        originalError: e,
      );
    }
  }

  /// Web tabanlı OAuth flow (HTTP server ile)
  Future<CalendarAuthResult> _connectCalendarWeb() async {
    if (_clientId == null || _clientId!.isEmpty) {
      throw ApiException(
        message:
            'Microsoft Client ID yapılandırılmamış. Lütfen Azure Portal\'dan Client ID alıp environment variable olarak ekleyin.',
      );
    }

    // OAuth 2.0 parametreleri - Calendar scope'ları ile
    String redirectUri = 'http://localhost:8080/oauth-callback';
    final scopes = [
      'https://graph.microsoft.com/Calendars.Read',
      'https://graph.microsoft.com/Calendars.ReadWrite',
      'https://graph.microsoft.com/User.Read',
      'offline_access',
    ].join(' ');

    // Local HTTP server başlat
    HttpServer? server;
    String? authCode;
    String? error;
    int port = 8080;
    List<int> alternativePorts = [8081, 8082, 8083, 3000, 3001];

    try {
      // Port 8080'i dene, başarısız olursa alternatif portları dene
      bool serverStarted = false;
      SocketException? lastException;

      try {
        server = await HttpServer.bind('localhost', port);
        serverStarted = true;
        debugPrint('✅ HTTP server başlatıldı: localhost:$port');
      } on SocketException catch (e) {
        lastException = e;
        debugPrint('⚠️ Port $port kullanılamıyor: ${e.message}');

        // Alternatif portları dene
        for (final altPort in alternativePorts) {
          try {
            server = await HttpServer.bind('localhost', altPort);
            port = altPort;
            serverStarted = true;
            debugPrint('✅ HTTP server alternatif portta başlatıldı: localhost:$port');
            break;
          } on SocketException catch (altE) {
            debugPrint('⚠️ Port $altPort da kullanılamıyor: ${altE.message}');
            lastException = altE;
            continue;
          }
        }
      }

      if (!serverStarted || server == null) {
        throw ApiException(
          message: 'Localhost\'a bağlanılamadı. Portlar kullanımda olabilir veya firewall engelliyor olabilir.\n\n'
              'Çözüm:\n'
              '1. Diğer uygulamaları kapatın (port 8080, 8081, 8082, 8083, 3000, 3001 kullanıyor olabilir)\n'
              '2. Windows Firewall ayarlarını kontrol edin\n'
              '3. Uygulamayı yönetici olarak çalıştırmayı deneyin\n'
              '4. Antivirus yazılımınızın localhost bağlantılarını engellemediğinden emin olun',
          originalError: lastException,
        );
      }

      // Port değiştiyse redirect URI'yi güncelle
      if (port != 8080) {
        redirectUri = 'http://localhost:$port/oauth-callback';
        debugPrint('⚠️ Port değişti, redirect URI güncellendi: $redirectUri');
        debugPrint('⚠️ ÖNEMLİ: Azure Portal\'da bu redirect URI\'yi eklemeniz gerekebilir: $redirectUri');
      }

      // Microsoft OAuth URL oluştur
      final queryString = [
        'client_id=${Uri.encodeComponent(_clientId!)}',
        'redirect_uri=${Uri.encodeComponent(redirectUri)}',
        'response_type=code',
        'scope=${Uri.encodeComponent(scopes)}',
        'response_mode=query',
      ].join('&');

      final authUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize?$queryString';

      debugPrint('🔄 Outlook Calendar OAuth başlatılıyor...');
      debugPrint('  Auth URL: $authUrl');
      debugPrint('  Redirect URI: $redirectUri');
      debugPrint('  Scopes: $scopes');

      // Tarayıcıyı aç
      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await server.close();
        throw ApiException(
          message: 'Tarayıcı açılamadı. Lütfen manuel olarak şu URL\'yi açın:\n\n$authUrl',
        );
      }

      // Authorization code'u bekle
      debugPrint('⏳ Authorization code bekleniyor...');
      final completer = Completer<CalendarAuthResult>();

      server.listen((request) async {
        if (request.uri.path == '/oauth-callback') {
          try {
            final queryParams = request.uri.queryParameters;
            authCode = queryParams['code'];
            error = queryParams['error'];
            final errorDescription = queryParams['error_description'];

            if (error != null) {
              debugPrint('❌ OAuth hatası: $error - $errorDescription');
              await request.response.close();
              await server?.close();
              completer.completeError(
                ApiException(
                  message:
                      'Outlook Calendar bağlantısı başarısız: $error${errorDescription != null ? ' - $errorDescription' : ''}',
                ),
              );
              return;
            }

            if (authCode != null) {
              debugPrint('✅ Authorization code alındı');
              request.response
                ..statusCode = 200
                ..headers.contentType = ContentType.html
                ..write('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Outlook Calendar Bağlantısı Başarılı</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            text-align: center;
            max-width: 400px;
        }
        h1 {
            color: #667eea;
            margin-bottom: 20px;
        }
        p {
            color: #666;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>✅ Outlook Calendar bağlantısı başarılı!</h1>
        <p>Bu pencereyi kapatabilirsiniz.</p>
        <p>Uygulamaya dönün.</p>
    </div>
</body>
</html>
''');
              await request.response.close();
              await server?.close();

              // Token exchange ve user info alma işlemlerini başlat
              try {
                final result = await _completeAuthFlow(authCode!, redirectUri);
                completer.complete(result);
              } catch (e) {
                completer.completeError(e);
              }
            } else {
              debugPrint('❌ Authorization code alınamadı');
              request.response
                ..statusCode = 400
                ..write('Authorization code alınamadı');
              await request.response.close();
              await server?.close();
              completer.completeError(
                ApiException(
                  message: 'Authorization code alınamadı',
                ),
              );
            }
          } catch (e) {
            debugPrint('❌ OAuth callback hatası: $e');
            await request.response.close();
            await server?.close();
            completer.completeError(e);
          }
        } else {
          request.response
            ..statusCode = 404
            ..write('Not Found');
          await request.response.close();
        }
      });

      // Timeout kontrolü (2 dakika)
      Future.delayed(const Duration(minutes: 2)).then((_) {
        if (!completer.isCompleted) {
          server?.close();
          completer.completeError(
            ApiException(
              message: 'OAuth işlemi zaman aşımına uğradı. Lütfen tekrar deneyin.',
            ),
          );
        }
      });

      return await completer.future;
    } catch (e) {
      if (server != null) {
        await server.close();
      }
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Outlook Calendar bağlantısı başarısız: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// OAuth flow'unu tamamla (token exchange + user info)
  Future<CalendarAuthResult> _completeAuthFlow(String authCode, String redirectUri) async {
    debugPrint('🔄 Authorization code token exchange\'e gönderiliyor...');

    // Authorization code ile access token al
    Map<String, dynamic> tokenResponse;
    try {
      tokenResponse = await _exchangeCodeForTokens(authCode, redirectUri);
      debugPrint('✅ Token exchange başarılı');
    } catch (e) {
      debugPrint('❌ Token exchange hatası: $e');
      rethrow;
    }

    // Kullanıcı bilgilerini al
    debugPrint('🔄 Kullanıcı bilgileri alınıyor...');
    Map<String, dynamic> userInfo;
    try {
      userInfo = await _getUserInfo(tokenResponse['access_token'] as String);
      debugPrint('✅ Kullanıcı bilgileri alındı: ${userInfo['mail'] ?? userInfo['userPrincipalName'] ?? 'N/A'}');
    } catch (e) {
      debugPrint('❌ Kullanıcı bilgileri alma hatası: $e');
      // Kullanıcı bilgileri alınamazsa da devam et
      userInfo = {
        'mail': '',
        'userPrincipalName': '',
        'displayName': null,
      };
    }

    return CalendarAuthResult(
      accessToken: tokenResponse['access_token'] as String,
      refreshToken: tokenResponse['refresh_token'] as String?,
      email: userInfo['mail'] as String? ?? userInfo['userPrincipalName'] as String? ?? '',
      displayName: userInfo['displayName'] as String?,
    );
  }

  /// Authorization code'u access token'a çevir
  Future<Map<String, dynamic>> _exchangeCodeForTokens(String code, String redirectUri) async {
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

    final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
    return tokenData;
  }

  /// Kullanıcı bilgilerini al
  Future<Map<String, dynamic>> _getUserInfo(String accessToken) async {
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

  /// Outlook Calendar bağlantısını kes
  Future<void> disconnectCalendar() async {
    // Microsoft Graph API'de logout endpoint yok, sadece token'ı silmek yeterli
    debugPrint('Outlook Calendar bağlantısı kesildi');
  }

  /// Access token'ı yenile
  Future<CalendarAuthResult> refreshAccessToken(String refreshToken) async {
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

    final tokenData = jsonDecode(response.body) as Map<String, dynamic>;

    // Kullanıcı bilgilerini al
    Map<String, dynamic> userInfo;
    try {
      userInfo = await _getUserInfo(tokenData['access_token'] as String);
    } catch (e) {
      userInfo = {
        'mail': '',
        'userPrincipalName': '',
        'displayName': null,
      };
    }

    return CalendarAuthResult(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String? ?? refreshToken,
      email: userInfo['mail'] as String? ?? userInfo['userPrincipalName'] as String? ?? '',
      displayName: userInfo['displayName'] as String?,
    );
  }
}

/// Calendar OAuth sonuç modeli (Google ve Outlook için ortak)
class CalendarAuthResult {
  final String accessToken;
  final String? refreshToken;
  final String email;
  final String? displayName;

  CalendarAuthResult({
    required this.accessToken,
    this.refreshToken,
    required this.email,
    this.displayName,
  });
}
