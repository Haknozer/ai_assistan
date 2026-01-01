import 'dart:async';
import 'dart:io' show Platform;

import 'package:ai_asisstan/core/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Conditional imports for mobile platforms
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

/// Jarvis wake word detection servisi
/// - iOS/Android: Picovoice Porcupine (optimize edilmiş, düşük gecikme)
/// - Windows: speech_to_text ile sürekli dinleme (fallback)
/// Singleton pattern ile uygulama genelinde tek instance kullanılır.
class WakeWordService {
  static final WakeWordService _instance = WakeWordService._internal();
  factory WakeWordService() => _instance;
  WakeWordService._internal();

  // Mobile (Porcupine)
  PorcupineManager? _porcupineManager;

  // Windows (speech_to_text)
  stt.SpeechToText? _speechToText;
  Timer? _restartTimer;
  bool _windowsListening = false;

  bool _isListening = false;
  bool _isInitialized = false;
  Function()? _onWakeWordDetected;

  // Picovoice Access Key
  static const String _accessKey = 'HpO+t7i5RD/hWigNX7V5Fc60NKfDeTZuiBchT54xTwJp1sdoxr+ONA==';

  /// Platform kontrolü
  bool get _isMobilePlatform => Platform.isAndroid || Platform.isIOS;
  bool get _isWindowsPlatform => Platform.isWindows;

  /// Wake word servisini başlat
  Future<void> init({required Function() onWakeWordDetected}) async {
    _onWakeWordDetected = onWakeWordDetected;

    if (_isInitialized) {
      AppLogger.info('WakeWordService already initialized', 'WAKE_WORD');
      return;
    }

    // Mikrofon iznini kontrol et
    final status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.microphone.request();
      if (result != PermissionStatus.granted) {
        AppLogger.error('Microphone permission denied!', tag: 'WAKE_WORD');
        return;
      }
    }

    if (_isMobilePlatform) {
      await _initPorcupine();
    } else if (_isWindowsPlatform) {
      await _initSpeechToText();
    } else {
      AppLogger.warning(
        'Wake word not supported on ${Platform.operatingSystem}. Use Ctrl+V.',
        'WAKE_WORD',
      );
    }
  }

  /// Mobile: Porcupine ile wake word (optimize edilmiş)
  Future<void> _initPorcupine() async {
    try {
      _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
        _accessKey,
        [BuiltInKeyword.JARVIS],
        (int keywordIndex) {
          if (keywordIndex == 0) {
            AppLogger.info('Wake word "Jarvis" detected! (Porcupine)', 'WAKE_WORD');
            _onWakeWordDetected?.call();
          }
        },
      );
      _isInitialized = true;
      AppLogger.info('WakeWordService initialized (Porcupine/Mobile)', 'WAKE_WORD');
    } on PorcupineException catch (e) {
      AppLogger.error('Porcupine init error: ${e.message}', error: e, tag: 'WAKE_WORD');
    } catch (e) {
      AppLogger.error('Unexpected error in Porcupine init', error: e, tag: 'WAKE_WORD');
    }
  }

  /// Windows: speech_to_text ile sürekli dinleme
  Future<void> _initSpeechToText() async {
    try {
      _speechToText = stt.SpeechToText();
      final available = await _speechToText!.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          AppLogger.warning('Speech error: ${error.errorMsg}', 'WAKE_WORD');
        },
      );

      if (available) {
        _isInitialized = true;
        AppLogger.info('WakeWordService initialized (speech_to_text/Windows)', 'WAKE_WORD');
      } else {
        AppLogger.error('Speech recognition not available on Windows', tag: 'WAKE_WORD');
      }
    } catch (e) {
      AppLogger.error('speech_to_text init error', error: e, tag: 'WAKE_WORD');
    }
  }

  /// Windows: Speech status callback
  void _onSpeechStatus(String status) {
    AppLogger.info('Speech status: $status', 'WAKE_WORD');

    // Dinleme durduğunda otomatik yeniden başlat (sürekli dinleme için)
    if (status == 'done' || status == 'notListening') {
      if (_windowsListening && _isInitialized) {
        // Hemen yeniden başlat (hızlı tepki için)
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(milliseconds: 300), () {
          _startWindowsListening();
        });
      }
    }
  }

  /// Wake word dinlemeyi başlat
  Future<void> startListening() async {
    if (!_isInitialized || _isListening) return;

    if (_isMobilePlatform) {
      await _startPorcupineListening();
    } else if (_isWindowsPlatform) {
      await _startWindowsListening();
    }
  }

  /// Mobile: Porcupine dinleme
  Future<void> _startPorcupineListening() async {
    if (_porcupineManager == null) return;

    try {
      await _porcupineManager!.start();
      _isListening = true;
      AppLogger.info('Wake word listening started - say "Jarvis"! (Porcupine)', 'WAKE_WORD');
    } on PorcupineException catch (e) {
      AppLogger.error('Failed to start Porcupine', error: e, tag: 'WAKE_WORD');
    }
  }

  /// Windows: speech_to_text ile sürekli dinleme
  Future<void> _startWindowsListening() async {
    if (_speechToText == null || !_speechToText!.isAvailable) return;

    // Eğer zaten dinliyorsa, dur ve yeniden başla
    if (_speechToText!.isListening) {
      await _speechToText!.stop();
    }

    _windowsListening = true;
    _isListening = true;

    try {
      await _speechToText!.listen(
        onResult: (result) {
          final text = result.recognizedWords.toLowerCase().trim();

          if (text.isNotEmpty) {
            AppLogger.info('Heard: "$text"', 'WAKE_WORD');

            // "jarvis" kelimesini kontrol et (Türkçe/İngilizce varyasyonları)
            if (text.contains('jarvis') ||
                text.contains('cervis') ||
                text.contains('carvis') ||
                text.contains('jervis') ||
                text.contains('carvıs') ||
                text.contains('jarviş') ||
                text.contains('carviş') ||
                text.contains('garviz') ||
                text.contains('djarvis') ||
                text.contains('çarvis') ||
                text.contains('charvis') ||
                text.startsWith('jar') ||
                text.endsWith('vis') ||
                text.endsWith('viş')) {
              AppLogger.info('Wake word "Jarvis" detected! (Windows)', 'WAKE_WORD');

              // Callback'i tetikle
              _onWakeWordDetected?.call();

              // Kısa süreliğine dinlemeyi durdur (çift tetiklemeyi önle)
              _windowsListening = false;
              _speechToText!.stop();
            }
          }
        },
        listenFor: const Duration(seconds: 30), // Maksimum dinleme süresi
        pauseFor: const Duration(seconds: 3), // Sessizlikte bekle (kısa = hızlı tepki)
        listenMode: stt.ListenMode.dictation,
        localeId: 'en-US', // İngilizce (Jarvis daha iyi tanınır)
      );

      AppLogger.info('Wake word listening started - say "Jarvis"! (Windows)', 'WAKE_WORD');
    } catch (e) {
      AppLogger.error('Failed to start Windows listening', error: e, tag: 'WAKE_WORD');
      _isListening = false;
      _windowsListening = false;
    }
  }

  /// Wake word dinlemeyi durdur
  Future<void> stopListening() async {
    if (!_isListening) return;

    _restartTimer?.cancel();
    _restartTimer = null;

    if (_isMobilePlatform) {
      await _stopPorcupineListening();
    } else if (_isWindowsPlatform) {
      await _stopWindowsListening();
    }
  }

  Future<void> _stopPorcupineListening() async {
    if (_porcupineManager == null) return;

    try {
      await _porcupineManager!.stop();
      _isListening = false;
      AppLogger.info('Wake word listening stopped (Porcupine)', 'WAKE_WORD');
    } on PorcupineException catch (e) {
      AppLogger.error('Failed to stop Porcupine', error: e, tag: 'WAKE_WORD');
    }
  }

  Future<void> _stopWindowsListening() async {
    _windowsListening = false;

    try {
      await _speechToText?.stop();
      _isListening = false;
      AppLogger.info('Wake word listening stopped (Windows)', 'WAKE_WORD');
    } catch (e) {
      AppLogger.error('Failed to stop Windows listening', error: e, tag: 'WAKE_WORD');
    }
  }

  /// Servisi temizle
  Future<void> dispose() async {
    await stopListening();

    _porcupineManager?.delete();
    _porcupineManager = null;

    _speechToText?.cancel();
    _speechToText = null;

    _restartTimer?.cancel();
    _restartTimer = null;

    _isInitialized = false;
  }

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
}
