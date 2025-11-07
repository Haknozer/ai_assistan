import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../core/api/api_exceptions.dart';
import '../core/config/app_config.dart';
import 'location_service.dart';
import 'weather/geocoding_helper.dart';
import 'weather/timezone_utils.dart';

/// Hava durumu servisi - OpenWeatherMap One Call API 3.0 kullanıyor
class WeatherService {
  final LocationService _locationService;
  final String _apiKey;
  final GeocodingHelper _geocodingHelper;
  static const String _oneCallBaseUrl = 'https://api.openweathermap.org/data/3.0/onecall';

  WeatherService({
    LocationService? locationService,
    String? apiKey,
    GeocodingHelper? geocodingHelper,
  })  : _locationService = locationService ?? LocationService(),
        _apiKey = apiKey ?? AppConfig.weatherApiKey,
        _geocodingHelper = geocodingHelper ?? GeocodingHelper(apiKey: apiKey ?? AppConfig.weatherApiKey);

  /// One Call API ile hava durumunu al (enlem-boylam ile)
  Future<Weather?> getWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw ApiException(
          message: 'Hava durumu API anahtarı yapılandırılmamış',
        );
      }

      debugPrint('📍 Konum alındı: Lat=$latitude, Lon=$longitude');

      // Geocoding API ile şehir ve ülke bilgisini al
      final geocodingResult = await _geocodingHelper.getLocationInfo(
        latitude: latitude,
        longitude: longitude,
      );

      // One Call API 3.0'ı çağır
      final url = '$_oneCallBaseUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&lang=tr';
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final timezone = data['timezone'] as String? ?? '';
        debugPrint('🌍 Timezone: $timezone');

        // Şehir ve ülke bilgisini belirle (geocoding → timezone fallback)
        String cityName = geocodingResult.cityName;
        String country = geocodingResult.country;

        if (cityName.isEmpty) {
          cityName = TimezoneUtils.extractCityFromTimezone(timezone);
          debugPrint('🏙️ Timezone\'dan çıkarılan şehir adı: $cityName');
        }

        if (country.isEmpty) {
          country = TimezoneUtils.extractCountryFromTimezone(timezone);
        }

        debugPrint('✅ Final şehir adı: $cityName, Ülke: $country');

        return _parseOneCallWeatherData(data, cityName, country, timezone);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException(
          message: 'Hava durumu API anahtarı geçersiz',
        );
      } else if (response.statusCode == 403) {
        throw ForbiddenException(
          message: 'One Call API 3.0 için abonelik gerekli. Lütfen OpenWeatherMap hesabınızı kontrol edin.',
        );
      } else {
        throw ApiException(
          message: 'Hava durumu verisi alınamadı: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Ağ hatası: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Hava durumu servisi hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Mevcut konuma göre hava durumunu al
  Future<Weather?> getCurrentLocationWeather() async {
    final position = await _locationService.getCurrentLocation();
    if (position == null) {
      throw ApiException(
        message: 'Konum alınamadı. Lütfen konum iznini kontrol edin.',
      );
    }
    return getWeatherByCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Şehir adına göre hava durumunu al
  /// Not: Şehir adından koordinat bulmak için geocoding API gerekir
  /// Şimdilik bu metod kullanılmıyor, sadece koordinat bazlı sorgu yapılıyor
  @Deprecated('Şehir adından sorgu için geocoding API gerekli. Koordinat bazlı sorgu kullanın.')
  Future<Weather?> getWeatherByCityName(String cityName) async {
    throw ApiException(
      message: 'Şehir adından sorgu şu anda desteklenmiyor. Lütfen koordinat bazlı sorgu kullanın.',
    );
  }

  /// One Call API verisini parse et
  Weather _parseOneCallWeatherData(
    Map<String, dynamic> data,
    String cityName,
    String country,
    String timezone,
  ) {
    final current = data['current'] as Map<String, dynamic>;
    final weather = (current['weather'] as List<dynamic>).first as Map<String, dynamic>;

    // One Call API 3.0'da wind_speed ve wind_deg direkt current içinde
    final windSpeed = (current['wind_speed'] as num? ?? 0).toDouble();
    final windDeg = (current['wind_deg'] as int? ?? 0);

    return Weather(
      temperature: (current['temp'] as num).toDouble(),
      feelsLike: (current['feels_like'] as num).toDouble(),
      humidity: current['humidity'] as int,
      pressure: (current['pressure'] as num).toDouble(),
      windSpeed: windSpeed,
      windDirection: windDeg,
      description: weather['description'] as String? ?? '',
      icon: weather['icon'] as String? ?? '01d',
      city: cityName.isNotEmpty ? cityName : 'Bilinmeyen',
      country: country,
      timezone: timezone,
      timestamp: DateTime.fromMillisecondsSinceEpoch((current['dt'] as int) * 1000),
    );
  }

  /// One Call API ile saatlik hava durumu tahmini
  Future<List<Weather>> getHourlyForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw ApiException(
          message: 'Hava durumu API anahtarı yapılandırılmamış',
        );
      }

      // Geocoding API ile şehir ve ülke bilgisini al
      final geocodingResult = await _geocodingHelper.getLocationInfo(
        latitude: latitude,
        longitude: longitude,
      );

      // One Call API 3.0'ı çağır
      final url = '$_oneCallBaseUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&lang=tr';
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final hourly = data['hourly'] as List<dynamic>? ?? [];
        final timezone = data['timezone'] as String? ?? '';

        // Şehir ve ülke bilgisini belirle
        String cityName = geocodingResult.cityName;
        String country = geocodingResult.country;

        if (cityName.isEmpty) {
          cityName = TimezoneUtils.extractCityFromTimezone(timezone);
        }
        if (country.isEmpty) {
          country = TimezoneUtils.extractCountryFromTimezone(timezone);
        }

        return hourly.map((item) {
          final weather = (item['weather'] as List<dynamic>).first as Map<String, dynamic>;
          final dt = item['dt'] as int;

          // One Call API 3.0'da wind_speed ve wind_deg direkt item içinde
          final windSpeed = (item['wind_speed'] as num? ?? 0).toDouble();
          final windDeg = (item['wind_deg'] as int? ?? 0);

          return Weather(
            temperature: (item['temp'] as num).toDouble(),
            feelsLike: (item['feels_like'] as num).toDouble(),
            humidity: item['humidity'] as int,
            pressure: (item['pressure'] as num).toDouble(),
            windSpeed: windSpeed,
            windDirection: windDeg,
            description: weather['description'] as String? ?? '',
            icon: weather['icon'] as String? ?? '01d',
            city: cityName.isNotEmpty ? cityName : 'Bilinmeyen',
            country: country,
            timezone: timezone,
            timestamp: DateTime.fromMillisecondsSinceEpoch(dt * 1000),
          );
        }).toList();
      } else {
        throw ApiException(
          message: 'Saatlik tahmin alınamadı: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Saatlik tahmin servisi hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// One Call API ile günlük hava durumu tahmini
  Future<List<Weather>> getDailyForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw ApiException(
          message: 'Hava durumu API anahtarı yapılandırılmamış',
        );
      }

      // Geocoding API ile şehir ve ülke bilgisini al
      final geocodingResult = await _geocodingHelper.getLocationInfo(
        latitude: latitude,
        longitude: longitude,
      );

      // One Call API 3.0'ı çağır
      final url = '$_oneCallBaseUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&lang=tr';
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final daily = data['daily'] as List<dynamic>? ?? [];
        final timezone = data['timezone'] as String? ?? '';

        // Şehir ve ülke bilgisini belirle
        String cityName = geocodingResult.cityName;
        String country = geocodingResult.country;

        if (cityName.isEmpty) {
          cityName = TimezoneUtils.extractCityFromTimezone(timezone);
        }
        if (country.isEmpty) {
          country = TimezoneUtils.extractCountryFromTimezone(timezone);
        }

        return daily.map((item) {
          final temp = item['temp'] as Map<String, dynamic>;
          final weather = (item['weather'] as List<dynamic>).first as Map<String, dynamic>;
          // One Call API 3.0'da wind_speed ve wind_deg direkt item içinde
          final windSpeed = (item['wind_speed'] as num? ?? 0).toDouble();
          final windDeg = (item['wind_deg'] as int? ?? 0);
          final dt = item['dt'] as int;

          return Weather(
            temperature: (temp['day'] as num).toDouble(),
            feelsLike: (item['feels_like']?['day'] as num? ?? temp['day'] as num).toDouble(),
            humidity: item['humidity'] as int,
            pressure: (item['pressure'] as num).toDouble(),
            windSpeed: windSpeed,
            windDirection: windDeg,
            description: weather['description'] as String? ?? '',
            icon: weather['icon'] as String? ?? '01d',
            city: cityName.isNotEmpty ? cityName : 'Bilinmeyen',
            country: country,
            timezone: timezone,
            timestamp: DateTime.fromMillisecondsSinceEpoch(dt * 1000),
          );
        }).toList();
      } else {
        throw ApiException(
          message: 'Günlük tahmin alınamadı: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Günlük tahmin servisi hatası: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
