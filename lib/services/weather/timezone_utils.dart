/// Timezone yardımcı fonksiyonları - Şehir ve ülke çıkarma
class TimezoneUtils {
  /// Timezone'dan şehir adını çıkar (örn: "Europe/Istanbul" -> "İstanbul")
  static String extractCityFromTimezone(String timezone) {
    if (timezone.isEmpty) return '';

    // Timezone formatı: "Continent/City" veya "Country/City"
    final parts = timezone.split('/');
    if (parts.length >= 2) {
      final city = parts.last;
      // Türkçe şehir adları için özel dönüşümler
      final cityMap = {
        'Istanbul': 'İstanbul',
        'Ankara': 'Ankara',
        'Izmir': 'İzmir',
        'Konya': 'Konya',
        'Antalya': 'Antalya',
        'Bursa': 'Bursa',
        'Adana': 'Adana',
        'Gaziantep': 'Gaziantep',
        'Kayseri': 'Kayseri',
        'Mersin': 'Mersin',
        'Chicago': 'Chicago',
        'New_York': 'New York',
        'London': 'London',
        'Paris': 'Paris',
        'Berlin': 'Berlin',
        'Rome': 'Rome',
        'Madrid': 'Madrid',
      };

      return cityMap[city] ?? city.replaceAll('_', ' ');
    }

    return '';
  }

  /// Timezone'dan ülke kodunu çıkar (örn: "Europe/Istanbul" -> "TR")
  static String extractCountryFromTimezone(String timezone) {
    if (timezone.isEmpty) return '';

    // Timezone'a göre ülke kodları
    final timezoneCountryMap = {
      // Türkiye
      'Europe/Istanbul': 'TR',
      'Europe/Konya': 'TR',
      'Europe/Ankara': 'TR',
      'Europe/Izmir': 'TR',
      // Amerika
      'America/Chicago': 'US',
      'America/New_York': 'US',
      'America/Los_Angeles': 'US',
      'America/Denver': 'US',
      // Avrupa
      'Europe/London': 'GB',
      'Europe/Paris': 'FR',
      'Europe/Berlin': 'DE',
      'Europe/Rome': 'IT',
      'Europe/Madrid': 'ES',
      'Europe/Amsterdam': 'NL',
      'Europe/Brussels': 'BE',
      'Europe/Vienna': 'AT',
      'Europe/Zurich': 'CH',
      'Europe/Stockholm': 'SE',
      'Europe/Oslo': 'NO',
      'Europe/Copenhagen': 'DK',
      'Europe/Helsinki': 'FI',
      'Europe/Warsaw': 'PL',
      'Europe/Prague': 'CZ',
      'Europe/Budapest': 'HU',
      'Europe/Bucharest': 'RO',
      'Europe/Sofia': 'BG',
      'Europe/Athens': 'GR',
      'Europe/Lisbon': 'PT',
      // Asya
      'Asia/Tokyo': 'JP',
      'Asia/Shanghai': 'CN',
      'Asia/Hong_Kong': 'HK',
      'Asia/Singapore': 'SG',
      'Asia/Dubai': 'AE',
      'Asia/Riyadh': 'SA',
      'Asia/Kolkata': 'IN',
      'Asia/Bangkok': 'TH',
      'Asia/Seoul': 'KR',
      // Diğer
      'Australia/Sydney': 'AU',
      'Australia/Melbourne': 'AU',
      'Pacific/Auckland': 'NZ',
      'America/Toronto': 'CA',
      'America/Mexico_City': 'MX',
      'America/Sao_Paulo': 'BR',
      'America/Buenos_Aires': 'AR',
    };

    return timezoneCountryMap[timezone] ?? '';
  }
}

