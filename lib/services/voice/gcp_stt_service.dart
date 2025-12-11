import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_asisstan/core/config/app_config.dart';
import 'package:ai_asisstan/services/voice/gcp_auth_service.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/logger.dart';

/// Google Cloud Speech-to-Text entegrasyonu.
class GcpSttService {
  final GcpAuthService authService;
  final String languageCode;
  final int sampleRateHertz;

  GcpSttService({
    required this.authService,
    String? languageCode,
    this.sampleRateHertz = 16000,
  }) : languageCode = languageCode ?? AppConfig.gcpSttLanguage;

  Future<String> transcribeFile(File file) async {
    final bytes = await file.readAsBytes();
    return transcribeBytes(bytes);
  }

  Future<String> transcribeBytes(Uint8List bytes) async {
    final token = await authService.getAccessToken();
    final uri = Uri.parse('https://speech.googleapis.com/v1/speech:recognize');

    final payload = {
      'config': {
        'languageCode': languageCode,
        'encoding': 'LINEAR16',
        'sampleRateHertz': sampleRateHertz,
      },
      'audio': {
        'content': base64Encode(bytes),
      },
    };

    AppLogger.debug(
      'Sending ${bytes.length} bytes to STT (config: ${payload['config']})',
      'VOICE_STT',
    );

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
        'GcpSttService Error: ${response.statusCode} - ${response.body}',
        tag: 'VOICE_STT',
      );
      throw Exception('STT failed: ${response.body}');
    }

    AppLogger.debug('GcpSttService Response: ${response.body}', 'VOICE_STT');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      AppLogger.error('GcpSttService: Results list is empty or null.', tag: 'VOICE_STT');
      throw Exception('No transcription result');
    }

    final alternatives = (results.first as Map<String, dynamic>)['alternatives'] as List<dynamic>?;
    if (alternatives == null || alternatives.isEmpty) {
      throw Exception('No alternatives returned from STT');
    }

    return (alternatives.first as Map<String, dynamic>)['transcript'] as String? ?? '';
  }
}
