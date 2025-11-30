import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/core/config/app_config.dart';
import 'oauth/gmail/gmail_oauth_config.dart';
import 'oauth/gmail/gmail_token_exchange.dart';
import 'oauth/gmail/gmail_user_info.dart';
import 'oauth/utils/oauth_server_helper.dart';

/// Gmail OAuth servisi - Google Sign-In ile Gmail hesabı bağlama
class GmailOAuthService {
  final GoogleSignIn? _googleSignIn;
  final String? _clientId;
  final String? _clientSecret;
  late final GmailTokenExchange _tokenExchange;

  GmailOAuthService({
    GoogleSignIn? googleSignIn,
    String? clientId,
    String? clientSecret,
  })  : _googleSignIn = googleSignIn,
        _clientId = clientId ?? (AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null),
        _clientSecret =
            clientSecret ?? (AppConfig.googleClientSecret.isNotEmpty ? AppConfig.googleClientSecret : null) {
    _tokenExchange = GmailTokenExchange(clientId: _clientId, clientSecret: _clientSecret);
    debugPrint('GmailOAuthService initialized:');
    debugPrint('  Client ID: ${_clientId ?? "NULL"}');
    debugPrint('  Client Secret: ${_clientSecret != null && _clientSecret!.isNotEmpty ? "***SET***" : "NULL/EMPTY"}');
  }

  /// Gmail hesabına bağlan (OAuth flow)
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

      await _googleSignIn!.signOut();
      final GoogleSignInAccount? account = await _googleSignIn!.signIn();

      if (account == null) {
        throw ApiException(
          message: 'Gmail bağlantısı iptal edildi',
        );
      }

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

    String redirectUri = 'http://localhost:8080/oauth-callback';
    HttpServer? server;
    String? authCode;
    String? error;

    try {
      // HTTP server başlat
      server = await OAuthServerHelper.startServer();
      final port = server.port;

      // Port değiştiyse redirect URI'yi güncelle
      if (port != 8080) {
        redirectUri = 'http://localhost:$port/oauth-callback';
        debugPrint('⚠️ Port değişti, redirect URI güncellendi: $redirectUri');
        debugPrint('⚠️ ÖNEMLİ: Google Cloud Console\'da bu redirect URI\'yi eklemeniz gerekebilir: $redirectUri');

        if (kDebugMode) {
          debugPrint('💡 İPUCU: Tüm olası portları Google Cloud Console\'a ekleyerek bu sorunu önleyebilirsiniz:');
          debugPrint('   - http://localhost:8080/oauth-callback');
          debugPrint('   - http://localhost:8081/oauth-callback');
          debugPrint('   - http://localhost:8082/oauth-callback');
          debugPrint('   - http://localhost:8083/oauth-callback');
          debugPrint('   - http://localhost:3000/oauth-callback');
          debugPrint('   - http://localhost:3001/oauth-callback');
        }
      }

      // OAuth URL oluştur
      final authUrlString = GmailOAuthConfig.buildAuthUrl(
        clientId: _clientId!,
        redirectUri: redirectUri,
      );

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
        await OAuthServerHelper.sendSuccessResponse(request, 'Gmail');
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
    final tokenResponse = await _tokenExchange.exchangeCodeForTokens(authCode, redirectUri);

    // Kullanıcı bilgilerini al
    final userInfo = await GmailUserInfo.getUserInfo(tokenResponse['access_token'] as String);

    return GmailAuthResult(
      accessToken: tokenResponse['access_token'] as String,
      refreshToken: tokenResponse['refresh_token'] as String?,
      email: userInfo['email'] as String,
      displayName: userInfo['name'] as String?,
    );
  }

  /// Gmail bağlantısını kes
  Future<void> disconnectGmail() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
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
    return null;
  }

  /// Refresh token ile access token yenile
  Future<GmailAuthResult> refreshAccessToken(String refreshToken) async {
    try {
      final tokenResponse = await _tokenExchange.refreshAccessToken(refreshToken);
      final newAccessToken = tokenResponse['access_token'] as String;

      // User info'yu almak için yeni access token kullan
      try {
        final userInfo = await GmailUserInfo.getUserInfo(newAccessToken);
        return GmailAuthResult(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
          email: userInfo['email'] as String? ?? '',
          displayName: userInfo['name'] as String?,
        );
      } catch (e) {
        return GmailAuthResult(
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
