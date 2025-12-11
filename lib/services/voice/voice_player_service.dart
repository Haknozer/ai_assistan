import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as Math;

import 'package:audioplayers/audioplayers.dart';
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
      
      print('VoicePlayerService: Writing ${bytes.length} bytes to ${file.path}');
      await file.writeAsBytes(bytes, flush: true);

      if (!await file.exists()) {
        throw Exception('TTS dosyası oluşturulamadı: ${file.path}');
      }

      print('VoicePlayerService: Setting source to DeviceFileSource...');
      await _player.setSource(DeviceFileSource(file.path));
      
      print('VoicePlayerService: Starting playback...');
      await _player.resume(); // play() yerine setSource + resume ya da play(DeviceFileSource)
      print('VoicePlayerService: Playback started');
    } catch (e) {
      print('VoicePlayerService Exception: $e');
      rethrow;
    }
  }

  /// İnternetten güvenilir bir MP3 çalarak testi gerçekleştirir.
  Future<void> playTestSound() async {
    print('VoicePlayerService: Playing remote test sound (AudioPlayers)...');
    try {
      await _player.stop();
      await _player.setVolume(1.0);
      
      const url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      print('VoicePlayerService: Loading URL: $url');
      
      await _player.play(UrlSource(url));
      
      print('VoicePlayerService: Starting playback...');
    } catch (e) {
      print('VoicePlayerService Test Sound Error: $e');
      
      // Fallback: Windows notify sesi
      try {
         print('VoicePlayerService: Trying system sound fallback...');
         await Process.run('powershell', ['-c', '(New-Object Media.SoundPlayer "C:\\Windows\\Media\\notify.wav").PlaySync();']);
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

