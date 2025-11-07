import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Geocoding API yardımcı sınıfı - Şehir ve ülke bilgisi çıkarma
class GeocodingHelper {
  final String _apiKey;
  static const String _geocodingBaseUrl = 'https://api.openweathermap.org/geo/1.0/reverse';

  GeocodingHelper({required String apiKey}) : _apiKey = apiKey;

  /// Koordinatlardan şehir ve ülke bilgisini al
  Future<GeocodingResult> getLocationInfo({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final geocodingUrl = '$_geocodingBaseUrl?lat=$latitude&lon=$longitude&limit=1&appid=$_apiKey';
      final geocodingResponse = await http.get(Uri.parse(geocodingUrl)).timeout(
            const Duration(seconds: 5),
          );

      if (geocodingResponse.statusCode == 200) {
        final geocodingData = jsonDecode(geocodingResponse.body) as List<dynamic>;
        if (geocodingData.isNotEmpty) {
          final location = geocodingData.first as Map<String, dynamic>;
          // Önce il (state), sonra şehir (name) dene
          final cityName = location['state'] as String? ??
              location['name'] as String? ??
              location['local_names']?['tr'] as String? ??
              location['local_names']?['en'] as String? ??
              '';
          final country = location['country'] as String? ?? '';

          debugPrint('🏙️ Geocoding API şehir adı: $cityName, Ülke: $country');

          return GeocodingResult(
            cityName: cityName,
            country: country,
            success: true,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Geocoding API hatası: $e');
    }

    return const GeocodingResult(
      cityName: '',
      country: '',
      success: false,
    );
  }
}

/// Geocoding sonuç modeli
class GeocodingResult {
  final String cityName;
  final String country;
  final bool success;

  const GeocodingResult({
    required this.cityName,
    required this.country,
    required this.success,
  });
}
