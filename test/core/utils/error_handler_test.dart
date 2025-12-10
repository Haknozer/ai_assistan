import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/core/utils/error_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorHandler.getUserFriendlyMessage', () {
    test('returns specific messages for ApiException with status code', () {
      expect(
        ErrorHandler.getUserFriendlyMessage(ApiException(message: 'Bad request', statusCode: 400)),
        'Bad request',
      );
      expect(
        ErrorHandler.getUserFriendlyMessage(ApiException(message: '', statusCode: 401)),
        'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.',
      );
      expect(
        ErrorHandler.getUserFriendlyMessage(ApiException(message: '', statusCode: 403)),
        'Bu işlem için yetkiniz bulunmamaktadır.',
      );
      expect(
        ErrorHandler.getUserFriendlyMessage(ApiException(message: '', statusCode: 404)),
        'İstenen kayıt bulunamadı.',
      );
      expect(
        ErrorHandler.getUserFriendlyMessage(ApiException(message: '', statusCode: 503)),
        'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.',
      );
    });

    test('handles network related exceptions', () {
      expect(
        ErrorHandler.getUserFriendlyMessage(
          NetworkException(message: 'No internet'),
        ),
        'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.',
      );

      expect(
        ErrorHandler.getUserFriendlyMessage(
          ApiException(message: 'SocketException: Failed host lookup'),
        ),
        'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.',
      );
    });

    test('handles timeout and validation errors', () {
      expect(
        ErrorHandler.getUserFriendlyMessage(
          TimeoutException(message: 'timeout'),
        ),
        'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.',
      );

      expect(
        ErrorHandler.getUserFriendlyMessage(
          ValidationException(message: 'Invalid email'),
        ),
        'Invalid email',
      );
    });

    test('falls back to generic message for unknown errors', () {
      expect(
        ErrorHandler.getUserFriendlyMessage(Exception('unknown')),
        'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
      );
    });
  });
}

