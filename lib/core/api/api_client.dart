import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exceptions.dart';
import 'api_endpoints.dart';
import '../config/app_config.dart';

/// HTTP API çağrılarını yöneten client sınıfı
class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final Map<String, String> defaultHeaders;

  ApiClient({
    String? baseUrl,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
  })  : baseUrl = baseUrl ?? ApiEndpoints.baseUrl,
        timeout = timeout ?? AppConfig.apiTimeout,
        defaultHeaders = defaultHeaders ??
            {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            };

  /// GET isteği
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    String? accessToken,
  }) async {
    return _request(
      'GET',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      accessToken: accessToken,
    );
  }

  /// POST isteği
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    String? accessToken,
  }) async {
    return _request(
      'POST',
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      accessToken: accessToken,
    );
  }

  /// PUT isteği
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    String? accessToken,
  }) async {
    return _request(
      'PUT',
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      accessToken: accessToken,
    );
  }

  /// PATCH isteği
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    String? accessToken,
  }) async {
    return _request(
      'PATCH',
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      accessToken: accessToken,
    );
  }

  /// DELETE isteği
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    String? accessToken,
  }) async {
    return _request(
      'DELETE',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      accessToken: accessToken,
    );
  }

  /// Ana request metodu
  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    String? accessToken,
  }) async {
    try {
      // URL oluştur
      var url = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');

      // Query parametreleri ekle
      if (queryParameters != null && queryParameters.isNotEmpty) {
        url = url.replace(queryParameters: {
          ...url.queryParameters,
          ...queryParameters.map((key, value) => MapEntry(key, value.toString())),
        });
      }

      // Header'ları birleştir
      final requestHeaders = <String, String>{
        ...defaultHeaders,
        if (headers != null) ...headers,
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

      // Request body oluştur
      http.Response response;
      final bodyString = body != null ? jsonEncode(body) : null;

      // HTTP isteğini yap
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await http.post(url, headers: requestHeaders, body: bodyString).timeout(timeout);
          break;
        case 'PUT':
          response = await http.put(url, headers: requestHeaders, body: bodyString).timeout(timeout);
          break;
        case 'PATCH':
          response = await http.patch(url, headers: requestHeaders, body: bodyString).timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders).timeout(timeout);
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method');
      }

      // Response'u parse et
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } on FormatException catch (e) {
      throw ApiException(
        message: 'Invalid response format: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Response'u işle ve hataları yönet
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Başarılı response'lar
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }

      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json;
      } catch (e) {
        // JSON parse hatası - bazı API'ler boş string dönebilir
        return {};
      }
    }

    // Hata response'ları
    String errorMessage = 'Unknown error';
    Map<String, dynamic>? errorData;

    try {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = errorJson['message'] as String? ?? errorJson['error'] as String? ?? 'HTTP $statusCode';
      errorData = errorJson['errors'] as Map<String, dynamic>?;
    } catch (e) {
      errorMessage = 'HTTP $statusCode: ${response.reasonPhrase ?? 'Unknown error'}';
    }

    // Status code'a göre exception fırlat
    switch (statusCode) {
      case 400:
        throw ValidationException(
          message: errorMessage,
          errors: errorData,
          originalError: response.body,
        );
      case 401:
        throw UnauthorizedException(
          message: errorMessage,
          originalError: response.body,
        );
      case 403:
        // Gmail API için daha açıklayıcı hata mesajı
        String forbiddenMessage = errorMessage;
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final errorDetail = errorJson['error'] as Map<String, dynamic>?;
          if (errorDetail != null) {
            final reason = errorDetail['reason'] as String? ?? '';
            final message = errorDetail['message'] as String? ?? '';
            
            if (reason.contains('accessNotConfigured') || message.contains('Gmail API')) {
              forbiddenMessage = 'Gmail API etkin değil. Lütfen Google Cloud Console\'da Gmail API\'yi enable edin:\n'
                  '1. https://console.cloud.google.com/ adresine gidin\n'
                  '2. Projenizi seçin\n'
                  '3. "APIs & Services" > "Library" bölümüne gidin\n'
                  '4. "Gmail API" arayın ve "Enable" butonuna tıklayın\n'
                  '5. Birkaç dakika bekleyip tekrar deneyin';
            } else if (reason.contains('insufficientPermissions') || message.contains('permission')) {
              forbiddenMessage = 'Gmail API için yeterli izin yok. Lütfen Gmail bağlantısını yeniden yapın ve tüm izinleri verin.';
            } else {
              forbiddenMessage = 'Gmail API erişim hatası: $message\n\nDetay: $reason';
            }
          }
        } catch (e) {
          // JSON parse hatası durumunda varsayılan mesajı kullan
        }
        throw ForbiddenException(
          message: forbiddenMessage,
          originalError: response.body,
        );
      case 404:
        throw NotFoundException(
          message: errorMessage,
          originalError: response.body,
        );
      case 500:
      case 502:
      case 503:
        throw ServerException(
          message: errorMessage,
          statusCode: statusCode,
          originalError: response.body,
        );
      default:
        throw ApiException(
          message: errorMessage,
          statusCode: statusCode,
          originalError: response.body,
        );
    }
  }
}
