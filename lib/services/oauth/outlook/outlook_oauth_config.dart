/// Outlook OAuth yapılandırması
class OutlookOAuthConfig {
  /// OAuth scopes
  static const List<String> scopes = [
    'https://graph.microsoft.com/Calendars.Read',
    'https://graph.microsoft.com/Calendars.ReadWrite',
    'https://graph.microsoft.com/User.Read',
    'offline_access',
  ];

  /// OAuth authorization URL
  static const String authorizationUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';

  /// OAuth token URL
  static const String tokenUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/token';

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
      'response_mode=query',
    ].join('&');

    return '$authorizationUrl?$queryString';
  }
}

