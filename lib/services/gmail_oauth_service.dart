import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/core/config/app_config.dart';

/// Gmail OAuth servisi - Google Sign-In ile Gmail hesabı bağlama
class GmailOAuthService {
  final GoogleSignIn? _googleSignIn;
  final String? _clientId;
  final String? _clientSecret;

  GmailOAuthService({
    GoogleSignIn? googleSignIn,
    String? clientId,
    String? clientSecret,
  })  : _googleSignIn = googleSignIn,
        _clientId = clientId ?? (AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null),
        _clientSecret =
            clientSecret ?? (AppConfig.googleClientSecret.isNotEmpty ? AppConfig.googleClientSecret : null) {
    // Debug: Client Secret kontrolü
    debugPrint('GmailOAuthService initialized:');
    debugPrint('  Client ID: ${_clientId ?? "NULL"}');
    debugPrint('  Client Secret: ${_clientSecret != null && _clientSecret!.isNotEmpty ? "***SET***" : "NULL/EMPTY"}');
  }

  /// Gmail hesabına bağlan (OAuth flow)
  /// Returns: (accessToken, refreshToken, email, displayName)
  Future<GmailAuthResult> connectGmail() async {
    try {
      // Windows/Linux/MacOS için web tabanlı OAuth
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        return await _connectGmailWeb();
      }

      // Mobil platformlar için Google Sign-In
      if (_googleSignIn == null) {
        throw ApiException(
          message: 'Google Sign-In yapılandırılmamış',
        );
      }

      // Önce çıkış yap (eğer önceki oturum varsa)
      await _googleSignIn!.signOut();

      // Google Sign-In flow'u başlat
      final GoogleSignInAccount? account = await _googleSignIn!.signIn();

      if (account == null) {
        throw ApiException(
          message: 'Gmail bağlantısı iptal edildi',
        );
      }

      // Access token al
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.accessToken == null) {
        throw ApiException(
          message: 'Gmail access token alınamadı. Lütfen Google hesabınızın izinlerini kontrol edin.',
        );
      }

      return GmailAuthResult(
        accessToken: auth.accessToken!,
        refreshToken: auth.idToken,
        email: account.email,
        displayName: account.displayName,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      String errorMessage = 'Gmail bağlantısı başarısız';

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
        errorMessage = 'Gmail bağlantısı başarısız: ${e.toString()}';
      }

      throw ApiException(
        message: errorMessage,
        originalError: e,
      );
    }
  }

  /// Windows için web tabanlı OAuth flow (HTTP server ile)
  Future<GmailAuthResult> _connectGmailWeb() async {
    if (_clientId == null || _clientId!.isEmpty) {
      throw ApiException(
        message:
            'Windows için Google Client ID yapılandırılmamış. Lütfen Google Cloud Console\'dan Client ID alıp environment variable olarak ekleyin.',
      );
    }

    // OAuth 2.0 parametreleri
    const redirectUri = 'http://localhost:8080/oauth-callback';
    final scopes = [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.send',
      'https://www.googleapis.com/auth/gmail.modify',
    ].join(' ');

    // Local HTTP server başlat
    HttpServer? server;
    String? authCode;
    String? error;

    try {
      server = await HttpServer.bind('localhost', 8080);

      // OAuth URL oluştur - query parametrelerini manuel olarak encode et
      // Uri.https bazen query parametrelerini kaybedebiliyor, bu yüzden manuel oluşturuyoruz
      final queryString = [
        'client_id=${Uri.encodeComponent(_clientId!)}',
        'redirect_uri=${Uri.encodeComponent(redirectUri)}',
        'response_type=code',
        'scope=${Uri.encodeComponent(scopes)}',
        'access_type=offline',
        'prompt=consent',
      ].join('&');

      final authUrlString = 'https://accounts.google.com/o/oauth2/v2/auth?$queryString';
      final authUrl = Uri.parse(authUrlString);

      // URL'i debug için loglayalım
      debugPrint('OAuth URL: $authUrlString');
      debugPrint('response_type parametresi kontrolü: ${authUrl.queryParameters['response_type']}');

      // Windows'ta ShellExecute kullanarak URL'i aç (daha güvenilir)
      if (Platform.isWindows) {
        // Windows'ta ShellExecute kullan
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

      // Callback'i bekle (30 saniye timeout)
      await for (final request in server.take(1).timeout(
        const Duration(seconds: 30),
        onTimeout: (sink) {
          sink.close();
          throw ApiException(message: 'OAuth timeout: Kullanıcı yanıt vermedi');
        },
      )) {
        final uri = request.uri;
        authCode = uri.queryParameters['code'];
        error = uri.queryParameters['error'];

        // Başarılı yanıt gönder
        request.response.statusCode = 200;
        request.response.headers.set('Content-Type', 'text/html; charset=utf-8');
        request.response.write('''
          <html>
            <head><title>Gmail Bağlantısı Başarılı</title></head>
            <body>
              <h1>✅ Gmail bağlantısı başarılı!</h1>
              <p>Bu pencereyi kapatabilirsiniz. Uygulamaya geri dönün.</p>
            </body>
          </html>
        ''');
        await request.response.close();
        break;
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

    return GmailAuthResult(
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

      // Daha açıklayıcı hata mesajları
      if (errorBody.contains('invalid_client')) {
        errorMessage =
            'Client ID veya Client Secret yanlış. Lütfen Google Cloud Console\'daki değerlerle eşleştiğinden emin olun. Ayrıca OAuth Client ID tipinin "Web application" olduğundan emin olun.';
      } else if (errorBody.contains('invalid_grant')) {
        errorMessage = 'Authorization code geçersiz veya süresi dolmuş. Lütfen tekrar deneyin.';
      } else if (errorBody.contains('redirect_uri_mismatch')) {
        errorMessage =
            'Redirect URI eşleşmiyor. Google Cloud Console\'da http://localhost:8080/oauth-callback ekli olduğundan emin olun.';
      }

      throw ApiException(
        message: errorMessage,
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Kullanıcı bilgilerini al
  Future<Map<String, dynamic>> _getUserInfo(String accessToken) async {
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

  /// Gmail bağlantısını kes
  Future<void> disconnectGmail() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      // Web OAuth için çıkış yapılmasına gerek yok (token geçersizleştirilebilir ama şimdilik yeterli)
    } catch (e) {
      throw ApiException(
        message: 'Gmail bağlantısı kesilemedi: ${e.toString()}',
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
  Future<GmailAuthResult?> getCurrentUser() async {
    if (_googleSignIn != null) {
      final account = _googleSignIn!.currentUser;
      if (account == null) return null;

      try {
        final auth = await account.authentication;
        return GmailAuthResult(
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
}

/// Gmail OAuth sonuç modeli
class GmailAuthResult {
  final String accessToken;
  final String? refreshToken;
  final String email;
  final String? displayName;

  GmailAuthResult({
    required this.accessToken,
    this.refreshToken,
    required this.email,
    this.displayName,
  });
}
