import 'package:ai_asisstan/core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger', () {
    late List<String?> logs;
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      logs = [];
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        logs.add(message);
      };
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
    });

    test('debug and info should log messages in debug mode', () {
      AppLogger.debug('test debug', 'API');
      AppLogger.info('test info');

      expect(
        logs.any((m) => m?.contains('[AI Assistant][API] DEBUG: test debug') ?? false),
        isTrue,
      );
      expect(
        logs.any((m) => m?.contains('[AI Assistant] INFO: test info') ?? false),
        isTrue,
      );
    });

    test('warning should log message and error details', () {
      AppLogger.warning('warn message', 'Database', 'constraint failed');

      expect(
        logs.any((m) => m?.contains('[AI Assistant][Database] WARNING: warn message') ?? false),
        isTrue,
      );
      expect(
        logs.any((m) => m?.contains('Error details: constraint failed') ?? false),
        isTrue,
      );
    });

    test('error should always log message and error', () {
      final stackTrace = StackTrace.current;

      AppLogger.error(
        'critical failure',
        tag: 'API',
        error: '500',
        stackTrace: stackTrace,
      );

      expect(
        logs.any((m) => m?.contains('[AI Assistant][API] ERROR: critical failure') ?? false),
        isTrue,
      );
      expect(logs.any((m) => m?.contains('Error: 500') ?? false), isTrue);
    });

    test('api and oauth helpers should format messages', () {
      AppLogger.api('GET', '/emails', statusCode: 200);
      AppLogger.oauth('token refreshed', isError: false);

      expect(
        logs.any((m) => m?.contains('[AI Assistant] API: GET /emails [200]') ?? false),
        isTrue,
      );
      expect(
        logs.any((m) => m?.contains('[AI Assistant] OAuth [INFO]: token refreshed') ?? false),
        isTrue,
      );
    });
  });
}

