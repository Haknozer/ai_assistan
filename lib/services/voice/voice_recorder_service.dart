import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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
      final levelDb = amp.current ?? 0;
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

      print('VoiceRecorderService: Starting recording to $filePath');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: filePath,
      );
    } catch (e) {
      print('VoiceRecorderService start error: $e');
      rethrow;
    }
  }

  /// Stops recording and returns the recorded file.
  Future<File> stop() async {
    print('VoiceRecorderService: Stopping recording...');
    await _ampSub?.cancel();
    _ampSub = null;

    try {
      final path = await _recorder.stop();
      final filePath = path ?? _currentPath;
      
      print('VoiceRecorderService: Stop returned path: $path, using: $filePath');

      if (filePath == null) {
        throw Exception('No recording path available.');
      }
      
      final file = File(filePath);
      
      // Wait a bit for file to be flushed if not exists immediately
      if (!await file.exists()) {
        print('VoiceRecorderService: File not found immediately, waiting 200ms...');
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (!await file.exists()) {
        print('VoiceRecorderService: File still not found at $filePath');
        throw Exception('Recording file not found at $filePath');
      }
      
      final len = await file.length();
      print('VoiceRecorderService: Recording saved, size: $len bytes');
      if (len == 0) {
         print('VoiceRecorderService Warning: File is empty!');
      }

      return file;
    } catch (e) {
      print('VoiceRecorderService stop error: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _ampSub?.cancel();
    await _recorder.dispose();
  }
}

