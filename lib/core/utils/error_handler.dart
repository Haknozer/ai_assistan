import 'package:flutter/material.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/core/utils/logger.dart';

/// Merkezi hata yönetimi ve kullanıcı dostu mesajlar
class ErrorHandler {
  /// Hata mesajını kullanıcı dostu formata çevir
  static String getUserFriendlyMessage(dynamic error) {
    if (error is ApiException) {
      return _getApiErrorMessage(error);
    }

    if (error is NetworkException) {
      return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
    }

    if (error is TimeoutException) {
      return 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }

    if (error is UnauthorizedException) {
      return 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.';
    }

    if (error is ForbiddenException) {
      return 'Bu işlem için yetkiniz bulunmamaktadır.';
    }

    if (error is NotFoundException) {
      return 'İstenen kayıt bulunamadı.';
    }

    if (error is ServerException) {
      return 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.';
    }

    if (error is ValidationException) {
      return error.message;
    }

    // Genel hata
    final errorStr = error.toString();
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Failed host lookup') ||
        errorStr.contains('Network is unreachable')) {
      return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
    }

    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  }

  /// API hata mesajını kullanıcı dostu formata çevir
  static String _getApiErrorMessage(ApiException error) {
    // Özel mesajlar varsa onları kullan
    if (error.message.isNotEmpty) {
      return error.message;
    }

    // Status code'a göre genel mesajlar
    switch (error.statusCode) {
      case 400:
        return 'Geçersiz istek. Lütfen girdiğiniz bilgileri kontrol edin.';
      case 401:
        return 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.';
      case 403:
        return 'Bu işlem için yetkiniz bulunmamaktadır.';
      case 404:
        return 'İstenen kayıt bulunamadı.';
      case 500:
      case 502:
      case 503:
        return 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Hatayı logla ve kullanıcıya göster
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? tag,
    StackTrace? stackTrace,
    VoidCallback? onRetry,
  }) {
    // Hatayı logla
    AppLogger.error(
      getUserFriendlyMessage(error),
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    // Kullanıcıya göster
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getUserFriendlyMessage(error)),
          backgroundColor: Colors.red,
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Tekrar Dene',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Sadece logla, kullanıcıya gösterme (sessiz hatalar için)
  static void logError(
    dynamic error, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    AppLogger.error(
      getUserFriendlyMessage(error),
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Başarı mesajı göster
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: duration,
        ),
      );
    }
  }

  /// Bilgilendirme mesajı göster
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
        ),
      );
    }
  }
}

