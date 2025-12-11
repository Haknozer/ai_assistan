import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_asisstan/core/config/app_config.dart';
import 'package:ai_asisstan/core/utils/logger.dart';
import 'package:ai_asisstan/services/voice/gcp_auth_service.dart';
import 'package:http/http.dart' as http;

/// Google Cloud Text-to-Speech entegrasyonu.
class GcpTtsService {
  final GcpAuthService authService;
  final String voiceName;
  final String languageCode;
  final String audioEncoding;

  GcpTtsService({
    required this.authService,
    String? voiceName,
    String? languageCode,
    String? audioEncoding,
  })  : voiceName = voiceName ?? AppConfig.gcpTtsVoice,
        languageCode = languageCode ?? AppConfig.gcpSttLanguage,
        audioEncoding = audioEncoding ?? AppConfig.gcpTtsEncoding;

  Future<Uint8List> synthesize(String text) async {
    try {
      final token = await authService.getAccessToken();
      final uri = Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize');

      final payload = {
        'input': {'text': text},
        'voice': {
          'languageCode': languageCode,
          'name': voiceName,
        },
        'audioConfig': {
          'audioEncoding': audioEncoding,
        },
      };

      AppLogger.debug(
        'Requesting TTS for "${text.substring(0, text.length > 20 ? 20 : text.length)}..."',
        'VOICE_TTS',
      );
      AppLogger.debug('Voice=$voiceName, Lang=$languageCode', 'VOICE_TTS');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        AppLogger.error(
          'GcpTtsService Error: ${response.statusCode} body=${response.body}',
          tag: 'VOICE_TTS',
        );
        throw Exception('TTS failed (${response.statusCode}): ${response.body}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final audioContent = body['audioContent'] as String?;
      if (audioContent == null) {
        throw Exception('No audio content returned from TTS');
      }

      AppLogger.info('Success, audio length: ${audioContent.length}', 'VOICE_TTS');
      return base64Decode(audioContent);
    } catch (e) {
      AppLogger.error('GcpTtsService Exception', error: e, tag: 'VOICE_TTS');
      rethrow;
    }
  }
}
