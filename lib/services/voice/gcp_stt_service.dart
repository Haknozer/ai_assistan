import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_asisstan/core/config/app_config.dart';
import 'package:ai_asisstan/services/voice/gcp_auth_service.dart';
import 'package:http/http.dart' as http;

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

    print('GcpSttService: Sending ${bytes.length} bytes to STT (config: ${payload['config']})');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      print('GcpSttService Error: ${response.statusCode} - ${response.body}');
      throw Exception('STT failed: ${response.body}');
    }

    print('GcpSttService Response: ${response.body}');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      print('GcpSttService: Results list is empty or null.');
      throw Exception('No transcription result');
    }

    final alternatives = (results.first as Map<String, dynamic>)['alternatives'] as List<dynamic>?;
    if (alternatives == null || alternatives.isEmpty) {
      throw Exception('No alternatives returned from STT');
    }

    return (alternatives.first as Map<String, dynamic>)['transcript'] as String? ?? '';
  }
}

