import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/calendar_account.dart';

/// Calendar repository error handler
class CalendarErrorHandler {
  /// Provider adını al
  static String getProviderName(CalendarProvider provider) {
    return provider == CalendarProvider.google ? 'Google Calendar' : 'Outlook Calendar';
  }

  /// Unauthorized exception'ı handle et
  static UnauthorizedException handleUnauthorized(
    UnauthorizedException e,
    CalendarProvider provider,
  ) {
    final providerName = getProviderName(provider);
    return UnauthorizedException(
      message: 'Oturum süresi dolmuş. Lütfen $providerName bağlantısını yeniden yapın.',
      originalError: e.originalError,
    );
  }

  /// Validation exception'ı handle et
  static ApiException handleValidation(ValidationException e) {
    return ApiException(
      message: 'Event oluşturma hatası. Lütfen tüm alanların doğru olduğundan emin olun.\n\nDetay: ${e.message}',
      originalError: e.originalError,
    );
  }
}

