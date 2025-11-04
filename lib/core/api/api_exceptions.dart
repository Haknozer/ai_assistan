/// API istekleri sırasında oluşan hataları temsil eden exception sınıfları

/// Genel API hatası
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Ağ bağlantı hatası
class NetworkException extends ApiException {
  NetworkException({
    required super.message,
    super.originalError,
  }) : super(statusCode: null);
}

/// Timeout hatası
class TimeoutException extends ApiException {
  TimeoutException({
    required super.message,
    super.originalError,
  }) : super(statusCode: null);
}

/// Yetkilendirme hatası (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException({
    required super.message,
    super.originalError,
  }) : super(statusCode: 401);
}

/// Yasak erişim hatası (403)
class ForbiddenException extends ApiException {
  ForbiddenException({
    required super.message,
    super.originalError,
  }) : super(statusCode: 403);
}

/// Kaynak bulunamadı hatası (404)
class NotFoundException extends ApiException {
  NotFoundException({
    required super.message,
    super.originalError,
  }) : super(statusCode: 404);
}

/// Sunucu hatası (500+)
class ServerException extends ApiException {
  ServerException({
    required super.message,
    super.statusCode,
    super.originalError,
  });
}

/// Validasyon hatası (400)
class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException({
    required super.message,
    this.errors,
    super.originalError,
  }) : super(statusCode: 400);
}

