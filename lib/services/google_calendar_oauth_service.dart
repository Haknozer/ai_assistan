import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/core/config/app_config.dart';

/// Google Calendar OAuth servisi - Google Sign-In ile Calendar hesabı bağlama
class GoogleCalendarOAuthService {
  final GoogleSignIn? _googleSignIn;
  final String? _clientId;
  final String? _clientSecret;

  GoogleCalendarOAuthService({
    GoogleSignIn? googleSignIn,
    String? clientId,
    String? clientSecret,
  })  : _googleSignIn = googleSignIn,
        _clientId = clientId ?? (AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null),
        _clientSecret =
            clientSecret ?? (AppConfig.googleClientSecret.isNotEmpty ? AppConfig.googleClientSecret : null) {
    // Debug: Client Secret kontrolü
    debugPrint('GoogleCalendarOAuthService initialized:');
    debugPrint('  Client ID: ${_clientId ?? "NULL"}');
    debugPrint('  Client Secret: ${_clientSecret != null && _clientSecret!.isNotEmpty ? "***SET***" : "NULL/EMPTY"}');
  }

  /// Google Calendar hesabına bağlan (OAuth flow)
  /// Returns: (accessToken, refreshToken, email, displayName)
  Future<CalendarAuthResult> connectCalendar() async {
    try {
      // Windows/Linux/MacOS için web tabanlı OAuth
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        return await _connectCalendarWeb();
      }

      // Mobil platformlar için Google Sign-In
      if (_googleSignIn == null) {
        throw ApiException(
          message: 'Google Sign-In yapılandırılmamış',
        );
      }

      // Önce çıkış yap (eğer önceki oturum varsa)
      await _googleSignIn!.signOut();

      // Google Sign-In flow'u başlat - Calendar scope'ları ile
      final GoogleSignInAccount? account = await _googleSignIn!.signIn();

      if (account == null) {
        throw ApiException(
          message: 'Google Calendar bağlantısı iptal edildi',
        );
      }

      // Access token al
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.accessToken == null) {
        throw ApiException(
          message: 'Google Calendar access token alınamadı. Lütfen Google hesabınızın izinlerini kontrol edin.',
        );
      }

      return CalendarAuthResult(
        accessToken: auth.accessToken!,
        refreshToken: auth.idToken,
        email: account.email,
        displayName: account.displayName,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      String errorMessage = 'Google Calendar bağlantısı başarısız';

      if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'Windows için web tabanlı OAuth kullanılıyor. Client ID yapılandırmasını kontrol edin.';
      } else if (e.toString().contains('PlatformException')) {
        errorMessage =
            'Google Sign-In yapılandırması eksik. Lütfen google-services.json (Android) veya GoogleService-Info.plist (iOS) dosyalarını kontrol edin.';
      } else if (e.toString().contains('SIGN_IN_REQUIRED')) {
        errorMessage = 'Google hesabıyla giriş yapmanız gerekiyor.';
      } else if (e.toString().contains('NETWORK_ERROR')) {
        errorMessage = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
      } else {
        errorMessage = 'Google Calendar bağlantısı başarısız: ${e.toString()}';
      }

      throw ApiException(
        message: errorMessage,
        originalError: e,
      );
    }
  }

  /// Windows için web tabanlı OAuth flow (HTTP server ile)
  Future<CalendarAuthResult> _connectCalendarWeb() async {
    if (_clientId == null || _clientId!.isEmpty) {
      throw ApiException(
        message: 'Client ID yapılandırılmamış. Lütfen GOOGLE_CLIENT_ID environment variable\'ını ayarlayın.',
      );
    }

    // Redirect URI (localhost)
    const redirectUri = 'http://localhost:8080/callback';
    const port = 8080;

    // OAuth URL oluştur
    final authUrl = Uri.parse('https://accounts.google.com/o/oauth2/v2/auth').replace(queryParameters: {
      'client_id': _clientId!,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/calendar.events',
      'access_type': 'offline',
      'prompt': 'consent',
    });

    // Local HTTP server başlat
    HttpServer? server;
    String? authCode;
    String? error;

    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      debugPrint('OAuth callback server başlatıldı: http://localhost:$port');

      // Tarayıcıyı aç
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      } else {
        throw ApiException(message: 'Tarayıcı açılamadı');
      }

      // Callback'i bekle
      await for (final request in server) {
        if (request.uri.path == '/callback') {
          authCode = request.uri.queryParameters['code'];
          error = request.uri.queryParameters['error'];

          // Başarılı yanıt gönder
          request.response.statusCode = 200;
          request.response.headers.set('Content-Type', 'text/html; charset=utf-8');
          request.response.write('''
            <html>
              <head><title>Google Calendar Bağlantısı Başarılı</title></head>
              <body>
                <h1>✅ Google Calendar bağlantısı başarılı!</h1>
                <p>Bu pencereyi kapatabilirsiniz. Uygulamaya geri dönün.</p>
              </body>
            </html>
          ''');
          await request.response.close();
          break;
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
        message: 'Authorization code alınamadı',
      );
    }

    // Authorization code ile access token al
    final tokenResponse = await _exchangeCodeForTokens(authCode, redirectUri);

    // Kullanıcı bilgilerini al
    final userInfo = await _getUserInfo(tokenResponse['access_token'] as String);

    return CalendarAuthResult(
      accessToken: tokenResponse['access_token'] as String,
      refreshToken: tokenResponse['refresh_token'] as String?,
      email: userInfo['email'] as String,
      displayName: userInfo['name'] as String?,
    );
  }

  /// Authorization code'u access token'a çevir
  Future<Map<String, dynamic>> _exchangeCodeForTokens(String code, String redirectUri) async {
    if (_clientSecret == null || _clientSecret!.isEmpty) {
      throw ApiException(
        message:
            'Client Secret eksik. Lütfen Google Cloud Console\'dan Client Secret alıp environment variable olarak ekleyin.',
      );
    }

    final tokenUrl = Uri.parse('https://oauth2.googleapis.com/token');

    // Debug: Token exchange bilgilerini logla (secret hariç)
    debugPrint('Token exchange başlatılıyor...');
    debugPrint('  Redirect URI: $redirectUri');
    debugPrint('  Client ID: ${_clientId ?? "NULL"}');
    debugPrint('  Client Secret: ${_clientSecret != null && _clientSecret!.isNotEmpty ? "***SET***" : "NULL/EMPTY"}');

    final response = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId!,
        'client_secret': _clientSecret!,
        'code': code,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode != 200) {
      final errorBody = response.body;
      String errorMessage = 'Token alınamadı: $errorBody';

      if (errorBody.contains('invalid_grant')) {
        errorMessage = 'Authorization code geçersiz veya süresi dolmuş. Lütfen tekrar deneyin.';
      } else if (errorBody.contains('invalid_client')) {
        errorMessage = 'Client ID veya Client Secret yanlış.';
      } else if (errorBody.contains('redirect_uri_mismatch')) {
        errorMessage = 'Redirect URI eşleşmiyor. Google Cloud Console\'da redirect URI\'yi kontrol edin.';
      }

      throw ApiException(message: errorMessage);
    }

    final tokenResponse = json.decode(response.body) as Map<String, dynamic>;
    debugPrint('Token exchange başarılı!');
    debugPrint('  Access token: ${tokenResponse['access_token'] != null ? "***RECEIVED***" : "NULL"}');
    debugPrint('  Refresh token: ${tokenResponse['refresh_token'] != null ? "***RECEIVED***" : "NULL"}');

    return tokenResponse;
  }

  /// Kullanıcı bilgilerini al
  Future<Map<String, dynamic>> _getUserInfo(String accessToken) async {
    final userInfoUrl = Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo');

    final response = await http.get(
      userInfoUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw ApiException(message: 'Kullanıcı bilgileri alınamadı: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Google Calendar bağlantısını kes
  Future<void> disconnectCalendar() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      // Web OAuth için çıkış yapılmasına gerek yok (token geçersizleştirilebilir ama şimdilik yeterli)
    } catch (e) {
      throw ApiException(
        message: 'Google Calendar bağlantısı kesilemedi: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Mevcut oturumu kontrol et
  Future<bool> isSignedIn() async {
    if (_googleSignIn != null) {
      return await _googleSignIn!.isSignedIn();
    }
    // Web OAuth için token kontrolü yapılabilir ama şimdilik false döndürüyoruz
    return false;
  }

  /// Mevcut kullanıcı bilgilerini al
  Future<CalendarAuthResult?> getCurrentUser() async {
    if (_googleSignIn != null) {
      final account = _googleSignIn!.currentUser;
      if (account == null) return null;

      try {
        final auth = await account.authentication;
        return CalendarAuthResult(
          accessToken: auth.accessToken ?? '',
          refreshToken: auth.idToken,
          email: account.email,
          displayName: account.displayName,
        );
      } catch (e) {
        return null;
      }
    }
    // Web OAuth için token kontrolü yapılabilir ama şimdilik null döndürüyoruz
    return null;
  }

  /// Refresh token ile access token yenile
  Future<CalendarAuthResult> refreshAccessToken(String refreshToken) async {
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
          errorMessage = 'Refresh token geçersiz veya süresi dolmuş. Lütfen Google Calendar bağlantısını yeniden yapın.';
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
        return CalendarAuthResult(
          accessToken: newAccessToken,
          refreshToken: refreshToken, // Refresh token aynı kalır
          email: userInfo['email'] as String? ?? '',
          displayName: userInfo['name'] as String?,
        );
      } catch (e) {
        // User info alınamazsa da access token'ı döndür
        return CalendarAuthResult(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
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

/// Google Calendar OAuth sonuç modeli
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

