import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/core/config/app_config.dart';
import 'oauth/outlook/outlook_oauth_config.dart';
import 'oauth/outlook/outlook_token_exchange.dart';
import 'oauth/outlook/outlook_user_info.dart';
import 'oauth/utils/oauth_server_helper.dart';

/// Outlook Calendar OAuth servisi - Microsoft Graph API ile Calendar hesabı bağlama
class OutlookCalendarOAuthService {
  final String? _clientId;
  final String? _clientSecret;
  late final OutlookTokenExchange _tokenExchange;

  OutlookCalendarOAuthService({
    String? clientId,
    String? clientSecret,
  })  : _clientId = clientId ?? (AppConfig.microsoftClientId.isNotEmpty ? AppConfig.microsoftClientId : null),
        _clientSecret =
            clientSecret ?? (AppConfig.microsoftClientSecret.isNotEmpty ? AppConfig.microsoftClientSecret : null) {
    _tokenExchange = OutlookTokenExchange(clientId: _clientId, clientSecret: _clientSecret);
    debugPrint('OutlookCalendarOAuthService initialized:');
    debugPrint('  Client ID: ${_clientId ?? "NULL"}');
    debugPrint('  Client Secret: ${_clientSecret != null && _clientSecret!.isNotEmpty ? "***SET***" : "NULL/EMPTY"}');
  }

  /// Outlook Calendar hesabına bağlan (OAuth flow)
  Future<CalendarAuthResult> connectCalendar() async {
    try {
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

    String redirectUri = 'http://localhost:8080/oauth-callback';
    HttpServer? server;

    try {
      // HTTP server başlat
      server = await OAuthServerHelper.startServer();
      final port = server.port;

      // Port değiştiyse redirect URI'yi güncelle
      if (port != 8080) {
        redirectUri = 'http://localhost:$port/oauth-callback';
        debugPrint('⚠️ Port değişti, redirect URI güncellendi: $redirectUri');
        debugPrint('⚠️ ÖNEMLİ: Azure Portal\'da bu redirect URI\'yi eklemeniz gerekebilir: $redirectUri');
      }

      // OAuth URL oluştur
      final authUrl = OutlookOAuthConfig.buildAuthUrl(
        clientId: _clientId!,
        redirectUri: redirectUri,
      );

      debugPrint('🔄 Outlook Calendar OAuth başlatılıyor...');
      debugPrint('  Auth URL: $authUrl');
      debugPrint('  Redirect URI: $redirectUri');

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
            final authCode = queryParams['code'];
            final error = queryParams['error'];
            final errorDescription = queryParams['error_description'];

            if (error != null) {
              debugPrint('❌ OAuth hatası: $error - $errorDescription');
              await OAuthServerHelper.sendErrorResponse(
                request,
                '$error${errorDescription != null ? ' - $errorDescription' : ''}',
              );
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
              await OAuthServerHelper.sendSuccessResponse(request, 'Outlook Calendar');
              await server?.close();

              // Token exchange ve user info alma işlemlerini başlat
              try {
                final result = await _completeAuthFlow(authCode, redirectUri);
                completer.complete(result);
              } catch (e) {
                completer.completeError(e);
              }
            } else {
              debugPrint('❌ Authorization code alınamadı');
              await OAuthServerHelper.sendErrorResponse(request, 'Authorization code alınamadı');
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
      tokenResponse = await _tokenExchange.exchangeCodeForTokens(authCode, redirectUri);
      debugPrint('✅ Token exchange başarılı');
    } catch (e) {
      debugPrint('❌ Token exchange hatası: $e');
      rethrow;
    }

    // Kullanıcı bilgilerini al
    debugPrint('🔄 Kullanıcı bilgileri alınıyor...');
    Map<String, dynamic> userInfo;
    try {
      userInfo = await OutlookUserInfo.getUserInfo(tokenResponse['access_token'] as String);
      debugPrint('✅ Kullanıcı bilgileri alındı: ${userInfo['mail'] ?? userInfo['userPrincipalName'] ?? 'N/A'}');
    } catch (e) {
      debugPrint('❌ Kullanıcı bilgileri alma hatası: $e');
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

  /// Outlook Calendar bağlantısını kes
  Future<void> disconnectCalendar() async {
    debugPrint('Outlook Calendar bağlantısı kesildi');
  }

  /// Access token'ı yenile
  Future<CalendarAuthResult> refreshAccessToken(String refreshToken) async {
    final tokenData = await _tokenExchange.refreshAccessToken(refreshToken);

    // Kullanıcı bilgilerini al
    Map<String, dynamic> userInfo;
    try {
      userInfo = await OutlookUserInfo.getUserInfo(tokenData['access_token'] as String);
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
