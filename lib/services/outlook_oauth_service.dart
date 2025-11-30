import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/core/config/app_config.dart';

/// Outlook OAuth servisi - Microsoft Graph API ile Outlook hesabı bağlama
class OutlookOAuthService {
  final String? _clientId;
  final String? _clientSecret;

  OutlookOAuthService({
    String? clientId,
    String? clientSecret,
  })  : _clientId = clientId ?? (AppConfig.microsoftClientId.isNotEmpty ? AppConfig.microsoftClientId : null),
        _clientSecret = clientSecret ?? (AppConfig.microsoftClientSecret.isNotEmpty ? AppConfig.microsoftClientSecret : null) {
    debugPrint('OutlookOAuthService initialized:');
    debugPrint('  Client ID: ${_clientId ?? "NULL"}');
    debugPrint('  Client Secret: ${_clientSecret != null && _clientSecret!.isNotEmpty ? "***SET***" : "NULL/EMPTY"}');
  }

  /// Outlook hesabına bağlan (OAuth flow)
  /// Returns: (accessToken, refreshToken, email, displayName)
  Future<OutlookAuthResult> connectOutlook() async {
    try {
      // Windows/Linux/MacOS için web tabanlı OAuth
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        return await _connectOutlookWeb();
      }

      // Mobil platformlar için de web OAuth kullan (Microsoft Graph API mobil için de web flow kullanır)
      return await _connectOutlookWeb();
    } on ApiException {
      rethrow;
    } catch (e) {
      String errorMessage = 'Outlook bağlantısı başarısız';

      if (e.toString().contains('NETWORK_ERROR')) {
        errorMessage = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
      } else {
        errorMessage = 'Outlook bağlantısı başarısız: ${e.toString()}';
      }

      throw ApiException(
        message: errorMessage,
        originalError: e,
      );
    }
  }

  /// Windows için web tabanlı OAuth flow (HTTP server ile)
  Future<OutlookAuthResult> _connectOutlookWeb() async {
    if (_clientId == null || _clientId!.isEmpty) {
      throw ApiException(
        message:
            'Windows için Microsoft Client ID yapılandırılmamış. Lütfen Azure Portal\'dan Client ID alıp environment variable olarak ekleyin.',
      );
    }

    // OAuth 2.0 parametreleri
    String redirectUri = 'http://localhost:8080/oauth-callback';
    final scopes = [
      'https://graph.microsoft.com/Mail.Read',
      'https://graph.microsoft.com/Mail.Send',
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

      final authUrlString = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize?$queryString';

      debugPrint('OAuth URL: $authUrlString');

      // Windows'ta ShellExecute kullanarak URL'i aç
      if (Platform.isWindows) {
        final result = await Process.run(
          'powershell',
          [
            '-Command',
            'Start-Process',
            authUrlString,
          ],
          runInShell: false,
        );
        debugPrint('Browser açıldı, exit code: ${result.exitCode}');
        if (result.exitCode != 0) {
          debugPrint('Powershell error: ${result.stderr}');
          // Fallback olarak url_launcher dene
          final uri = Uri.parse(authUrlString);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            throw ApiException(
              message: 'Browser açılamadı. Lütfen varsayılan browser\'ınızı kontrol edin.',
            );
          }
        }
      } else {
        // Linux/MacOS için url_launcher kullan
        final uri = Uri.parse(authUrlString);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw ApiException(
            message: 'Browser açılamadı. Lütfen varsayılan browser\'ınızı kontrol edin.',
          );
        }
      }

      // Callback'i bekle (90 saniye timeout - daha uzun süre)
      debugPrint('⏳ OAuth callback bekleniyor... (90 saniye timeout)');
      debugPrint('📍 Server dinliyor: http://localhost:$port/oauth-callback');
      debugPrint('💡 Tarayıcıda giriş yaptıktan sonra, callback URL\'si otomatik olarak açılacak.');
      debugPrint('💡 Eğer callback URL\'si açılmazsa veya "Bu siteye ulaşılamıyor" hatası alırsanız:');
      debugPrint('   1. Port $port\'un kullanılabilir olduğundan emin olun');
      debugPrint('   2. Firewall ayarlarını kontrol edin');
      debugPrint('   3. Antivirus yazılımınızın localhost bağlantılarını engellemediğinden emin olun');
      
      // Server'ın tüm istekleri dinlemesini sağla (sadece oauth-callback değil)
      await for (final request in server.timeout(
        const Duration(seconds: 90),
        onTimeout: (sink) {
          sink.close();
          throw ApiException(
            message: 'OAuth timeout: Kullanıcı yanıt vermedi veya callback URL\'ye ulaşılamadı.\n\n'
                'Callback URL: $redirectUri\n'
                'Port: $port\n\n'
                'Çözüm:\n'
                '1. Tarayıcıda giriş yaptıktan sonra callback URL\'sinin açıldığından emin olun\n'
                '2. Eğer "Bu siteye ulaşılamıyor" hatası alıyorsanız, port $port kullanılamıyor olabilir\n'
                '3. Firewall veya antivirus yazılımının localhost bağlantılarını engellemediğinden emin olun\n'
                '4. Uygulamayı yönetici olarak çalıştırmayı deneyin\n'
                '5. Tekrar deneyin',
          );
        },
      )) {
        final uri = request.uri;
        debugPrint('📥 İstek alındı: ${uri.path}');
        
        // Sadece oauth-callback path'ini işle
        if (uri.path == '/oauth-callback' || uri.path.contains('oauth-callback')) {
          debugPrint('✅ Callback alındı: ${uri.toString()}');
          authCode = uri.queryParameters['code'];
          error = uri.queryParameters['error'];
          final errorDescription = uri.queryParameters['error_description'];
          
          if (error != null) {
            debugPrint('❌ OAuth error: $error');
            if (errorDescription != null) {
              debugPrint('❌ Error description: $errorDescription');
            }
          } else if (authCode != null) {
            debugPrint('✅ Authorization code alındı: ${authCode.length > 20 ? authCode.substring(0, 20) : authCode}...');
          } else {
            debugPrint('⚠️ Callback alındı ama authorization code yok');
          }

          // Başarılı yanıt gönder
          request.response.statusCode = 200;
          request.response.headers.set('Content-Type', 'text/html; charset=utf-8');
          request.response.write('''
            <html>
              <head>
                <title>Outlook Bağlantısı Başarılı</title>
                <meta charset="utf-8">
                <style>
                  body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; }
                  h1 { color: #0078D4; }
                  p { color: #666; }
                </style>
              </head>
              <body>
                <h1>✅ Outlook bağlantısı başarılı!</h1>
                <p>Bu pencereyi kapatabilirsiniz. Uygulamaya geri dönün.</p>
              </body>
            </html>
          ''');
          await request.response.close();
          break;
        } else {
          // Diğer path'ler için 404 döndür
          request.response.statusCode = 404;
          request.response.write('Not Found');
          await request.response.close();
          continue;
        }
      }
    } finally {
      await server?.close(force: true);
    }

    if (error != null) {
      throw ApiException(
        message: 'OAuth hatası: $error',
      );
    }

    if (authCode == null) {
      throw ApiException(
        message: 'Authorization code alınamadı. Callback URL açıldı ama code parametresi bulunamadı.\n\n'
            'Çözüm:\n'
            '1. Tarayıcıda callback URL\'sinin tam olarak açıldığından emin olun\n'
            '2. URL\'de "code=" parametresinin olduğunu kontrol edin\n'
            '3. Tekrar deneyin',
      );
    }

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

    return OutlookAuthResult(
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
    debugPrint('  Client ID uzunluğu: ${_clientId?.length ?? 0} karakter');
    debugPrint('  Client Secret uzunluğu: ${_clientSecret?.length ?? 0} karakter');
    debugPrint('  Redirect URI: $redirectUri');
    
    // Client ID format kontrolü (GUID formatında olmalı)
    if (_clientId != null && !_clientId!.contains('-')) {
      debugPrint('⚠️ UYARI: Client ID GUID formatında görünmüyor (tire içermeli)');
    }

    final response = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': _clientId!,
        'client_secret': _clientSecret!,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'scope': 'https://graph.microsoft.com/Mail.Read https://graph.microsoft.com/Mail.Send https://graph.microsoft.com/User.Read offline_access',
      },
    );

    debugPrint('Token exchange yanıtı: Status=${response.statusCode}');
    debugPrint('Token exchange body (ilk 200 karakter): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}...');

    if (response.statusCode != 200) {
      final errorBody = response.body;
      debugPrint('❌ Token exchange başarısız!');
      debugPrint('❌ Status Code: ${response.statusCode}');
      debugPrint('❌ Error Body: $errorBody');
      
      String errorMessage = 'Token alınamadı: $errorBody';

      // Daha açıklayıcı hata mesajları
      if (errorBody.contains('invalid_client')) {
        errorMessage =
            'Client ID veya Client Secret yanlış.\n\n'
            'Kontrol edin:\n'
            '1. Azure Portal > App registrations > Your app > Overview\n'
            '   → "Application (client) ID" değerini kopyalayın (GUID formatında, örn: 12345678-1234-1234-1234-123456789012)\n\n'
            '2. Azure Portal > App registrations > Your app > Certificates & secrets\n'
            '   → "Value" sütunundaki değeri kopyalayın (oluşturduktan sonra bir daha gösterilmez!)\n\n'
            '3. run_windows.bat dosyasında değerlerin doğru yapıştırıldığından emin olun\n'
            '4. Client Secret\'in süresi dolmamış olduğundan emin olun\n\n'
            'Mevcut Client ID: ${_clientId?.substring(0, _clientId!.length > 20 ? 20 : _clientId!.length)}...';
      } else if (errorBody.contains('invalid_grant')) {
        errorMessage = 'Authorization code geçersiz veya süresi dolmuş. Lütfen tekrar deneyin.';
      } else if (errorBody.contains('redirect_uri_mismatch')) {
        errorMessage =
            'Redirect URI eşleşmiyor.\n\n'
            'Azure Portal\'da şu redirect URI\'leri eklemeniz gerekiyor:\n\n'
            '1. http://localhost:8080/oauth-callback\n'
            '2. http://localhost:8081/oauth-callback\n'
            '3. http://localhost:8082/oauth-callback\n'
            '4. http://localhost:8083/oauth-callback\n'
            '5. http://localhost:3000/oauth-callback\n'
            '6. http://localhost:3001/oauth-callback\n\n'
            'Adımlar:\n'
            'Azure Portal > App registrations > Your app > Authentication > Redirect URIs\n'
            '→ Platform: Web seçin\n'
            '→ Yukarıdaki URI\'leri ekleyin\n'
            '→ Save butonuna tıklayın';
      } else if (errorBody.contains('AADSTS70011')) {
        errorMessage =
            'İzin kapsamı (scope) geçersiz.\n\n'
            'Azure Portal > App registrations > Your app > API permissions\n'
            '→ Şu izinlerin ekli olduğundan emin olun:\n'
            '  - Mail.Read\n'
            '  - Mail.Send\n'
            '  - User.Read\n'
            '→ "Grant admin consent" butonuna tıklayın (gerekirse)';
      }

      throw ApiException(
        message: errorMessage,
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Kullanıcı bilgilerini al
  Future<Map<String, dynamic>> _getUserInfo(String accessToken) async {
    final userInfoUrl = Uri.parse('https://graph.microsoft.com/v1.0/me');

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

  /// Refresh token ile access token yenile
  Future<OutlookAuthResult> refreshAccessToken(String refreshToken) async {
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

    try {
      final tokenUrl = Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token');

      final response = await http.post(
        tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId!,
          'client_secret': _clientSecret!,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
          'scope': 'https://graph.microsoft.com/Mail.Read https://graph.microsoft.com/Mail.Send https://graph.microsoft.com/User.Read offline_access',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        String errorMessage = 'Token yenilenemedi: $errorBody';

        if (errorBody.contains('invalid_grant')) {
          errorMessage = 'Refresh token geçersiz veya süresi dolmuş. Lütfen Outlook bağlantısını yeniden yapın.';
        } else if (errorBody.contains('invalid_client')) {
          errorMessage = 'Client ID veya Client Secret yanlış.';
        }

        throw ApiException(message: errorMessage);
      }

      final tokenResponse = json.decode(response.body) as Map<String, dynamic>;
      final newAccessToken = tokenResponse['access_token'] as String;

      // User info'yu almak için yeni access token kullan
      try {
        final userInfo = await _getUserInfo(newAccessToken);
        return OutlookAuthResult(
          accessToken: newAccessToken,
          refreshToken: tokenResponse['refresh_token'] as String? ?? refreshToken, // Yeni refresh token varsa kullan
          email: userInfo['mail'] as String? ?? userInfo['userPrincipalName'] as String? ?? '',
          displayName: userInfo['displayName'] as String?,
        );
      } catch (e) {
        // User info alınamazsa da access token'ı döndür
        return OutlookAuthResult(
          accessToken: newAccessToken,
          refreshToken: tokenResponse['refresh_token'] as String? ?? refreshToken,
          email: '',
          displayName: null,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Token yenileme hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }
}

/// Outlook OAuth sonuç modeli
class OutlookAuthResult {
  final String accessToken;
  final String? refreshToken;
  final String email;
  final String? displayName;

  OutlookAuthResult({
    required this.accessToken,
    this.refreshToken,
    required this.email,
    this.displayName,
  });
}

