import 'dart:async';
import 'dart:io';

import 'package:ai_asisstan/core/utils/error_handler.dart';
import 'package:ai_asisstan/core/utils/logger.dart';
import 'package:ai_asisstan/services/voice/gcp_auth_service.dart';
import 'package:ai_asisstan/services/voice/gcp_stt_service.dart';
import 'package:ai_asisstan/services/voice/gcp_tts_service.dart';
import 'package:ai_asisstan/services/voice/voice_player_service.dart';
import 'package:ai_asisstan/services/voice/voice_recorder_service.dart';
import 'package:ai_asisstan/presentation/widgets/voice/voice_bubbles.dart';
import 'package:ai_asisstan/presentation/widgets/voice/voice_control_panel.dart';
import 'package:ai_asisstan/presentation/widgets/voice/voice_sheet_header.dart';
import 'package:ai_asisstan/presentation/widgets/voice/voice_types.dart';
import 'package:ai_asisstan/presentation/widgets/voice/voice_error_banner.dart';
import 'package:flutter/material.dart';

bool _isVoiceSheetOpen = false;

Future<void> showVoiceCommandSheet(
  BuildContext context, {
  required String serviceAccountPath,
  required String languageCode,
  required String voiceName,
  required String audioEncoding,
  required String userId,
  double? latitude,
  double? longitude,
  Future<String?> Function(String text)? onSendVoice,
}) {
  // Toggle davranışı: açıksa kapat, değilse aç
  if (_isVoiceSheetOpen) {
    Navigator.of(context, rootNavigator: true).pop();
    return Future.value();
  }

  return showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => VoiceCommandSheet(
      serviceAccountPath: serviceAccountPath,
      languageCode: languageCode,
      voiceName: voiceName,
      audioEncoding: audioEncoding,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      onSendVoice: onSendVoice,
    ),
  ).whenComplete(() {
    _isVoiceSheetOpen = false;
  });
}

class VoiceCommandSheet extends StatefulWidget {
  final String serviceAccountPath;
  final String languageCode;
  final String voiceName;
  final String audioEncoding;
  final String userId;
  final double? latitude;
  final double? longitude;
  final Future<String?> Function(String text)? onSendVoice;

  const VoiceCommandSheet({
    super.key,
    required this.serviceAccountPath,
    required this.languageCode,
    required this.voiceName,
    required this.audioEncoding,
    required this.userId,
    this.latitude,
    this.longitude,
    this.onSendVoice,
  });

  @override
  State<VoiceCommandSheet> createState() => _VoiceCommandSheetState();
}

class _VoiceCommandSheetState extends State<VoiceCommandSheet> {
  late final VoiceRecorderService _recorder;
  late final VoicePlayerService _player;
  late final GcpAuthService _auth;
  late final GcpSttService _stt;
  late final GcpTtsService _tts;

  VoiceStep _step = VoiceStep.idle;
  String _transcript = '';
  String _reply = '';
  String? _error;
  int _currentDb = 0;

  @override
  void initState() {
    super.initState();
    _isVoiceSheetOpen = true;
    _recorder = VoiceRecorderService();
    _player = VoicePlayerService();
    _auth = GcpAuthService(serviceAccountPath: widget.serviceAccountPath);
    _stt = GcpSttService(authService: _auth, languageCode: widget.languageCode);
    _tts = GcpTtsService(
      authService: _auth,
      voiceName: widget.voiceName,
      languageCode: widget.languageCode,
      audioEncoding: widget.audioEncoding,
    );
    // Sheet açılır açılmaz kayda başla (push-to-talk'e basmadan)
    WidgetsBinding.instance.addPostFrameCallback((_) => _startOnOpen());
  }

  @override
  void dispose() {
    _recorder.dispose();
    // _player.dispose(); // Singleton olduğu için dispose etmiyoruz, ses kesilmesin.
    super.dispose();
  }

  void _setStep(VoiceStep step, {String? error}) {
    if (!mounted) {
      // Widget dispose olsa bile internal state'i güncellemek isteyebiliriz ama setState çağıramayız.
      // Bu yüzden sadece log basıp geçiyoruz.
      AppLogger.info('VoiceCommandSheet unmounted, skipping UI update for step: $step', 'VOICE');
      _step = step; // State'i güncel tutalım (gerçi dispose olduysa çok önemli değil ama logic için)
      return;
    }
    setState(() {
      _step = step;
      _error = error;
    });
  }

  Future<void> _startOnOpen() async {
    if (_step != VoiceStep.idle) return;

    // Varsayılan otomatik mesaj (istek üzerine)
    const kickoffMessage = 'Ayarlar Sayfasına Git.';
    if (widget.onSendVoice != null) {
      // 1. Düşünüyor moduna geç
      _setStep(VoiceStep.thinking);
      try {
        // 2. Mesajı gönder ve cevabı bekle
        final reply = await widget.onSendVoice!(kickoffMessage);

        // 3. Cevap varsa konuş
        if (reply != null && reply.isNotEmpty) {
          await _speak(reply);
        }
      } catch (e) {
        AppLogger.error('Kickoff message failed', error: e, tag: 'VOICE');
      }
      // 4. İşlem bitince idle ol
      _setStep(VoiceStep.idle);
    } else {
      // Callback yoksa normal akış (kayıt başlat)
      await _toggleRecording();
    }
  }

  Future<void> _speak(String text) async {
    _reply = text;
    _setStep(VoiceStep.speaking);
    try {
      AppLogger.info('TTS start (len=${text.length})', 'VOICE');
      // Emojileri temizle
      final cleanReply = text.replaceAll(RegExp(r'[^\w\s\d.,!?-çğıöşüÇĞIÖŞÜ]', unicode: true), '').trim();

      AppLogger.debug('Original text: "$text"', 'VOICE');
      AppLogger.debug('Sanitized text for TTS: "$cleanReply"', 'VOICE');

      if (cleanReply.isNotEmpty) {
        final audio = await _tts.synthesize(cleanReply);
        AppLogger.debug(
          'Audio bytes received matching sanitized text: ${audio.length}',
          'VOICE',
        );

        // Encoding'e göre dosya uzantısı belirle (MP3 dönüldüğü için MP3)
        // AppConfig'den okuyabiliriz ama basitleştirmek için mp3 varsayıyoruz (zaten düzelttik)
        final ext = widget.audioEncoding == 'LINEAR16' ? 'wav' : 'mp3';
        await _player.playBytes(audio, fileExtension: ext);
      } else {
        AppLogger.info('Text empty after sanitization, skipping TTS.', 'VOICE');
      }

      AppLogger.info('TTS playback finished', 'VOICE');
    } catch (e, st) {
      AppLogger.error('TTS play failed', error: e, stackTrace: st, tag: 'VOICE');
    }
  }

  Future<void> _toggleRecording() async {
    if (_step == VoiceStep.listening) {
      await _stopAndProcess();
      return;
    }

    try {
      _transcript = '';
      _reply = '';
      _setStep(VoiceStep.listening);
      // Sessizlik bazlı otomatik durdurma
      final file = await _recorder.recordWithSilenceStop(
        silenceDb: -45, // eşiğin altı sessizlik
        silenceDurationMs: 1200, // 1.2s sessizlikte durdur
        maxDurationMs: 15000, // 15s güvenlik sınırı
        onAmplitude: (amp) {
          final val = amp.current;
          final safe = (val.isFinite) ? val.round() : 0;
          setState(() {
            _currentDb = safe;
          });
        },
      );
      // Sessizlikle durduysa doğrudan işleme geç
      await _stopAndProcess(fileOverride: file);
    } catch (e, st) {
      _setStep(VoiceStep.error, error: ErrorHandler.getUserFriendlyMessage(e));
      AppLogger.error('Recording start failed', error: e, stackTrace: st, tag: 'VOICE');
    }
  }

  Future<void> _stopAndProcess({File? fileOverride}) async {
    try {
      _setStep(VoiceStep.thinking);
      final File file = fileOverride ?? await _recorder.stop();
      if (!await file.exists()) {
        throw Exception('Kayıt dosyası bulunamadı');
      }

      final transcript = await _stt.transcribeFile(file);
      _transcript = transcript;

      // Chat ekranı ile aynı akış: onSendVoice callback'i varsa onu kullan ve cevabı konuş
      if (widget.onSendVoice != null) {
        final reply = await widget.onSendVoice!(transcript);
        AppLogger.info('Voice reply received: ${reply?.length ?? 0} chars', 'VOICE');

        if (reply != null && reply.isNotEmpty) {
          await _speak(reply);
        } else {
          AppLogger.info('No reply to speak (empty or null)', 'VOICE');
        }
      }

      _setStep(VoiceStep.idle);
    } catch (e, st) {
      // DEBUG: Show full error to user for debugging
      _setStep(VoiceStep.error, error: 'Hata: $e');
      AppLogger.error('Voice pipeline failed', error: e, stackTrace: st, tag: 'VOICE');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VoiceSheetHeader(onClose: () => Navigator.of(context).pop()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (_error != null) VoiceErrorBanner(error: _error!),
                VoiceControlPanel(
                  step: _step,
                  currentDb: _currentDb,
                  onToggleRecording: _toggleRecording,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          VoiceBubbles(
            transcript: _transcript,
            reply: _reply,
          ),
        ],
      ),
    );
  }
}
