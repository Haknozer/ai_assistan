/// Timezone yardımcı fonksiyonları
class TimezoneHelper {
  /// Outlook API'den gelen dateTime string'ini parse et
  /// Outlook bazen timezone bilgisi ile birlikte gönderir
  static DateTime parseOutlookDateTime(String dateTimeStr) {
    try {
      // Outlook formatı: "2025-12-15T07:30:00.0000000" veya "2025-12-15T07:30:00.0000000Z"
      // Eğer 'Z' ile bitiyorsa UTC, değilse local time olabilir
      
      // Önce direkt parse et
      DateTime parsed = DateTime.parse(dateTimeStr);
      
      // Eğer string 'Z' ile bitiyorsa UTC'dir, local'e çevir
      if (dateTimeStr.endsWith('Z')) {
        return parsed.toLocal();
      }
      
      // Eğer string timezone offset içeriyorsa (örn: +03:00)
      if (dateTimeStr.contains('+') || dateTimeStr.contains('-')) {
        // DateTime.parse zaten timezone'u handle eder
        return parsed.toLocal();
      }
      
      // Timezone bilgisi yoksa, UTC olarak kabul et ve local'e çevir
      // Outlook genellikle UTC gönderir
      if (!parsed.isUtc) {
        // Eğer UTC değilse, UTC olarak kabul et
        parsed = DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
        );
      }
      
      return parsed.toLocal();
    } catch (e) {
      // Parse hatası durumunda şimdiki zamanı döndür
      return DateTime.now();
    }
  }

  /// Google Calendar API'den gelen dateTime string'ini parse et
  static DateTime parseGoogleDateTime(String dateTimeStr) {
    try {
      // Google formatı: "2025-12-15T07:30:00Z" veya "2025-12-15T07:30:00+03:00"
      final parsed = DateTime.parse(dateTimeStr);
      
      // Eğer UTC ise local'e çevir
      if (parsed.isUtc) {
        return parsed.toLocal();
      }
      
      // Zaten local timezone'da
      return parsed;
    } catch (e) {
      return DateTime.now();
    }
  }

  /// DateTime'ı timezone-aware olarak karşılaştır
  /// İki tarih aynı zamanı temsil ediyorsa true döner (timezone farkına rağmen)
  static bool isSameTime(DateTime date1, DateTime date2, {Duration tolerance = const Duration(minutes: 5)}) {
    // UTC'ye çevir ve karşılaştır
    final utc1 = date1.toUtc();
    final utc2 = date2.toUtc();
    final difference = (utc1.difference(utc2)).abs();
    return difference <= tolerance;
  }
}

