import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';

/// OAuth callback için HTTP server yardımcı sınıfı
class OAuthServerHelper {
  /// HTTP server başlat ve port döndür
  static Future<HttpServer> startServer({
    int preferredPort = 8080,
    List<int> alternativePorts = const [8081, 8082, 8083, 3000, 3001],
  }) async {
    HttpServer? server;
    SocketException? lastException;

    // Önce tercih edilen portu dene
    try {
      server = await HttpServer.bind('localhost', preferredPort);
      debugPrint('✅ HTTP server başlatıldı: localhost:$preferredPort');
      return server;
    } on SocketException catch (e) {
      lastException = e;
      debugPrint('⚠️ Port $preferredPort kullanılamıyor: ${e.message}');
    }

    // Alternatif portları dene
    for (final altPort in alternativePorts) {
      try {
        server = await HttpServer.bind('localhost', altPort);
        debugPrint('✅ HTTP server alternatif portta başlatıldı: localhost:$altPort');
        return server;
      } on SocketException catch (altE) {
        debugPrint('⚠️ Port $altPort da kullanılamıyor: ${altE.message}');
        lastException = altE;
        continue;
      }
    }

    // Hiçbir port kullanılamazsa hata fırlat
    throw ApiException(
      message: 'Localhost\'a bağlanılamadı. Portlar kullanımda olabilir veya firewall engelliyor olabilir.\n\n'
          'Çözüm:\n'
          '1. Diğer uygulamaları kapatın (port $preferredPort, ${alternativePorts.join(', ')} kullanıyor olabilir)\n'
          '2. Windows Firewall ayarlarını kontrol edin\n'
          '3. Uygulamayı yönetici olarak çalıştırmayı deneyin\n'
          '4. Antivirus yazılımınızın localhost bağlantılarını engellemediğinden emin olun',
      originalError: lastException,
    );
  }

  /// OAuth callback için başarılı HTML response gönder
  static Future<void> sendSuccessResponse(HttpRequest request, String serviceName) async {
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.html
      ..write(_buildSuccessHtml(serviceName));
    await request.response.close();
  }

  /// OAuth callback için hata HTML response gönder
  static Future<void> sendErrorResponse(HttpRequest request, String errorMessage) async {
    request.response
      ..statusCode = 400
      ..headers.contentType = ContentType.html
      ..write(_buildErrorHtml(errorMessage));
    await request.response.close();
  }

  /// Başarılı HTML sayfası oluştur
  static String _buildSuccessHtml(String serviceName) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$serviceName Bağlantısı Başarılı</title>
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
        <h1>✅ $serviceName bağlantısı başarılı!</h1>
        <p>Bu pencereyi kapatabilirsiniz.</p>
        <p>Uygulamaya dönün.</p>
    </div>
</body>
</html>
''';
  }

  /// Hata HTML sayfası oluştur
  static String _buildErrorHtml(String errorMessage) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Bağlantı Hatası</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
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
            color: #f5576c;
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
        <h1>❌ Bağlantı Hatası</h1>
        <p>$errorMessage</p>
        <p>Lütfen uygulamaya dönün ve tekrar deneyin.</p>
    </div>
</body>
</html>
''';
  }
}

