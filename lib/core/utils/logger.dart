import 'package:flutter/foundation.dart';

/// Profesyonel logging sistemi
/// 
/// Debug modunda detaylı loglar, production'da sadece kritik hatalar gösterilir
class AppLogger {
  static const String _tagPrefix = '[AI Assistant]';

  /// Debug log - Sadece debug modunda gösterilir
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '$_tagPrefix[$tag]' : _tagPrefix;
      debugPrint('$tagStr DEBUG: $message');
    }
  }

  /// Info log - Önemli bilgilendirmeler
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '$_tagPrefix[$tag]' : _tagPrefix;
      debugPrint('$tagStr INFO: $message');
    }
  }

  /// Warning log - Uyarılar
  static void warning(String message, [String? tag, Object? error]) {
    final tagStr = tag != null ? '$_tagPrefix[$tag]' : _tagPrefix;
    if (kDebugMode) {
      debugPrint('$tagStr WARNING: $message');
      if (error != null) {
        debugPrint('$tagStr Error details: $error');
      }
    }
  }

  /// Error log - Hatalar (her zaman gösterilir)
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final tagStr = tag != null ? '$_tagPrefix[$tag]' : _tagPrefix;
    debugPrint('$tagStr ERROR: $message');
    if (error != null) {
      debugPrint('$tagStr Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('$tagStr Stack trace: $stackTrace');
    }
  }

  /// API log - API çağrıları için özel log
  static void api(String method, String endpoint, {int? statusCode, String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '$_tagPrefix[$tag]' : _tagPrefix;
      final status = statusCode != null ? ' [$statusCode]' : '';
      debugPrint('$tagStr API: $method $endpoint$status');
    }
  }

  /// OAuth log - OAuth işlemleri için özel log
  static void oauth(String message, {String? tag, bool isError = false}) {
    final tagStr = tag != null ? '$_tagPrefix[$tag]' : _tagPrefix;
    final level = isError ? 'ERROR' : 'INFO';
    if (kDebugMode || isError) {
      debugPrint('$tagStr OAuth [$level]: $message');
    }
  }

  /// Database log - Veritabanı işlemleri için özel log
  static void database(String operation, [String? tag]) {
    final tagStr = tag != null ? '$_tagPrefix[$tag]' : _tagPrefix;
    if (kDebugMode) {
      debugPrint('$tagStr DB: $operation');
    }
  }
}

