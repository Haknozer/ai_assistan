import 'package:flutter/material.dart';
import '../../../../models/weather.dart';

/// Hava durumu görüntüleme yardımcı fonksiyonları
class WeatherDisplayUtils {
  /// Şehir ve ülke bilgisini formatla
  static String getLocationText(Weather weather) {
    // Önce şehir adını kullan (geocoding API'den geliyor)
    String displayText = weather.city.isNotEmpty ? weather.city : 'Bilinmeyen';
    final country = weather.country.isNotEmpty ? weather.country : '';

    // Eğer şehir adı yoksa veya "Bilinmeyen" ise, timezone'dan şehir adını çıkar
    if (displayText == 'Bilinmeyen' && weather.timezone.isNotEmpty) {
      final timezoneParts = weather.timezone.split('/');
      if (timezoneParts.length >= 2) {
        displayText = timezoneParts.last.replaceAll('_', ' ');
      }
    }

    if (country.isNotEmpty) {
      return '$displayText, $country';
    }
    return displayText;
  }

  /// İkon koduna göre hava durumu ikonu döndür
  static IconData getWeatherIcon(String iconCode) {
    // OpenWeatherMap icon kodlarına göre ikon döndür
    if (iconCode.contains('01')) return Icons.wb_sunny; // Clear sky
    if (iconCode.contains('02')) return Icons.wb_cloudy; // Few clouds
    if (iconCode.contains('03') || iconCode.contains('04')) {
      return Icons.cloud; // Scattered/Broken clouds
    }
    if (iconCode.contains('09') || iconCode.contains('10')) {
      return Icons.grain; // Rain
    }
    if (iconCode.contains('11')) return Icons.flash_on; // Thunderstorm
    if (iconCode.contains('13')) return Icons.ac_unit; // Snow
    if (iconCode.contains('50')) return Icons.blur_on; // Mist
    return Icons.wb_sunny; // Default
  }

  /// İlk harfi büyük yap
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

