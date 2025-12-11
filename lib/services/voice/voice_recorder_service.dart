import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/utils/logger.dart';

/// Basit push-to-talk kayıt servisi (WAV 16k mono) + sessizlik takibi.
class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSub;
  String? _currentPath;

  /// Sessizlik eşiği ve süresi ms cinsinden (örn: -45 dB, 1200 ms).
  Future<File> recordWithSilenceStop({
    required double silenceDb,
    required int silenceDurationMs,
    required int maxDurationMs,
    required void Function(Amplitude amp) onAmplitude,
  }) async {
    await start();

    final completer = Completer<File>();
    int silentMs = 0;
    final stopwatch = Stopwatch()..start();

    _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) async {
      onAmplitude(amp);
      final levelDb = amp.current;
      if (levelDb < silenceDb) {
        silentMs += 100;
      } else {
        silentMs = 0;
      }

      final elapsed = stopwatch.elapsedMilliseconds;
      if (silentMs >= silenceDurationMs || elapsed >= maxDurationMs) {
        if (!completer.isCompleted) {
          final file = await stop();
          if (await file.exists()) {
            completer.complete(file);
          } else {
            completer.completeError(Exception('Kayıt dosyası bulunamadı'));
          }
        }
      }
    });

    return completer.future;
  }

  Future<void> start() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (hasPermission != true) {
        throw Exception('Microphone permission is required.');
      }

      final dir = await getTemporaryDirectory();
      // Safe path construction
      final filePath = '${dir.path}${Platform.pathSeparator}voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentPath = filePath;

      AppLogger.debug('Starting recording to $filePath', 'VOICE_RECORDER');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: filePath,
      );
    } catch (e) {
      AppLogger.error('VoiceRecorderService start error', error: e, tag: 'VOICE_RECORDER');
      rethrow;
    }
  }

  /// Stops recording and returns the recorded file.
  Future<File> stop() async {
    AppLogger.debug('Stopping recording...', 'VOICE_RECORDER');
    await _ampSub?.cancel();
    _ampSub = null;

    try {
      final path = await _recorder.stop();
      final filePath = path ?? _currentPath;

      AppLogger.debug('Stop returned path: $path, using: $filePath', 'VOICE_RECORDER');

      if (filePath == null) {
        throw Exception('No recording path available.');
      }

      final file = File(filePath);

      // Wait a bit for file to be flushed if not exists immediately
      if (!await file.exists()) {
        AppLogger.debug('File not found immediately, waiting 200ms...', 'VOICE_RECORDER');
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (!await file.exists()) {
        AppLogger.error('File still not found at $filePath', tag: 'VOICE_RECORDER');
        throw Exception('Recording file not found at $filePath');
      }

      final len = await file.length();
      AppLogger.info('Recording saved, size: $len bytes', 'VOICE_RECORDER');
      if (len == 0) {
        AppLogger.warning('File is empty!', 'VOICE_RECORDER');
      }

      return file;
    } catch (e) {
      AppLogger.error('VoiceRecorderService stop error', error: e, tag: 'VOICE_RECORDER');
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _ampSub?.cancel();
    await _recorder.dispose();
  }
}
