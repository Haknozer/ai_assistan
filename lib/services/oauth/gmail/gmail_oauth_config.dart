/// Gmail OAuth yapılandırması
class GmailOAuthConfig {
  /// OAuth scopes
  static const List<String> scopes = [
    'email',
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/gmail.modify',
  ];

  /// OAuth authorization URL
  static const String authorizationUrl = 'https://accounts.google.com/o/oauth2/v2/auth';

  /// OAuth token URL
  static const String tokenUrl = 'https://oauth2.googleapis.com/token';

  /// Scopes'u string'e çevir
  static String getScopesString() {
    return scopes.join(' ');
  }

  /// OAuth URL oluştur
  static String buildAuthUrl({
    required String clientId,
    required String redirectUri,
  }) {
    final queryString = [
      'client_id=${Uri.encodeComponent(clientId)}',
      'redirect_uri=${Uri.encodeComponent(redirectUri)}',
      'response_type=code',
      'scope=${Uri.encodeComponent(getScopesString())}',
      'access_type=offline',
      'prompt=consent',
    ].join('&');

    return '$authorizationUrl?$queryString';
  }
}

