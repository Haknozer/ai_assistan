import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as gauth;

/// Service account tabanlı kısa ömürlü access token üretir.
class GcpAuthService {
  final String serviceAccountPath;
  final List<String> scopes;

  gauth.AccessCredentials? _cached;

  GcpAuthService({
    required this.serviceAccountPath,
    this.scopes = const [
      'https://www.googleapis.com/auth/cloud-platform',
    ],
  });

  Future<String> getAccessToken() async {
    // Eğer cache edilmiş ve süresi dolmamış token varsa kullan
    if (_cached != null && _cached!.accessToken.expiry.isAfter(DateTime.now().add(const Duration(minutes: 2)))) {
      return _cached!.accessToken.data;
    }

    final file = File(serviceAccountPath);
    if (!await file.exists()) {
      throw Exception('Service account file not found: $serviceAccountPath');
    }

    final jsonMap = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final credentials = gauth.ServiceAccountCredentials.fromJson(jsonMap);

    final client = await gauth.clientViaServiceAccount(credentials, scopes);
    _cached = client.credentials;
    final token = _cached!.accessToken.data;
    client.close();
    return token;
  }
}

