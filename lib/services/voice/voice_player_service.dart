import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import '../../core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Bellekteki MP3/WAV verisini çalmak için basit player (AudioPlayers Versiyonu).
class VoicePlayerService {
  static final VoicePlayerService _instance = VoicePlayerService._internal();
  factory VoicePlayerService() => _instance;
  VoicePlayerService._internal() {
    // Windows için gerekli olabilir, AudioContext ayarları
    // _player.setAudioContext(...)
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> playBytes(
    Uint8List bytes, {
    String fileExtension = 'mp3',
  }) async {
    try {
      await _player.stop();
      await _player.setVolume(1.0);

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/voice_tts_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
      );

      AppLogger.debug('Writing ${bytes.length} bytes to ${file.path}', 'VOICE_PLAYER');
      await file.writeAsBytes(bytes, flush: true);

      if (!await file.exists()) {
        throw Exception('TTS dosyası oluşturulamadı: ${file.path}');
      }

      AppLogger.debug('Setting source to DeviceFileSource...', 'VOICE_PLAYER');
      await _player.setSource(DeviceFileSource(file.path));

      AppLogger.debug('Starting playback...', 'VOICE_PLAYER');
      await _player.resume(); // play() yerine setSource + resume ya da play(DeviceFileSource)
      AppLogger.info('Playback started', 'VOICE_PLAYER');
    } catch (e) {
      AppLogger.error('VoicePlayerService Exception', error: e, tag: 'VOICE_PLAYER');
      rethrow;
    }
  }

  /// İnternetten güvenilir bir MP3 çalarak testi gerçekleştirir.
  Future<void> playTestSound() async {
    AppLogger.info('Playing remote test sound (AudioPlayers)...', 'VOICE_PLAYER');
    try {
      await _player.stop();
      await _player.setVolume(1.0);

      const url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      AppLogger.debug('Loading URL: $url', 'VOICE_PLAYER');

      await _player.play(UrlSource(url));

      AppLogger.info('Starting playback...', 'VOICE_PLAYER');
    } catch (e) {
      AppLogger.error('VoicePlayerService Test Sound Error', error: e, tag: 'VOICE_PLAYER');

      // Fallback: Windows notify sesi
      try {
        AppLogger.info('Trying system sound fallback...', 'VOICE_PLAYER');
        await Process.run(
            'powershell', ['-c', '(New-Object Media.SoundPlayer "C:\\Windows\\Media\\notify.wav").PlaySync();']);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
